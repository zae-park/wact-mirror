import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wact/common/init.dart';
import 'package:wact/common/theme/app_theme.dart';
import 'package:wact/pages/login/account_page.dart';
import 'package:wact/pages/login/login_page.dart';
import 'package:wact/pages/login/splash_page.dart';
import 'package:wact/root_layout.dart';
import 'package:wact/routes/route.dart';

Future<void> main() async {
  await initializeApp();

  runApp(const MyApp());
}

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
      routes: getAppRoutes(),
    );
  }
}
