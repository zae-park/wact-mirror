// 홈 > 후기게시판 홈
// 240525 ,로 인원 구분이 아닌 review['participants']값 저장 후 불러오기로 수정

import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:wact/common/const/color.dart';
import 'package:wact/pages/home/review/review_add_page.dart';
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
  bool isListView = true; // true: 리스트 뷰, false: 달력 뷰
  DateTime focusedDay = DateTime.now(); // 달력에서 현재 포커스된 날짜

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
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('yyyy년 M월').format(focusedDay);

    return Scaffold(
      backgroundColor: isListView ? Colors.white : Color(0xff232529),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: isListView ? Colors.white : Color(0xff232529),
        elevation: 0,
        toolbarHeight: 60,
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isListView ? '서액트 후기' : formattedDate,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: isListView ? Colors.black : Colors.white,
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    isListView = !isListView; // 뷰 전환
                  });
                },
                child: isListView
                    ? SizedBox(
                        width: 45,
                        height: 45,
                        child: Container(
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                                color: primary),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  [
                                    '월',
                                    '화',
                                    '수',
                                    '목',
                                    '금',
                                    '토',
                                    '일'
                                  ][DateTime.now().weekday - 1],
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  '${DateTime.now().day}',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            )),
                      )
                    : SizedBox(
                        width: 45,
                        height: 45,
                        child: Container(
                          width: double.infinity,
                          height: double.infinity,
                          child: Icon(
                            Icons.list_alt_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
      body: RefreshIndicator(
        color: isListView ? Colors.black : Colors.white,
        backgroundColor: isListView ? Colors.white : Color(0xff232529),
        onRefresh: () async {
          setState(() {
            _stream = _loadDataStream();
          });
        },
        child: isListView ? _buildListView() : _buildCalendarView(),
      ),
      floatingActionButton: SizedBox(
        height: 48,
        child: FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ReviewAddPage(
                  onUpload: (String) {},
                ),
              ),
            ).then((result) {
              if (result == true) {
                debugPrint('새로운 게시글 작성 후 ReviewPage를 새로고침');
                refresh();
              }
            });
          },
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(40),
          ),
          label: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 0),
            child: SizedBox(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '글쓰기  ',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  Padding(
                    padding: EdgeInsets.only(bottom: 5),
                    child: Text(
                      '+',
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.w200),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildListView() {
    return Container(
      color: Colors.white,
      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _stream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(
                color: Colors.black,
              ),
            );
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
              if (review['compressed_image_urls'] is List<dynamic>) {
                imageUrls = review['compressed_image_urls'];
              } else if (review['compressed_image_urls'] is String) {
                String imageUrlString = review['compressed_image_urls'];
                imageUrls = json.decode(imageUrlString);
              }

              final imageUrl = imageUrls.isNotEmpty ? imageUrls[0] : null;

              if (imageUrl != null) {
                precacheImage(NetworkImage(imageUrl), context);
              }

              // 날짜 형식 변경
              final createdAt = DateTime.parse(review['created_at']);
              final formattedDate = DateFormat('MM.dd').format(createdAt);

              return InkWell(
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ReviewDetailPage(
                        review: reviews[index],
                        currentIndex: index,
                        onUpdateSuccess: refresh,
                      ),
                    ),
                  );

                  if (result == true) {
                    refresh();
                  }
                },
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        20,
                        index == 0 ? 10 : 10, // 첫 번째 아이템도 10px 패딩
                        20,
                        10,
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        height: 75,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // 모임 종류와 글 작성 날짜
                            SizedBox(
                              width: 40,
                              height: 55,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 40,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color: primary,
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: Center(
                                      child: Text(
                                        review['team'],
                                        style: const TextStyle(
                                          color: bg_10,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  SizedBox(
                                    width: 40,
                                    child: Center(
                                      child: Text(
                                        formattedDate,
                                        style: const TextStyle(
                                          fontSize: 12.5,
                                          color: Colors.black,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // 콘텐츠 영역
                            Expanded(
                              child: Container(
                                height: 55,
                                margin: EdgeInsets.only(left: 10, right: 0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 3),
                                          SizedBox(
                                            height: 25,
                                            child: Align(
                                              alignment: Alignment.bottomLeft,
                                              child: Text(
                                                review['title'],
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Row(
                                            children: <Widget>[
                                              if (review['participants'] !=
                                                  null)
                                                Row(
                                                  children: [
                                                    Image.asset(
                                                      'assets/imgs/icon/bottomnavigation/mypage_selected.png',
                                                      width: 15,
                                                      height: 15,
                                                    ),
                                                    SizedBox(width: 2),
                                                    Text(
                                                      '${review['participants']}명 ',
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w300,
                                                        color: Colors.black,
                                                      ),
                                                    ),
                                                  ],
                                                )
                                              else
                                                const Text(
                                                  '참석 ',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w500,
                                                    color: primary,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),

                                    // 썸네일 이미지
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
    );
  }

  Widget _buildCalendarView() {
    return SingleChildScrollView(
      child: Container(
        color: Color(0xff232529),
        child: TableCalendar(
          locale: 'ko_KR',
          headerVisible: false, // 기본 헤더 숨기기
          daysOfWeekHeight: 30,
          rowHeight: 85,
          daysOfWeekStyle: const DaysOfWeekStyle(
            weekdayStyle: TextStyle(color: bg_70, fontSize: 12),
            weekendStyle: TextStyle(color: bg_70, fontSize: 12),
          ),
          calendarStyle: const CalendarStyle(
            defaultTextStyle: TextStyle(color: Colors.white),
            weekendTextStyle: TextStyle(color: Colors.white),
            todayTextStyle: TextStyle(color: Colors.white),
            outsideTextStyle: TextStyle(color: bg_70),
            cellAlignment: Alignment.topCenter,
            tableBorder: TableBorder(),
          ),
          focusedDay: focusedDay, // 상태 변수 사용
          firstDay: DateTime.utc(2000, 01, 01),
          lastDay: DateTime.utc(2999, 12, 31),
          onPageChanged: (focusedDay) {
            // 월이 변경될 때마다 호출
            setState(() {
              this.focusedDay = focusedDay;
            });
          },
          calendarBuilders: CalendarBuilders(
            todayBuilder: (context, date, events) {
              return Align(
                alignment: Alignment.topCenter,
                child: Container(
                  margin: const EdgeInsets.only(top: 4),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: secondary,
                  ),
                  width: 24,
                  height: 24,
                  child: Center(
                    child: Text(
                      "${date.day}",
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
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

                  // 해당 날짜에 해당하는 일기들을 필터링
                  final filteredReviews = reviews.where((review) {
                    DateTime reviewDate = DateTime.parse(review['meet_date']);
                    return reviewDate.year == date.year &&
                        reviewDate.month == date.month &&
                        reviewDate.day == date.day;
                  }).toList();

                  double topValue = filteredReviews.length >= 2 ? 30.0 : 30.0;

                  return Positioned(
                    top: topValue,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: filteredReviews.asMap().entries.map((entry) {
                        int index = entry.key;
                        var review = entry.value;

                        // 이미지 URL 확인 및 team 이름 가져오기
                        String? imageUrl =
                            review['compressed_image_urls'] is List<dynamic> &&
                                    review['compressed_image_urls'].isNotEmpty
                                ? review['compressed_image_urls'][0]
                                : '';
                        String teamName = review['team'];
                        bool schedule = review['schedule'];
                        String title = review['title'];

                        return InkWell(
                          onTap: () async {
                            final result = await Get.to(
                              () => ReviewDetailPage(
                                review: entry.value,
                                currentIndex: index,
                                onUpdateSuccess: refresh,
                              ),
                            );
                            if (result == true) {
                              _loadData();
                            }
                          },
                          child: Column(
                            children: [
                              if (schedule && filteredReviews.length < 2)
                                Container(
                                  width: 30,
                                  height: 45,
                                  decoration: BoxDecoration(
                                    image: DecorationImage(
                                      image: NetworkImage(imageUrl!),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              if (!schedule &&
                                  imageUrl != '' &&
                                  filteredReviews.length < 3)
                                Container(
                                  width: 27,
                                  height: 27,
                                  margin: const EdgeInsets.only(bottom: 3),
                                  decoration: BoxDecoration(
                                    image: DecorationImage(
                                      image: NetworkImage(imageUrl!),
                                      fit: BoxFit.contain,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              if (filteredReviews.length > 1)
                                Container(
                                  margin:
                                      EdgeInsets.only(bottom: schedule ? 3 : 0),
                                  width: schedule ? 32 : 27,
                                  height: schedule ? 24 : 16,
                                  decoration: BoxDecoration(
                                    color: schedule ? Colors.red : primary,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: Center(
                                    child: Text(
                                      schedule ? title : teamName,
                                      overflow: TextOverflow.clip,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: schedule ? 8 : 9,
                                        fontWeight: schedule
                                            ? FontWeight.w500
                                            : FontWeight.w800,
                                      ),
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
      ),
    );
  }
}
