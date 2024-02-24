// 처음 호출되는 페이지로 기존 사용자 유무 체크 후 메인 혹은 로그인으로 이동

import 'package:flutter/material.dart';
import 'package:wact/main.dart';

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
    await Future.delayed(Duration.zero);

    if (!mounted) return;

    final session = supabase.auth.currentSession;
    if (session != null) {
      // 사용자의 프로필 정보 가져오기
      final response = await supabase
          .from('profiles')
          .select('username, university')
          .eq('id', session.user.id)
          .single();
      // 여기서 다시 mounted 체크

      if (!mounted) return;

      if (response.isNotEmpty) {
        // username과 website가 있는 경우 RootLayout으로 이동
        Navigator.of(context).pushReplacementNamed('/home');
      } else {
        // 없는 경우 AccountPage로 이동
        Navigator.of(context).pushReplacementNamed('/account');
      }
    } else {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
