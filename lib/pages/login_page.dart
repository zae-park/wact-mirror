// 카톡 로그인 페이지

import 'dart:async';

import 'package:wact/common/const/color.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wact/main.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isLoading = false;
  bool _redirecting = false;
  late final StreamSubscription<AuthState> _authStateSubscription;

  Future<void> _signIn() async {
    final prefs = await SharedPreferences.getInstance();
    bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    if (isLoggedIn) {
      Navigator.of(context).pushReplacementNamed('/home');
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      await supabase.auth.signInWithOAuth(
        OAuthProvider.kakao,
        redirectTo: kIsWeb
            ? 'http://localhost:3000'
            : 'io.supabase.actapp://login-callback/',
      );

      // 로그인 성공 시 로컬 스토리지에 상태 저장
      await prefs.setBool('isLoggedIn', true);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('카톡 로그인 성공')),
        );
      }
    } on AuthException catch (error) {
      SnackBar(
        content: Text(error.message),
        backgroundColor: Theme.of(context).colorScheme.error,
      );
    } catch (error) {
      SnackBar(
        content: const Text('예상치못한 오류 발생'),
        backgroundColor: Theme.of(context).colorScheme.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void initState() {
    _authStateSubscription = supabase.auth.onAuthStateChange.listen((data) {
      if (_redirecting) return;
      final session = data.session;
      if (session != null) {
        _redirecting = true;
        Navigator.of(context).pushReplacementNamed('/account');
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    _authStateSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: const IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white), // 흰색 뒤로가기 아이콘
          onPressed: null, // 비활성화
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 90,
                height: 90,
                child: Image.asset(
                  'assets/imgs/logo/actlogo.jpg',
                ),
              ),
              const SizedBox(
                height: 190,
              ),
              const Text(
                'SNS 계정 가입',
                style: TextStyle(color: bg_90, fontSize: 12),
              ),
              const SizedBox(height: 24),
              // 카톡 로그인
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: _isLoading ? null : _signIn,
                    child: SizedBox(
                        width: 54,
                        height: 54,
                        child: Image.asset(
                          'assets/imgs/logo/sns/kakao.png',
                          fit: BoxFit.contain,
                        )),
                  ), //
                ],
              ),
            ]),
      ),
    );
  }
}
