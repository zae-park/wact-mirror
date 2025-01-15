import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:wact/common/const/bible_books.dart';
import 'package:wact/common/init.dart';

class SermonNoteAddPage extends StatefulWidget {
  @override
  _SermonNoteAddPageState createState() => _SermonNoteAddPageState();
}

class _SermonNoteAddPageState extends State<SermonNoteAddPage> {
  final List<Map<String, dynamic>> _selectedBibleVerses = [];
  final TextEditingController _preacherController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  String? _selectedBook;
  int? _selectedChapter;
  int? _selectedStartVerse;
  int? _selectedEndVerse;
  List<File> _selectedImages = [];
  bool _isUploading = false;

  List<int> _generateNumbers(int count) =>
      List<int>.generate(count, (i) => i + 1);

  Future<void> _pickImages() async {
    final pickedFiles = await ImagePicker().pickMultiImage();
    if (pickedFiles != null &&
        pickedFiles.length + _selectedImages.length > 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('최대 10장의 이미지만 선택할 수 있습니다.')),
      );
      return;
    }

    if (pickedFiles != null) {
      setState(() {
        _selectedImages.addAll(pickedFiles.map((file) => File(file.path)));
      });
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
    if (_preacherController.text.isEmpty || _contentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('모든 필수 항목을 작성해주세요.')),
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

      // 이미지 압축 및 업로드 처리
      List<String> imageUrls = [];
      for (var image in _selectedImages) {
        final compressedImage = await _compressImage(image);

        // Supabase 스토리지에 사용자별 폴더에 이미지 업로드
        final fileName =
            'images/${userId}/${DateTime.now().millisecondsSinceEpoch}.jpg';
        final uploadResponse = await supabase.storage
            .from('sermon_note_photo')
            .upload(fileName, compressedImage);

        if (uploadResponse.isEmpty) {
          throw Exception('이미지 업로드 실패: $uploadResponse');
        }

        final publicUrl =
            supabase.storage.from('sermon_note_photo').getPublicUrl(fileName);
        imageUrls.add(publicUrl);
      }

      // 테이블에 데이터 삽입
      final response = await supabase.from('sermon_notes').insert({
        'user_id': userId, // 작성자의 ID 추가
        'preacher': _preacherController.text,
        'location': _locationController.text,
        'content': _contentController.text,
        'bible_verses': _selectedBibleVerses,
        'images': imageUrls,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('설교 노트가 저장되었습니다.')),
      );

      Navigator.pop(context);

      // 성공 후 초기화
      _preacherController.clear();
      _locationController.clear();
      _contentController.clear();
      setState(() {
        _selectedBibleVerses.clear();
        _selectedImages.clear();
      });
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('설교노트 작성'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 설교자 입력
            TextFormField(
              controller: _preacherController,
              decoration: const InputDecoration(
                labelText: '설교자',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16.0),

            // 장소 입력
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: '장소',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16.0),

            // 성경절 선택
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedBook,
                    hint: const Text('성경책 선택'),
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
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: '성경책',
                    ),
                  ),
                ),
                const SizedBox(width: 8.0),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _addSelectedBibleVerse,
                ),
              ],
            ),

            const SizedBox(height: 16.0),

            if (_selectedBook != null)
              DropdownButtonFormField<int>(
                value: _selectedChapter,
                hint: const Text('장 선택'),
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
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: '장',
                ),
              ),

            const SizedBox(height: 16.0),

            if (_selectedChapter != null)
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _selectedStartVerse,
                      hint: const Text('시작 절 선택'),
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
                      },
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: '시작 절',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _selectedEndVerse,
                      hint: const Text('끝 절 선택 (선택)'),
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
                      },
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: '끝 절',
                      ),
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 16.0),

            // 사진 추가
            ElevatedButton.icon(
              onPressed: _pickImages,
              icon: const Icon(Icons.add_photo_alternate),
              label: const Text('사진 추가'),
            ),

            if (_selectedImages.isNotEmpty)
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: _selectedImages.map((image) {
                  return Stack(
                    alignment: Alignment.topRight,
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8.0),
                          image: DecorationImage(
                            image: FileImage(image),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          setState(() {
                            _selectedImages.remove(image);
                          });
                        },
                      ),
                    ],
                  );
                }).toList(),
              ),

            const SizedBox(height: 16.0),

            // 본문 추가
            TextFormField(
              controller: _contentController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: '본문 추가',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16.0),

            ElevatedButton(
              onPressed: _isUploading ? null : _saveToSupabase,
              child: _isUploading
                  ? const CircularProgressIndicator()
                  : const Text('작성 완료'),
            ),

            const SizedBox(height: 16.0),

            if (_selectedBibleVerses.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _selectedBibleVerses.map((verse) {
                  return ListTile(
                    title: Text(
                        '${verse['book']} ${verse['chapter']}장 ${verse['verses']}절'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        setState(() {
                          _selectedBibleVerses.remove(verse);
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}
