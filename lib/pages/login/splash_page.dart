// 처음 호출되는 페이지로 기존 사용자 유무 체크 후 메인 혹은 로그인으로 이동

import 'package:flutter/material.dart';
import 'package:wact/common/init.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  _SplashPageState createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _redirect();
  }

  Future<void> _redirect() async {
    await Future.delayed(Duration.zero); // UI 안정화를 위한 지연

    if (!mounted) return;

    final session = supabase.auth.currentSession;
    if (session != null) {
      // 세션이 존재할 경우
      final response = await supabase
          .from('profiles')
          .select('username')
          .eq('id', session.user.id)
          .maybeSingle();

      if (!mounted) return;

      if (response == null || response['username'] == null) {
        // 프로필 정보가 없으면 '프로필' 페이지로 이동
        Navigator.of(context).pushReplacementNamed('/account');
      } else {
        // 프로필 정보가 있으면 홈 화면으로 이동
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } else {
      // 세션이 없으면 로그인 페이지로 이동
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
          child: CircularProgressIndicator(
        color: Colors.black,
      )),
    );
  }
}
