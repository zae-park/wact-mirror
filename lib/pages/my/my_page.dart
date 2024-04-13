// 마이페이지
// 240406 탈퇴 항목 추가

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wact/common/const/color.dart';
import 'package:wact/pages/my/add_sermon_note_page.dart';
import 'package:wact/pages/my/my_bug_report_page.dart';
import 'package:wact/pages/my/my_home_page.dart';
import 'package:wact/pages/my/my_privacy_policy_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wact/pages/my/my_user_edit_page.dart';

class MyPage extends StatefulWidget {
  const MyPage({
    super.key,
  });

  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> with TickerProviderStateMixin {
  late Future<List<Map<String, dynamic>>>? _future;
  late Future<String> _usernameFuture;
  late final TabController _tabController;
  DateTime? _scheduledDeletionDate;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(vsync: this, length: 2);

    _usernameFuture = _getUsername();
    _loadData();
    _fetchScheduledDeletionDate();
  }

  Future<String> _getUsername() async {
    final userId = Supabase.instance.client.auth.currentUser!.id;
    final response = await Supabase.instance.client
        .from('profiles')
        .select()
        .eq('id', userId)
        .single();

    if (response.isEmpty) {
      throw Exception('Failed to load username');
    }

    final data = response;
    return data['team'] + ' ' + data['username'] ?? 'No username';
  }

  Future<void> _loadData() async {
    final userId =
        Supabase.instance.client.auth.currentUser!.id; // 현재 로그인한 사용자의 ID 가져오기

    _future = Supabase.instance.client
        .from('posts')
        .select()
        .eq('author_id', userId)
        .order('created_at', ascending: false);
    setState(() {});
  }

  Future<void> _fetchScheduledDeletionDate() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final response = await Supabase.instance.client
          .from('profiles')
          .select('scheduled_deletion_date')
          .eq('id', user.id)
          .single();

      setState(() {
        if (response['scheduled_deletion_date'] != null) {
          _scheduledDeletionDate =
              DateTime.parse(response['scheduled_deletion_date'] as String);
        } else {
          _scheduledDeletionDate = null;
        }
      });
    }
  }

  // 탈퇴 요청 대화상자를 표시하는 함수
  void _showDeleteAccountDialog() {
    // 이미 탈퇴 예정일이 설정되어 있는 경우
    if (_scheduledDeletionDate != null) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            surfaceTintColor: Colors.white,
            backgroundColor: Colors.white,
            title: const Text('탈퇴 취소'),
            content: const Text('탈퇴를 취소하시겠습니까?'),
            actions: <Widget>[
              TextButton(
                child: const Text(
                  '아니오',
                  style: TextStyle(color: bg_90, fontWeight: FontWeight.w500),
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
              TextButton(
                child: const Text(
                  '예',
                  style: TextStyle(color: primary, fontWeight: FontWeight.w500),
                ),
                onPressed: () async {
                  Navigator.of(context).pop(); // 대화상자를 닫고
                  await _cancelAccountDeletion(); // 탈퇴 취소 처리 함수 호출
                },
              ),
            ],
          );
        },
      );
    } else {
      // 탈퇴 예정일이 설정되어 있지 않은 경우, 탈퇴 요청 대화상자를 표시
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            surfaceTintColor: Colors.white,
            backgroundColor: Colors.white,
            title: const Text('계정 탈퇴'),
            content: const Text(
                '정말로 탈퇴하시겠습니까? \n탈퇴를 진행할 경우, 30일의 유예 기간이 부여되며, 이 기간 동안은 탈퇴를 취소할 수 있습니다. \n또한 기존에 작성한 모든 글이 비활성화되어, 다른 유저에게 보이지 않습니다.\n유예 기간이 만료되면 계정 정보와 모든 사진은 영구적으로 삭제됩니다.'),
            actions: <Widget>[
              TextButton(
                child: const Text(
                  '취소',
                  style: TextStyle(color: primary, fontWeight: FontWeight.w500),
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
              TextButton(
                child: const Text(
                  '탈퇴',
                  style: TextStyle(color: bg_90, fontWeight: FontWeight.w500),
                ),
                onPressed: () async {
                  Navigator.of(context).pop(); // 대화상자를 닫고
                  await _requestAccountDeletion(); // 탈퇴 요청 처리 함수 호출
                },
              ),
            ],
          );
        },
      );
    }
  }

  // 탈퇴 취소를 처리하는 함수
  Future<void> _cancelAccountDeletion() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      // Supabase에서 scheduled_deletion_date 항목을 제거
      await Supabase.instance.client
          .from('profiles')
          .update({'scheduled_deletion_date': null}).eq('id', user.id);

      // 상태 업데이트
      setState(() {
        _scheduledDeletionDate = null;
      });
    }
  }

// 탈퇴 요청을 처리하는 함수
  Future<void> _requestAccountDeletion() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final deletionDate =
          DateTime.now().add(Duration(days: 30)); // 30일 후의 날짜 계산
      await Supabase.instance.client.from('profiles').update({
        'scheduled_deletion_date': deletionDate.toIso8601String()
      }).eq('id', user.id);
      _fetchScheduledDeletionDate(); // 업데이트된 삭제 예정일을 다시 불러옴
    }
  }

  String _formatRemainingTime(DateTime scheduledDate) {
    final now = DateTime.now();
    final difference = scheduledDate.difference(now).inDays;
    return '$difference일 후 탈퇴 예정';
  }

  // 로그아웃 기능을 가진 함수
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          surfaceTintColor: Colors.white,
          backgroundColor: Colors.white,
          title: const Text('로그아웃'),
          content: const Text('로그아웃 하시겠습니까?'),
          actions: <Widget>[
            TextButton(
              child: const Text(
                '아니오',
                style: TextStyle(color: primary, fontWeight: FontWeight.w500),
              ),
              onPressed: () {
                Navigator.of(context).pop(); // 대화상자 닫기
              },
            ),
            TextButton(
              child: const Text(
                '예',
                style: TextStyle(color: bg_90, fontWeight: FontWeight.w500),
              ),
              onPressed: () async {
                // 로그아웃 처리
                await Supabase.instance.client.auth.signOut();

                // 로그인 상태 업데이트
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('isLoggedIn', false);

                // 로그아웃 후 로그인 화면으로 리디렉션
                Navigator.of(context)
                    .pushNamedAndRemoveUntil('/login', (route) => false);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0, // 앱바 그림자 제거
        centerTitle: true,
        title: FutureBuilder<String>(
          future: _usernameFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Text('');
            }
            if (snapshot.hasError) {
              return const Text('X');
            }
            return Text(
              snapshot.data ?? '',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            );
          },
        ),
      ),
      backgroundColor: Colors.white,
      body: ListView(
        shrinkWrap: true,
        children: <Widget>[
          GestureDetector(
            onTap: () {
              Get.to(
                () => const MyHomePage(),
              );
            },
            child: const ListTile(
              title: Text('내 글 보기'),
              trailing: Icon(
                Icons.list_alt,
                size: 20,
                color: Colors.black,
              ),
            ),
          ),
          Divider(
            thickness: 0.5,
            height: 0,
          ),
          GestureDetector(
            onTap: () {
              Get.to(
                () => const UserEditPage(),
              );
            },
            child: const ListTile(
              title: Text('정보 수정'),
              trailing: Icon(
                Icons.edit,
                size: 20,
                color: Colors.black,
              ),
            ),
          ),
          Divider(
            thickness: 0.5,
            height: 0,
          ),
          GestureDetector(
            onTap: () {
              Get.to(
                () => BugReportPage(),
              );
            },
            child: const ListTile(
              title: Text('고객센터'),
              trailing: Icon(
                Icons.question_mark_rounded,
                size: 20,
                color: Colors.black,
              ),
            ),
          ),
          Divider(
            thickness: 0.5,
            height: 0,
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const PrivacyPolicyPage()),
              );
            },
            child: const ListTile(
              title: Text('개인정보처리방침'),
              trailing: Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: Colors.black,
              ),
            ),
          ),
          Divider(
            thickness: 0.5,
            height: 0,
          ),
          GestureDetector(
            onTap: _showLogoutDialog, // 로그아웃 대화상자 표시
            child: const ListTile(
              title: Text('로그아웃'),
              trailing: Icon(
                Icons.logout_rounded,
                size: 20,
                color: Colors.black,
              ),
            ),
          ),
          Divider(
            thickness: 0.5,
            height: 0,
          ),
          GestureDetector(
            onTap: _showDeleteAccountDialog, // 로그아웃 대화상자 표시
            child: ListTile(
              title: const Text('탈퇴'),
              trailing: _scheduledDeletionDate != null
                  ? Text(_formatRemainingTime(_scheduledDeletionDate!))
                  : const Icon(Icons.cancel_outlined),
            ),
          ),
          Divider(
            thickness: 0.5,
            height: 0,
          ),
        ],
      ),
    );
  }
}
