import 'package:flutter/material.dart';
import 'package:wact/pages/home/home_page.dart';
import 'package:wact/pages/home/post/post_add_page.dart';
import 'package:wact/pages/home/review/review_add_page.dart';

class CustomFAB extends StatefulWidget {
  final bool isFABVisible;
  final bool isFabOpen;
  final VoidCallback toggleFAB;
  final int selectedIndex; // 추가
  final ValueChanged<int> onTabChange; // 추가
  final GlobalKey<HomePageState> homePageKey; // 추가

  const CustomFAB({
    Key? key,
    required this.isFABVisible,
    required this.isFabOpen,
    required this.toggleFAB,
    required this.selectedIndex,
    required this.onTabChange,
    required this.homePageKey,
  }) : super(key: key);

  @override
  _CustomFABState createState() => _CustomFABState();
}

class _CustomFABState extends State<CustomFAB> {
  @override
  Widget build(BuildContext context) {
    return widget.isFABVisible
        ? Stack(
            alignment: Alignment.bottomCenter,
            children: [
              _buildExtendedFAB(),
              _buildFAB(),
            ],
          )
        : Container();
  }

  Widget _buildFAB() {
    return Padding(
      padding: const EdgeInsets.only(top: 30.0),
      child: FloatingActionButton(
        backgroundColor: Colors.black,
        onPressed: widget.toggleFAB,
        heroTag: "mainFAB",
        child: Center(
          child: Icon(
            widget.isFabOpen ? Icons.close : Icons.add,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildExtendedFAB() {
    if (!widget.isFabOpen) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.only(bottom: 50),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          FloatingActionButton(
            backgroundColor: Colors.black,
            mini: true,
            onPressed: () {
              widget.toggleFAB();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PostAddPage(
                    onUpload: (List<String> urls) {}, // 이 부분은 필요에 따라 조정
                    homePageKey: widget.homePageKey,
                  ),
                ),
              ).then((result) {
                if (result == true) {
                  debugPrint(
                      'FAB1: 새로운 게시글 작성 후 PostPage를 새로고침하기 위해 refreshPostPage 실행');
                  widget.homePageKey.currentState?.refreshPostPage();
                }
              });
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
              widget.toggleFAB();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ReviewAddPage(onUpload: (String) {}),
                ),
              ).then((result) {
                if (result == true) {
                  debugPrint('FAB2: 새로운 게시글 작성 후 ReviewPage를 새로고침');
                  // 새로운 게시글 작성 후 ReviewPage를 새로고침
                  widget.onTabChange(1); // 수정
                }
              });
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
