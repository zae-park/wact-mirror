// 홈 > 후기게시판 > 후기 상세페이지
// 240525 참석 인원 수 가져오기 변경

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import 'package:wact/common/const/color.dart';
import 'package:wact/common/const/reaction_emojis.dart';
import 'package:wact/common/init.dart';
import 'package:wact/pages/home/review/review_edit_page.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

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
    fetchTeamName;
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

  Future<String> fetchTeamName(String authorId) async {
    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select('team')
          .eq('id', authorId)
          .single();

      if (response.isNotEmpty && response['team'] != null) {
        return response['team'];
      } else {
        return 'No Team';
      }
    } catch (e) {
      print('팀 이름 가져오기 오류: $e');
      return 'No Team';
    }
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
      } else if (Uri.tryParse(part)?.hasAbsolutePath == true) {
        // 웹페이지 링크인 경우
        widgets.add(
          GestureDetector(
            onTap: () async {
              if (await canLaunchUrl(Uri.parse(part))) {
                await launchUrl(Uri.parse(part));
              } else {
                content;
              }
            },
            child: Text(
              part,
              style: TextStyle(
                fontSize: 16,
                color: Colors.pink[200], // 링크 색상
                decoration: TextDecoration.underline, // 밑줄 추가
                decorationColor: Colors.pink[200],
              ),
            ),
          ),
        );
      } else {
        // YouTube 링크나 웹페이지 링크가 아닌 경우 텍스트로 표시
        widgets.add(
          Text(
            part,
            style: TextStyle(
              fontSize: 16,
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

  void showReactionOptions(
      BuildContext context, String commentId, String authorId) async {
    showModalBottomSheet(
      backgroundColor: Color(0xffF1F2FF),
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(15.0)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildReactionIcon('❤️', 'love', commentId),
              _buildReactionIcon('🙏🏻', 'amen', commentId),
              _buildReactionIcon('🤣', 'funny', commentId),
              _buildReactionIcon('😮', 'amazing', commentId),
              _buildReactionIcon('👏🏻', 'clap', commentId),
              _buildReactionIcon('🥹', 'touched', commentId),
              _buildReactionIcon('😢', 'sad', commentId),
            ],
          ),
        );
      },
    );
  }

  Future<void> addReaction(String commentId, String reactionType) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;

      if (userId == null) throw Exception("로그인이 필요합니다.");

      // 기존 감정 확인
      final existingReactions = await Supabase.instance.client
          .from('reactions')
          .select()
          .eq('comment_id', commentId)
          .eq('user_id', userId);

      if (existingReactions != null && existingReactions.isNotEmpty) {
        final existingReaction = existingReactions[0];

        if (existingReaction['reaction_type'] == reactionType) {
          // 같은 감정이라면 삭제
          await Supabase.instance.client
              .from('reactions')
              .delete()
              .eq('comment_id', commentId)
              .eq('user_id', userId);
        } else {
          // 다른 감정이라면 업데이트
          await Supabase.instance.client
              .from('reactions')
              .update({'reaction_type': reactionType})
              .eq('comment_id', commentId)
              .eq('user_id', userId);
        }
      } else {
        // 새로운 감정 추가
        await Supabase.instance.client.from('reactions').insert({
          'comment_id': commentId,
          'user_id': userId,
          'reaction_type': reactionType,
        });
      }

      // UI 갱신
      setState(() {
        fetchComments(); // 댓글 목록 다시 불러오기
      });
    } catch (e) {
      print("감정 추가/업데이트 오류: $e");
    }
  }

  Future<List<Map<String, dynamic>>> fetchReactions(String commentId) async {
    try {
      final response = await Supabase.instance.client
          .from('reactions')
          .select()
          .eq('comment_id', commentId);

      if (response.isEmpty) {
        // 결과가 없을 경우 빈 리스트 반환
        return [];
      }

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print("감정 가져오기 오류: $e");
      return [];
    }
  }

  // 감정 버튼 UI 생성
  Widget _buildReactionIcon(
      String emoji, String reactionType, String commentId) {
    final userId = Supabase.instance.client.auth.currentUser?.id;

    if (userId == null) throw Exception("로그인이 필요합니다.");

    return FutureBuilder(
      future: Supabase.instance.client
          .from('reactions')
          .select()
          .eq('comment_id', commentId)
          .eq('user_id', userId)
          .eq('reaction_type', reactionType)
          .maybeSingle(),
      builder: (context, snapshot) {
        Color backgroundColor = Colors.transparent;

        // 선택된 감정일 경우 배경색 변경
        if (snapshot.hasData && snapshot.data != null) {
          backgroundColor = primary;
        }

        return GestureDetector(
          onTap: () async {
            await addReaction(commentId, reactionType);
            Navigator.pop(context); // Bottom Sheet 닫기
          },
          child: Container(
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Padding(
              padding: const EdgeInsets.all(6.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    emoji,
                    style: const TextStyle(fontSize: 24),
                  ),
                ],
              ),
            ),
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
        toolbarHeight: 60,
        leading: Transform.translate(
          offset: const Offset(12, 0.0),
          child: IconButton(
            iconSize: 34,
            icon: Image.asset('assets/imgs/icon/btn_back_grey@3x.png'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ),
        backgroundColor: Colors.white,
        title: Text(
          widget.review['team'],
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
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
              padding: const EdgeInsets.only(left: 20, right: 20, top: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(
                    width: (MediaQuery.of(context).size.width * 2 / 3) - 15,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.review['title'],
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 5,
                  ),
                  SizedBox(
                    width: (MediaQuery.of(context).size.width * 1 / 3) - 30,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${widget.review['current_author']}',
                          style: const TextStyle(
                              fontSize: 10, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          createdAt,
                          style: const TextStyle(fontSize: 9, color: bg_70),
                        ),
                      ],
                    ),
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
                      ],
                    ),
                  const SizedBox(
                    height: 4,
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
            const SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 20),
              child: buildContent(
                widget.review['content'],
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
            const Padding(
              padding: EdgeInsets.only(left: 20, right: 20),
              child: Divider(
                height: 30,
                color: bg_10,
              ),
            ),

            // 댓글 영역 시작
            if (comments.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      '댓글',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                    ),
                    SizedBox(
                      width: 5,
                    ),
                    Text(
                      '${comments.length}',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: primary),
                    ),
                  ],
                ),
              ),
            // 댓글 목록
            Column(
              children: List.generate(
                comments.length,
                (index) {
                  var comment = comments[index];
                  bool isCommentAuthor = user?.id == comment['author_id'];
                  bool isPostAuthor =
                      comment['author_id'] == widget.review['author_id'];

                  // 날짜 형식 변환
                  String formattedDate = DateFormat('MM/dd HH:mm')
                      .format(DateTime.parse(comment['created_at']));

                  return FutureBuilder(
                    future: fetchTeamName(comment['author_id']),
                    builder: (context, snapshot) {
                      String teamName = snapshot.data ?? 'No Team';

                      return Column(
                        children: [
                          Container(
                            color: Colors.transparent,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: GestureDetector(
                                onLongPress: () {
                                  // 감정 선택 Bottom Sheet 열기
                                  if (comment['author_id'] != user?.id)
                                    showReactionOptions(context, comment['id'],
                                        comment['author_id']);
                                },
                                onLongPressStart: null, // 진동 트리거 방지
                                onLongPressDown: null, // 진동 트리거 방지
                                behavior:
                                    HitTestBehavior.translucent, // 터치 가능한 영역 설정
                                child: ListTile(
                                  title: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            comment['current_author'] ?? '',
                                            style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: isPostAuthor
                                                    ? FontWeight.w600
                                                    : FontWeight.w500,
                                                color: isPostAuthor
                                                    ? primary
                                                    : Colors.black),
                                          ),
                                          const SizedBox(width: 6),
                                          SizedBox(
                                            width: (teamName.length == 4)
                                                ? 45
                                                : (teamName == '목회자')
                                                    ? 36
                                                    : 30,
                                            height: 18,
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: (teamName == '오비')
                                                    ? bg_10
                                                    : (teamName == '목회자' ||
                                                            teamName == '장로' ||
                                                            teamName == '운영')
                                                        ? Colors.black
                                                        : primary,
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              child: Center(
                                                child: Text(
                                                  teamName,
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: (teamName ==
                                                                '목회자' ||
                                                            teamName == '장로')
                                                        ? FontWeight.w600
                                                        : FontWeight.w800,
                                                    color: (teamName == '오비')
                                                        ? primary
                                                        : Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Text(
                                            formattedDate,
                                            style: const TextStyle(
                                              fontSize: 9,
                                              color: bg_70,
                                            ),
                                          ),
                                          if (isCommentAuthor)
                                            Padding(
                                              padding: EdgeInsets.only(left: 4),
                                              child: GestureDetector(
                                                  child: const Icon(
                                                      Icons.delete_outline,
                                                      size: 16),
                                                  onTap: () {
                                                    deleteComment(
                                                        comment['id'], context);
                                                  }),
                                            ),
                                        ],
                                      )
                                    ],
                                  ),
                                  subtitle: Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        comment['content'],
                                        style: const TextStyle(
                                          fontSize: 14,
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: FutureBuilder<
                                                List<Map<String, dynamic>>>(
                                              future:
                                                  fetchReactions(comment['id']),
                                              builder: (context, snapshot) {
                                                if (!snapshot.hasData ||
                                                    snapshot.data!.isEmpty)
                                                  return SizedBox.shrink();

                                                // JSONB reaction_counts를 가져오기
                                                final Map<String, dynamic>
                                                    reactionCounts = Map<String,
                                                        dynamic>.from(comment[
                                                            'reaction_counts'] ??
                                                        {});

                                                final reactions =
                                                    snapshot.data!;
                                                return Row(
                                                  children: reactionCounts
                                                      .entries
                                                      .map((entry) {
                                                    final reactionType =
                                                        entry.key; // 예: 'amen'
                                                    final count =
                                                        entry.value; // 예: 3
                                                    final emoji =
                                                        reactionEmojis[
                                                                reactionType] ??
                                                            ''; // 예: '🙏🏻'

                                                    return Padding(
                                                      padding: EdgeInsets.only(
                                                          right: (count > 1)
                                                              ? 8.0
                                                              : 4.0),
                                                      child: Row(
                                                        children: [
                                                          Text(emoji,
                                                              style: const TextStyle(
                                                                  fontSize:
                                                                      14)), // 이모지 표시
                                                          const SizedBox(
                                                              width: 4),
                                                          if (count > 1)
                                                            Text(
                                                              count
                                                                  .toString(), // 감정 수 표시
                                                              style: const TextStyle(
                                                                  fontSize: 10,
                                                                  color:
                                                                      blueGrey,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w500),
                                                            ),
                                                        ],
                                                      ),
                                                    );
                                                  }).toList(),
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  // trailing: isCommentAuthor
                                  //     ? GestureDetector(
                                  //         child: const Icon(
                                  //             Icons.delete_outline,
                                  //             size: 16),
                                  //         onTap: () {
                                  //           deleteComment(
                                  //               comment['id'], context);
                                  //         })
                                  //     : null,
                                ),
                              ),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.only(left: 20, right: 20),
                            child: Divider(
                              height: 1,
                              color: bg_10,
                            ),
                          ),
                        ],
                      );
                    },
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
            bottom: MediaQuery.of(context).viewInsets.bottom + 36),
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
