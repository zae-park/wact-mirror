// 첫 번째 FAB누르면 나오는 게시글 작성페이지

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:wact/common/const/color.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wact/main.dart';

class AddSermonNotePage extends StatefulWidget {
  final XFile? image;
  final void Function(String) onUpload;

  const AddSermonNotePage({Key? key, this.image, required this.onUpload})
      : super(key: key);

  @override
  _AddSermonNotePageState createState() => _AddSermonNotePageState();
}

class _AddSermonNotePageState extends State<AddSermonNotePage> {
  final _titleEditingController = TextEditingController();
  final _contentEditingController = TextEditingController();
  XFile? _currentImage;
  String? _imageUrl;
  bool _isLoading = false;
  String? _compressedimageUrl;
  final TextRecognizer _textRecognizer =
      TextRecognizer(script: TextRecognitionScript.korean);

  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _currentImage = pickedFile;
      });
      // 이미지를 선택한 후 텍스트 추출 함수 호출
      await _extractTextFromImage(pickedFile);
    }
  }

  Future<void> _extractTextFromImage(XFile image) async {
    try {
      final inputImage = InputImage.fromFilePath(image.path);
      final RecognizedText recognizedText =
          await _textRecognizer.processImage(inputImage);

      setState(() {
        _contentEditingController.text = recognizedText.text;
      });
      _textRecognizer.close();
    } catch (e) {
      // 에러 로깅
      print('텍스트 추출 오류 - Error extracting text from image: $e');
    }
  }

  // 이미지 없이 업로드 가능
  Future<void> _uploadPost() async {
    if (_isLoading) return;

    try {
      setState(() => _isLoading = true);

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const AlertDialog(
            backgroundColor: bg_50,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [Text('설교노트를 저장중입니다.')],
            ),
          );
        },
      );

      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('User not found');

      // 이미지를 바이트 배열로 변환
      final imageBytes = await _currentImage?.readAsBytes();
      // 압축된 이미지 파일
      final compressedImageBytes = await FlutterImageCompress.compressWithList(
        imageBytes!,
        quality: 70,
      );

      final fileExt = _currentImage?.path.split('.').last;
      final fileName = '${DateTime.now().toIso8601String()}.$fileExt';
      final compressedfileName =
          '${DateTime.now().toIso8601String()})compressed.$fileExt';
      final filePath = fileName;
      final compressedfilePath = compressedfileName;

      // 파일 업로드
      await supabase.storage.from('post_photo').uploadBinary(
          filePath, imageBytes,
          fileOptions: FileOptions(contentType: _currentImage?.mimeType));

      // 압축 파일 업로드
      await supabase.storage.from('post_compressed_photo').uploadBinary(
          compressedfilePath, compressedImageBytes,
          fileOptions: FileOptions(contentType: _currentImage?.mimeType));

      final imageUrlResponse = await supabase.storage
          .from('post_photo')
          .createSignedUrl(filePath, 60 * 60 * 24 * 365 * 10);

      final compressedimageUrlResponse = await supabase.storage
          .from('post_compressed_photo')
          .createSignedUrl(compressedfilePath, 60 * 60 * 24 * 365 * 10);

      _imageUrl = imageUrlResponse;
      _compressedimageUrl = compressedimageUrlResponse;
      widget.onUpload(imageUrlResponse);

      final profileResponse = await supabase
          .from('profiles')
          .select('username')
          .match({'id': user.id}).single();

      print('유저: $profileResponse');

      final username = profileResponse['username'] as String?;
      print('유저 이름: $username');

      await supabase.from('posts').insert({
        'author_id': user.id,
        'author': username,
        'title': _titleEditingController.text,
        'content': _contentEditingController.text,
        'image_urls': [_imageUrl],
        'compressed_image_urls': [_compressedimageUrl],
      });

      if (mounted) {
        Navigator.pop(context, true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.image != null) {
      _currentImage = widget.image;
      _extractTextFromImage(_currentImage!);
    }
    _titleEditingController.addListener(() {
      setState(() {});
    });
    _contentEditingController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _titleEditingController.dispose();
    _contentEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget imageDisplayWidget;

    if (_currentImage != null) {
      // 플랫폼이 웹이 아닐 때, 즉 모바일 앱일 때
      if (!kIsWeb) {
        imageDisplayWidget = GestureDetector(
          onTap: _pickImage,
          child: Image.file(
            File(_currentImage!.path),
            fit: BoxFit.contain,
          ),
        );
      } else {
        // 플랫폼이 웹일 때
// 플랫폼이 웹일 때
        imageDisplayWidget = GestureDetector(
          onTap: _pickImage,
          child: Image.memory(
            File(_currentImage!.path).readAsBytesSync(), // 수정된 부분
            fit: BoxFit.contain,
          ),
        );
      }
    } else {
      // _currentImage가 null일 때의 placeholder 처리
      imageDisplayWidget = GestureDetector(
        onTap: _pickImage,
        child: Container(
          width: MediaQuery.of(context).size.width,
          height: 200, // placeholder의 높이
          color: Colors.grey[300],
          child: const Icon(Icons.image, size: 100),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        surfaceTintColor: Colors.white,
        iconTheme: const IconThemeData(color: Color.fromARGB(255, 42, 31, 31)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Transform.translate(
          offset: const Offset(12, 0.0),
          child: IconButton(
            iconSize: 34,
            icon: Image.asset('assets/imgs/icon/btn_back_grey@3x.png'),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
        title: const Text(
          '설교노트',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 9, 20, 9),
            child: SizedBox(
              width: 52,
              child: GestureDetector(
                onTap: () async {
                  if (_titleEditingController.text.isNotEmpty ||
                      _contentEditingController.text.isNotEmpty) {
                    await _uploadPost().then((_) {
                      Navigator.pop(context);
                    });
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        backgroundColor: Colors.black,
                        content: Text(
                          '내용을 작성해주세요.',
                          style: TextStyle(
                              fontWeight: FontWeight.w500, color: Colors.white),
                        ),
                      ),
                    );
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(19),
                      color: Colors.black),
                  child: const Center(
                    child: Text(
                      '작성',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            imageDisplayWidget, // 제목과 내용 입력
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: SizedBox(
                height: (MediaQuery.of(context).size.height * 0.65 - 56),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                          '${_contentEditingController.text.length}/150',
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
                        maxLines: 15,
                        maxLength: 500,
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
