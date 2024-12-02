// 홈 > 후기게시판 > 후기 상세페이지
// 240525 참석 인원 수 가져오기 변경

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:wact/common/const/color.dart';
import 'package:wact/common/init.dart';
import 'package:wact/pages/home/review/review_edit_page.dart';

class ReviewDetailPage extends StatefulWidget {
  Map<String, dynamic> review;
  final int currentIndex;
  final Function onUpdateSuccess; // 콜백 추가

  ReviewDetailPage(
      {Key? key,
      required this.review,
      required this.currentIndex,
      required this.onUpdateSuccess})
      : super(key: key);

  @override
  State<ReviewDetailPage> createState() => _ReviewDetailPageState();
}

class _ReviewDetailPageState extends State<ReviewDetailPage> {
  late TextEditingController commentController;
  late User? user;
  late bool isAuthor;
  List<dynamic>? imageUrls;
  List<Map<String, dynamic>> comments = [];

  @override
  void initState() {
    super.initState();
    commentController = TextEditingController();
    user = Supabase.instance.client.auth.currentUser;
    updateAuthorStatus();
    isAuthor = user?.id == widget.review['author_id'];
    // 타입 확인 및 처리
    if (widget.review['compressed_image_urls'] is String) {
      String jsonString = widget.review['compressed_image_urls'];
      imageUrls = json.decode(jsonString);
    } else if (widget.review['compressed_image_urls'] is List) {
      // 이미 List<dynamic> 타입인 경우 직접 할당
      imageUrls = widget.review['compressed_image_urls'];
    } else {
      // null 또는 다른 타입인 경우 빈 리스트 할당
      imageUrls = [];
    }

    fetchComments();
  }

  void updateAuthorStatus() {
    setState(() {
      isAuthor = user?.id == widget.review['author_id'];
    });
  }

  Future<void> fetchComments() async {
    final response = await Supabase.instance.client
        .from('comments')
        .select('*')
        .eq('target_table', 'reviews') // reviews 타겟
        .eq('target_id', widget.review['id']) // 리뷰 ID
        .order('created_at', ascending: true);

    setState(() {
      comments = List<Map<String, dynamic>>.from(response);
    });
  }

  Future<void> addComment(String content, BuildContext context) async {
    if (user == null) return;

    try {
      final profileResponse = await Supabase.instance.client
          .from('profiles')
          .select('username')
          .eq('id', user!.id)
          .single();

      final username = profileResponse['username'] as String;

      final newComment = {
        'id': const Uuid().v4(),
        'target_table': 'reviews', // 대상 테이블
        'target_id': widget.review['id'], // 리뷰 ID
        'author_id': user!.id, // 작성자 ID
        'author': username, // 작성자 이름
        'content': content, // 댓글 내용
        'created_at': DateTime.now().toIso8601String(), // 생성 시간
      };

      final response =
          await Supabase.instance.client.from('comments').insert(newComment);

      print('댓글 추가 성공: $response');

      // 키보드 숨기기
      FocusScope.of(context).unfocus();

      // UI 갱신
      setState(() {
        fetchComments(); // 댓글 목록 다시 불러오기
      });
    } catch (error) {
      print('댓글 추가 오류: $error');
    }
  }

  Future<void> deleteComment(String commentId, BuildContext context) async {
    final response = await Supabase.instance.client
        .from('comments')
        .delete()
        .eq('id', commentId);

    print('댓글 삭제 응답: $response');

    fetchComments(); // 댓글 목록 다시 로드
  }

  @override
  void dispose() {
    commentController.dispose();
    super.dispose();
  }

  // 게시글 삭제 함수
  Future<void> deletereview() async {
    final response = await Supabase.instance.client
        .from('reviews')
        .delete()
        .match({'id': widget.review['id']}).select();
    print('supabase 삭제: $response');
    // 삭제 성공
    Navigator.of(context).pop(true); // 삭제 후 이전 화면으로 돌아가며 true 값 전달
  }

  // 선택한 이미지를 팝업으로 표시
  void _showImagePopup(BuildContext context, String selectedImagePath) {
    int initialPage = imageUrls!.indexOf(selectedImagePath);
    final PageController pageController =
        PageController(initialPage: initialPage);

    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (BuildContext context) {
        return GestureDetector(
          onTap: () => Navigator.pop(context),
          behavior: HitTestBehavior.opaque,
          child: Stack(
            children: [
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.8),
                ),
              ),
              Center(
                child: SizedBox(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height * 0.8,
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      PageView.builder(
                        controller: pageController,
                        itemCount: imageUrls!.length,
                        itemBuilder: (context, index) {
                          return Image.network(
                            imageUrls![index],
                            fit: BoxFit.contain,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    print('Is Author: $isAuthor');

    final createdAt =
        DateFormat('MM/dd').format(DateTime.parse(widget.review['created_at']));
    // 이미지 URL 리스트
    final DateTime parsedDate = DateTime.parse(widget.review['meet_date']);
    final formattedMeetDate = DateFormat('MM/dd(E)', 'ko').format(parsedDate);

    // 240525 참석 인원 수 가져오기
    final String participants = widget.review['participants'] ?? '0';

    // 참석 멤버수 구하기 - ,를 기준으로,
    String members = widget.review['member'];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(widget.review['team']),
        centerTitle: true,
        actions: isAuthor
            ? [
                PopupMenuButton(
                  surfaceTintColor: Colors.white,
                  color: Colors.white,
                  onSelected: (value) async {
                    // 수정 버튼 눌렀을 때의 로직
                    if (value == 'edit') {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ReviewEditPage(
                            review: widget.review,
                            onUpdateSuccess: () {
                              widget.onUpdateSuccess(); // 콜백 호출
                            },
                            onUpload: (String) {},
                          ),
                        ),
                      );
                      if (result != null && result is Map<String, dynamic>) {
                        setState(() {
                          widget.review = result;
                          if (result.containsKey('compressed_image_urls')) {
                            imageUrls = result['compressed_image_urls'];
                          }
                        });
                      }
                    } else if (value == 'delete') {
                      deletereview();
                    }
                  },
                  itemBuilder: (BuildContext context) => <PopupMenuEntry>[
                    const PopupMenuItem(
                      value: 'edit',
                      child: ListTile(
                        title: Text(
                          '수정',
                        ),
                      ),
                    ),
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
                        widget.review['title'],
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      Text(
                        '${widget.review['author']}',
                        style: const TextStyle(
                            fontSize: 10, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        createdAt,
                        style: const TextStyle(fontSize: 9, color: bg_70),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(
                    height: 10,
                  ),
                  Row(
                    children: [
                      const Text(
                        '날짜 ',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: primary,
                        ),
                      ),
                      Text(
                        formattedMeetDate,
                        style: const TextStyle(
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 4,
                  ),
                  if (widget.review['place'] != '')
                    Row(
                      children: [
                        const Text(
                          '장소 ',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: primary,
                          ),
                        ),
                        Text(
                          '${widget.review['place']}',
                          style: const TextStyle(
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(
                    height: 4,
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '참석 인원 ',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: primary,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          '$participants명',
                          style: const TextStyle(
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 4,
                  ),
                  if (widget.review['member'] != '')
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '참석 ',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: primary,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            members,
                            style: const TextStyle(
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 4,
                        ),
                        const SizedBox(
                          height: 4,
                        ),
                      ],
                    ),
                  if (widget.review['bible'] != '')
                    Row(
                      children: [
                        const Text(
                          '본문 ',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: primary,
                          ),
                        ),
                        Text(
                          '${widget.review['bible']}',
                          style: const TextStyle(
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 20),
              child: Text(
                widget.review['content'],
                style: const TextStyle(
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(
              height: 20,
            ),

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
                        onTap: () {
                          // _showImagePopup 함수를 호출하면서 현재 인덱스의 이미지 URL을 전달.
                          _showImagePopup(context, imageUrls![index]);
                        },
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
                comments.length,
                (index) {
                  final comment = comments[index];
                  final isCommentAuthor = user?.id == comment['author_id'];
                  final formattedDate = DateFormat('MM/dd HH:mm')
                      .format(DateTime.parse(comment['created_at']));

                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 4,
                        ),
                        child: ListTile(
                          title: Text(
                            comment['author'],
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(comment['content']),
                              Text(
                                formattedDate,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          trailing: isCommentAuthor
                              ? IconButton(
                                  icon: const Icon(Icons.delete_outline,
                                      size: 16),
                                  onPressed: () {
                                    deleteComment(comment['id'], context);
                                  },
                                )
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
