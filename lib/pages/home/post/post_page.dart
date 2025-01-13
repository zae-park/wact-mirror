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
  late Stream<List<Map<String, dynamic>>> _noticeStream; // 공지
  int _currentNoticePage = 0; // 현재 페이지 인덱스 상태 추가

  @override
  void initState() {
    super.initState();
    controller = ScrollController();

    _postStream = _loadPostStream();
    _noticeStream = _loadNoticeStream(); // 공지 스트림 추가

    _commentCountStream = _loadCommentCountStream();
  }

  Stream<List<Map<String, dynamic>>> _loadPostStream() {
    return Supabase.instance.client
        .from('posts')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) {
          return List<Map<String, dynamic>>.from(data)
              .where((post) =>
                  post['disabled'] == false && post['notice'] == false)
              .toList();
        });
  }

  Stream<List<Map<String, dynamic>>> _loadNoticeStream() {
    return Supabase.instance.client
        .from('posts')
        .stream(primaryKey: ['id'])
        .eq('notice', true) // notice가 true인 데이터 필터링
        .order('created_at', ascending: false)
        .limit(3) // 최신 3개로 제한
        .map((data) => List<Map<String, dynamic>>.from(data));
  }

  Stream<Map<int, int>> _loadCommentCountStream() {
    return Supabase.instance.client
        .from('comments')
        .stream(primaryKey: ['id'])
        .eq('target_table', 'posts') // posts 테이블에 해당하는 댓글만 필터링
        .map((data) {
          final counts = <int, int>{};
          for (var comment in data) {
            final postId = comment['target_id'] as int; // target_id에 매핑
            counts[postId] = (counts[postId] ?? 0) + 1;
          }
          return counts;
        });
  }

  void refresh() {
    setState(() {
      _postStream = _loadPostStream();
      _commentCountStream = _loadCommentCountStream();
      _noticeStream = _loadNoticeStream(); // 공지 스트림도 새로고침

      debugPrint('PostPage 새로고침 실행됨');
    });
  }

  @override
  void dispose() {
    controller.dispose(); // Dispose the ScrollController
    super.dispose();
  }

  Widget _buildNoticeSectionWithIndicator(List<Map<String, dynamic>> notices) {
    if (notices.isEmpty) {
      return const SizedBox.shrink(); // 공지가 없으면 아무것도 표시하지 않음
    }

    return SizedBox(
      height: 44,
      child: Container(
        color: secondary,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              SizedBox(
                width: 40,
                height: 25,
                child: Container(
                  width: 40,
                  height: 25,
                  decoration: BoxDecoration(
                    color: primary,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Center(
                    child: Text(
                      '공지',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: MediaQuery.of(context).size.width - 40 - 10 - 40,
                child: Column(
                  children: [
                    SizedBox(
                      height: 44,
                      child: PageView.builder(
                        itemCount: notices.length,
                        onPageChanged: (index) {
                          setState(() {
                            _currentNoticePage = index;
                          });
                        },
                        itemBuilder: (context, index) {
                          final notice = notices[index];
                          return GestureDetector(
                            onTap: () async {
                              // 팝업으로 페이지 표시
                              showDialog(
                                context: context,
                                barrierDismissible: true, // 외부 클릭 시 닫힘 허용
                                builder: (context) => Dialog(
                                  insetPadding:
                                      const EdgeInsets.all(10), // 팝업 패딩 조정
                                  backgroundColor: Colors.transparent, // 투명 배경
                                  child: PostDetailPage(
                                    post: notice,
                                    refreshCallback: () {
                                      refresh();
                                    },
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              color: Colors.transparent, // 전체 영역 클릭 가능
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    notice['title'],
                                    style: const TextStyle(
                                      fontSize: 17,
                                      color: Colors.black,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

// 페이지 인디케이터(공지 3개)
  // SizedBox(
  //   height: 20,
  //   child: Column(
  //     children: [
  //       Row(
  //         mainAxisAlignment: MainAxisAlignment.center,
  //         children: List.generate(
  //           notices.length,
  //           (index) => AnimatedContainer(
  //             duration: const Duration(milliseconds: 300),
  //             width: _currentNoticePage == index ? 12 : 8,
  //             height: 6,
  //             margin:
  //                 const EdgeInsets.symmetric(horizontal: 3),
  //             decoration: BoxDecoration(
  //               shape: BoxShape.circle,
  //               color: _currentNoticePage == index
  //                   ? Colors.black
  //                   : Colors.grey,
  //             ),
  //           ),
  //         ),
  //       ),
  //       SizedBox(
  //         height: 10,
  //       ),
  //     ],
  //   ),
  // ),

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
            stream: _noticeStream,
            builder: (context, noticeSnapshot) {
              if (!noticeSnapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.black),
                );
              }
              final notices = noticeSnapshot.data ?? [];

              return StreamBuilder<List<Map<String, dynamic>>>(
                stream: _postStream,
                builder: (context, postSnapshot) {
                  if (!postSnapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.black),
                    );
                  }
                  final posts = postSnapshot.data!;

                  return StreamBuilder<Map<int, int>>(
                    stream: _commentCountStream,
                    builder: (context, commentSnapshot) {
                      if (!commentSnapshot.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(color: Colors.black),
                        );
                      }
                      final commentCounts = commentSnapshot.data ?? {};

                      return ListView.builder(
                        controller: controller,
                        itemCount: posts.length + 1, // 공지 + 게시글
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return _buildNoticeSectionWithIndicator(notices);
                          }
                          final post = posts[index - 1];

                          // 이미지 URL 처리
                          List<dynamic> imageUrls = [];
                          if (post['compressed_image_urls'] is List<dynamic>) {
                            imageUrls = post['compressed_image_urls'];
                          } else if (post['compressed_image_urls'] is String) {
                            imageUrls =
                                json.decode(post['compressed_image_urls']);
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

                          bool isReported = post['report'];

                          return InkWell(
                            onTap: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PostDetailPage(
                                    post: post,
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
                                (isReported == false)
                                    ? Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                            20, 10, 20, 10),
                                        child: SizedBox(
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width -
                                              40,
                                          height: 90,
                                          child: GestureDetector(
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                SizedBox(
                                                  width: MediaQuery.of(context)
                                                          .size
                                                          .width -
                                                      40 -
                                                      60 -
                                                      10,
                                                  height: 90,
                                                  child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        post['title'],
                                                        style: const TextStyle(
                                                            fontSize: 18,
                                                            fontWeight:
                                                                FontWeight
                                                                    .w600),
                                                      ),
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        post['content'],
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: const TextStyle(
                                                            fontSize: 14,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                            color: bg_90),
                                                      ),
                                                      const SizedBox(height: 5),
                                                      Row(
                                                        children: [
                                                          if (commentCount > 0)
                                                            Row(
                                                              children: [
                                                                Icon(
                                                                  Icons
                                                                      .comment_outlined,
                                                                  size: 12,
                                                                ),
                                                                const SizedBox(
                                                                    width: 3),
                                                                Text(
                                                                  '$commentCount',
                                                                  style: const TextStyle(
                                                                      fontSize:
                                                                          10,
                                                                      color:
                                                                          blueGrey),
                                                                ),
                                                                const SizedBox(
                                                                    width: 5),
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
                                                                  decoration:
                                                                      BoxDecoration(
                                                                    color:
                                                                        blueGrey,
                                                                    shape: BoxShape
                                                                        .circle, // 원형
                                                                  ),
                                                                ),
                                                                const SizedBox(
                                                                    width: 5),
                                                              ],
                                                            ),
                                                          Text(
                                                            formattedDate,
                                                            style:
                                                                const TextStyle(
                                                                    fontSize:
                                                                        10,
                                                                    color:
                                                                        blueGrey),
                                                          ),
                                                          const SizedBox(
                                                              width: 5),
                                                          // const Text(
                                                          //   'ㅣ',
                                                          //   style: TextStyle(
                                                          //       fontSize: 8,
                                                          //       color: bg_70),
                                                          // ),
                                                          Container(
                                                            width: 2,
                                                            height: 2,
                                                            decoration:
                                                                BoxDecoration(
                                                              color: blueGrey,
                                                              shape: BoxShape
                                                                  .circle, // 원형
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                              width: 5),
                                                          Text(
                                                            post[
                                                                'current_author'],
                                                            style:
                                                                const TextStyle(
                                                                    fontSize:
                                                                        10,
                                                                    color:
                                                                        blueGrey),
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
                                                          BorderRadius.circular(
                                                              20),
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
                                      )
                                    : Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                            20, 10, 20, 10),
                                        child: SizedBox(
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width -
                                              40,
                                          height: 30,
                                          child: Align(
                                            alignment: Alignment.centerLeft,
                                            child: Text(
                                              '비활성화된 게시글입니다.',
                                              textAlign: TextAlign.left,
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
              );
            },
          ),
        ],
      ),
    );
  }
}
