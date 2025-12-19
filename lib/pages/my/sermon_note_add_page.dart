import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wact/common/const/bible_books.dart';
import 'package:wact/common/const/color.dart';
import 'package:wact/common/init.dart';
import 'package:wact/common/utils/image_compression.dart';
import 'package:wact/common/utils/xfile_image.dart';
import 'package:wact/models/shared/icon_info.dart';

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

  // XFile? _ocrImage; // ???? OCR ???
  // String uploadedOcrFilePath = '';
  // String uploadedOcrCompressedFilePath = '';

  List<XFile> _currentImages = [];
  List<String> uploadedFilePaths = [];
  List<String> uploadedCompressedFilePaths = [];
  bool _isOCREnabled = false; // OCR ??? ??
  bool _isExtractingText = false; // ??? ?? ??? ???? ??

  late Future<List<IconInfo>> emotionIconsFuture;
  late Future<List<IconInfo>> weatherIconsFuture;
  bool _isUploading = false;

  List<int> _generateNumbers(int count) =>
      List<int>.generate(count, (i) => i + 1);

  String _getWeekdayString(int weekday) {
    const weekdays = ['?', '?', '?', '?', '?', '?', '?'];
    return weekdays[weekday - 1]; // DateTime.weekday? 1(???)?? ??
  }

  @override
  void initState() {
    super.initState();
    emotionIconsFuture = _loadIcons("emotion");
    weatherIconsFuture = _loadIcons("weather");

    _locationController.text = '?????'; // ?? ? ??
  }

  // ?? ?? ??? ??
  Future<String> _extractTextFromImage(XFile imageFile) async {
    setState(() {
      _isExtractingText = true; // ??? ?? ??
    });

    const String apiKey = 'AIzaSyB4k5Clcz2Wpm2haTwgdsQ0F2J8P9aB6_s';
    final Uri uri = Uri.parse(
        'https://vision.googleapis.com/v1/images:annotate?key=$apiKey');

    final imageBytes = await imageFile.readAsBytes();

    final requestPayload = {
      "requests": [
        {
          "image": {
            "content": base64Encode(imageBytes), // ??? Base64 ???
          },
          "features": [
            {
              "type": "TEXT_DETECTION", // ??? ?? ??
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
            ['text']; // OCR ?? ??

        return extractedText ?? '';
      } else {
        debugPrint('Google Vision API ?? ? ??: ${response.body}');

        throw Exception('Google Vision API Error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Google Vision API ?? ? ??: $e');
      return '';
    }
  }

  // ?? ?? ???
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

// ??? ?? ? ?? ????? ?? ? ???? ???? ??
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
      _isUploading = true; // ??? ?? ? ?? ??
    });

    try {
      for (int i = 0; i < selectedImages.length; i++) {
        var imageFile = selectedImages[i];
        var filePath = filePaths[i];
        var compressedFilePath = compressedFilePaths[i];

        final imageBytes = await imageFile.readAsBytes();
        final fileExt = imageFile.path.split('.').last;

        // ??? ??
        final compressedImageBytes =
            await compressImage(imageBytes, quality: 80);

        // ?? ??? ???
        await supabase.storage.from('sermon_note_photo').uploadBinary(
              filePath,
              imageBytes,
              fileOptions: FileOptions(contentType: 'image/$fileExt'),
            );

        // ??? ??? ???
        await supabase.storage
            .from('sermon_note_compressed_photo')
            .uploadBinary(
              compressedFilePath,
              compressedImageBytes,
              fileOptions: FileOptions(contentType: 'image/$fileExt'),
            );
      }

      // ??? URL ??
      final signedOriginalUrls = await supabase.storage
          .from('sermon_note_photo')
          .createSignedUrls(filePaths, 60 * 60 * 24 * 365 * 10); // 10? ??
      final signedCompressedUrls = await supabase.storage
          .from('sermon_note_compressed_photo')
          .createSignedUrls(
              compressedFilePaths, 60 * 60 * 24 * 365 * 10); // 10? ??

      setState(() {
        uploadedFilePaths = signedOriginalUrls.map((e) => e.signedUrl).toList();
        uploadedCompressedFilePaths =
            signedCompressedUrls.map((e) => e.signedUrl).toList();
      });
    } catch (e) {
      debugPrint('??? ? ?? ??: $e');
    } finally {
      setState(() {
        _isUploading = false; // ??? ?? ? ?? ??
      });
    }
  }

  Future<void> _pickImages() async {
    final pickedFiles = await ImagePicker().pickMultiImage();

    if (_currentImages.length + pickedFiles.length > 10) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('?? 10?? ???? ??? ? ????.')));
    } else {
      setState(() {
        _currentImages.addAll(pickedFiles);
      });

      // OCR ??? ??? ? Google Vision API ??
      if (_isOCREnabled && pickedFiles.isNotEmpty) {
        for (final imageFile in pickedFiles) {
          final extractedText = await _extractTextFromImage(imageFile);
          if (extractedText.isNotEmpty) {
            setState(() {
              _contentController.text += '\n$extractedText'; // ??? ??? ??
              _isExtractingText = false;
            });
          }
        }
      }
      // ??? ???? ?? ????? ??
      await _uploadImages(pickedFiles);
    }
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
        const SnackBar(content: Text('?? ??? ??????.')),
      );
    }
  }

  Future<void> _saveToSupabase() async {
    if (_preacherController.text.isEmpty ||
        _titleController.text.isEmpty ||
        _contentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('?? ??? ??????.')),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      // ?? ??? ID ????
      final user = supabase.auth.currentUser;
      if (user == null) {
        throw Exception('???? ???? ????.');
      }

      // ???? ?? ?? ??
      final userId = user.id;

      // ?? ?? ?? (YYYY-MM-DD)
      final formattedDate =
          "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}";

      // ???? ??? ??
      final response = await supabase.from('sermon_notes').insert({
        'user_id': userId, // ???? ID ??
        'sermon_date': formattedDate,
        'weekday': _getWeekdayString(_selectedDate.weekday), // ?? ?? ??
        'preacher': _preacherController.text,
        'location': _locationController.text,
        'title': _titleController.text,
        'content': _contentController.text,
        'bible_verses': _selectedBibleVerses,
        'emotion_icon': 'assets/imgs/icon/emotion/$_selectedEmotionIcon',
        'images': uploadedFilePaths, // ?? ??? ?? ??
        'compressed_images': uploadedCompressedFilePaths, // ?? ??? ?? ??
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('?? ??? ???????.')),
      );

      Navigator.pop(context, true); // ?? ?? ? true ??

      // ?? ? ???
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

  // ?? ?? ??? ??
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
                          _selectedEmotionIcon = null; // ?? ??
                        } else {
                          _selectedEmotionIcon = iconInfo.fileName;
                        }
                      } else {
                        if (_selectedWeatherIcon == iconInfo.fileName) {
                          _selectedWeatherIcon = null; // ?? ??
                        } else {
                          _selectedWeatherIcon = iconInfo.fileName;
                        }
                      }
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18.0),
                      color:
                          isSelected ? primary : Colors.white, // ??? ?? ??? ??
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

  // ?????? ???? ???? ??
  Future<void> _deleteUploadedImages() async {
    for (String filePath in uploadedFilePaths) {
      try {
        await supabase.storage.from('sermon_note_photo').remove([filePath]);
        debugPrint('?? ??? ?? ??: $filePath');
      } catch (e) {
        debugPrint('?? ??? ?? ? ?? ??: $filePath, $e');
      }
    }
    for (String compressedFilePath in uploadedCompressedFilePaths) {
      try {
        await supabase.storage
            .from('sermon_note_compressed_photo')
            .remove([compressedFilePath]);
        debugPrint('?? ??? ?? ??: $compressedFilePath');
      } catch (e) {
        debugPrint('?? ??? ?? ? ?? ??: $compressedFilePath, $e');
      }
    }
  }

  // ??? ?? ?? ?? ? ???? ???? ???? ??
  Future<void> _cancelUploadAndDeleteImages() async {
    // ???? ?? ???, ???? ???? ??
    if (_isUploading) {
      debugPrint('???? ?? ????. ?? ???? ???? ?????.');
      await _deleteUploadedImages();
    } else {
      debugPrint('?? ???? ?? ???? ?????.');
    }
  }

  @override
  void dispose() {
    if (_currentImages.isNotEmpty) {
      // '??' ??? ??? ?? ???? ??? ?? ???? ???? ???? ??
      _cancelUploadAndDeleteImages();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ??? ?? ??
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
                      child: buildLocalImage(
                        _currentImages[index],
                        fit: BoxFit.cover,
                        width: 100,
                        height: 100,
                      ),
                    ),
                    childWhenDragging: Container(),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: buildLocalImage(
                              _currentImages[index],
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),

                        // ?? ??
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
                          color: _isOCREnabled ? primary : blueGrey,
                          width: _isOCREnabled ? 3 : 1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: _isOCREnabled
                        ? const Column(
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
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add, color: Colors.black, size: 20),
                              SizedBox(
                                height: 1,
                              ),
                              Text(
                                '??',
                                style: TextStyle(
                                  color: blueGrey,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          )),
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
        toolbarHeight: 60,
        backgroundColor: Color(0xffF1F2FF),
        title: const Text(
          '????',
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
                onTap: (_isUploading || _isExtractingText)
                    ? null
                    : _saveToSupabase,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(19),
                    color: (_isUploading || _isExtractingText)
                        ? bg_30
                        : primary, // ???? ?? ??
                  ),
                  child: Center(
                    child: Text(
                      (_isUploading || _isExtractingText) ? '...' : '??',
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
        onTap: () => FocusScope.of(context).unfocus(), // ?? ??? ???? ???? ??
        child: Scrollbar(
          thumbVisibility: true,
          thickness: 6.0,
          radius: const Radius.circular(4.0),
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
                                      "${_selectedDate.year}? ${_selectedDate.month}? ${_selectedDate.day}? (${_getWeekdayString(_selectedDate.weekday)})",
                                      style: const TextStyle(
                                          fontSize: 15,
                                          color: Colors.black,
                                          fontWeight: FontWeight.w500),
                                    )
                                  : const Text(
                                      "?? ??",
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
                _iconSelector("emotion", "??", emotionIconsFuture),

                const Divider(
                  color: bg_30,
                ),

                // ??&??? ??
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
                            labelText: '??',
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
                          labelText: '???',
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
                // ??? ??? ??
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '?? ???',
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
                      children:
                          _selectedBibleVerses.asMap().entries.map((entry) {
                        final index = entry.key + 1; // 1?? ???? ??
                        final verse = entry.value;

                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '$index. ${verse['book']} ${verse['chapter']}? ${verse['verses']}?',
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

                // ??? ??

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
                        dropdownColor: Colors.amber[100],
                        value: _selectedBook,
                        style: TextStyle(
                            color: Colors.black, fontWeight: FontWeight.w500),
                        hint: const Text(
                          '??? ??',
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
                                BorderRadius.circular(5.0), // ??? ??? ??
                            borderSide: BorderSide.none, // ??? ? ??
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4.0),
                    if (_selectedBook != null)
                      SizedBox(
                        width: (MediaQuery.of(context).size.width - 16 - 4) / 4,
                        child: DropdownButtonFormField<int>(
                          dropdownColor: Colors.green[100],
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
                                  BorderRadius.circular(5.0), // ??? ??? ??
                              borderSide: BorderSide.none, // ??? ? ??
                            ),
                          ),
                          value: _selectedChapter,
                          hint: const Text(
                            '?',
                            style: TextStyle(
                                color: blueGrey, fontWeight: FontWeight.w500),
                          ),
                          items: _generateNumbers(50).map((chapter) {
                            return DropdownMenuItem(
                              value: chapter,
                              child: Text('$chapter?'),
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
                          hint: const Text('?? ?'),
                          items: _generateNumbers(176).map((verse) {
                            return DropdownMenuItem(
                              value: verse,
                              child: Text('$verse?'),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedStartVerse = value;
                              _selectedEndVerse = null;
                            });
                            if (value != null) {
                              FocusScope.of(context).nextFocus(); // ?? ??? ??
                            }
                          },
                          dropdownColor: Colors.pink[100],
                          decoration: InputDecoration(
                            fillColor: paleGrey,
                            filled: true,
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(5.0), // ??? ??? ??
                              borderSide: BorderSide.none, // ??? ? ??
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
                          hint: const Text('? ?'),
                          items: _generateNumbers(176).map((verse) {
                            return DropdownMenuItem(
                              value: verse,
                              child: Text('$verse?'),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedEndVerse = value;
                            });
                            FocusScope.of(context)
                                .nextFocus(); // ? ? ?? ? ?? ??? ??
                          },
                          dropdownColor: Colors.blue[100],
                          decoration: InputDecoration(
                            fillColor: paleGrey,
                            filled: true,
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(5.0), // ??? ??? ??
                              borderSide: BorderSide.none, // ??? ? ??
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
                        '?? ??',
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
                      hintText: '?? ??? ??????.',
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
                        '?? ??',
                        style: TextStyle(
                          color: bg_90,
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      Text(
                        '${_contentController.text.length}/2000',
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
                    minLines: 2,
                    maxLines: null, // TextField? ??? ??? ?? ??
                    maxLength: 2000,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(2000),
                    ],
                    cursorColor: primary,
                    decoration: InputDecoration(
                      hintText: _isExtractingText
                          ? '??? ???..'
                          : '?? ??? ?????.', // ??? ?? ??? ??
                      hintStyle: TextStyle(
                        color: _isExtractingText ? primary : bg_70,
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                      ),
                      border: InputBorder.none,
                      counterText: '',
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                buildImageGrid(),
                const SizedBox(height: 36.0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
