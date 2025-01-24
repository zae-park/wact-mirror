import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wact/common/const/color.dart';
import 'package:wact/pages/my/sermon_note_edit_page.dart';

class SermonNoteDetailPage extends StatefulWidget {
  final Map<String, dynamic> post;
  final int currentIndex;

  final Function refreshCallback;

  const SermonNoteDetailPage({
    Key? key,
    required this.post,
    required this.refreshCallback,
    required this.currentIndex,
  }) : super(key: key);

  @override
  State<SermonNoteDetailPage> createState() => _SermonNoteDetailPageState();
}

class _SermonNoteDetailPageState extends State<SermonNoteDetailPage> {
  late Map<String, dynamic> post;

  @override
  void initState() {
    super.initState();
    post = widget.post;
  }

  void updatePost(Map<String, dynamic> updatedPost) {
    setState(() {
      post = updatedPost;
      // 필요하다면 widget.post도 업데이트
      widget.post.addAll(updatedPost);
    });
    widget.refreshCallback(updatedPost); // 상위 콜백 호출
  }

  // 설교노트 삭제 함수
  Future<void> deleteSermonNote() async {
    final response = await Supabase.instance.client
        .from('sermon_notes')
        .delete()
        .match({'id': widget.post['id']}).select();
    print('supabase 삭제: $response');
    // 삭제 성공
    Navigator.of(context).pop(true); // 삭제 후 이전 화면으로 돌아가며 true 값 전달
  }

  @override
  Widget build(BuildContext context) {
    // 데이터 처리
    final createdAt = DateFormat('yyyy년 MM월 dd일 (E)', 'ko_KR')
        .format(DateTime.parse(widget.post['created_at']));
    final preacher = widget.post['preacher'] ?? '미입력';
    final location = widget.post['location'] ?? '미입력';
    final title = widget.post['title'] ?? '제목 없음';
    final content = widget.post['content'] ?? '내용이 없습니다.';
    final emotionIcon =
        widget.post['emotion_icon'] ?? 'assets/imgs/icon/default.png';
// 성경 구절 가져오기
    final bibleVerses = (widget.post['bible_verses'] as List<dynamic>?) ?? [];

    List<dynamic> imageUrls = [];
    if (widget.post['compressed_images'] is String) {
      imageUrls = json.decode(widget.post['compressed_images']);
    } else if (widget.post['compressed_images'] is List) {
      imageUrls = widget.post['compressed_images'];
    }

    Widget buildImageGrid() {
      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: imageUrls.length,
        itemBuilder: (BuildContext context, int index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: GestureDetector(
              onTap: () => showDialog(
                context: context,
                builder: (context) => Dialog(
                  child: Image.network(imageUrls[index]),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.network(
                  imageUrls[index],
                  fit: BoxFit.cover,
                ),
              ),
            ),
          );
        },
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        toolbarHeight: 60,
        leading: Transform.translate(
          offset: const Offset(12, 0.0),
          child: IconButton(
            iconSize: 34,
            icon: Image.asset('assets/imgs/icon/btn_back_white.png'),
            onPressed: () {
              Navigator.pop(context, post);
            },
          ),
        ),
        actions: <Widget>[
          PopupMenuButton(
            surfaceTintColor: Colors.white,
            color: Colors.white,
            onSelected: (value) async {
              // 수정 버튼 눌렀을 때의 로직
              if (value == 'edit') {
                final updatedPost = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SermonNoteEditPage(
                      post: post, // 상태 변수 전달
                      refreshCallback: (updatedData) {
                        // 콜백 호출 시 상태 갱신
                        updatePost(updatedData);
                      },
                    ),
                  ),
                );
                // 반환된 데이터가 있으면 반영
                if (updatedPost != null) {
                  debugPrint('반환? : $updatedPost');
                  updatePost(updatedPost);
                }
              } else if (value == 'delete') {
                deleteSermonNote();
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
          // Transform.translate(
          //   offset: const Offset(-4, 0.0),
          //   child: IconButton(
          //     onPressed: () async {
          //       final updatedPost = await Navigator.push(
          //         context,
          //         MaterialPageRoute(
          //           builder: (context) => SermonNoteEditPage(
          //             post: post, // 상태 변수 전달
          //             refreshCallback: (updatedData) {
          //               // 콜백 호출 시 상태 갱신
          //               updatePost(updatedData);
          //             },
          //           ),
          //         ),
          //       );
          //       // 반환된 데이터가 있으면 반영
          //       if (updatedPost != null) {
          //         debugPrint('반환? : $updatedPost');
          //         updatePost(updatedPost);
          //       }
          //     },
          //     icon: Image.asset(
          //       'assets/imgs/icon/icon_edit.png',
          //       width: 24,
          //       height: 24,
          //     ),
          //   ),
          // ),
        ],
        backgroundColor: const Color(0xffF1F2FF),
        title: const Text(
          '설교노트 상세',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              // 최상단 날짜와 감정 아이콘
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    createdAt,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                  Image.asset(
                    emotionIcon,
                    width: 20,
                    height: 20,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Divider(
                color: paleGrey,
              ),

              // 설교 제목
              const Text(
                '설교 제목',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: bg_90,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const Divider(color: paleGrey, height: 20),

              // 장소 & 설교자
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '장소',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: bg_90,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          location,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: 35,
                    child: VerticalDivider(
                      width: 2,
                      color: paleGrey,
                    ),
                  ),
                  SizedBox(
                    width: 10,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '설교자',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: bg_90,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          preacher,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(color: paleGrey, height: 20),

              // 설교 내용 아래에 성경 구절 표시 추가
              if (bibleVerses.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '본문 성경절',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: bg_90,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: bibleVerses.map((verse) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4.0),
                          child: Text(
                            '${verse['book']} ${verse['chapter']}장 ${verse['verses']}절',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: primary,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              const Divider(color: paleGrey, height: 20),

              // 설교 내용
              const Text(
                '설교 내용',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: bg_90,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                content,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  color: Colors.black,
                ),
              ),

              // 이미지
              if (imageUrls.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    buildImageGrid(),
                  ],
                ),
              const SizedBox(height: 34),
            ],
          ),
        ),
      ),
    );
  }
}
