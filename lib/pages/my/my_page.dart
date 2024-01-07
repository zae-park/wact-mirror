import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wact/common/const/color.dart';
import 'package:wact/pages/add_post_page.dart';

class MyPage extends StatefulWidget {
  const MyPage({
    super.key,
  });

  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  late Future<List<Map<String, dynamic>>> _future;
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
              return Text('');
            }
            if (snapshot.hasError) {
              return Text('X');
            }
            return Text(
              snapshot.data ?? '',
              style: TextStyle(
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
              final imageUrls = post['image_urls'] as List<dynamic>?;
              final imageUrl = imageUrls != null && imageUrls.isNotEmpty
                  ? imageUrls[0]
                  : null;

              // 댓글 개수 처리
              final commentCount =
                  (post['comments'] as List<dynamic>?)?.length ?? 0;

              // 날짜 형식 변경
              final createdAt = DateTime.parse(post['created_at']);
              final formattedDate = DateFormat('MM/dd').format(createdAt);

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                    child: Container(
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
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  post['content'],
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 14),
                                ),
                                SizedBox(
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
                                          Icon(
                                            FontAwesomeIcons.comment,
                                            color: Colors.black,
                                            size: 6,
                                          ),
                                          SizedBox(
                                            width: 1.5,
                                          ),
                                          Text(
                                            '$commentCount',
                                            style: TextStyle(
                                                fontSize: 8, color: bg_90),
                                          ),
                                          SizedBox(
                                            width: 3,
                                          ),
                                          Center(
                                            child: Text(
                                              'ㅣ',
                                              style: TextStyle(
                                                  fontSize: 8, color: bg_90),
                                            ),
                                          ),
                                          SizedBox(
                                            width: 3,
                                          ),
                                        ],
                                      ),
                                    Text(
                                      formattedDate,
                                      style:
                                          TextStyle(fontSize: 8, color: bg_70),
                                    ),
                                    SizedBox(
                                      width: 3,
                                    ),
                                    Text(
                                      'ㅣ',
                                      style:
                                          TextStyle(fontSize: 8, color: bg_70),
                                    ),
                                    SizedBox(
                                      width: 3,
                                    ),
                                    Text(
                                      post['author'],
                                      style:
                                          TextStyle(fontSize: 9, color: bg_90),
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
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                    child: Divider(
                      color: bg_10,
                      height: 1,
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.black,
        child: Center(
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
