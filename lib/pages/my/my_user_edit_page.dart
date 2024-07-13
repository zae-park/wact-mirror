import 'package:wact/common/const/color.dart';
import 'package:wact/common/init.dart';
import 'package:wact/common/init.dart';
import 'package:wact/root_layout.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserEditPage extends StatefulWidget {
  const UserEditPage({Key? key}) : super(key: key);

  @override
  State<UserEditPage> createState() => _UserEditPageState();
}

class _UserEditPageState extends State<UserEditPage> {
  final TextEditingController _usernameController = TextEditingController();
  bool _isLoading = false;
  bool _isUsernameAvailable = false; // 중복 확인 결과 저장
  bool _usernameValid = true; // 형식 유효성 검사
  bool _isSubmitButtonEnabled = false; // 완료 버튼 활성화 상태

  @override
  void initState() {
    super.initState();
    _fetchCurrentUsername();
    _usernameController.addListener(_onUsernameChanged);
  }

  void _onUsernameChanged() {
    final username = _usernameController.text;
    // 닉네임 형식 검사
    if (username.length >= 2 &&
        username.length <= 15 &&
        RegExp(r'^[a-zA-Z0-9_\uAC00-\uD7A3]+$').hasMatch(username) &&
        !RegExp(r'[\u3131-\u314E\u314F-\u3163]+').hasMatch(username)) {
      setState(() {
        _usernameValid = true;
      });
    } else {
      setState(() {
        _usernameValid = false;
      });
    }

    // 중복 확인 완료 후 닉네임 수정 시 '완료' 버튼 비활성화
    setState(() {
      _isUsernameAvailable = false; // 중복 확인 상태 초기화
      _isSubmitButtonEnabled = false; // '완료' 버튼 비활성화
    });
  }

  Future<void> _fetchCurrentUsername() async {
    setState(() {
      _isLoading = true;
    });
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final response = await Supabase.instance.client
          .from('profiles')
          .select('username')
          .eq('id', user.id)
          .single();

      debugPrint('response: $response');

      if (response.isNotEmpty) {
        _usernameController.text = response['username'];
      }
    }
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _checkUsernameAvailable() async {
    final username = _usernameController.text.trim();
    if (!_usernameValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('닉네임 형식이 올바르지 않습니다.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response =
          await supabase.from('profiles').select().eq('username', username);

      final data = response;
      final exists = data.isNotEmpty;

      setState(() {
        _isUsernameAvailable = !exists;
        _isSubmitButtonEnabled = !exists; // 중복되지 않는 경우에만 완료 버튼 활성화
      });

      _showSnackBar(
          exists ? '이미 사용 중인 닉네임입니다. 다른 닉네임을 선택해주세요.' : '사용 가능한 닉네임입니다.');
    } catch (error) {
      _showSnackBar('닉네임 중복 확인 중 오류가 발생했습니다.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _updateUsername() async {
    setState(() {
      _isLoading = true;
    });
    final userName = _usernameController.text.trim();
    final user = supabase.auth.currentUser;
    final updates = {
      'id': user!.id,
      'username': userName,
      'updated_at': DateTime.now().toIso8601String(),
    };
    try {
      await supabase.from('profiles').upsert(updates);
      if (mounted) {
        // 페이지 이동 전에 현재 표시 중인 SnackBar를 제거합니다.
        ScaffoldMessenger.of(context).clearSnackBars();
        Get.offAll(() => const RootLayout(initialTab: 1));
      }
    } on PostgrestException catch (error) {
      SnackBar(
        content: Text(error.message),
        backgroundColor: Theme.of(context).colorScheme.error,
      );
    } catch (error) {
      SnackBar(
        content: const Text('Unexpected error occurred'),
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
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvoked: ((didPop) =>
          ScaffoldMessenger.of(context).clearSnackBars()),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              ScaffoldMessenger.of(context).clearSnackBars();
              Navigator.of(context).pop();
            },
          ),
          actions: <Widget>[
            IconButton(
              onPressed: _isSubmitButtonEnabled && !_isLoading
                  ? _updateUsername
                  : null,
              icon: Icon(
                Icons.check,
                color: _isSubmitButtonEnabled ? primary : Colors.grey,
              ),
            ),
          ],
          title: const Text('닉네임 수정'),
          backgroundColor: Colors.white,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: '닉네임',
                  errorText:
                      _usernameValid ? null : '2~15자의 한글, 영문, 숫자, 밑줄(_)만 사용 가능',
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.resolveWith<Color?>(
                    (Set<MaterialState> states) {
                      if (states.contains(MaterialState.disabled)) {
                        return Colors.grey;
                      }
                      return _isSubmitButtonEnabled
                          ? Colors.black
                          : Colors.grey; // 중복 확인 완료 시 활성화
                    },
                  ),
                ),
                onPressed: _usernameValid && !_isLoading
                    ? _checkUsernameAvailable
                    : null,
                child: Text(
                  _isLoading ? '확인중...' : '중복 확인',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
