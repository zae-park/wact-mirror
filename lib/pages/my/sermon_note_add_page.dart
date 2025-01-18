import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wact/common/const/bible_books.dart';
import 'package:wact/common/const/color.dart';
import 'package:wact/common/init.dart';
import 'package:wact/models/%08shared/icon_info.dart';

class SermonNoteAddPage extends StatefulWidget {
  @override
  _SermonNoteAddPageState createState() => _SermonNoteAddPageState();
}

class _SermonNoteAddPageState extends State<SermonNoteAddPage> {
  final List<Map<String, dynamic>> _selectedBibleVerses = [];
  final TextEditingController _preacherController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  String? _selectedWeatherIcon;
  String? _selectedEmotionIcon;
  String? _selectedBook;
  int? _selectedChapter;
  int? _selectedStartVerse;
  int? _selectedEndVerse;

  // XFile? _ocrImage; // 설교노트 OCR 이미지
  // String uploadedOcrFilePath = '';
  // String uploadedOcrCompressedFilePath = '';

  List<XFile> _currentImages = [];
  List<String> uploadedFilePaths = [];
  List<String> uploadedCompressedFilePaths = [];
  bool _isOCREnabled = false; // OCR 활성화 여부

  late Future<List<IconInfo>> emotionIconsFuture;
  late Future<List<IconInfo>> weatherIconsFuture;
  bool _isUploading = false;

  List<int> _generateNumbers(int count) =>
      List<int>.generate(count, (i) => i + 1);

  String _getWeekdayString(int weekday) {
    const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    return weekdays[weekday - 1]; // DateTime.weekday는 1(월요일)부터 시작
  }

  @override
  void initState() {
    super.initState();
    emotionIconsFuture = _loadIcons("emotion");
    weatherIconsFuture = _loadIcons("weather");

    _locationController.text = '서액트교회'; // 초기 값 설정
  }

  // 설교 노트 텍스트 인식

  Future<String> _extractTextFromImage(String imagePath) async {
    const String apiKey = 'AIzaSyB4k5Clcz2Wpm2haTwgdsQ0F2J8P9aB6_s';
    final Uri uri = Uri.parse(
        'https://vision.googleapis.com/v1/images:annotate?key=$apiKey');

    final imageBytes = await File(imagePath).readAsBytes();

    final requestPayload = {
      "requests": [
        {
          "image": {
            "content": base64Encode(imageBytes), // 이미지 Base64 인코딩
          },
          "features": [
            {
              "type": "TEXT_DETECTION", // 텍스트 감지 기능
            }
          ]
        }
      ]
    };

    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestPayload),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final extractedText = responseData['responses'][0]['fullTextAnnotation']
            ['text']; // OCR 결과 추출
        return extractedText ?? '';
      } else {
        debugPrint('Google Vision API 호출 중 오류: ${response.body}');

        throw Exception('Google Vision API Error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Google Vision API 호출 중 오류: $e');
      return '';
    }
  }

  // 날짜 선택 메서드
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
            colorScheme: const ColorScheme.light(
              primary: primary,
            ),
            buttonTheme:
                const ButtonThemeData(textTheme: ButtonTextTheme.primary),
            dialogBackgroundColor: secondary,
          ),
          child: child!,
        );
      },
    );
    return pickedDate;
  }

  // 이미지 선택 후 즉시 스토리지에 원본 및 압축본을 저장하는 함수
  Future<void> _uploadImages(List<XFile> selectedImages) async {
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception('User not found');

    List<String> filePaths = selectedImages.map((imageFile) {
      final fileExt = imageFile.path.split('.').last;
      final fileName = '${DateTime.now().toIso8601String()}.$fileExt';
      return '${user.id}/$fileName';
    }).toList();

    List<String> compressedFilePaths = selectedImages.map((imageFile) {
      final fileExt = imageFile.path.split('.').last;
      final fileName =
          '${DateTime.now().toIso8601String()}_compressed.$fileExt';
      return '${user.id}/$fileName';
    }).toList();

    setState(() {
      _isUploading = true; // 업로드 시작 시 상태 설정
    });

    try {
      for (int i = 0; i < selectedImages.length; i++) {
        var imageFile = selectedImages[i];
        var filePath = filePaths[i];
        var compressedFilePath = compressedFilePaths[i];

        final imageBytes = await imageFile.readAsBytes();
        final fileExt = imageFile.path.split('.').last;

        // 이미지 압축
        final compressedImageBytes =
            await FlutterImageCompress.compressWithList(
          imageBytes,
          quality: 80, // 80% 품질로 압축
        );

        // 원본 이미지 업로드
        await supabase.storage.from('sermon_note_photo').uploadBinary(
              filePath,
              imageBytes,
              fileOptions: FileOptions(contentType: 'image/$fileExt'),
            );
        uploadedFilePaths.add(filePath); // 업로드된 파일 경로 저장

        // 압축본 이미지 업로드
        await supabase.storage
            .from('sermon_note_compressed_photo')
            .uploadBinary(
              compressedFilePath,
              compressedImageBytes,
              fileOptions: FileOptions(contentType: 'image/$fileExt'),
            );
        uploadedCompressedFilePaths.add(compressedFilePath); // 압축본 경로 저장

        // Google Vision API 호출하여 텍스트 인식
        if (_isOCREnabled) {
          final extractedText = await _extractTextFromImage(imageFile.path);
          if (extractedText.isNotEmpty) {
            setState(() {
              _contentController.text +=
                  '\n\n--- OCR 텍스트 추출 ---\n$extractedText'; // 텍스트 필드에 추가
            });
          }
        }
      }
    } catch (e) {
      debugPrint('업로드 중 오류 발생: $e');
    } finally {
      setState(() {
        _isUploading = false; // 업로드 종료 시 상태 변경
      });
    }
  }

  Future<void> _pickImages() async {
    final pickedFiles = await ImagePicker().pickMultiImage();

    if (_currentImages.length + pickedFiles.length > 10) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('최대 10장의 이미지만 선택할 수 있습니다.')));
    } else {
      setState(() {
        _currentImages.addAll(pickedFiles);
      });

      // 선택된 이미지를 바로 스토리지에 저장
      await _uploadImages(pickedFiles);
    }
  }

  Future<File> _compressImage(File file) async {
    final result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      '${file.parent.path}/compressed_${file.uri.pathSegments.last}',
      quality: 80,
    );
    if (result == null) {
      throw Exception("Image compression failed");
    }
    return File(result.path);
  }

  void _addSelectedBibleVerse() {
    if (_selectedBook != null &&
        _selectedChapter != null &&
        _selectedStartVerse != null) {
      final verseRange =
          _selectedEndVerse != null && _selectedEndVerse! > _selectedStartVerse!
              ? '$_selectedStartVerse-$_selectedEndVerse'
              : '$_selectedStartVerse';

      setState(() {
        _selectedBibleVerses.add({
          'book': _selectedBook,
          'chapter': _selectedChapter,
          'verses': verseRange,
        });
        _selectedBook = null;
        _selectedChapter = null;
        _selectedStartVerse = null;
        _selectedEndVerse = null;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('모든 항목을 선택해주세요.')),
      );
    }
  }

  Future<void> _saveToSupabase() async {
    if (_preacherController.text.isEmpty ||
        _titleController.text.isEmpty ||
        _contentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('모든 항목을 작성해주세요.')),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      // 현재 사용자 ID 가져오기
      final user = supabase.auth.currentUser;
      if (user == null) {
        throw Exception('로그인된 사용자가 없습니다.');
      }

      // 사용자별 폴더 이름 생성
      final userId = user.id;

      // 날짜 형식 변환 (YYYY-MM-DD)
      final formattedDate =
          "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}";

      // 테이블에 데이터 삽입
      final response = await supabase.from('sermon_notes').insert({
        'user_id': userId, // 작성자의 ID 추가
        'sermon_date': formattedDate,
        'weekday': _getWeekdayString(_selectedDate.weekday), // 요일 별도 저장
        'preacher': _preacherController.text,
        'location': _locationController.text,
        'title': _titleController.text,
        'content': _contentController.text,
        'bible_verses': _selectedBibleVerses,
        'emotion_icon': 'assets/imgs/icon/emotion/$_selectedEmotionIcon',
        'images': uploadedFilePaths, // 원본 이미지 경로 추가
        'compressed_images': uploadedCompressedFilePaths, // 압축 이미지 경로 추가
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('설교 노트가 저장되었습니다.')),
      );

      Navigator.pop(context, true); // 작성 성공 시 true 반환

      // 성공 후 초기화
      _preacherController.clear();
      _selectedBibleVerses.clear();
      _locationController.clear();
      _titleController.clear();
      _contentController.clear();

      setState(() {
        _selectedBibleVerses.clear();
        _currentImages.clear();
      });
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  // 감정 날씨 아이콘 선택
  Widget _iconSelector(
      String iconName, String hintText, Future<List<IconInfo>> iconsFuture) {
    return FutureBuilder<List<IconInfo>>(
      future: iconsFuture,
      builder: (BuildContext context, AsyncSnapshot<List<IconInfo>> snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.hasData) {
          return SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: snapshot.data!.length,
              itemBuilder: (BuildContext context, int index) {
                final iconInfo = snapshot.data![index];
                final isSelected = (iconName == "emotion" &&
                        _selectedEmotionIcon == iconInfo.fileName) ||
                    (iconName == "weather" &&
                        _selectedWeatherIcon == iconInfo.fileName);

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (iconName == "emotion") {
                        if (_selectedEmotionIcon == iconInfo.fileName) {
                          _selectedEmotionIcon = null; // 선택 취소
                        } else {
                          _selectedEmotionIcon = iconInfo.fileName;
                        }
                      } else {
                        if (_selectedWeatherIcon == iconInfo.fileName) {
                          _selectedWeatherIcon = null; // 선택 취소
                        } else {
                          _selectedWeatherIcon = iconInfo.fileName;
                        }
                      }
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.only(
                        left: 4, top: 8, right: 8, bottom: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18.0),
                      color:
                          isSelected ? primary : Colors.white, // 선택된 경우 색상을 변경
                    ),
                    child: Column(
                      children: [
                        Image.asset(
                          "assets/imgs/icon/$iconName/${iconInfo.fileName}",
                          width: 28,
                          height: 28,
                        ),
                        Text(
                          iconInfo.name,
                          style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected
                                  ? Color(int.parse('0xFF${iconInfo.color}'))
                                  : bg_70,
                              fontSize: isSelected ? 10 : 10),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        } else {
          return Container();
        }
      },
    );
  }

  Future<List<IconInfo>> _loadIcons(String dirName) async {
    final String jsonString =
        await rootBundle.loadString('assets/icon_list.json');
    final Map<String, dynamic> iconMap = json.decode(jsonString);
    final List<dynamic> iconList = iconMap[dirName] ?? [];

    return iconList
        .map((iconData) => IconInfo(
            fileName: iconData['fileName'],
            name: iconData['name'],
            color: iconData['color']))
        .toList();
  }

  // 스토리지에서 이미지를 삭제하는 함수
  Future<void> _deleteUploadedImages() async {
    for (String filePath in uploadedFilePaths) {
      try {
        await supabase.storage.from('sermon_note_photo').remove([filePath]);
        debugPrint('원본 이미지 삭제 완료: $filePath');
      } catch (e) {
        debugPrint('원본 이미지 삭제 중 오류 발생: $filePath, $e');
      }
    }
    for (String compressedFilePath in uploadedCompressedFilePaths) {
      try {
        await supabase.storage
            .from('sermon_note_compressed_photo')
            .remove([compressedFilePath]);
        debugPrint('압축 이미지 삭제 완료: $compressedFilePath');
      } catch (e) {
        debugPrint('압축 이미지 삭제 중 오류 발생: $compressedFilePath, $e');
      }
    }
  }

  // 업로드 중인 작업 중지 및 업로드된 이미지만 삭제하는 함수
  Future<void> _cancelUploadAndDeleteImages() async {
    // 업로드가 진행 중이면, 업로드된 이미지만 삭제
    if (_isUploading) {
      debugPrint('업로드가 진행 중입니다. 일부 업로드된 이미지를 삭제합니다.');
      await _deleteUploadedImages();
    } else {
      debugPrint('모든 이미지가 이미 업로드된 상태입니다.');
    }
  }

  @override
  void dispose() {
    if (_currentImages.isNotEmpty) {
      // '게시' 버튼을 누르지 않고 페이지를 벗어날 경우 업로드를 중단하고 이미지를 삭제
      _cancelUploadAndDeleteImages();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 이미지 표시 부분
    Widget buildImageGrid() {
      return Padding(
        padding: const EdgeInsets.all(0.0),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            mainAxisSpacing: 8.0,
            crossAxisSpacing: 8.0,
          ),
          itemCount: min(_currentImages.length + 1, 10),
          itemBuilder: (BuildContext context, int index) {
            if (index < _currentImages.length) {
              return DragTarget<XFile>(
                onWillAccept: (data) => true,
                onAccept: (data) {
                  setState(() {
                    final oldIndex = _currentImages.indexOf(data);
                    _currentImages.remove(data);
                    if (index > oldIndex) {
                      _currentImages.insert(index - 1, data);
                    } else {
                      _currentImages.insert(index, data);
                    }
                  });
                },
                builder: (context, candidateData, rejectedData) {
                  return LongPressDraggable<XFile>(
                    data: _currentImages[index],
                    feedback: Material(
                      child: Image.file(File(_currentImages[index].path),
                          fit: BoxFit.cover, width: 100, height: 100),
                    ),
                    childWhenDragging: Container(),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Image.file(File(_currentImages[index].path),
                              fit: BoxFit.cover),
                        ),
                        // 삭제 버튼
                        Positioned(
                          right: -8,
                          top: -8,
                          child: IconButton(
                            iconSize: 16,
                            icon: const FaIcon(
                              FontAwesomeIcons.circleMinus,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              setState(() {
                                _currentImages.removeAt(index);
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            } else if (_currentImages.length < 10) {
              return GestureDetector(
                onTap: _pickImages,
                onLongPress: () {
                  setState(() {
                    _isOCREnabled = !_isOCREnabled;
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: _isOCREnabled ? primary : Colors.grey,
                        width: _isOCREnabled ? 3 : 1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _isOCREnabled
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.document_scanner_outlined,
                                color: primary, size: 20),
                            SizedBox(
                              height: 1,
                            ),
                            Text(
                              'OCR',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        )
                      : Icon(Icons.add),
                ),
              );
            } else {
              return Container();
            }
          },
        ),
      );
    }

    // IconButton(
    //                         icon: Icon(
    //                           _isOCREnabled
    //                               ? Icons.document_scanner
    //                               : Icons.document_scanner,
    //                           color: _isOCREnabled ? primary : blueGrey,
    //                         ),
    //                         onPressed: () {
    //                           setState(() {
    //                             _isOCREnabled = !_isOCREnabled;
    //                           });
    //                         },
    //                       );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        toolbarHeight: 60,
        backgroundColor: Color(0xffF1F2FF),
        title: const Text(
          '설교노트',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        leading: Transform.translate(
          offset: const Offset(12, 0.0),
          child: IconButton(
            iconSize: 34,
            icon: Image.asset('assets/imgs/icon/btn_back_white.png'),
            onPressed: () async {
              Navigator.pop(context);
            },
          ),
        ),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 9, 20, 9),
            child: SizedBox(
              width: 46,
              height: 37,
              child: GestureDetector(
                onTap: _isUploading ? null : _saveToSupabase,
                child: Container(
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(19), color: primary),
                  child: const Center(
                    child: Text(
                      '저장',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(), // 다른 영역을 터치하면 키보드가 닫힘
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  children: [
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
                              '',
                              style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.black,
                                  fontWeight: FontWeight.w500),
                            ),
                            _selectedDate != DateTime.now()
                                ? Text(
                                    "${_selectedDate.year}년 ${_selectedDate.month}월 ${_selectedDate.day}일 (${_getWeekdayString(_selectedDate.weekday)})",
                                    style: const TextStyle(
                                        fontSize: 15,
                                        color: Colors.black,
                                        fontWeight: FontWeight.w500),
                                  )
                                : const Text(
                                    "날짜 선택",
                                    style: TextStyle(color: secondary),
                                  ),
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
              ),
              const SizedBox(height: 2),
              _iconSelector("emotion", "감정", emotionIconsFuture),

              const Divider(
                color: bg_30,
              ),

              // 장소&설교자 입력
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(
                    width: (MediaQuery.of(context).size.width - 42) / 2,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 5),
                      child: TextFormField(
                        controller: _locationController,
                        maxLines: 1,
                        maxLength: 20,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(20),
                        ],
                        cursorColor: primary,
                        decoration: const InputDecoration(
                          labelText: '장소',
                          labelStyle: TextStyle(color: bg_70),
                          hintStyle: TextStyle(
                            color: bg_70,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                          border: InputBorder.none,
                          counterText: '',
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 10,
                    height: 40,
                    child: VerticalDivider(
                      color: bg_50,
                    ),
                  ),
                  SizedBox(
                    width: (MediaQuery.of(context).size.width - 42) / 2,
                    child: TextFormField(
                      controller: _preacherController,
                      maxLines: 1,
                      maxLength: 20,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(20),
                      ],
                      cursorColor: primary,
                      decoration: const InputDecoration(
                        labelText: '설교자',
                        labelStyle: TextStyle(color: bg_70),
                        hintStyle: TextStyle(
                          color: bg_70,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                        border: InputBorder.none,
                        counterText: '',
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(
                color: bg_30,
              ),
              SizedBox(
                height: 6,
              ),
              // 선택된 성경절 목록
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '본문 성경절',
                      style: TextStyle(
                        color: bg_90,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 6,
              ),
              if (_selectedBibleVerses.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _selectedBibleVerses.asMap().entries.map((entry) {
                      final index = entry.key + 1; // 1부터 시작하는 번호
                      final verse = entry.value;

                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '$index. ${verse['book']} ${verse['chapter']}장 ${verse['verses']}절',
                            style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Colors.black),
                          ),
                          IconButton(
                            icon: Image.asset(
                              'assets/imgs/icon/btn_close.png',
                              width: 22,
                              height: 22,
                            ),
                            onPressed: () {
                              setState(() {
                                _selectedBibleVerses.remove(verse);
                              });
                            },
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),

              // 성경절 선택

              Row(
                children: [
                  SizedBox(
                    width: (MediaQuery.of(context).size.width - 16) / 2,
                    child: DropdownButtonFormField<String>(
                      icon: Image.asset(
                        'assets/imgs/icon/btn_dropdown.png',
                        width: 20,
                        height: 20,
                      ),
                      dropdownColor: Colors.pink[50],
                      value: _selectedBook,
                      style: TextStyle(
                          color: Colors.black, fontWeight: FontWeight.w700),
                      hint: const Text(
                        '성경절 선택',
                        style: TextStyle(
                            color: blueGrey, fontWeight: FontWeight.w500),
                      ),
                      items: bibleBooks.map((book) {
                        return DropdownMenuItem(
                          value: book,
                          child: Text(book),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedBook = value;
                          _selectedChapter = null;
                          _selectedStartVerse = null;
                          _selectedEndVerse = null;
                        });
                      },
                      decoration: InputDecoration(
                        fillColor: paleGrey,
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(5.0), // 모서리 둥글게 설정
                          borderSide: BorderSide.none, // 테두리 선 제거
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4.0),
                  if (_selectedBook != null)
                    SizedBox(
                      width: (MediaQuery.of(context).size.width - 16 - 4) / 4,
                      child: DropdownButtonFormField<int>(
                        dropdownColor: Colors.orange[200],
                        icon: Image.asset(
                          'assets/imgs/icon/btn_dropdown.png',
                          width: 20,
                          height: 20,
                        ),
                        decoration: InputDecoration(
                          fillColor: paleGrey,
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(5.0), // 모서리 둥글게 설정
                            borderSide: BorderSide.none, // 테두리 선 제거
                          ),
                        ),
                        value: _selectedChapter,
                        hint: const Text(
                          '장',
                          style: TextStyle(
                              color: blueGrey, fontWeight: FontWeight.w500),
                        ),
                        items: _generateNumbers(50).map((chapter) {
                          return DropdownMenuItem(
                            value: chapter,
                            child: Text('$chapter장'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedChapter = value;
                            _selectedStartVerse = null;
                            _selectedEndVerse = null;
                          });
                        },
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 4.0),

              if (_selectedChapter != null)
                Row(
                  children: [
                    SizedBox(
                      width: (MediaQuery.of(context).size.width - 16 - 4) / 3,
                      child: DropdownButtonFormField<int>(
                        icon: Image.asset(
                          'assets/imgs/icon/btn_dropdown.png',
                          width: 20,
                          height: 20,
                        ),
                        value: _selectedStartVerse,
                        hint: const Text('시작 절'),
                        items: _generateNumbers(176).map((verse) {
                          return DropdownMenuItem(
                            value: verse,
                            child: Text('$verse절'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedStartVerse = value;
                            _selectedEndVerse = null;
                          });
                          if (value != null) {
                            FocusScope.of(context).nextFocus(); // 다음 필드로 이동
                          }
                        },
                        dropdownColor: Colors.amber[100],
                        decoration: InputDecoration(
                          fillColor: paleGrey,
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(5.0), // 모서리 둥글게 설정
                            borderSide: BorderSide.none, // 테두리 선 제거
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4.0),
                    SizedBox(
                      width: (MediaQuery.of(context).size.width - 16 - 4) / 3,
                      child: DropdownButtonFormField<int>(
                        icon: Image.asset(
                          'assets/imgs/icon/btn_dropdown.png',
                          width: 20,
                          height: 20,
                        ),
                        value: _selectedEndVerse,
                        hint: const Text('끝 절'),
                        items: _generateNumbers(176).map((verse) {
                          return DropdownMenuItem(
                            value: verse,
                            child: Text('$verse절'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedEndVerse = value;
                          });
                          FocusScope.of(context)
                              .nextFocus(); // 끝 절 선택 후 다음 필드로 이동
                        },
                        dropdownColor: Colors.green[100],
                        decoration: InputDecoration(
                          fillColor: paleGrey,
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(5.0), // 모서리 둥글게 설정
                            borderSide: BorderSide.none, // 테두리 선 제거
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Image.asset(
                        (_selectedBook != null &&
                                _selectedChapter != null &&
                                _selectedStartVerse != null)
                            ? 'assets/imgs/icon/ic_check_big_on.png'
                            : 'assets/imgs/icon/ic_check_big_off.png',
                        width: 30,
                        height: 30,
                      ),
                      onPressed: _addSelectedBibleVerse,
                    ),
                  ],
                ),
              const SizedBox(height: 4.0),
              const Divider(
                color: bg_30,
              ),
              const SizedBox(height: 6.0),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '설교 제목',
                      style: TextStyle(
                        color: bg_90,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    Text(
                      '${_titleController.text.length}/20',
                      style: const TextStyle(
                        color: bg_90,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: TextFormField(
                  controller: _titleController,
                  maxLines: 1,
                  maxLength: 20,
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(20),
                  ],
                  cursorColor: primary,
                  decoration: const InputDecoration(
                    hintText: '설교 제목을 입력해주세요.',
                    hintStyle: TextStyle(
                      color: bg_70,
                      fontWeight: FontWeight.w500,
                      fontSize: 15,
                    ),
                    border: InputBorder.none,
                    counterText: '',
                  ),
                ),
              ),
              // 색상 정보 복사 버튼과 사진 정보 복사 버튼
              const Divider(
                color: bg_30,
              ),

              const SizedBox(height: 6.0),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '설교 내용',
                      style: TextStyle(
                        color: bg_90,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    Text(
                      '${_contentController.text.length}/1000',
                      style: const TextStyle(
                        color: bg_90,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: TextFormField(
                  controller: _contentController,
                  minLines: 3,
                  maxLines: 50,
                  maxLength: 1000,
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(1000),
                  ],
                  cursorColor: primary,
                  decoration: const InputDecoration(
                    hintText: '설교 내용을 적어주세요.',
                    hintStyle: TextStyle(
                      color: bg_70,
                      fontWeight: FontWeight.w500,
                      fontSize: 15,
                    ),
                    border: InputBorder.none,
                    counterText: '',
                  ),
                ),
              ),
              // 색상 정보 복사 버튼과 사진 정보 복사 버튼
              const SizedBox(height: 6),
              buildImageGrid(),
              const SizedBox(height: 36.0),
            ],
          ),
        ),
      ),
    );
  }
}
