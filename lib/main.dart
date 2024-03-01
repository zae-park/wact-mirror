import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wact/common/theme/app_theme.dart';
import 'package:wact/pages/account_page.dart';
import 'package:wact/pages/login_page.dart';
import 'package:wact/pages/splash_page.dart';
import 'package:wact/root_layout.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'notification/messaging_page.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

Future<void> onTokenRefreshFCM() async {
  print('FCM 토큰 관련 함수 체크예정');
  FirebaseMessaging.instance.onTokenRefresh.listen((String fcmToken) async {
    print("New token: $fcmToken");
    // FFAppState().fcmTokenRefresh = true;
  }, onError: (err) async {
    print("Error getting token");
  });
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FirebaseApp firebaseInit = await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 카톡앱 '캄피-TEST' 키
  KakaoSdk.init(
    nativeAppKey: '5d4cef15a6813674d5a8e4fd5907ac4f',
    javaScriptAppKey: '9f1a4a118913974e699835637ce11dca',
  );

  Supabase supabaseInit = await Supabase.initialize(
    url: 'https://tucpydftldyqknodgghy.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR1Y3B5ZGZ0bGR5cWtub2RnZ2h5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MDQ3OTI0NTgsImV4cCI6MjAyMDM2ODQ1OH0.iCo1iAtV55fZjNpiYI-ccH6Hcrzhi55UB-yZYNtkKsg',
  );

  await Firebase.initializeApp();

  var channel = const AndroidNotificationChannel(
    'high_importance_channel', // id
    'High Importance Notifications', // name
    description:
        'This channel is used for important notifications.', // description
    importance: Importance.high,
  );

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('Receive push-notification in foreground');
    print('Handling a foreground message: ${message.data}');
  });

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print('Push=notification was tapped');
    // 사용자가 푸시 알림을 탭하여 앱을 열었을 때 수행할 로직
  });

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  runApp(const MyApp());
}

final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''), // 영어
        Locale('ko', ''), // 한국어 추가
      ],
      debugShowCheckedModeBanner: false,
      title: 'Supabase Flutter',
      theme: appTheme,
      initialRoute: '/',
      routes: <String, WidgetBuilder>{
        '/': (_) => const SplashPage(),
        '/login': (_) => const LoginPage(),
        '/account': (_) => const AccountPage(),
        '/home': (_) => const HomePage(),
        // '/home': (_) => const RootLayout(),
      },
    );
  }
}
