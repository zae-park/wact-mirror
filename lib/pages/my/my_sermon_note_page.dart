import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wact/common/const/color.dart';
import 'package:wact/pages/my/sermon_note_detail_page.dart';

class MySermonNotePage extends StatefulWidget {
  const MySermonNotePage({super.key});

  @override
  State<MySermonNotePage> createState() => _MySermonNotePageState();
}

class _MySermonNotePageState extends State<MySermonNotePage> {
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        toolbarHeight: 60,
        backgroundColor: Color(0xffF1F2FF),
        leading: Transform.translate(
          offset: const Offset(12, 0.0),
          child: IconButton(
            iconSize: 34,
            icon: Image.asset('assets/imgs/icon/btn_back_white.png'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ),
        title: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _stream,
            builder: (context, snapshot) {
              final count = snapshot.hasData ? snapshot.data!.length : 0;
              return Text(
                '설교노트 $count일차',
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 20),
              );
            }),
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
                    final formattedDate =
                        DateFormat('MM. dd').format(createdAt);

                    return InkWell(
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SermonNoteDetailPage(
                              post: sermon,
                              currentIndex: index,
                              refreshCallback: (updatedPost) {
                                // 특정 데이터만 업데이트
                                setState(() {
                                  _stream = _loadDataStream(); // 전체 데이터 새로 로드
                                });
                              },
                            ),
                          ),
                        );

                        // result가 반환된 경우 스트림 갱신
                        if (result == true) {
                          setState(() {
                            _stream = _loadDataStream();
                          });
                        }
                      },
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                            child: SizedBox(
                              width: MediaQuery.of(context).size.width - 40,
                              height: 50,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: 45,
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          formattedDate,
                                          style: const TextStyle(
                                              fontSize: 14,
                                              color: Colors.black,
                                              fontWeight: FontWeight.w700),
                                        ),
                                        Text(
                                          sermon['weekday'] ?? '',
                                          style: const TextStyle(
                                              fontSize: 12, color: blueGrey),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(
                                      width: 25,
                                      height: 25,
                                      child: VerticalDivider(
                                        width: 1,
                                        color: paleGrey,
                                      )),
                                  SizedBox(
                                    width: MediaQuery.of(context).size.width -
                                        40 -
                                        40 -
                                        30 -
                                        40,
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          sermon['title'] ?? '',
                                          style: const TextStyle(
                                              fontSize: 14,
                                              color: Colors.black,
                                              fontWeight: FontWeight.w700),
                                        ),
                                        Text(
                                          '설교: ${sermon['preacher']}',
                                          style: const TextStyle(
                                              fontSize: 12, color: blueGrey),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(
                                    width: 40,
                                    child: Image.asset(
                                      '${sermon['emotion_icon']}',
                                      width: 32,
                                      height: 32,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.fromLTRB(20, 0, 20, 0),
                            child: Divider(
                              color: paleGrey,
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
