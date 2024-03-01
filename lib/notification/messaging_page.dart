import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// reference: https://totally-developer.tistory.com/149

String server_key =
    'BPi_ZsKTbasEoaPsqDQ14HLpMCy0bQYsLex3-6EXthmm2_Nyi9ZbUzYFr4obH3TXU4ZnXR27muLTirSORvBmDwM';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  // 세부 내용이 필요한 경우 추가...
}

@pragma('vm:entry-point')
void backgroundHandler(NotificationResponse details) {
  // 액션 추가... 파라미터는 details.payload 방식으로 전달
}

void initializeNotification() async {
  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(const AndroidNotificationChannel(
          'high_importance_channel', 'high_importance_notification',
          importance: Importance.max));

  await flutterLocalNotificationsPlugin.initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings("@mipmap/ic_launcher"),
      iOS: DarwinInitializationSettings(),
    ),
    onDidReceiveNotificationResponse: (details) {
      // 액션 추가...
    },
    onDidReceiveBackgroundNotificationResponse: backgroundHandler,
  );

  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    RemoteNotification? notification = message.notification;

    if (notification != null) {
      flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'high_importance_channel',
              'high_importance_notification',
              importance: Importance.max,
            ),
            iOS: DarwinNotificationDetails(),
          ),
          payload: message.data['test_paremeter1']);

      print("수신자 측 메시지 수신");
    }
  });

  RemoteMessage? message = await FirebaseMessaging.instance.getInitialMessage();

  if (message != null) {
    // 액션 부분 -> 파라미터는 message.data['test_parameter1'] 이런 방식으로...
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  initializeNotification();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  var messageString = "";

  bool isSent = false;
  late String deviceTkn;

  Future<void> getMyDeviceToken() async {
    deviceTkn = await FirebaseMessaging.instance.getToken() ?? '';
    print("내 디바이스 토큰: $deviceTkn");
  }

  Future<void> sendNotificationToDevice(
      {required String deviceToken,
      required String title,
      required String content,
      required Map<String, dynamic> data}) async {
    final url = Uri.parse('https://fcm.googleapis.com/fcm/send');

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'key=$server_key',
    };

    final body = {
      'notification': {'title': title, 'body': content, 'data': data},
      'to': deviceToken,
    };

    final response =
        await http.post(url, headers: headers, body: json.encode(body));

    if (response.statusCode == 200) {
      // Notification sent successfully

      print("성공적으로 전송되었습니다.");

      print("$title $content");
    } else {
      // Failed to send notification

      print("전송에 실패하였습니다. ErrCode: ${response.statusCode}");
    }
  }

  @override
  void initState() {
    getMyDeviceToken();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("메시지 내용: $messageString"),
            ElevatedButton(
              onPressed: () => sendNotificationToDevice(
                  deviceToken: deviceTkn,
                  title: '푸시 알림 테스트',
                  content: '푸시 알림 내용',
                  data: {'test_parameter1': 1, 'test_parameter2': '테스트1'}),
              child: const Text("알림 전송"),
            )
          ],
        ),
      ),
    );
  }
}
