import 'package:flutter/material.dart';
import 'package:wact/pages/home/home_page.dart';
import 'package:wact/pages/my/my_page.dart';

class RootLayout extends StatefulWidget {
  const RootLayout({super.key});

  @override
  State<RootLayout> createState() => _RootLayoutState();
}

class _RootLayoutState extends State<RootLayout> {
  int _selectedIndex = 0; // 현재 선택된 탭의 인덱스
  late ScrollController _scrollController; // 스크롤을 감지하기 위한 컨트롤러

  // 화면 리스트
  final List<Widget> _screens = [
    const HomePage(),
    const MyPage(),
  ];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
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
            icon: Icon(Icons.home),
            label: '홈',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
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
    );
  }
}
