import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:wact/pages/home/home_page.dart';
import 'package:wact/pages/home/post/add_post_page.dart';
import 'package:wact/pages/home/review/add_review_page.dart';
import 'package:wact/pages/my/my_page.dart';
import 'package:wact/pages/qtroom/qtroom_page.dart';

class RootLayout extends StatefulWidget {
  const RootLayout({super.key});

  @override
  State<RootLayout> createState() => _RootLayoutState();
}

class _RootLayoutState extends State<RootLayout>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0; // 현재 선택된 탭의 인덱스
  late ScrollController _scrollController; // 스크롤을 감지하기 위한 컨트롤러
  bool _isFABVisible = true; // FAB 가시성 설정
  bool _isFabOpen = false;

  // 화면 리스트
  final List<Widget> _screens = [
    const HomePage(),
    // const QTRoom(),
    const MyPage(),
  ];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
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
      floatingActionButton: _isFABVisible
          ? Stack(
              alignment: Alignment.bottomCenter,
              children: [
                _buildExtendedFAB(),
                _buildFAB(),
              ],
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildFAB() {
    return Padding(
      padding: const EdgeInsets.only(top: 30.0),
      child: FloatingActionButton(
        backgroundColor: Colors.black,
        onPressed: _toggleFAB,
        heroTag: "mainFAB",
        child: Center(
          child:
              Icon(_isFabOpen ? Icons.close : Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildExtendedFAB() {
    if (!_isFabOpen) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.only(bottom: 50),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          FloatingActionButton(
            backgroundColor: Colors.black,
            mini: true,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddPostPage(
                    onUpload: (String) {},
                  ),
                ),
              );
            },
            heroTag: "FAB1",
            child: const SizedBox(
              width: 24,
              height: 24,
              child: Center(
                child: Text(
                  '자유',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
          FloatingActionButton(
            backgroundColor: Colors.black,
            mini: true,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddReviewPage(
                    onUpload: (String) {},
                  ),
                ),
              );
            },
            heroTag: "FAB2",
            child: const SizedBox(
              width: 24,
              height: 24,
              child: Center(
                child: Text(
                  '후기',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
