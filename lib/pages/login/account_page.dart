// 유저 상세 정보 입력페이지

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wact/common/init.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  _AccountPageState createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final _usernameController = TextEditingController();
  final _universityController = TextEditingController();
  final _studentidController = TextEditingController();
  final _groupCodeController = TextEditingController();
  final _teamController = TextEditingController(); // 안 쓰는 것 같음
  String? _selectedGroup;
  String? _selectedTeam;
  bool _isUsernameEmpty = true;

  var _loading = true;

  Future<void> _getProfile() async {
    setState(() {
      _loading = true;
    });

    try {
      final userId = supabase.auth.currentUser!.id;
      final data =
          await supabase.from('profiles').select().eq('id', userId).single();

      // 이름 정보가 있는지 확인
      final username = (data['username'] ?? '') as String;
      _isUsernameEmpty = username.isEmpty;

      _usernameController.text = username;
      _studentidController.text = (data['studentid'] ?? '') as String;
      _universityController.text = (data['university'] ?? '') as String;
      _selectedGroup = (data['group_name'] ?? '') as String;
      _selectedTeam = (data['team'] ?? '') as String;
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
          _loading = false;
        });
      }
    }
  }

  /// Called when user taps `Update` button
  Future<void> _updateProfile() async {
    debugPrint('프로필 업데이트 시작~');
    setState(() {
      _loading = true;
    });
    final userName = _usernameController.text.trim();
    final studentid = _studentidController.text.trim();
    final university = _universityController.text.trim();
    final group = _selectedGroup ?? '';
    final team = _selectedTeam ?? '';

    final user = supabase.auth.currentUser;
    final updates = {
      'id': user!.id,
      'updated_at': DateTime.now().toIso8601String(),
      'username': userName,
      'studentid': studentid,
      'university': university,
      'group': group,
      'team': team,
    };

    final codeInfo = await _getGroupCode();
    debugPrint('코드 업데이트 시작~$codeInfo');

    if (_groupCodeController.text == codeInfo) {
      try {
        await supabase.from('profiles').upsert(updates);

        // 회원가입 완료 후 첫 로그인 플래그를 false로 설정
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isFirstLogin', false);

        if (mounted) {
          const SnackBar(
            content: Text('Successfully updated profile!'),
          );
          Navigator.of(context).pushReplacementNamed('/home');
        }
      } on PostgrestException catch (error) {
        debugPrint('코드 오류~$error.message');

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
            _loading = false;
          });
        }
      }
    } else {
      showDialog(
          context: context,
          builder: (BuildContext context) => Dialog(
                backgroundColor: Colors.black,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      const Text(
                        '코드가 유효하지 않습니다.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 15),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _loading = false;
                          });
                          Navigator.pop(context);
                        },
                        child: const Text(
                          '닫기',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ));
    }
  }

  Future<void> _signOut() async {
    try {
      await supabase.auth.signOut();
    } on AuthException catch (error) {
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
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }

  Future<String> _getGroupCode() async {
    final codeInfo = await supabase
        .from('codes')
        .select()
        .eq('group_name', _selectedGroup ?? '')
        .single();
    return codeInfo['group_code'];
  }

  @override
  void initState() {
    super.initState();
    _getProfile();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _universityController.dispose();
    _studentidController.dispose();
    _groupCodeController.dispose();
    _teamController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          '프로필',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
              children: [
                // 이름 입력 필드는 이름이 비어있을 때만 표시
                if (_isUsernameEmpty)
                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                        labelText: '이름', hintText: '성과 이름을 같이 입력해주세요.'),
                  ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _universityController,
                  decoration: const InputDecoration(labelText: '대학교'),
                ),
                const SizedBox(height: 18),
                TextFormField(
                  maxLength: 2,
                  controller: _studentidController,
                  decoration: const InputDecoration(
                      labelText: '학번', hintText: '숫자만 입력해주세요.'),
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _groupCodeController,
                  decoration: const InputDecoration(labelText: '코드'),
                ),
                const SizedBox(height: 18),
                DropdownButton<String>(
                  style: const TextStyle(color: Colors.black),
                  dropdownColor: Colors.white,
                  value: _selectedGroup != null &&
                          _selectedGroup!.isNotEmpty &&
                          ['서중한액트', '동중한액트'].contains(_selectedGroup)
                      ? _selectedGroup
                      : null, // 유효하지 않은 값이거나 null이면 null로 설정
                  hint: const Text('합회'),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedGroup = newValue;
                    });
                  },
                  items: <String>[
                    '서중한액트',
                    '동중한액트',
                  ].map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(
                        value,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 18),
                DropdownButton<String>(
                  style: const TextStyle(color: Colors.black),
                  dropdownColor: Colors.white,
                  value: _selectedTeam != null &&
                          _selectedTeam!.isNotEmpty &&
                          ['강남', '시내', '신촌', '인천', '태릉', '오비', '청년', '목회자']
                              .contains(_selectedTeam)
                      ? _selectedTeam
                      : null, // 유효하지 않은 값이면 null로 설정
                  hint: const Text('소속'),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedTeam = newValue;
                    });
                  },
                  items: <String>[
                    '강남',
                    '시내',
                    '신촌',
                    '인천',
                    '태릉',
                    '오비',
                    '청년',
                    '목회자',
                  ].map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(
                        value,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 18),
                ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor:
                        MaterialStateProperty.all<Color>(Colors.black),
                  ),
                  onPressed: _loading
                      ? null
                      : () {
                          if (_usernameController.text.isNotEmpty &&
                              _universityController.text.isNotEmpty &&
                              _studentidController.text.isNotEmpty &&
                              _groupCodeController.text.isNotEmpty &&
                              _selectedGroup != null &&
                              _selectedGroup!.isNotEmpty &&
                              _selectedTeam != null &&
                              _selectedTeam!.isNotEmpty) {
                            _updateProfile();
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '양식을 모두 작성해주세요',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500),
                                ),
                                backgroundColor: Colors.black,
                              ),
                            );
                          }
                        },
                  child: Text(
                    _loading ? '저장중...' : '입장',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 18),
                TextButton(
                  onPressed: _signOut,
                  child: const Text(
                    '로그아웃',
                    style: TextStyle(
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
