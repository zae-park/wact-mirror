import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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
    _scrollController = ScrollController();
    _screens = [
      HomePage(key: _homePageKey), // initState에서 _screens를 초기화합니다.
      // const QTRoom(),
      const MyPage(),
    ];
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
      body: _screens[_selectedIndex], // 선택된 인덱스에 따른 화면 보여주기
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
