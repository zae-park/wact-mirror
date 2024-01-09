import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wact/common/const/color.dart';
import 'package:wact/pages/add_post_page.dart';
import 'package:wact/pages/home/home_post_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Stream<List<Map<String, dynamic>>> _stream;
  late ScrollController controller;

  @override
  void initState() {
    super.initState();
    controller = ScrollController();

    _stream = _loadDataStream();
  }

  Stream<List<Map<String, dynamic>>> _loadDataStream() {
    // Create a stream that listens for real-time changes in the 'posts' table
    return Supabase.instance.client
        .from('posts')
        .stream(primaryKey: ['id']) // Replace 'id' with your primary key column
        .order('created_at', ascending: false)
        .map((data) => List<Map<String, dynamic>>.from(data));
  }

  @override
  void dispose() {
    controller.dispose(); // Dispose the ScrollController
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text(
          '후기',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
        ),
      ),
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        color: Colors.white,
        backgroundColor: Colors.black,
        onRefresh: () async {
          setState(() {
            _stream = _loadDataStream(); // 스트림을 재구독하여 새로운 데이터 로드
          });
        },
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: _stream,
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

                if (imageUrl != null) {
                  precacheImage(NetworkImage(imageUrl), context);
                }

                // 댓글 개수 처리
                final commentCount =
                    (post['comments'] as List<dynamic>?)?.length ?? 0;

                // 날짜 형식 변경
                final createdAt = DateTime.parse(post['created_at']);
                final formattedDate = DateFormat('MM/dd').format(createdAt);

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              HomePostPage(post: posts[index])),
                    );
                  },
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                        child: SizedBox(
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
                                      style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600),
                                    ),
                                    SizedBox(
                                      height: 2,
                                    ),
                                    Text(
                                      post['content'],
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    const SizedBox(
                                      height: 5,
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
                                              const Icon(
                                                FontAwesomeIcons.comment,
                                                color: Colors.black,
                                                size: 9,
                                              ),
                                              const SizedBox(
                                                width: 3,
                                              ),
                                              Text(
                                                '$commentCount',
                                                style: const TextStyle(
                                                    fontSize: 9, color: bg_90),
                                              ),
                                              const SizedBox(
                                                width: 3,
                                              ),
                                              const Center(
                                                child: Text(
                                                  'ㅣ',
                                                  style: TextStyle(
                                                      fontSize: 8,
                                                      color: bg_90),
                                                ),
                                              ),
                                              const SizedBox(
                                                width: 3,
                                              ),
                                            ],
                                          ),
                                        Text(
                                          formattedDate,
                                          style: const TextStyle(
                                              fontSize: 9, color: bg_70),
                                        ),
                                        const SizedBox(
                                          width: 3,
                                        ),
                                        const Text(
                                          'ㅣ',
                                          style: TextStyle(
                                              fontSize: 8, color: bg_70),
                                        ),
                                        const SizedBox(
                                          width: 3,
                                        ),
                                        Text(
                                          post['author'],
                                          style: const TextStyle(
                                              fontSize: 9, color: bg_90),
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
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.black,
        child: const Center(
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
