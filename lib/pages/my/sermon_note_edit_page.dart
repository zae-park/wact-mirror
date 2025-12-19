import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wact/common/const/bible_books.dart';
import 'package:wact/common/const/color.dart';
import 'package:wact/models/shared/icon_info.dart';

class SermonNoteEditPage extends StatefulWidget {
  final Map<String, dynamic> post;
  final Function refreshCallback;

  const SermonNoteEditPage({
    Key? key,
    required this.post,
    required this.refreshCallback,
  }) : super(key: key);

  @override
  _SermonNoteEditPageState createState() => _SermonNoteEditPageState();
}

class _SermonNoteEditPageState extends State<SermonNoteEditPage> {
  final List<Map<String, dynamic>> _selectedBibleVerses = [];

  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late TextEditingController _preacherController;
  late TextEditingController _locationController;

  late DateTime _selectedDate;
  String? _selectedEmotionIcon;
  bool _isSaving = false;

  String? _selectedBook;
  int? _selectedChapter;
  int? _selectedStartVerse;
  int? _selectedEndVerse;

  List<int> _generateNumbers(int count) =>
      List<int>.generate(count, (i) => i + 1);

  String _getWeekdayString(int weekday) {
    const weekdays = ['?', '?', '?', '?', '?', '?', '?'];
    return weekdays[weekday - 1]; // DateTime.weekday? 1(???)?? ??
  }

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.post['title']);
    _contentController = TextEditingController(text: widget.post['content']);
    _preacherController = TextEditingController(text: widget.post['preacher']);
    _locationController = TextEditingController(text: widget.post['location']);
    _selectedDate = DateTime.parse(widget.post['created_at']);

    _selectedEmotionIcon = widget.post['emotion_icon']?.split('/').last;

    // bible_verses? ???? ??
    final bibleVerses = widget.post['bible_verses'] ?? [];
    if (bibleVerses is List<dynamic>) {
      _selectedBibleVerses.addAll(
        bibleVerses.whereType<Map<String, dynamic>>(),
      );
    }
  }

  Future<void> _selectDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      locale: const Locale('ko', 'KR'),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: primary,
            colorScheme: const ColorScheme.light(primary: primary),
            buttonTheme: const ButtonThemeData(
              textTheme: ButtonTextTheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
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

  Future<void> _saveChanges() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final supabase = Supabase.instance.client;

      // ??? URL ??
      List<String> signedImageUrls = [];
      List<String> signedCompressedImageUrls = [];

      // ??? ????
      await supabase.from('sermon_notes').update({
        'title': _titleController.text,
        'content': _contentController.text,
        'preacher': _preacherController.text,
        'location': _locationController.text,
        'created_at': _selectedDate.toIso8601String(),
        'emotion_icon': _selectedEmotionIcon != null
            ? 'assets/imgs/icon/emotion/$_selectedEmotionIcon'
            : null,
        'bible_verses': _selectedBibleVerses,
        'images': signedImageUrls, // ??? ?? ??? URL ??
        'compressed_images': signedCompressedImageUrls, // ??? ?? ??? URL ??
      }).eq('id', widget.post['id']);

      // ??? ???? ??
      final updatedPost = {
        ...widget.post,
        'title': _titleController.text,
        'content': _contentController.text,
        'preacher': _preacherController.text,
        'location': _locationController.text,
        'created_at': _selectedDate.toIso8601String(),
        'emotion_icon': _selectedEmotionIcon != null
            ? 'assets/imgs/icon/emotion/$_selectedEmotionIcon'
            : null,
        'bible_verses': _selectedBibleVerses,
      };

      debugPrint('updatedPost: $updatedPost');

      Navigator.pop(context, updatedPost);
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('?? ? ??? ??????. ?? ??????.')),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _preacherController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<dynamic> imageUrls = widget.post['compressed_images'] ?? [];
    if (widget.post['compressed_images'] is String) {
      imageUrls = json.decode(widget.post['compressed_images']);
    } else if (widget.post['compressed_images'] is List) {
      imageUrls = widget.post['compressed_images'];
    }

    Widget buildImageGrid() {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          mainAxisSpacing: 8.0,
          crossAxisSpacing: 8.0,
        ),
        itemCount: imageUrls.length,
        itemBuilder: (BuildContext context, int index) {
          return GestureDetector(
            onTap: () => showDialog(
              context: context,
              builder: (context) => Dialog(
                child: Image.network(imageUrls[index]),
              ),
            ),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.network(
                    imageUrls[index],
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  right: -8,
                  top: -8,
                  child: IconButton(
                    iconSize: 16,
                    onPressed: () {
                      setState(() {
                        imageUrls.removeAt(index);
                      });
                    },
                    icon: const FaIcon(
                      FontAwesomeIcons.circleMinus,
                      color: Colors.red,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        toolbarHeight: 60,
        backgroundColor: const Color(0xffF1F2FF),
        title: const Text(
          '???? ??',
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
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 9, 20, 9),
            child: GestureDetector(
              onTap: _isSaving ? null : _saveChanges,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(19),
                  color: _isSaving ? bg_70 : primary,
                ),
                width: 46,
                height: 37,
                child: const Center(
                  child: Text(
                    '??',
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
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ?? ??

              InkWell(
                onTap: _selectDate,
                child: Row(
                  children: [
                    Text(
                      DateFormat('yyyy? MM? dd? (E)', 'ko_KR')
                          .format(_selectedDate),
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.black,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Image.asset(
                      'assets/imgs/icon/icon_calendar.png',
                      width: 20,
                      height: 20,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ?? ??? ??
              const Text(
                '?? ???',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: bg_90,
                ),
              ),
              const SizedBox(height: 8),
              FutureBuilder<List<IconInfo>>(
                future: _loadIcons("emotion"), // ?? ??? ?? ??? ??
                builder: (BuildContext context,
                    AsyncSnapshot<List<IconInfo>> snapshot) {
                  if (snapshot.connectionState == ConnectionState.done &&
                      snapshot.hasData) {
                    return SizedBox(
                      height: 60,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: snapshot.data!.length,
                        itemBuilder: (BuildContext context, int index) {
                          final iconInfo = snapshot.data![index];
                          // _selectedEmotionIcon? iconInfo.fileName ??
                          final isSelected =
                              _selectedEmotionIcon == iconInfo.fileName;

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedEmotionIcon = isSelected
                                    ? null
                                    : iconInfo.fileName; // ?? ?? ??
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.only(right: 12),
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18.0),
                                color: isSelected
                                    ? primary
                                    : Colors.white, // ?? ? ?? ??
                              ),
                              child: Column(
                                children: [
                                  Image.asset(
                                    "assets/imgs/icon/emotion/${iconInfo.fileName}",
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
                                          ? Color(int.parse(
                                              '0xFF${iconInfo.color}'))
                                          : bg_70,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  } else {
                    return const Center(child: CircularProgressIndicator());
                  }
                },
              ),
              const Divider(color: bg_30),

              // ??&??? ??
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(
                    width: (MediaQuery.of(context).size.width - 50) / 2,
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
                    width: (MediaQuery.of(context).size.width - 50) / 2,
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
                    children: _selectedBibleVerses.asMap().entries.map((entry) {
                      final index = entry.key + 1; // 1?? ???? ??
                      final verse = entry.value;

                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '$index. ${verse['book']} ${verse['chapter']}? ${verse['verses']}?',
                            style: const TextStyle(
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
                                _selectedBibleVerses.removeAt(entry.key);
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
                      dropdownColor: Colors.pink[50],
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
                        dropdownColor: Colors.amber[100],
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
                        dropdownColor: Colors.green[100],
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
                  minLines: 2,
                  maxLines: 50,
                  maxLength: 1000,
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(1000),
                  ],
                  cursorColor: primary,
                  decoration: const InputDecoration(
                    hintText: '?? ??? ?????.',
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
              const SizedBox(height: 20),

              buildImageGrid(),
              const SizedBox(height: 36.0),
            ],
          ),
        ),
      ),
    );
  }

  Future<List<String>> _loadEmotionIcons() async {
    return ['happy.png', 'sad.png', 'neutral.png'];
  }

  InputDecoration _inputDecoration(String hintText) => InputDecoration(
        hintText: hintText,
        border: const OutlineInputBorder(),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: primary),
        ),
      );

  static const TextStyle _labelStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: bg_90,
  );
}
