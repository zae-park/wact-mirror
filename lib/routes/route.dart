import 'package:flutter/material.dart';
import 'package:wact/pages/login/account_page.dart';
import 'package:wact/pages/login/login_page.dart';
import 'package:wact/pages/login/splash_page.dart';
import 'package:wact/root_layout.dart';

Map<String, WidgetBuilder> getAppRoutes() {
  return {
    '/': (_) => const SplashPage(),
    '/login': (_) => const LoginPage(),
    '/account': (_) => const AccountPage(),
    '/home': (_) => const RootLayout(
          initialTab: 0,
        ),
  };
}
