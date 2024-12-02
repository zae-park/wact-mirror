// 홈 > 자유게시판 홈 > 게시글 상세페이지

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:wact/common/const/color.dart';
import 'package:wact/pages/home/post/post_edit_page.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

class PostDetailPage extends StatefulWidget {
  Map<String, dynamic> post;
  final Function refreshCallback;

  PostDetailPage({Key? key, required this.post, required this.refreshCallback})
      : super(key: key);

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  late TextEditingController commentController;
  late User? user;
  late bool isAuthor;
  List<dynamic>? imageUrls;
  List<dynamic> comments = [];

  // 현재 페이지 인덱스를 추적하기 위한 변수
  int currentPageIndex = 0;

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
    fetchComments(); // 댓글 로드

    // 로그 출력
    print('User ID: ${user?.id}');
    print('Author ID: ${widget.post['author_id']}');
  }

  Future<void> fetchComments() async {
    final response = await Supabase.instance.client
        .from('comments')
        .select('*') // 필드를 명시적으로 지정 가능
        .eq('target_id', widget.post['id'])
        .eq('target_table', 'posts') // target_table 추가
        .order('created_at', ascending: true);

    setState(() {
      comments = List<dynamic>.from(response);
    });
  }

  void updateAuthorStatus() {
    setState(() {
      isAuthor = user?.id == widget.post['author_id'];
    });
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
    Navigator.of(context).pop(true); // 삭제 후 이전 화면으로 돌아감
  }

  Future<void> addComment(String content, BuildContext context) async {
    try {
      // 사용자 정보 가져오기
      final profileResponse = await Supabase.instance.client
          .from('profiles')
          .select('username')
          .eq('id', user!.id)
          .single();

      if (profileResponse == null) {
        throw Exception('유저 정보를 가져오지 못했습니다.');
      }

      final username = profileResponse['username'] as String?;
      print('유저 이름: $username');

      // target_id 타입 확인 및 변환
      final postId = widget.post['id'];
      if (postId == null || !(postId is int || postId is String)) {
        throw Exception('올바르지 않은 target_id: $postId');
      }
      print('Post ID: $postId');

      // 댓글 데이터 준비
      var uuid = const Uuid();
      // final newComment = {
      //   'id': uuid.v4(), // UUID 생성
      //   'target_id': postId, // 게시글 ID
      //   'author_id': user?.id, // 작성자 ID
      //   'author': username, // 작성자 이름
      //   'content': content, // 댓글 내용
      //   'created_at': DateTime.now().toIso8601String(), // 생성 시간
      // };

      // print('댓글 데이터: $newComment');

      // 댓글 추가
      final response = await Supabase.instance.client.from('comments').insert({
        'id': uuid.v4(), // UUID 생성
        'target_id': widget.post['id'], // 게시글 ID
        'target_table': 'posts', // target_table 설정
        'author_id': user!.id, // 작성자 ID
        'author': username, // 작성자 이름
        'content': content, // 댓글 내용
        'created_at': DateTime.now().toIso8601String(), // 생성 시간
      });

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

// 댓글 삭제 함수
  Future<void> deleteComment(String commentId, BuildContext context) async {
    // comments 테이블에서 댓글 삭제
    final response = await Supabase.instance.client
        .from('comments')
        .delete()
        .eq('id', commentId);

    print('댓글 삭제 응답: $response');

    fetchComments(); // 댓글 목록 다시 로드
  }

  // 문자열 필터링
  String? extractVideoId(String content) {
    RegExp regExp = RegExp(
      r'(?:https:\/\/)?(?:www\.)?(?:youtube\.com\/(?:[^\/\n\s]+\/\S+\/|(?:v|e(?:mbed)?)\/|\S*?[?&]v=)|youtu\.be\/)([a-zA-Z0-9_-]{11})',
    );
    Match? match = regExp.firstMatch(content);
    if (match != null) {
      return match.group(1);
    } else {
      return null;
    }
  }

  // 링크 변환
  Widget buildContent(String content) {
    List<String> parts = content.split('\n'); // 줄 바꿈을 기준으로 텍스트를 나눔
    List<Widget> widgets = [];

    for (String part in parts) {
      if (part.contains('youtube.com') || part.contains('youtu.be')) {
        String videoId = extractVideoId(part) ?? ''; // null이면 빈 문자열로 초기화

        if (videoId.isNotEmpty) {
          widgets.add(
            Container(
              child: YoutubePlayer(
                controller: YoutubePlayerController.fromVideoId(
                  videoId: videoId,
                  autoPlay: false,
                  params: const YoutubePlayerParams(showFullscreenButton: true),
                ),
                aspectRatio: 16 / 9, // Aspect ratio you want to take in screen
              ),
            ),
          );
        }
      } else {
        // YouTube 링크가 아닌 경우 텍스트로 표시
        widgets.add(
          Text(
            part,
            style: const TextStyle(
              fontSize: 14,
            ),
          ),
        );
      }
    }

    // 위젯을 Column으로 묶어서 반환
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start, // 왼쪽 정렬
      children: widgets,
    );
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
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
          ),
          onPressed: () {
            Navigator.of(context).pop(); // 수정 성공 후 돌아가기
            widget.refreshCallback(); // 변경 사항을 알리는 콜백 호출
          },
        ),
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
                          builder: (context) => PostEditPage(
                            post: widget.post,
                            onUpdateSuccess: () {},
                            onUpload: (String) {},
                          ),
                        ),
                      );
                      if (result != null && result is Map<String, dynamic>) {
                        setState(() {
                          widget.post = result; // 수정된 게시글 데이터로 업데이트
                          if (result.containsKey('compressed_image_urls')) {
                            imageUrls = result['compressed_image_urls'];
                          }
                        });
                      }
                    } else if (value == 'delete') {
                      deletePost();
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
            : [
                // PopupMenuButton(
                //   surfaceTintColor: Colors.white,
                //   color: Colors.white,
                //   onSelected: (value) async {
                //     if (value == 'bookmark') {
                //     } else if (value == 'report') {}
                //   },
                //   itemBuilder: (BuildContext context) => <PopupMenuEntry>[
                //     const PopupMenuItem(
                //       value: 'bookmark',
                //       child: ListTile(
                //         title: Text(
                //           '저장',
                //         ),
                //       ),
                //     ),
                //     const PopupMenuItem(
                //       value: 'report',
                //       child: ListTile(
                //         title: Text('신고'),
                //       ),
                //     ),
                //   ],
                //   icon: const Icon(
                //     Icons.more_vert,
                //   ),
                // ),
              ],
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
              child: buildContent(widget.post['content']),
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
// 댓글 표시
            Column(
              children: List.generate(
                comments.length,
                (index) {
                  var comment = comments[index];
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
                                    deleteComment(comment['id'], context);
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
