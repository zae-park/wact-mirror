// 홈페이지로 자유게시판과 리뷰게시판 두 탭의 부모 위젯

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wact/common/const/color.dart';
import 'package:wact/pages/home/review/review_page.dart';
import 'package:wact/pages/my/my_post_page.dart';
import 'package:wact/pages/my/my_review_page.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(vsync: this, length: 2);
    // TabController에 리스너 추가
    _tabController.addListener(() {
      if (!mounted) return;
      setState(() {
        // 탭이 변경될 때 UI를 갱신
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Get.back();
          },
        ),
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 180,
              height: 42,
              child: Container(
                decoration: const BoxDecoration(
                    borderRadius: BorderRadius.all(
                      Radius.circular(29),
                    ),
                    color: bg_10),
                child: TabBar(
                  dividerColor: Colors.transparent,
                  indicatorColor: Colors.transparent,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicatorPadding: const EdgeInsets.all(2),
                  labelPadding: const EdgeInsets.all(2),
                  indicator: BoxDecoration(
                    borderRadius: const BorderRadius.all(
                      Radius.circular(25),
                    ),
                    color: Colors.black,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        offset: const Offset(3, 3),
                        blurRadius: 4,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  controller: _tabController,

                  labelColor: Colors.white, // 선택된 탭의 글씨색
                  unselectedLabelColor: bg_70,
                  labelStyle: const TextStyle(
                    color: Colors.black,
                    fontSize: 13.0,
                    fontWeight: FontWeight.w400,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    color: bg_50,
                    fontSize: 13.0,
                    fontWeight: FontWeight.w400,
                  ),
                  tabs: const [
                    Tab(
                      text: '자유게시판',
                    ),
                    Tab(
                      text: '후기게시판',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(width: 48), // trailing 자리에 아이콘 대신 빈 공간을 추가
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          MyPostPage(),
          MyReviewPage(),
        ],
      ),
    );
  }
}
