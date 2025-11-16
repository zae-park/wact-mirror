import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wact/common/const/color.dart';
import 'package:wact/common/init.dart';
import 'package:wact/common/utils/image_compression.dart';
import 'package:wact/common/utils/xfile_image.dart';

class ReviewEditPage extends StatefulWidget {
  final Map<String, dynamic> review;
  final void Function(String) onUpload;
  final Function() onUpdateSuccess;

  const ReviewEditPage({
    Key? key,
    required this.onUpload,
    required this.review,
    required this.onUpdateSuccess,
  }) : super(key: key);

  @override
  State<ReviewEditPage> createState() => _ReviewEditPageState();
}

class _ReviewEditPageState extends State<ReviewEditPage> {
  late TextEditingController _titleEditingController;
  late TextEditingController _contentEditingController;
  late TextEditingController _placeEditingController;
  late TextEditingController _memberEditingController;
  late TextEditingController _bibleController;
  late List<XFile> images;
  bool _isLoading = false;
  String? _selectedTeam;
  DateTime _selectedDate = DateTime.now();
  // 참가자 리스트
  List<String> participantsList =
      ['00명'] + List.generate(100, (index) => '$index명');
  String? _selectedParticipants;

  @override
  void initState() {
    super.initState();

    _titleEditingController =
        TextEditingController(text: widget.review['title']);
    _contentEditingController =
        TextEditingController(text: widget.review['content']);
    _placeEditingController =
        TextEditingController(text: widget.review['place']);
    _memberEditingController =
        TextEditingController(text: widget.review['member']);
    _selectedDate = DateTime.parse(widget.review['meet_date']);
    _bibleController = TextEditingController(text: widget.review['bible']);
    _selectedTeam = ['강남', '시내', '신촌', '인천', '태릉', '오비', '행사', '모임']
            .contains(widget.review['team'])
        ? widget.review['team']
        : '강남'; // 기본값 설정
    _selectedParticipants =
        participantsList.contains('${widget.review['participants']}명')
            ? '${widget.review['participants']}명'
            : '00명';

    var imageUrls = widget.review['compressed_image_urls'];
    if (imageUrls is String) {
      images = (jsonDecode(imageUrls) as List<dynamic>)
          .map((item) => XFile(item as String))
          .toList();
    } else if (imageUrls is List<dynamic>) {
      images = imageUrls.map((item) => XFile(item as String)).toList();
    } else {
      images = [];
    }
  }

  Future<void> _pickImages() async {
    final pickedFiles = await ImagePicker().pickMultiImage();

    if (images.length + pickedFiles.length > 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('최대 6장의 이미지만 선택할 수 있습니다.')),
      );
    } else {
      setState(() {
        images.addAll(pickedFiles);
      });
    }
  }

  // 날짜 선택
  Future<DateTime?> _selectDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      locale: const Locale('ko', 'KR'),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: primary,
            colorScheme: const ColorScheme.light(primary: secondary),
            buttonTheme:
                const ButtonThemeData(textTheme: ButtonTextTheme.primary),
            dialogBackgroundColor: Colors.grey[200],
          ),
          child: child!,
        );
      },
    );
    return pickedDate;
  }

  Future<void> _updateReview() async {
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception('사용자를 찾지 못했습니다.');

    if (_isLoading) return;

    setState(() => _isLoading = true);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          backgroundColor: Colors.white,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [Text('수정된 정보를 저장중입니다•••')],
          ),
        );
      },
    );

    bool shouldUpdate = false;
    Map<String, dynamic> updateData = {};

    if (_titleEditingController.text != widget.review['title']) {
      updateData['title'] = _titleEditingController.text;
      shouldUpdate = true;
    }
    if (_contentEditingController.text != widget.review['content']) {
      updateData['content'] = _contentEditingController.text;
      shouldUpdate = true;
    }
    if (_placeEditingController.text != widget.review['place']) {
      updateData['place'] = _placeEditingController.text;
      shouldUpdate = true;
    }
    if (_memberEditingController.text != widget.review['member']) {
      updateData['member'] = _memberEditingController.text;
      shouldUpdate = true;
    }
    if (_bibleController.text != widget.review['bible']) {
      updateData['bible'] = _bibleController.text;
      shouldUpdate = true;
    }
    if (_selectedTeam != widget.review['team']) {
      updateData['team'] = _selectedTeam;
      shouldUpdate = true;
    }

    if (_selectedDate != widget.review['meet_date']) {
      updateData['meet_date'] = _selectedDate.toIso8601String();
      shouldUpdate = true;
    }

    if (_selectedParticipants != widget.review['participants']) {
      updateData['participants'] = _selectedParticipants?.replaceAll('명', '');
      shouldUpdate = true;
    }

    List<String> imageUrls = [];
    List<String> compressedImageUrls = [];

    if (images.isNotEmpty) {
      for (XFile image in images) {
        if (image.path.startsWith('http')) {
          imageUrls.add(image.path);
          compressedImageUrls.add(image.path);
        } else {
          final imageBytes = await image.readAsBytes();
          final compressedImageBytes =
              await compressImage(imageBytes, quality: 80);

          final fileExt = image.name.split('.').last;
          final fileName = '${DateTime.now().toIso8601String()}.$fileExt';
          final compressedFileName =
              '${DateTime.now().toIso8601String()}_compressed.$fileExt';
          final filePath = 'review_images/$fileName';
          final compressedFilePath =
              'review_compressed_images/$compressedFileName';

          await supabase.storage
              .from('review_photo')
              .uploadBinary(filePath, imageBytes);
          await supabase.storage
              .from('review_compressed_photo')
              .uploadBinary(compressedFilePath, compressedImageBytes);

          final imageUrlResponse = await supabase.storage
              .from('review_photo')
              .createSignedUrl(filePath, 60 * 60 * 24 * 365 * 10);

          final compressedImageUrlResponse = await supabase.storage
              .from('review_compressed_photo')
              .createSignedUrl(compressedFilePath, 60 * 60 * 24 * 365 * 10);

          imageUrls.add(imageUrlResponse);
          compressedImageUrls.add(compressedImageUrlResponse);
          widget.onUpload(imageUrlResponse);
        }
      }

      updateData['image_urls'] = imageUrls;
      updateData['compressed_image_urls'] = compressedImageUrls;
    }

    if (shouldUpdate) {
      final response = await supabase
          .from('reviews')
          .update(updateData)
          .eq('id', widget.review['id']);

      final updatedReview = {
        ...widget.review,
        ...updateData,
        'image_url': imageUrls,
        'compressed_image_url': compressedImageUrls,
      };

      widget.onUpdateSuccess();

      Navigator.of(context, rootNavigator: true).pop();

      setState(() => _isLoading = false);
      Navigator.of(context).pop(updatedReview);
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _titleEditingController.dispose();
    _contentEditingController.dispose();
    _placeEditingController.dispose();
    _memberEditingController.dispose();
    _bibleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget buildImageGrid() {
      return Padding(
        padding: const EdgeInsets.all(20.0),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 8.0,
            crossAxisSpacing: 8.0,
          ),
          itemCount: min(images.length + 1, 6),
          itemBuilder: (BuildContext context, int index) {
            if (index < images.length) {
              Widget imageWidget;
              if (Uri.parse(images[index].path).isAbsolute) {
                imageWidget =
                    Image.network(images[index].path, fit: BoxFit.cover);
              } else {
                imageWidget = buildLocalImage(
                  images[index],
                  fit: BoxFit.cover,
                );
              }
              return LongPressDraggable<XFile>(
                data: images[index],
                feedback: Material(
                  child: Uri.parse(images[index].path).isAbsolute
                      ? Image.network(
                          images[index].path,
                          fit: BoxFit.cover,
                          width: 100,
                          height: 100,
                        )
                      : buildLocalImage(
                          images[index],
                          fit: BoxFit.cover,
                          width: 100,
                          height: 100,
                        ),
                ),
                childWhenDragging: Container(),
                child: Stack(
                  children: [
                    Positioned.fill(child: imageWidget),
                    Positioned(
                      right: -8,
                      top: -8,
                      child: IconButton(
                        iconSize: 16,
                        icon: const FaIcon(FontAwesomeIcons.circleMinus,
                            color: Colors.white),
                        onPressed: () {
                          setState(() {
                            images.removeAt(index);
                          });
                        },
                      ),
                    ),
                  ],
                ),
              );
            } else if (images.length < 6) {
              return GestureDetector(
                onTap: _pickImages,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.add),
                ),
              );
            } else {
              return Container();
            }
          },
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('후기 수정'),
        centerTitle: true,
        actions: <Widget>[
          IconButton(
            onPressed: () async {
              if (_titleEditingController.text.isNotEmpty &&
                  _contentEditingController.text.isNotEmpty) {
                await _updateReview();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    backgroundColor: primary,
                    content: Text('빈 내용을 작성해주세요.'),
                  ),
                );
              }
            },
            icon: const Icon(Icons.check),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            buildImageGrid(),
            const Text('(사진은 최대 6장까지 선택 가능🙂)'),

            // 제목과 내용
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: SizedBox(
                height: (MediaQuery.of(context).size.height),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 지부 & 날짜
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        DropdownButton<String>(
                          style: const TextStyle(color: Colors.black),
                          dropdownColor: Colors.white,
                          value: _selectedTeam,
                          hint: const Text('지부'),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedTeam = newValue;
                            });
                          },
                          items: <String>[
                            '강남',
                            '시내',
                            '신촌',
                            '인천',
                            '태릉',
                            '오비',
                            '행사',
                            '모임',
                          ].map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(
                                value,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 16,
                                ),
                              ),
                            );
                          }).toList(),
                        ),

                        // 날짜 선택
                        Align(
                          alignment: Alignment.topLeft,
                          child: InkWell(
                            onTap: () async {
                              DateTime? pickedDate = await _selectDate();
                              if (pickedDate != null &&
                                  pickedDate != _selectedDate) {
                                setState(() {
                                  _selectedDate = pickedDate;
                                });
                              }
                            },
                            child: Row(
                              children: [
                                const Text(
                                  '모임 날짜: ',
                                  style: TextStyle(
                                      fontSize: 15,
                                      color: Colors.black,
                                      fontWeight: FontWeight.w500),
                                ),
                                // 날짜 표시
                                _selectedDate != DateTime.now() // 날짜가 선택되었는지 확인
                                    ? Text(
                                        "${_selectedDate.year}년 ${_selectedDate.month}월 ${_selectedDate.day}일",
                                        style: const TextStyle(
                                            fontSize: 15,
                                            color: Colors.black,
                                            fontWeight: FontWeight.w500),
                                      )
                                    : const Text(
                                        "날짜 선택",
                                        style: TextStyle(color: secondary),
                                      ),
                                // 수정 아이콘 추가
                                const SizedBox(width: 4),
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: Image.asset(
                                      'assets/imgs/icon/icon_calendar.png'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 16,
                    ),

                    // 참석 인원
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '참석 인원',
                          style: TextStyle(
                            color: bg_90,
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        DropdownButton<String>(
                          style: const TextStyle(color: Colors.black),
                          dropdownColor: Colors.white,
                          value: _selectedParticipants,
                          hint: const Text('인원'),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedParticipants = newValue;
                            });
                          },
                          items: participantsList
                              .map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(
                                value,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 16,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),

                    // 참석한 사람
                    TextFormField(
                      controller: _memberEditingController,
                      maxLines: 1,
                      maxLength: 100,
                      cursorColor: primary,
                      decoration: const InputDecoration(
                        hintText: '참석한 사람을 적어주세요.',
                        hintStyle: TextStyle(
                          color: bg_70,
                          fontWeight: FontWeight.w500,
                          fontSize: 15,
                        ),
                        border: InputBorder.none,
                        counterText: '',
                      ),
                    ),
                    // 색상 정보 복사 버튼과 사진 정보 복사 버튼
                    const Divider(
                      color: bg_30,
                    ),
                    const SizedBox(
                      height: 16,
                    ),

                    // 장소
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '장소',
                          style: TextStyle(
                            color: bg_90,
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        Text(
                          '',
                          style: TextStyle(
                            color: bg_90,
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                    TextFormField(
                      controller: _placeEditingController,
                      maxLines: 1,
                      maxLength: 100,
                      cursorColor: primary,
                      decoration: const InputDecoration(
                        hintText: '모임 장소를 적어주세요.',
                        hintStyle: TextStyle(
                          color: bg_70,
                          fontWeight: FontWeight.w500,
                          fontSize: 15,
                        ),
                        border: InputBorder.none,
                        counterText: '',
                      ),
                    ),
                    // 색상 정보 복사 버튼과 사진 정보 복사 버튼
                    const Divider(
                      color: bg_30,
                    ),
                    const SizedBox(
                      height: 16,
                    ),

                    // 말씀 본문
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '말씀',
                          style: TextStyle(
                            color: bg_90,
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        Text(
                          '',
                          // '${_memberEditingController.text.length}',
                          style: TextStyle(
                            color: bg_90,
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                    TextFormField(
                      controller: _bibleController,
                      maxLines: 1,
                      maxLength: 100,
                      cursorColor: primary,
                      decoration: const InputDecoration(
                        hintText: '말씀 묵상 범위를 적어주세요.',
                        hintStyle: TextStyle(
                          color: bg_70,
                          fontWeight: FontWeight.w500,
                          fontSize: 15,
                        ),
                        border: InputBorder.none,
                        counterText: '',
                      ),
                    ),
                    // 색상 정보 복사 버튼과 사진 정보 복사 버튼
                    const Divider(
                      color: bg_30,
                    ),
                    const SizedBox(
                      height: 16,
                    ),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '제목',
                          style: TextStyle(
                            color: bg_90,
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        Text(
                          '${_titleEditingController.text.length}/15',
                          style: const TextStyle(
                            color: bg_90,
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                    TextFormField(
                      controller: _titleEditingController,
                      maxLines: 1,
                      maxLength: 15,
                      cursorColor: primary,
                      decoration: const InputDecoration(
                        hintText: '제목을 입력해주세요.',
                        hintStyle: TextStyle(
                          color: bg_70,
                          fontWeight: FontWeight.w500,
                          fontSize: 15,
                        ),
                        border: InputBorder.none,
                        counterText: '',
                      ),
                    ),
                    // 색상 정보 복사 버튼과 사진 정보 복사 버튼
                    const Divider(
                      color: bg_30,
                    ),
                    const SizedBox(
                      height: 16,
                    ),
                    // 내용 작성
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '내용',
                          style: TextStyle(
                            color: bg_90,
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        Text(
                          '${_contentEditingController.text.length}/1000',
                          style: const TextStyle(
                            color: bg_90,
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                    Expanded(
                      child: TextFormField(
                        controller: _contentEditingController,
                        maxLines: 10,
                        maxLength: 1000,
                        cursorColor: primary,
                        decoration: const InputDecoration(
                          hintText: '내용을 작성해주세요.',
                          hintStyle: TextStyle(
                            color: bg_70,
                            fontWeight: FontWeight.w500,
                            fontSize: 15,
                          ),
                          border: InputBorder.none,
                          counterText: '',
                          focusColor: primary,
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 32,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
