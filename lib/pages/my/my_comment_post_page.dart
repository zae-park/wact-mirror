// 240421 신설

import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wact/common/const/color.dart';
import 'package:wact/pages/home/post/post_detail_page.dart';

class MyCommentPostPage extends StatefulWidget {
  const MyCommentPostPage({super.key});

  @override
  State<MyCommentPostPage> createState() => _MyCommentPostPageState();
}

class _MyCommentPostPageState extends State<MyCommentPostPage> {
  late Stream<List<Map<String, dynamic>>> _stream;
  late ScrollController controller;

  @override
  void initState() {
    super.initState();
    controller = ScrollController();

    _stream = _loadDataStream();
  }

  Stream<List<Map<String, dynamic>>> _loadDataStream() {
    final userId = Supabase.instance.client.auth.currentUser!.id;

    return Supabase.instance.client
        .from('posts')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .asyncMap((postsData) async {
          // 모든 게시글 데이터 가져옴
          final postList = List<Map<String, dynamic>>.from(postsData);

          // 게시글 ID 리스트 가져오기
          final postIds = postList.map((post) => post['id']).toList();

          // target_id가 postIds에 해당하고, author_id가 현재 사용자인 댓글 조회
          final commentsResponse = await Supabase.instance.client
              .from('comments')
              .select()
              .or(postIds
                  .map((id) => 'target_id.eq.$id')
                  .join(',')) // target_id 조건
              .eq('author_id', userId); // 현재 사용자의 댓글만 조회

          final userComments =
              List<Map<String, dynamic>>.from(commentsResponse);

          // 본인의 댓글이 포함된 게시글만 필터링
          var filteredPosts = postList.where((post) {
            return userComments
                .any((comment) => comment['target_id'] == post['id']);
          }).toList();

          debugPrint('내 댓글 게시글: $filteredPosts');
          return filteredPosts;
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
        setState(() {
          _stream = _loadDataStream(); // 스트림을 재구독하여 새로운 데이터 로드
        });
      },
      child: Stack(
        children: [
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: _stream,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                    child: CircularProgressIndicator(
                  color: Colors.black,
                ));
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
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PostDetailPage(
                            post: posts[index],
                            refreshCallback: () {
                              setState(() {
                                _stream = _loadDataStream(); // 데이터 스트림 갱신
                              });
                            },
                          ),
                        ),
                      );
                      if (result == true) {
                        setState(() {
                          _stream = _loadDataStream();
                        });
                      }
                    },
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width - 40,
                            height: 90,
                            child: GestureDetector(
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  SizedBox(
                                    width: MediaQuery.of(context).size.width -
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
                                          style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: bg_90),
                                        ),
                                        const SizedBox(height: 5),
                                        Row(
                                          children: [
                                            if (commentCount > 0)
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.comment_outlined,
                                                    size: 12,
                                                  ),
                                                  const SizedBox(width: 3),
                                                  Text(
                                                    '$commentCount',
                                                    style: const TextStyle(
                                                        fontSize: 10,
                                                        color: blueGrey),
                                                  ),
                                                  const SizedBox(width: 5),
                                                  // const Text(
                                                  //   'ㅣ',
                                                  //   style: TextStyle(
                                                  //       fontSize:
                                                  //           8,
                                                  //       color:
                                                  //           bg_90),
                                                  // ),
                                                  Container(
                                                    width: 2,
                                                    height: 2,
                                                    decoration: BoxDecoration(
                                                      color: blueGrey,
                                                      shape:
                                                          BoxShape.circle, // 원형
                                                    ),
                                                  ),
                                                  const SizedBox(width: 5),
                                                ],
                                              ),
                                            Text(
                                              formattedDate,
                                              style: const TextStyle(
                                                  fontSize: 10,
                                                  color: blueGrey),
                                            ),
                                            const SizedBox(width: 5),
                                            // const Text(
                                            //   'ㅣ',
                                            //   style: TextStyle(
                                            //       fontSize: 8,
                                            //       color: bg_70),
                                            // ),
                                            Container(
                                              width: 2,
                                              height: 2,
                                              decoration: BoxDecoration(
                                                color: blueGrey,
                                                shape: BoxShape.circle, // 원형
                                              ),
                                            ),
                                            const SizedBox(width: 5),
                                            Text(
                                              post['current_author'],
                                              style: const TextStyle(
                                                  fontSize: 10,
                                                  color: blueGrey),
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
          ),
        ],
      ),
    );
  }
}
