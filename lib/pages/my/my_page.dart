import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wact/common/const/color.dart';
import 'package:wact/pages/home/post/add_post_page.dart';
import 'package:wact/pages/my/my_post_page.dart';

class MyPage extends StatefulWidget {
  const MyPage({
    super.key,
  });

  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  late Future<List<Map<String, dynamic>>>? _future;
  late Future<String> _usernameFuture;

  late ScrollController controller;

  @override
  void initState() {
    super.initState();
    controller = ScrollController(); // ScrollController 초기화

    _usernameFuture = _getUsername();
    _loadData();
  }

  Future<String> _getUsername() async {
    final userId = Supabase.instance.client.auth.currentUser!.id;
    final response = await Supabase.instance.client
        .from('profiles')
        .select('username')
        .eq('id', userId)
        .single();

    if (response.isEmpty) {
      throw Exception('Failed to load username');
    }

    final data = response;
    return data['username'] ?? 'No username';
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
    controller.dispose(); // ScrollController 해제
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0, // 앱바 그림자 제거
        // centerTitle: true,
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
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            );
          },
        ),
      ),
      backgroundColor: Colors.white,
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final posts = snapshot.data!;
          return ListView.builder(
            controller: controller,
            scrollDirection: Axis.vertical,
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              // 이미지 URL 처리
              List<dynamic> imageUrls = [];
              // post['compressed_image_urls']가 List<dynamic>이면 직접 사용
              if (post['compressed_image_urls'] is List<dynamic>) {
                imageUrls = post['compressed_image_urls'];
              }
// post['compressed_image_urls']가 String이면 JSON 파싱
              else if (post['compressed_image_urls'] is String) {
                String imageUrlString = post['compressed_image_urls'];
                imageUrls = json.decode(imageUrlString);
              }
              // 첫 번째 이미지 URL 추출
              final imageUrl = imageUrls.isNotEmpty ? imageUrls[0] : null;

              if (imageUrl != null) {
                precacheImage(NetworkImage(imageUrl), context);
              }

              // 댓글 개수 처리
              final commentCount =
                  (post['comments'] as List<dynamic>?)?.length ?? 0;

              // 날짜 형식 변경
              final createdAt = DateTime.parse(post['created_at']);
              final formattedDate = DateFormat('MM/dd').format(createdAt);

              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => MyPostPage(post: posts[index])),
                  );
                },
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width - 40,
                        height: 90,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            SizedBox(
                              width: MediaQuery.of(context).size.width -
                                  40 -
                                  60 -
                                  10,
                              height: 90,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    post['title'],
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600),
                                  ),
                                  Text(
                                    post['content'],
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  const SizedBox(
                                    height: 3,
                                  ),
                                  Row(
                                    children: [
                                      if (commentCount > 0)
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            const Icon(
                                              FontAwesomeIcons.comment,
                                              color: Colors.black,
                                              size: 9,
                                            ),
                                            const SizedBox(
                                              width: 3,
                                            ),
                                            Text(
                                              '$commentCount',
                                              style: const TextStyle(
                                                  fontSize: 9, color: bg_90),
                                            ),
                                            const SizedBox(
                                              width: 3,
                                            ),
                                            const Center(
                                              child: Text(
                                                'ㅣ',
                                                style: TextStyle(
                                                    fontSize: 8, color: bg_90),
                                              ),
                                            ),
                                            const SizedBox(
                                              width: 3,
                                            ),
                                          ],
                                        ),
                                      Text(
                                        formattedDate,
                                        style: const TextStyle(
                                            fontSize: 9, color: bg_70),
                                      ),
                                      const SizedBox(
                                        width: 3,
                                      ),
                                      const Text(
                                        'ㅣ',
                                        style: TextStyle(
                                            fontSize: 8, color: bg_70),
                                      ),
                                      const SizedBox(
                                        width: 3,
                                      ),
                                      Text(
                                        post['author'],
                                        style: const TextStyle(
                                            fontSize: 9, color: bg_90),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            ),
                            if (imageUrl != null)
                              SizedBox(
                                width: 60,
                                height: 60,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: Image.network(
                                    imageUrl,
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(20, 0, 20, 0),
                      child: Divider(
                        color: bg_10,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.black,
        child: const Center(
          child: Icon(
            Icons.add,
            color: Colors.white,
          ),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => AddPostPage(
                      onUpload: (String) {},
                    )),
          );
        },
      ),
    );
  }
}
