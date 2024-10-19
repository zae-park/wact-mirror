import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wact/common/init.dart';
import 'package:wact/pages/home/home_page.dart';
import 'package:wact/pages/home/post/post_add_page.dart';
import 'package:wact/pages/home/review/review_add_page.dart';
import 'package:wact/pages/my/my_page.dart';
import 'package:wact/widgets/buttons/custom_fab.dart';

class RootLayout extends StatefulWidget {
  const RootLayout({super.key, required int initialTab});

  @override
  State<RootLayout> createState() => _RootLayoutState();
}

class _RootLayoutState extends State<RootLayout>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0; // 현재 선택된 탭의 인덱스
  late ScrollController _scrollController; // 스크롤을 감지하기 위한 컨트롤러
  late List<Widget> _screens; // 화면 리스트
  bool _isFabOpen = false;
  final GlobalKey<HomePageState> _homePageKey =
      GlobalKey<HomePageState>(); // 추가

  @override
  void initState() {
    super.initState();

    supabase.auth.onAuthStateChange.listen((event) async {
      if (event.event == AuthChangeEvent.signedIn) {
        await FirebaseMessaging.instance.requestPermission();

        await FirebaseMessaging.instance.getAPNSToken();
        final fcmToken = await FirebaseMessaging.instance.getToken();
        if (fcmToken != null) {
          await _setFcmToken(fcmToken);
        }
      }
    });
    FirebaseMessaging.instance.onTokenRefresh.listen((fcmToken) {
      _setFcmToken(fcmToken);
    });

    FirebaseMessaging.onMessage.listen((payload) {
      final notification = payload.notification;
      if (notification != null) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(notification.title ?? 'Notification'),
              content: Text(notification.body ?? 'No content'),
              actions: [
                TextButton(
                  child: Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      }
    });

    _scrollController = ScrollController();
    _screens = [
      HomePage(key: _homePageKey), // initState에서 _screens를 초기화합니다.
      // const QTRoom(),
      const MyPage(),
    ];
  }

  // 241019 FCM 토큰 설정
  Future<void> _setFcmToken(String fcmToken) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId != null) {
      await supabase.from('profiles').upsert({
        'id': userId,
        'fcm_token': fcmToken,
      });
    }
  }

  void _toggleFAB() {
    setState(() {
      _isFabOpen = !_isFabOpen;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: GestureDetector(
        onTap: () {
          if (_isFabOpen) {
            _toggleFAB(); // 스크린을 터치하면 FAB를 닫기
          }
        },
        child: _screens[_selectedIndex], // 선택된 인덱스에 따른 화면 보여주기
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(
              FontAwesomeIcons.house,
              size: 16,
            ),
            label: '홈',
          ),
          // BottomNavigationBarItem(
          //   icon: Icon(
          //     FontAwesomeIcons.bookBible,
          //     size: 16,
          //   ),
          //   label: '말묵방',
          // ),
          BottomNavigationBarItem(
            icon: Icon(
              FontAwesomeIcons.userLarge,
              size: 16,
            ),
            label: '마이페이지',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.black, // 선택된 아이템의 색상
        unselectedItemColor: Colors.grey, // 선택되지 않은 아이템의 색상
        onTap: (index) {
          setState(() {
            if (_isFabOpen) {
              _toggleFAB(); // 탭 전환 시 FAB가 열려있으면 닫기
            }

            if (index == 0) {
              // '홈' 탭이 선택되었을 때 항상 실행되도록 수정
              if (_homePageKey.currentState != null) {
                if (_homePageKey.currentState!.tabController.index == 0) {
                  // 유저가 '자유게시판'에 있을 때
                  if (_homePageKey.currentState!.postPageKey.currentState
                          ?.controller.position.pixels !=
                      0) {
                    // 위치가 최상단이 아니면 최상단으로 이동하면서 새로고침
                    _homePageKey
                        .currentState!.postPageKey.currentState?.controller
                        .jumpTo(0);
                    _homePageKey.currentState!.refreshPostPage();
                  } else {
                    // 최상단이면 '후기게시판'으로 이동
                    _homePageKey.currentState!.tabController.animateTo(1);
                  }
                } else if (_homePageKey.currentState!.tabController.index ==
                    1) {
                  // 유저가 '후기게시판'에 있을 때
                  if (_homePageKey.currentState!.reviewPageKey.currentState
                          ?.controller.position.pixels !=
                      0) {
                    // 위치가 최상단이 아니면 최상단으로 이동하면서 새로고침
                    _homePageKey
                        .currentState!.reviewPageKey.currentState?.controller
                        .jumpTo(0);
                    _homePageKey.currentState!.refreshReviewPage();
                  } else {
                    // 최상단이면 '자유게시판'으로 이동
                    _homePageKey.currentState!.tabController.animateTo(0);
                  }
                }
              }
            }

            // 현재 선택된 탭과 상관없이 'index' 업데이트 (홈/마이페이지 전환 처리)
            _selectedIndex = index;
          });
        },
      ),
      floatingActionButton: CustomFAB(
        isFABVisible: true,
        isFabOpen: _isFabOpen,
        toggleFAB: _toggleFAB,
        selectedIndex: _selectedIndex, // 추가
        onTabChange: (index) {
          // 추가
          setState(() {
            _selectedIndex = index;
          });
        },
        homePageKey: _homePageKey,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
