import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wact/common/init.dart';
import 'package:wact/common/theme/app_theme.dart';
import 'package:wact/pages/home/post/post_detail_page.dart';
import 'package:wact/pages/home/review/review_detail_page.dart';
import 'package:wact/pages/login/account_page.dart';
import 'package:wact/pages/login/login_page.dart';
import 'package:wact/pages/login/splash_page.dart';
import 'package:wact/root_layout.dart';
import 'package:wact/routes/route.dart';

Future<void> main() async {
  await initializeApp();
  FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpened);
  runApp(const MyApp());
}

// 알림 클릭 시, 실행될 함수
void _handleMessageOpened(RemoteMessage message) async {
  // `click_action` 데이터 경로를 추출
  if (message.data.containsKey('click_action')) {
    final action = message.data['click_action'];
    final id = Uri.parse(action).queryParameters['id'];

    if (action.contains('post_detail')) {
      final postData = await fetchPostData(int.parse(id!));
      Get.to(() => PostDetailPage(
            post: postData,
            refreshCallback: () => {},
          ));
    } else if (action.contains('review_detail')) {
      final reviewData = await fetchReviewData(int.parse(id!));
      Get.to(() => ReviewDetailPage(
            review: reviewData,
            currentIndex: 0,
            onUpdateSuccess: () => {},
          ));
    }
  }
}

Future<Map<String, dynamic>> fetchPostData(int postId) async {
  final response = await Supabase.instance.client
      .from('posts')
      .select('*')
      .eq('id', postId)
      .single();

  return response;
}

Future<Map<String, dynamic>> fetchReviewData(int reviewId) async {
  final response = await Supabase.instance.client
      .from('reviews')
      .select('*')
      .eq('id', reviewId)
      .single();

  return response;
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
