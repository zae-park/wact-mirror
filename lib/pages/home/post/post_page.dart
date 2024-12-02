import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wact/common/const/color.dart';
import 'package:wact/pages/home/post/post_detail_page.dart';

class PostPage extends StatefulWidget {
  const PostPage({super.key});

  @override
  State<PostPage> createState() => PostPageState();
}

class PostPageState extends State<PostPage> {
  late Stream<List<Map<String, dynamic>>> _postStream;
  late Stream<Map<int, int>> _commentCountStream;
  late ScrollController controller;

  @override
  void initState() {
    super.initState();
    controller = ScrollController();

    _postStream = _loadPostStream();
    _commentCountStream = _loadCommentCountStream();
  }

  Stream<List<Map<String, dynamic>>> _loadPostStream() {
    return Supabase.instance.client
        .from('posts')
        .stream(primaryKey: ['id'])
        .eq('report', false)
        .order('created_at', ascending: false)
        .map((data) => List<Map<String, dynamic>>.from(data));
  }

  Stream<Map<int, int>> _loadCommentCountStream() {
    return Supabase.instance.client
        .from('comments')
        .stream(primaryKey: ['id']).map((data) {
      // 댓글 개수를 계산하여 Map으로 반환 (post_id: 댓글 수)
      final counts = <int, int>{};
      for (var comment in data) {
        final postId = comment['post_id'] as int;
        counts[postId] = (counts[postId] ?? 0) + 1;
      }
      return counts;
    });
  }

  void refresh() {
    setState(() {
      _postStream = _loadPostStream();
      _commentCountStream = _loadCommentCountStream();
      debugPrint('PostPage 새로고침 실행됨');
    });
  }

  @override
  void dispose() {
    controller.dispose(); // Dispose the ScrollController
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: Colors.white,
      backgroundColor: Colors.black,
      onRefresh: () async {
        refresh();
      },
      child: Stack(
        children: [
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: _postStream,
            builder: (context, postSnapshot) {
              if (!postSnapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: Colors.black,
                  ),
                );
              }
              final posts = postSnapshot.data!;

              return StreamBuilder<Map<int, int>>(
                stream: _commentCountStream,
                builder: (context, commentSnapshot) {
                  final commentCounts = commentSnapshot.data ?? {};

                  return ListView.builder(
                    controller: controller,
                    scrollDirection: Axis.vertical,
                    itemCount: posts.length,
                    itemBuilder: (context, index) {
                      final post = posts[index];

                      // 이미지 URL 처리
                      List<dynamic> imageUrls = [];
                      if (post['compressed_image_urls'] is List<dynamic>) {
                        imageUrls = post['compressed_image_urls'];
                      } else if (post['compressed_image_urls'] is String) {
                        imageUrls = json.decode(post['compressed_image_urls']);
                      }
                      final imageUrl =
                          imageUrls.isNotEmpty ? imageUrls[0] : null;
                      if (imageUrl != null) {
                        precacheImage(NetworkImage(imageUrl), context);
                      }

                      // 댓글 개수 처리
                      final commentCount = commentCounts[post['id']] ?? 0;

                      // 날짜 형식 변경
                      final createdAt = DateTime.parse(post['created_at']);
                      final formattedDate =
                          DateFormat('MM/dd').format(createdAt);

                      return InkWell(
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PostDetailPage(
                                post: posts[index],
                                refreshCallback: () {
                                  refresh();
                                  debugPrint('PostDetailPage에서 돌아옴: 새로고침');
                                },
                              ),
                            ),
                          );
                          if (result == true) {
                            refresh();
                          }
                        },
                        child: Column(
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(20, 10, 20, 10),
                              child: SizedBox(
                                width: MediaQuery.of(context).size.width - 40,
                                height: 90,
                                child: GestureDetector(
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      SizedBox(
                                        width:
                                            MediaQuery.of(context).size.width -
                                                40 -
                                                60 -
                                                10,
                                        height: 90,
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              post['title'],
                                              style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w600),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              post['content'],
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style:
                                                  const TextStyle(fontSize: 14),
                                            ),
                                            const SizedBox(height: 5),
                                            Row(
                                              children: [
                                                if (commentCount > 0)
                                                  Row(
                                                    children: [
                                                      const Icon(
                                                        FontAwesomeIcons
                                                            .comment,
                                                        color: Colors.black,
                                                        size: 9,
                                                      ),
                                                      const SizedBox(width: 3),
                                                      Text(
                                                        '$commentCount',
                                                        style: const TextStyle(
                                                            fontSize: 9,
                                                            color: bg_90),
                                                      ),
                                                      const SizedBox(width: 3),
                                                      const Text(
                                                        'ㅣ',
                                                        style: TextStyle(
                                                            fontSize: 8,
                                                            color: bg_90),
                                                      ),
                                                      const SizedBox(width: 3),
                                                    ],
                                                  ),
                                                Text(
                                                  formattedDate,
                                                  style: const TextStyle(
                                                      fontSize: 9,
                                                      color: bg_70),
                                                ),
                                                const SizedBox(width: 3),
                                                const Text(
                                                  'ㅣ',
                                                  style: TextStyle(
                                                      fontSize: 8,
                                                      color: bg_70),
                                                ),
                                                const SizedBox(width: 3),
                                                Text(
                                                  post['author'],
                                                  style: const TextStyle(
                                                      fontSize: 9,
                                                      color: bg_90),
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
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            child: CachedNetworkImage(
                                              imageUrl: imageUrl,
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
              );
            },
          ),
        ],
      ),
    );
  }
}
