import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wact/pages/my/sermon_note_detail_page.dart';

class MySermonPage extends StatefulWidget {
  const MySermonPage({super.key});

  @override
  State<MySermonPage> createState() => _MySermonPageState();
}

class _MySermonPageState extends State<MySermonPage> {
  late Stream<List<Map<String, dynamic>>> _stream;
  late ScrollController controller;

  @override
  void initState() {
    super.initState();
    controller = ScrollController();
    _stream = _loadDataStream();
  }

  Stream<List<Map<String, dynamic>>> _loadDataStream() {
    final userId =
        Supabase.instance.client.auth.currentUser!.id; // 현재 로그인한 사용자의 ID 가져오기

    return Supabase.instance.client
        .from('sermon_notes')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
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
        title: const Text('내 설교노트'),
        centerTitle: true,
      ),
      body: RefreshIndicator(
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
                final sermons = snapshot.data!;
                return ListView.builder(
                  controller: controller,
                  scrollDirection: Axis.vertical,
                  itemCount: sermons.length,
                  itemBuilder: (context, index) {
                    final sermon = sermons[index];
                    // 이미지 URL 처리
                    List<dynamic> imageUrls = [];
                    if (sermon['images'] is List<dynamic>) {
                      imageUrls = sermon['images'];
                    } else if (sermon['images'] is String) {
                      imageUrls = json.decode(sermon['images']);
                    }

                    // 첫 번째 이미지 URL 추출
                    final imageUrl = imageUrls.isNotEmpty ? imageUrls[0] : null;

                    // 날짜 형식 변경
                    final createdAt = DateTime.parse(sermon['created_at']);
                    final formattedDate = DateFormat('MM/dd').format(createdAt);

                    return InkWell(
                      onTap: () {},
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                            child: SizedBox(
                              width: MediaQuery.of(context).size.width - 40,
                              height: 90,
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
                                          sermon['preacher'],
                                          style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w600),
                                        ),
                                        const SizedBox(
                                          height: 2,
                                        ),
                                        Text(
                                          sermon['content'],
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                        const SizedBox(
                                          height: 5,
                                        ),
                                        Text(
                                          formattedDate,
                                          style: const TextStyle(
                                              fontSize: 9, color: Colors.grey),
                                        ),
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
                              color: Colors.grey,
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
      ),
    );
  }
}
