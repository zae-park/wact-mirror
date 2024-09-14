// 홈 > 후기게시판 홈
// 240525 ,로 인원 구분이 아닌 review['participants']값 저장 후 불러오기로 수정

import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:wact/common/const/color.dart';
import 'package:wact/pages/home/review/review_detail_page.dart';

class ReviewPage extends StatefulWidget {
  const ReviewPage({super.key});

  @override
  State<ReviewPage> createState() => ReviewPageState();
}

class ReviewPageState extends State<ReviewPage> {
  late Stream<List<Map<String, dynamic>>> _stream;
  late Future<List<Map<String, dynamic>>> _future;
  late ScrollController controller;
  bool isListView = true;

  @override
  void initState() {
    super.initState();
    controller = ScrollController();

    _stream = _loadDataStream();
    _loadData();
  }

  Stream<List<Map<String, dynamic>>> _loadDataStream() {
    return Supabase.instance.client
        .from('reviews')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) => List<Map<String, dynamic>>.from(data));
  }

  Future<void> _loadData() async {
    _future = Supabase.instance.client
        .from('reviews')
        .select()
        .order('created_at', ascending: false);

    setState(() {});
  }

  void refresh() {
    setState(() {
      _stream = _loadDataStream();
      debugPrint('ReviewPage 새로고침 실행됨');
    });
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
        toolbarHeight: 44,
        backgroundColor: primary,
        elevation: 0,
        title: TextButton(
          style: ButtonStyle(
            overlayColor: MaterialStateProperty.all(Colors.transparent),
          ),
          onPressed: () {
            setState(() {
              isListView = !isListView; // 뷰 전환
            });
          },
          child: isListView
              ? const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '달력 보기',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          fontSize: 16),
                    ),
                    Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.white,
                    ),
                  ],
                )
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '달력 접기',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          fontSize: 16),
                    ),
                    Icon(
                      Icons.keyboard_arrow_up,
                      color: Colors.white,
                    ),
                  ],
                ),
        ),
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
            isListView
                ? StreamBuilder<List<Map<String, dynamic>>>(
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
                          if (review['compressed_image_urls']
                              is List<dynamic>) {
                            imageUrls = review['compressed_image_urls'];
                          }
                          // review['compressed_image_urls']가 String이면 JSON 파싱
                          else if (review['compressed_image_urls'] is String) {
                            String imageUrlString =
                                review['compressed_image_urls'];
                            imageUrls = json.decode(imageUrlString);
                          }

                          // 첫 번째 이미지 URL 추출
                          final imageUrl =
                              imageUrls.isNotEmpty ? imageUrls[0] : null;

                          if (imageUrl != null) {
                            precacheImage(NetworkImage(imageUrl), context);
                          }

                          // 댓글 개수 처리
                          final commentCount =
                              (review['comments'] as List<dynamic>?)?.length ??
                                  0;

                          // 날짜 형식 변경
                          final createdAt =
                              DateTime.parse(review['created_at']);
                          final formattedDate =
                              DateFormat('MM/dd').format(createdAt);

                          DateTime parsedDate =
                              DateTime.parse(review['meet_date']);
                          String formattedMonth =
                              DateFormat('MMM').format(parsedDate);
                          String formattedDayOfWeek =
                              DateFormat('E', 'ko').format(parsedDate);
                          String formattedDay =
                              DateFormat('d').format(parsedDate);

                          // 참석자 수 ,값으로 세기
                          String members = review['member'];
                          int memberCount = members.split(',').length;

                          return InkWell(
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ReviewDetailPage(
                                    review: reviews[index],
                                    currentIndex: index,
                                    onUpdateSuccess: refresh, // 새로고침 함수 연결
                                  ),
                                ),
                              );
                            },
                            child: Column(
                              children: [
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(20, 10, 20, 10),
                                  child: SizedBox(
                                    width:
                                        MediaQuery.of(context).size.width - 40,
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
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w800),
                                                ),

                                                const SizedBox(
                                                  height: 3,
                                                ),
                                                SizedBox(
                                                  width: 40,
                                                  child: Text(
                                                    formattedDate,
                                                    style: const TextStyle(
                                                        fontSize: 12,
                                                        color: bg_70),
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
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width -
                                                40 -
                                                50,
                                            height: 55,
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
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
                                                        MainAxisAlignment
                                                            .center,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        review['title'],
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: const TextStyle(
                                                            fontSize: 16,
                                                            fontWeight:
                                                                FontWeight
                                                                    .w500),
                                                      ),
                                                      const SizedBox(
                                                        height: 3.5,
                                                      ),
                                                      Row(
                                                        children: <Widget>[
                                                          if (review[
                                                                  'participants'] !=
                                                              null)
                                                            Text(
                                                              '${review['participants']}명 ',
                                                              style: const TextStyle(
                                                                  fontSize: 12,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  color:
                                                                      primary), // 여기에 원하는 스타일 적용
                                                            )
                                                          else
                                                            const Text(
                                                              '참석 ',
                                                              style: TextStyle(
                                                                  fontSize: 12,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  color:
                                                                      primary), // 여기에 원하는 스타일 적용
                                                            ),
                                                          Expanded(
                                                            child: Text(
                                                              '${review['member']}',
                                                              style:
                                                                  const TextStyle(
                                                                fontSize: 12,
                                                              ),
                                                              maxLines: 1,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(
                                                  width: 5,
                                                ),
                                                if (imageUrl != null)
                                                  SizedBox(
                                                    width: 45,
                                                    height: 45,
                                                    child: ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              15),
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
                  )

                // 오른쪽 하단의 아이콘 클릭 시 나오는 캘린더 뷰
                : TableCalendar(
                    locale: 'ko_KR',
                    headerVisible: true,
                    daysOfWeekHeight: 50,
                    rowHeight: 85,
                    daysOfWeekStyle: const DaysOfWeekStyle(
                      weekdayStyle: TextStyle(color: bg_70, fontSize: 12),
                      weekendStyle: TextStyle(color: bg_70, fontSize: 12),
                    ),
                    calendarStyle: const CalendarStyle(
                      cellAlignment: Alignment.topCenter,
                      tableBorder: TableBorder(
                        horizontalInside: BorderSide(
                          width: 1,
                          color: Color(0xfff1f3f6),
                        ),
                      ),
                    ),
                    focusedDay: DateTime.now(),
                    firstDay: DateTime.utc(2000, 01, 01),
                    lastDay: DateTime.utc(2999, 12, 31),
                    headerStyle: const HeaderStyle(
                        leftChevronVisible: false,
                        rightChevronVisible: false,
                        formatButtonVisible: false,
                        titleCentered: true),
                    calendarBuilders: CalendarBuilders(
                      todayBuilder: (context, date, events) {
                        return Align(
                          alignment: Alignment.topCenter,
                          child: Container(
                            margin: const EdgeInsets.only(top: 4),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: bg_70, // 원하는 색상 지정
                            ),
                            width: 24, // 원의 크기 조정
                            height: 24,
                            child: Center(
                              child: Text(
                                "${date.day}", // 오늘 날짜의 일(day) 표시
                                style: const TextStyle(
                                  fontSize: 14, // 폰트 크기 조정
                                  color: Colors.white, // 폰트 색상 지정
                                ),
                              ),
                            ), // 원의 크기 조정
                          ),
                        );
                      },
                      markerBuilder: (context, date, reviews) {
                        return FutureBuilder(
                          future: _future,
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return Container();
                            }
                            final reviews = snapshot.data!;
                            print(reviews);
                            for (var review in reviews) {
                              print(
                                  review['team']); // 각 리뷰의 'team' 필드 값을 출력해봅니다.
                            }
                            // 해당 날짜에 해당하는 일기들을 필터링
                            var filteredreviews = reviews.where((review) {
                              DateTime reviewDate =
                                  DateTime.parse(review['meet_date']);
                              return reviewDate.year == date.year &&
                                  reviewDate.month == date.month &&
                                  reviewDate.day == date.day;
                            }).toList();

                            // 해당 날짜에 일기가 2개 이상인 경우 top 값을 30으로 설정
                            double topValue =
                                filteredreviews.length >= 2 ? 30.0 : 30.0;

                            return Positioned(
                              top: topValue,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: filteredreviews
                                    .asMap()
                                    .entries
                                    .map((entry) {
                                  int index = entry.key;
                                  var review = entry.value;

                                  String imageUrl =
                                      entry.value['compressed_image_urls'][0];
                                  String teamName = review['team'];
                                  return InkWell(
                                    onTap: () async {
                                      final result = await Get.to(
                                        () => ReviewDetailPage(
                                          review: entry.value,
                                          currentIndex: index,
                                          onUpdateSuccess:
                                              refresh, // 새로고침 함수 연결
                                        ),
                                      );
                                      if (result == true) {
                                        _loadData();
                                      }
                                    },
                                    child: Column(
                                      children: [
                                        Container(
                                          width: 28,
                                          height: 28,
                                          margin:
                                              const EdgeInsets.only(bottom: 3),
                                          decoration: BoxDecoration(
                                            image: DecorationImage(
                                              image: NetworkImage(imageUrl),
                                              fit: BoxFit.cover,
                                            ),
                                            shape: BoxShape.circle,
                                            // borderRadius:
                                            //     BorderRadius.circular(10),
                                          ),
                                        ),
                                        Container(
                                          width: 27,
                                          height: 16,
                                          decoration: BoxDecoration(
                                            color: primary,
                                            borderRadius:
                                                BorderRadius.circular(3),
                                          ),
                                          child: Center(
                                            child: Text(
                                              teamName,
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w800),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
          ],
        ),
      ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () {
      //     setState(() {
      //       isListView = !isListView; // 뷰 전환
      //     });
      //   },
      //   backgroundColor: Colors.black,
      //   elevation: 6.0,
      //   shape: const RoundedRectangleBorder(
      //     borderRadius: BorderRadius.all(Radius.circular(40)),
      //     side: BorderSide(color: Colors.white, width: 1),
      //   ),
      //   child: Image.asset(
      //     isListView
      //         ? 'assets/imgs/icon/btn_calendar_view@3x.png'
      //         : 'assets/imgs/icon/btn_list_view@3x.png',
      //     width: 30,
      //     height: 30,
      //   ),
      // ),
    );
  }
}
