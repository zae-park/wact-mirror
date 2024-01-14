import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wact/common/theme/app_theme.dart';
import 'package:wact/pages/account_page.dart';
import 'package:wact/pages/login_page.dart';
import 'package:wact/pages/splash_page.dart';
import 'package:wact/root_layout.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 카톡 캄피-TEST 키
  KakaoSdk.init(
    nativeAppKey: '5d4cef15a6813674d5a8e4fd5907ac4f',
    javaScriptAppKey: '9f1a4a118913974e699835637ce11dca',
  );

  await Supabase.initialize(
    url: 'https://tucpydftldyqknodgghy.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR1Y3B5ZGZ0bGR5cWtub2RnZ2h5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MDQ3OTI0NTgsImV4cCI6MjAyMDM2ODQ1OH0.iCo1iAtV55fZjNpiYI-ccH6Hcrzhi55UB-yZYNtkKsg',
  );

  runApp(const MyApp());
}

final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
        '/home': (_) => const RootLayout(),
      },
    );
  }
}
