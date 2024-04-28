// 카톡 로그인 페이지

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
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
  StreamSubscription<AuthState>? _authStateSubscription;
  final String supabaseClientId = 'com.one.wact';
  final String expectedIssuer = 'https://appleid.apple.com';
  final String expectedAudience = 'com.one.wact';

  @override
  void initState() {
    super.initState();
    _checkCurrentSession();
    _setupAuthListener();
  }

  void _checkCurrentSession() async {
    final currentSession = supabase.auth.currentSession;
    if (currentSession != null) {
      // 현재 세션이 유효하므로 홈 화면으로 바로 넘어감.
      _redirecting = true;

      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  void _setupAuthListener() {
    _authStateSubscription =
        supabase.auth.onAuthStateChange.listen((data) async {
      if (_redirecting) return;
      final session = data.session;
      if (session != null) {
        // 사용자 프로필 조회하여 username 확인
        final userProfile = await supabase
            .from('profiles')
            .select('username')
            .eq('id', session.user.id)
            .maybeSingle();

        debugPrint('사용자 프로필 조회: $userProfile');
        if (userProfile == null) {
          Navigator.of(context).pushReplacementNamed('/account');
        } else {
          Navigator.of(context).pushReplacementNamed('/home');
        }
      }
    });
  }

  Future<void> _signIn() async {
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
      final prefs = await SharedPreferences.getInstance();
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

  void verifyTokenAndNonce(String idToken, String rawNonce) {
    final parts = idToken.split('.');
    if (parts.length != 3) {
      debugPrint('ID 토큰 형식이 올바르지 않습니다.');
      return;
    }

    debugPrint('ID토큰 parts: $parts');

    final payload = json
        .decode(utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))));
    debugPrint('payload: $payload');

    final tokenExp = payload['exp'];
    debugPrint('tokenExp: $tokenExp');

    final tokenNonce = payload['nonce'];
    debugPrint('tokenNonce: $tokenNonce');

    final tokenAud = payload['aud']; // `aud` 필드 추출
    debugPrint('tokenAud: $tokenAud');

    final tokenIss = payload['iss']; // `iss` 필드
    debugPrint('tokenIss: $tokenIss');

    final tokenSub = payload['sub']; // `sub` 필드
    debugPrint('tokenSub: $tokenSub');

    // exp 필드 검증
    final currentTime = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
    debugPrint('currentTime: $currentTime');

    if (tokenExp < currentTime) {
      debugPrint('ID 토큰이 만료되었습니다.');
    } else {
      debugPrint('ID 토큰이 유효합니다.');
    }

    // nonce 값 일치 확인
    if (tokenNonce == rawNonce) {
      debugPrint('Nonce 값이 일치합니다.');
    } else {
      debugPrint('Nonce 값이 일치하지 않습니다.');
    }

    // `aud` 필드 검증
    if (tokenAud == supabaseClientId) {
      debugPrint('aud 필드가 일치합니다. 토큰이 해당 서비스를 위한 것입니다.');
    } else {
      debugPrint('aud 필드가 일치하지 않습니다. 토큰이 이 서비스를 위한 것이 아닙니다.');
    }

    if (tokenIss == expectedIssuer) {
      debugPrint('iss 필드가 올바릅니다.');
    } else {
      debugPrint('iss 필드가 기대하는 값과 다릅니다.');
    }

    // `sub` 필드는 일반적으로 사용자 식별자로, 특정 값과의 일치 여부보다는 값의 존재 유무를 검사하는 것이 일반적입니다.
    if (tokenSub != null && tokenSub.isNotEmpty) {
      debugPrint('sub 필드가 유효합니다.');
    } else {
      debugPrint('sub 필드가 유효하지 않습니다.');
    }

    // email_verified 검증
    final emailVerified = payload['email_verified'] == 'true' ||
        payload['email_verified'] == true;
    debugPrint('이메일 검증됨: $emailVerified');

    // is_private_email 검증
    final isPrivateEmail = payload['is_private_email'] == 'true' ||
        payload['is_private_email'] == true;
    debugPrint('프라이빗 이메일: $isPrivateEmail');

    // real_user_status 검증 로직 추가
    final realUserStatus = payload['real_user_status'];
    debugPrint('realUserStatus: $realUserStatus');

    if (realUserStatus != null) {
      switch (realUserStatus) {
        case 0: // Unsupported
          debugPrint('실제 사용자 상태: Unsupported');
          break;
        case 1: // Unknown
          debugPrint('실제 사용자 상태: Unknown');
          // 여기서 추가적인 검증 로직을 수행할 수 있습니다.
          break;
        case 2: // LikelyReal
          debugPrint('실제 사용자 상태: LikelyReal');
          // 사용자를 실제 사람으로 간주하고 계속 진행합니다.
          break;
        default:
          debugPrint('알 수 없는 실제 사용자 상태');
      }
    }
  }

  Future<void> _appleSignIn() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final rawNonce = supabase.auth.generateRawNonce();
      final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();

      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );

      final idToken = credential.identityToken;
      if (idToken == null) {
        throw const AuthException(
            'Could not find ID Token from generated credential.');
      }

      verifyTokenAndNonce(idToken, hashedNonce);

      final response = await supabase.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: idToken,
        nonce: rawNonce,
      );

      debugPrint('애플로그인성공');
      // 스낵바가 사라질 때까지 기다린 후 페이지 이동
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('로그인 프로세스가 사용자에 의해 취소되었습니다.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          // SnackBar(content: Text('로그인 중 오류 발생: ${e.message}')),
          const SnackBar(content: Text('로그인을 취소했습니다.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('애플 로그인 중 예기치 않은 오류 발생: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _appleSignInAndroid() async {
    debugPrint('애플 안드로이드 로그인 시작');
    try {
      setState(() {
        _isLoading = true;
      });

      await supabase.auth.signInWithOAuth(
        OAuthProvider.apple,
        redirectTo: 'io.supabase.actapp://login-callback/',
      );
      // 로그인 성공 시 로컬 스토리지에 상태 저장
      final prefs = await SharedPreferences.getInstance();
      debugPrint('로컬 저장정보: $prefs');
      await prefs.setBool('isLoggedIn', true);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('애플 로그인 성공')),
        );
      }
    } on AuthException catch (error) {
      debugPrint('애플 로그인 AuthException 오류: $error');

      SnackBar(
        content: Text(error.message),
        backgroundColor: Theme.of(context).colorScheme.error,
      );
    } catch (error) {
      debugPrint('애플 로그인 오류: $error');
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
  void dispose() {
    _authStateSubscription?.cancel();
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
                  // GestureDetector(
                  //   onTap: _isLoading ? null : _signIn,
                  //   child: SizedBox(
                  //     width: 54,
                  //     height: 54,
                  //     child: Image.asset(
                  //       'assets/imgs/logo/sns/kakao.png',
                  //       fit: BoxFit.contain,
                  //     ),
                  //   ),
                  // ),
                  // const SizedBox(
                  //   width: 20,
                  // ),
                  if (Platform.isIOS)
                    GestureDetector(
                      onTap: _isLoading ? null : _appleSignIn,
                      child: SizedBox(
                        width: 54,
                        height: 54,
                        child: Image.asset(
                          'assets/imgs/logo/sns/apple.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    )
                  else
                    GestureDetector(
                      onTap: _isLoading ? null : _appleSignInAndroid,
                      child: SizedBox(
                        width: 54,
                        height: 54,
                        child: Image.asset(
                          'assets/imgs/logo/sns/apple.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                ],
              ),
            ]),
      ),
    );
  }
}
