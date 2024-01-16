import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wact/common/const/color.dart';
import 'package:wact/pages/home/review/add_review_page.dart';
import 'package:wact/pages/home/review/review_detail_page.dart';

class ReviewPage extends StatefulWidget {
  const ReviewPage({super.key});

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  late Stream<List<Map<String, dynamic>>> _stream;
  late ScrollController controller;

  @override
  void initState() {
    super.initState();
    controller = ScrollController();

    _stream = _loadDataStream();
  }

  Stream<List<Map<String, dynamic>>> _loadDataStream() {
    // Create a stream that listens for real-time changes in the 'reviews' table
    return Supabase.instance.client
        .from('reviews')
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
    return RefreshIndicator(
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
                return const Center(child: CircularProgressIndicator());
              }
              final reviews = snapshot.data!;
              return ListView.builder(
                controller: controller,
                scrollDirection: Axis.vertical,
                itemCount: reviews.length,
                itemBuilder: (context, index) {
                  final review = reviews[index];
                  // 이미지 URL 처리
                  List<dynamic> imageUrls = [];
                  // review['compressed_image_urls']가 List<dynamic>이면 직접 사용
                  if (review['compressed_image_urls'] is List<dynamic>) {
                    imageUrls = review['compressed_image_urls'];
                  }
                  // review['compressed_image_urls']가 String이면 JSON 파싱
                  else if (review['compressed_image_urls'] is String) {
                    String imageUrlString = review['compressed_image_urls'];
                    imageUrls = json.decode(imageUrlString);
                  }

                  // 첫 번째 이미지 URL 추출
                  final imageUrl = imageUrls.isNotEmpty ? imageUrls[0] : null;

                  if (imageUrl != null) {
                    precacheImage(NetworkImage(imageUrl), context);
                  }

                  // 댓글 개수 처리
                  final commentCount =
                      (review['comments'] as List<dynamic>?)?.length ?? 0;

                  // 날짜 형식 변경
                  final createdAt = DateTime.parse(review['created_at']);
                  final formattedDate = DateFormat('MM/dd').format(createdAt);

                  DateTime parsedDate = DateTime.parse(review['meet_date']);
                  String formattedMonth = DateFormat('MMM').format(parsedDate);
                  String formattedDayOfWeek =
                      DateFormat('E', 'ko').format(parsedDate);
                  String formattedDay = DateFormat('d').format(parsedDate);

                  return InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                ReviewDetailPage(review: reviews[index])),
                      );
                    },
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width - 40,
                            height: 75,
                            child: GestureDetector(
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
// 모임 종류와 글 작성 날짜
                                  SizedBox(
                                    width: 40,
                                    height: 55,
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // const SizedBox(
                                        //   height: 5,
                                        // ),
                                        Text(
                                          review['team'],
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w800),
                                        ),

                                        SizedBox(
                                          height: 3,
                                        ),
                                        SizedBox(
                                          width: 40,
                                          child: Text(
                                            formattedDate,
                                            style: const TextStyle(
                                                fontSize: 12, color: bg_70),
                                          ),
                                        ),
                                        // Text(
                                        //   '$formattedDay($formattedDayOfWeek)',
                                        //   maxLines: 1,
                                        //   overflow: TextOverflow.ellipsis,
                                        //   style: const TextStyle(fontSize: 12),
                                        // ),
                                      ],
                                    ),
                                  ),
// 썸네일 이미지(업로드한 이미지 중 첫번째 이미지)

                                  SizedBox(
                                    width: MediaQuery.of(context).size.width -
                                        40 -
                                        50,
                                    height: 55,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width -
                                              40 -
                                              50 -
                                              10 -
                                              5 -
                                              45,
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                review['title'],
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight:
                                                        FontWeight.w500),
                                              ),
                                              SizedBox(
                                                height: 3,
                                              ),
                                              Row(
                                                children: <Widget>[
                                                  const Text(
                                                    '참석: ',
                                                    style: TextStyle(
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color:
                                                            primary), // 여기에 원하는 스타일 적용
                                                  ),
                                                  Expanded(
                                                    child: Text(
                                                      '${review['member']}',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                      ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      // 기본 스타일을 사용하거나 다른 스타일 지정
                                                    ),
                                                  ),
                                                ],
                                              ),

                                              // Text(
                                              //   '참석: ${review['member']}',
                                              //   maxLines: 1,
                                              //   overflow: TextOverflow.ellipsis,
                                              //   style: const TextStyle(
                                              //       fontSize: 12),
                                              // ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(
                                          width: 5,
                                        ),
                                        if (imageUrl != null)
                                          SizedBox(
                                            width: 45,
                                            height: 45,
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(15),
                                              child: CachedNetworkImage(
                                                imageUrl: imageUrl,
                                                width: 45,
                                                height: 45,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
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
          Positioned(
            right: 16,
            bottom: 16,
            child: Align(
              alignment: Alignment.center,
              child: FloatingActionButton(
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
                      builder: (context) => AddReviewPage(
                        onUpload: (String) {},
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
