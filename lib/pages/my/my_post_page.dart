// 마이페이지 > 내가 쓴 게시글(240120 수정 필요)

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:wact/common/const/color.dart';

class MyPostPage extends StatefulWidget {
  final Map<String, dynamic> post;

  const MyPostPage({Key? key, required this.post}) : super(key: key);

  @override
  State<MyPostPage> createState() => _MyPostPageState();
}

class _MyPostPageState extends State<MyPostPage> {
  late TextEditingController commentController;
  late User? user;
  late bool isAuthor;
  List<dynamic>? imageUrls;

  @override
  void initState() {
    super.initState();
    commentController = TextEditingController();
    user = Supabase.instance.client.auth.currentUser;
    updateAuthorStatus();
    isAuthor = user?.id == widget.post['author_id'];
    // 타입 확인 및 처리
    if (widget.post['compressed_image_urls'] is String) {
      String jsonString = widget.post['compressed_image_urls'];
      imageUrls = json.decode(jsonString);
    } else if (widget.post['compressed_image_urls'] is List) {
      // 이미 List<dynamic> 타입인 경우 직접 할당
      imageUrls = widget.post['compressed_image_urls'];
    } else {
      // null 또는 다른 타입인 경우 빈 리스트 할당
      imageUrls = [];
    }

    // 로그 출력
    print('User ID: ${user?.id}');
    print('Author ID: ${widget.post['author_id']}');
  }

  void updateAuthorStatus() {
    setState(() {
      isAuthor = user?.id == widget.post['author_id'];
    });
  }

  @override
  void dispose() {
    commentController.dispose();
    super.dispose();
  }

  // 게시글 삭제 함수
  Future<void> deletePost() async {
    final response = await Supabase.instance.client
        .from('posts')
        .delete()
        .match({'id': widget.post['id']}).select();
    print('supabase 삭제: $response');
    // 삭제 성공
    Navigator.of(context).pop(); // 삭제 후 이전 화면으로 돌아감
  }

  // 댓글 추가 함수
  Future<void> addComment(String content, BuildContext context) async {
    var existingComments = List<Map<String, dynamic>>.from(
        widget.post['comments'] as List<dynamic>? ?? []);
    var uuid = const Uuid();

    // 새 댓글에 고유 ID 할당
    existingComments.add({
      'id': uuid.v4(), // UUID 생성
      'author_id': user?.id,
      'author': widget.post['author'],
      'content': content,
      'created_at': DateTime.now().toIso8601String()
    });

    print('새 댓글: $existingComments');

    // 'posts' 테이블에 업데이트
    await Supabase.instance.client.from('posts').update(
        {'comments': existingComments}).match({'id': widget.post['id']});

    // 키보드 숨기기
    FocusScope.of(context).unfocus();

    setState(() {
      widget.post['comments'] = existingComments;
    });
  }

// 댓글 삭제 함수
  Future<void> deleteComment(String commentId, BuildContext context) async {
    var existingComments = List<Map<String, dynamic>>.from(
        widget.post['comments'] as List<dynamic>? ?? []);

    // 삭제할 댓글을 찾아 목록에서 제거
    existingComments.removeWhere((comment) => comment['id'] == commentId);

    // 'posts' 테이블에 업데이트
    final response = await Supabase.instance.client
        .from('posts')
        .update({'comments': existingComments}).eq('id', widget.post['id']);

    setState(() {
      widget.post['comments'] = existingComments;
    });
  }

  // 대댓글 추가 함수
  Future<void> addReply(
      String commentId, String content, BuildContext context) async {
    // 기존 댓글 목록 복사
    var existingComments = List<Map<String, dynamic>>.from(
        widget.post['comments'] as List<dynamic>? ?? []);
    var uuid = const Uuid();

    // 대댓글 생성
    Map<String, dynamic> newReply = {
      'id': uuid.v4(), // UUID 생성
      'author_id': user?.id,
      'author': user?.email, // 또는 다른 사용자 식별자
      'content': content,
      'created_at': DateTime.now().toIso8601String(),
      'replies': []
    };

    // 특정 댓글 찾아 대댓글 추가
    for (var comment in existingComments) {
      if (comment['id'] == commentId) {
        (comment['replies'] as List<dynamic>).add(newReply);
        break;
      }
    }

    // 'posts' 테이블에 업데이트
    await Supabase.instance.client
        .from('posts')
        .update({'comments': existingComments}).eq('id', widget.post['id']);
    setState(() => widget.post['comments'] = existingComments);
  }

// 대댓글 삭제 함수
  Future<void> deleteReply(
      String commentId, String replyId, BuildContext context) async {
    // 기존 댓글 목록 복사
    var existingComments = List<Map<String, dynamic>>.from(
        widget.post['comments'] as List<dynamic>? ?? []);

    // 특정 댓글의 대댓글 목록에서 대댓글 삭제
    for (var comment in existingComments) {
      if (comment['id'] == commentId) {
        (comment['replies'] as List<dynamic>)
            .removeWhere((reply) => reply['id'] == replyId);
        break;
      }
    }

    // 'posts' 테이블에 업데이트
    await Supabase.instance.client
        .from('posts')
        .update({'comments': existingComments}).eq('id', widget.post['id']);
    setState(() => widget.post['comments'] = existingComments);
  }

  @override
  Widget build(BuildContext context) {
    print('Is Author: $isAuthor');

    final createdAt =
        DateFormat('MM/dd').format(DateTime.parse(widget.post['created_at']));
    // 이미지 URL 리스트

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(''),
        actions: isAuthor
            ? [
                PopupMenuButton(
                  onSelected: (value) {
                    if (value == 'delete') {
                      deletePost();
                    }
                  },
                  itemBuilder: (BuildContext context) => <PopupMenuEntry>[
                    const PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        title: Text('삭제'),
                      ),
                    ),
                  ],
                  icon: const Icon(
                    Icons.more_vert,
                  ),
                ),
              ]
            : null,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    children: [
                      Text(
                        widget.post['title'],
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(
                        height: 6,
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      Text(
                        '${widget.post['author']}',
                        style: const TextStyle(
                            fontSize: 10, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        createdAt,
                        style: const TextStyle(fontSize: 9, color: bg_70),
                      ),
                    ],
                  )
                ],
              ),
            ),

            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 20),
              child: Text(
                widget.post['content'],
                style: const TextStyle(
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            // 이미지 리스트 표시
// 이미지 리스트 표시
            if (imageUrls != null && imageUrls!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 20, right: 20, top: 10),
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: imageUrls!.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: GestureDetector(
                        onTap: () {},
                        child: Image.network(
                          imageUrls![index],
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
                ),
              ),

            // 댓글 목록
            Column(
              children: List.generate(
                (widget.post['comments'] as List<dynamic>?)?.length ?? 0,
                (index) {
                  var comment = widget.post['comments'][index];
                  bool isCommentAuthor = user?.id == comment['author_id'];

                  // 날짜 형식 변환
                  String formattedDate = DateFormat('MM/dd HH:mm')
                      .format(DateTime.parse(comment['created_at']));

                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 4,
                        ),
                        child: ListTile(
                          title: Text(
                            comment['author'] ?? '',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                          subtitle: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                comment['content'],
                                style: const TextStyle(
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                formattedDate,
                                style: const TextStyle(
                                  fontSize: 9,
                                  color: bg_70,
                                ),
                              ),
                            ],
                          ),
                          trailing: isCommentAuthor
                              ? IconButton(
                                  icon: const Icon(Icons.delete_outline,
                                      size: 16),
                                  onPressed: () {
                                    if (comment['id'] != null) {
                                      deleteComment(comment['id'], context);
                                    }
                                  })
                              : null,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(left: 20, right: 20),
                        child: Divider(
                          height: 1,
                          color: bg_30,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(
              height: 10,
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(
            left: 10.0,
            right: 10.0,
            bottom: MediaQuery.of(context).viewInsets.bottom + 10),
        child: TextField(
          controller: commentController,
          decoration: InputDecoration(
            hintText: '댓글 작성',
            filled: true, // 배경색 채우기 활성화
            fillColor: bg_10, // 배경색 지정
            suffixIcon: IconButton(
              icon: const Icon(
                FontAwesomeIcons.paperPlane,
                size: 14,
              ),
              onPressed: () {
                if (commentController.text.isNotEmpty && user != null) {
                  addComment(commentController.text, context);
                  commentController.clear();
                }
              },
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15.0), // 둥근 모서리
              borderSide: BorderSide.none, // 테두리 없앰
            ),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 20, vertical: 15), // 패딩 조정
          ),
        ),
      ),
    );
  }
}
