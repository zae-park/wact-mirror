// 마이페이지

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wact/common/const/color.dart';

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(vsync: this, length: 2);

    _usernameFuture = _getUsername();
    _loadData();
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

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(42),
          child: SizedBox(
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
        ),
      ),
      backgroundColor: Colors.white,
      body: TabBarView(
        controller: _tabController,
        children: [
          Container(),
          Container(),
        ],
      ),
    );
  }
}
