// import 'dart:io';

// import 'package:flutter/scheduler.dart';
// import 'package:wact/pages/splash_page.dart';
// import 'package:wact/root_layout.dart';

// import 'package:firebase_core/firebase_core.dart';
// import 'firebase_options.dart';
import 'dart:convert';
// import 'dart:html';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'firebase_options.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';

Future<void> sendNotiToDevice(
    {required deviceToken,
    required title,
    required content,
    required Map<String, dynamic> data}) async {
  final url = Uri.parse('https://fcm.googleapis.com/fcm/send');
  final headers = {
    'Contest-Type': 'application/json',
    'Authorization':
        'key=BPi_ZsKTbasEoaPsqDQ14HLpMCy0bQYsLex3-6EXthmm2_Nyi9ZbUzYFr4obH3TXU4ZnXR27muLTirSORvBmDwM'
  };
  final body = {
    'notification': {'title': title, 'body': content, 'data': data},
    'to': deviceToken
  };

  final response =
      await http.post(url, headers: headers, body: json.encode(body));

  if (response.statusCode == 200) {
    print('Success');
    print('$title $content');
  } else {
    print('Failed');
  }
}

void getMyDeviceToken() async {
  final tkn = await FirebaseMessaging.instance.getToken();
  print('My device token : $tkn');
}

class NotiBtn extends StatelessWidget {
  const NotiBtn({super.key});

  @override
  Widget build(BuildContext context) {
    ElevatedButton(
      onPressed: () => sendNotiToDevice(
          deviceToken: 'testTkn',
          title: '푸시테스트',
          content: '푸시테스트 내용',
          data: {'contents_idx': 1, 'test_parameter': '테스트'}),
      child: const Text('알림 전송'),
    );

    return const Placeholder();
  }
}

// // initialise the plugin. app_icon needs to be a added as a drawable resource to the Android head project
// const AndroidInitializationSettings initializationSettingsAndroid =
//     AndroidInitializationSettings('app_icon');
// final DarwinInitializationSettings initializationSettingsDarwin =
//     DarwinInitializationSettings(
//         onDidReceiveLocalNotification: onDidReceiveLocalNotification);
// final LinuxInitializationSettings initializationSettingsLinux =
//     LinuxInitializationSettings(
//         defaultActionName: 'Open notification');
// final InitializationSettings initializationSettings = InitializationSettings(
//     android: initializationSettingsAndroid,
//     iOS: initializationSettingsDarwin,
//     linux: initializationSettingsLinux);
// flutterLocalNotificationsPlugin.initialize(initializationSettings,
//     onDidReceiveNotificationResponse: onDidReceiveNotificationResponse);

// ...

// void onDidReceiveLocalNotification(
//     int id, String title?, String? body, String? payload) async {
//   // display a dialog with the notification details, tap ok to go to another page
//   showDialog(
//     context: context,
//     builder: (BuildContext context) => CupertinoAlertDialog(
//       title: Text(title),
//       content: Text(body),
//       actions: [
//         CupertinoDialogAction(
//           isDefaultAction: true,
//           child: Text('Ok'),
//           onPressed: () async {
//             Navigator.of(context, rootNavigator: true).pop();
//             await Navigator.push(
//               context,
//               MaterialPageRoute(
//                 builder: (context) => SecondScreen(payload),
//               ),
//             );
//           },
//         )
//       ],
//     ),
//   );
// }


// // // 파이어베이스 메시징 설정하는 코드
// // firebaseMessaging.configure(
// // 	// 포그라운드 콜백
// //     onMessage = (Map<String, dynamic> message) async {
// //     	_showNotification(message); // Local Notification 실제 처리 코드
// //     },
    
// //     // 백그라운드 콜백
// //     onBackgroundMessage = ...
// //     // 앱 종료 콜백
// //     onLaunch: ..
// //     // 앱 종료되었지만, 백그라운드에 있는 경우
// //     onResume: .. 
// // );


// // Future _showNotification(message) async {
// //     String title, body;

// //     // AOS, iOS에 따라 message 오는 구조가 다르다. (직접 파베 찍어보면 확인 가능)
// //     if(Platform.isAndroid){
// //       title = message['notification']['title'];
// //       body = message['notification']['body'];
// //     }
// //     if(Platform.isIOS){
// //       title = message['aps']['alert']['title'];
// //       body = message['aps']['alert']['body'];
// //     }

// //     // AOS, iOS 별로 notification 표시 설정 
// //     var androidNotiDetails = AndroidNotificationDetails('dexterous.com.flutter.local_notifications', title, body, importance: Importance.max, priority: Priority.max);
// //     var iOSNotiDetails = IOSNotificationDetails();

// //     var details = NotificationDetails(android: androidNotiDetails, iOS: iOSNotiDetails);

// //     await flutterLocalNotificationsPlugin.show(0, title, body, details
// // 	// 0은 notification id 값을 넣으면 된다.
// // }
// // @override
// // void initState() {
// //    super.initState();
// //    ...
   
// //    _localNotiSetting(); // Local notificiatioin 초기 설정
// // }

// // void _localNotiSetting() async {
// //     var androidInitializationSettings =AndroidInitializationSettings('@mipmap/ic_launcher');
// //     // 안드로이드 알림 올 때 앱 아이콘 설정
    
// //     var iOSInitializationSettings = IOSInitializationSettings(
// //         requestAlertPermission: true,
// //         requestBadgePermission: true,
// //         requestSoundPermission: true);
// // 	// iOS 알림, 뱃지, 사운드 권한 셋팅
// //     // 만약에 사용자에게 앱 권한을 안 물어봤을 경우 이 셋팅으로 인해 permission check 함

// //     var initsetting = InitializationSettings(
// //         android: androidInitializationSettings, iOS: iOSInitializationSettings);

// //     await flutterLocalNotificationsPlugin.initialize(initsetting);
// // }