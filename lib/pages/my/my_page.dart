// 마이페이지
// 240406 탈퇴 항목 추가
// 240421 내 댓글 보기 추가

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wact/common/const/color.dart';
import 'package:wact/pages/my/add_sermon_note_page.dart';
import 'package:wact/pages/my/my_bug_report_page.dart';
import 'package:wact/pages/my/my_comment_page.dart';
import 'package:wact/pages/my/my_home_page.dart';
import 'package:wact/pages/my/my_post_page.dart';
import 'package:wact/pages/my/my_privacy_policy_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wact/pages/my/my_review_page.dart';
import 'package:wact/pages/my/my_user_edit_page.dart';
import 'package:wact/pages/my/sermon_note_add_page.dart';

class MyPage extends StatefulWidget {
  const MyPage({
    super.key,
  });

  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> with TickerProviderStateMixin {
  late Future<String> _usernameFuture;
  late final TabController _tabController;
  DateTime? _scheduledDeletionDate;
  // 상태 변수 추가
  int postCount = 0;
  int reviewCount = 0;
  int commentCount = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(vsync: this, length: 2);

    _usernameFuture = _getUsername();

    _fetchPostCount();
    _fetchReviewCount();
    _fetchCommentsCount();
  }

// posts 테이블에서 해당 유저가 작성한 글 개수 가져오기
  Future<void> _fetchPostCount() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      final response = await Supabase.instance.client
          .from('posts')
          .select()
          .eq('author_id', userId);

      setState(() {
        postCount = response.length;
      });
    }
  }

// reviews 테이블에서 해당 유저가 작성한 글 개수 가져오기
  Future<void> _fetchReviewCount() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      final response = await Supabase.instance.client
          .from('reviews')
          .select()
          .eq('author_id', userId);
      ;
      setState(() {
        reviewCount = response.length;
      });
    }
  }

  // comments 테이블에서 해당 유저가 작성한 글 개수 가져오기
  Future<void> _fetchCommentsCount() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      final response = await Supabase.instance.client
          .from('comments')
          .select()
          .eq('author_id', userId);
      ;
      setState(() {
        commentCount = response.length;
      });
    }
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
                // await prefs.setBool('isLoggedIn', false);
                await prefs.clear(); // 로컬 저장정보 초기화

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
        backgroundColor: Color(0xffF1F2FF),
        surfaceTintColor: Colors.white,
        elevation: 0, // 앱바 그림자 제거
        centerTitle: false,
        title: Padding(
          padding: const EdgeInsets.only(left: 4),
          child: FutureBuilder<String>(
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
                style: TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.w600),
              );
            },
          ),
        ),
      ),
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Container(
            color: Color(0xffF1F2FF),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                width: MediaQuery.of(context).size.width - 40,
                height: 82,
                decoration: BoxDecoration(
                  color: Colors.white, // 버튼 배경색
                  borderRadius: BorderRadius.circular(10), // 둥근 모서리
                  border: Border.all(color: primary, width: 1),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Get.to(
                          () => const MyHomePage(),
                        );
                      },
                      child: Column(
                        mainAxisAlignment:
                            MainAxisAlignment.center, // 세로축 중앙 정렬

                        children: [
                          Text(
                            '내 글',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: blueGrey),
                          ),
                          Text(
                            '${postCount + commentCount}',
                            style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                                color: Colors.black),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Get.to(
                          () => (),
                        );
                      },
                      child: Column(
                        mainAxisAlignment:
                            MainAxisAlignment.center, // 세로축 중앙 정렬

                        children: [
                          Text(
                            '설교노트',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: blueGrey),
                          ),
                          Text(
                            '0', // 50페이지 이상 포토북 개수
                            style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                                color: Colors.black),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Get.to(
                          () => const MyCommentPage(),
                        );
                      },
                      child: Column(
                        mainAxisAlignment:
                            MainAxisAlignment.center, // 세로축 중앙 정렬

                        children: [
                          Text(
                            '댓글',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: blueGrey),
                          ),
                          Text(
                            '$commentCount',
                            style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                                color: Colors.black),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(left: 20, top: 30, right: 20, bottom: 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '신앙',
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w500, color: blueGrey),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GestureDetector(
              onTap: () {
                // Get.to(
                //   () => SermonNoteAddPage(
                //     onUpload: (List<String> urls) {}, // 이 부분은 필요에 따라 조정
                //   ),
                // );
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      backgroundColor: Colors.white,
                      title: Text('설교노트 작성'),
                      content: Text('다음 업데이트에 추가 될 예정입니다.\n조금만 기다려주세요 :)'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text('확인', style: TextStyle(color: primary)),
                        ),
                      ],
                    );
                  },
                );
              },
              child: Container(
                height: 50, color: Colors.transparent, // 투명 배경으로 설정

                child: Row(
                  children: [
                    Image.asset(
                      'assets/imgs/icon/ic_question.png',
                      width: 22,
                      height: 22,
                    ),
                    SizedBox(
                      width: 10,
                    ),
                    Text(
                      '설교노트 작성',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Colors.black),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(left: 20, top: 30, right: 20, bottom: 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '설정',
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w500, color: blueGrey),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GestureDetector(
              child: Container(
                color: Colors.transparent, // 투명 배경으로 설정
                height: 50,
                child: Row(
                  children: [
                    Image.asset(
                      'assets/imgs/icon/ic_account.png',
                      width: 22,
                      height: 22,
                    ),
                    SizedBox(
                      width: 10,
                    ),
                    Text(
                      '계정 설정',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Colors.black),
                    ),
                  ],
                ),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  // MaterialPageRoute(builder: (context) => DeliveryInfo()),
                  MaterialPageRoute(builder: (context) => UserEditPage()),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GestureDetector(
              onTap: () {
                Get.to(
                  () => BugReportPage(),
                );
              },
              child: Container(
                height: 50, color: Colors.transparent, // 투명 배경으로 설정

                child: Row(
                  children: [
                    Image.asset(
                      'assets/imgs/icon/icon_ask.png',
                      width: 22,
                      height: 22,
                    ),
                    SizedBox(
                      width: 10,
                    ),
                    Text(
                      '문의하기',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Colors.black),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => PrivacyPolicyPage()));
              },
              child: SizedBox(
                height: 50,
                child: Row(
                  children: [
                    Image.asset(
                      'assets/imgs/icon/ic_agreement.png',
                      width: 22,
                      height: 22,
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    const Text(
                      '개인정보처리방침',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Colors.black),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: _showLogoutDialog, // 로그아웃 대화상자 표시
            child: Container(
                width: 84,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white, // 버튼 배경색
                  borderRadius: BorderRadius.circular(19), // 둥근 모서리
                  border: Border.all(color: const Color(0xffcfd6e1), width: 1),
                ),
                child: const Center(
                    child: Text(
                  '로그아웃',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                ))),
          ),
          SizedBox(
            height: 36,
          ),
        ],
      ),
    );
  }
}
