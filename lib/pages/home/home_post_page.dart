import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wact/common/const/color.dart';

class HomePostPage extends StatelessWidget {
  final Map<String, dynamic> post;

  const HomePostPage({Key? key, required this.post}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final isAuthor = user?.id == post['author_id'];

// 댓글 작성
    TextEditingController commentController = TextEditingController();

// 댓글 추가 함수
    Future<void> addComment(
        String content, String userId, BuildContext context) async {
      // 기존 댓글 목록 불러오기
      var existingComments = post['comments'] as List<dynamic>? ?? [];

      // 새 댓글 추가
      existingComments.add({
        'author_id': userId,
        'author': post['author'],
        'content': content,
        'created_at': DateTime.now().toIso8601String()
      });

      // posts 테이블에 업데이트
      final response = await Supabase.instance.client
          .from('posts')
          .update({'comments': existingComments}).eq('id', post['id']);

      if (response != null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('댓글 작성됐습니다.')));
      } else {
        print('댓글 작성에 실패했습니다');
        // 페이지 갱신 로직 필요
      }
    }

// 댓글 삭제 함수
    Future<void> deleteComment(int commentIndex, BuildContext context) async {
      // 기존 댓글 목록 불러오기
      var existingComments = post['comments'] as List<dynamic>? ?? [];

      // 해당 댓글 삭제
      existingComments.removeAt(commentIndex);

      // posts 테이블에 업데이트
      final response = await Supabase.instance.client
          .from('posts')
          .update({'comments': existingComments}).eq('id', post['id']);
      if (response.error != null) {
        print('댓글 삭제에 실패했습니다.');
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('댓글이 삭제되었습니다.')));
        // 페이지 갱신 로직 필요
      }
    }

    final createdAt =
        DateFormat('MM/dd').format(DateTime.parse(post['created_at']));
    // 이미지 URL 리스트
    List<dynamic>? imageUrls = post['image_urls'];

    // 게시글 삭제 함수
    Future<void> deletePost() async {
      final response = await Supabase.instance.client
          .from('posts')
          .delete()
          .match({'id': post['id']}).select();
      print('supabase 삭제: $response');
      // 삭제 성공
      Navigator.of(context).pop(); // 삭제 후 이전 화면으로 돌아감
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(''),
        actions: isAuthor
            ? [
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 16,
                  ),
                  onPressed: deletePost,
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
                        post['title'],
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.w600),
                      ),
                      SizedBox(
                        height: 6,
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      Text(
                        '${post['author']}',
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
                post['content'],
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
            if (imageUrls != null && imageUrls.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 20, right: 20, top: 10),
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: imageUrls.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: GestureDetector(
                        onTap: () {},
                        child: Image.network(
                          imageUrls[index],
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
                (post['comments'] as List<dynamic>?)?.length ?? 0,
                (index) {
                  var comment = post['comments'][index];
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
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                          subtitle: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                comment['content'],
                                style: TextStyle(
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                formattedDate,
                                style: TextStyle(
                                  fontSize: 9,
                                  color: bg_70,
                                ),
                              ),
                            ],
                          ),
                          trailing: isCommentAuthor
                              ? IconButton(
                                  icon: Icon(
                                    Icons.delete_outline,
                                    size: 16,
                                  ),
                                  onPressed: () => comment['id'] != null
                                      ? deleteComment(comment['id'], context)
                                      : null,
                                )
                              : null,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 20, right: 20),
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
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(left: 10.0, right: 10.0, bottom: 10.0),
        child: TextField(
          controller: commentController,
          decoration: InputDecoration(
            labelText: '댓글 작성',
            filled: true, // 배경색 채우기 활성화
            fillColor: bg_10, // 배경색 지정
            suffixIcon: IconButton(
              icon: Icon(
                FontAwesomeIcons.paperPlane,
                size: 14,
              ),
              onPressed: () {
                if (commentController.text.isNotEmpty && user != null) {
                  addComment(commentController.text, user.id, context);
                  commentController.clear();
                }
              },
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15.0), // 둥근 모서리
              borderSide: BorderSide.none, // 테두리 없앰
            ),
            contentPadding:
                EdgeInsets.symmetric(horizontal: 20, vertical: 15), // 패딩 조정
          ),
        ),
      ),
    );
  }
}
