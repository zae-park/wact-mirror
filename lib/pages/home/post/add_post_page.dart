// 첫 번째 FAB누르면 나오는 게시글 작성페이지

import 'dart:io';
import 'dart:math';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:wact/common/const/color.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wact/main.dart';

class AddPostPage extends StatefulWidget {
  final List<XFile>? images;
  final void Function(List<String>) onUpload;

  const AddPostPage({Key? key, this.images, required this.onUpload})
      : super(key: key);

  @override
  _AddPostPageState createState() => _AddPostPageState();
}

class _AddPostPageState extends State<AddPostPage> {
  final _titleEditingController = TextEditingController();
  final _contentEditingController = TextEditingController();
  List<XFile> _currentImages = [];
  bool _isLoading = false;

  Future<void> _pickImages() async {
    final pickedFiles = await ImagePicker().pickMultiImage();

    // 현재 이미지 수와 새로 선택된 이미지 수의 합이 6을 초과하는지 확인
    if (_currentImages.length + pickedFiles.length > 6) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('최대 6장의 이미지만 선택할 수 있습니다.')));
    } else {
      setState(() {
        _currentImages.addAll(pickedFiles);
      });
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
              children: [Text('게시글을 저장중입니다.')],
            ),
          );
        },
      );

      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('User not found');

      List<String> imageUrls = [];
      // 압축된 이미지의 URL 리스트
      List<String> compressedImageUrls = [];

      // 이미지가 있을 경우에만 업로드 로직 실행
      if (_currentImages.isNotEmpty) {
        // 파일 경로 리스트 생성
        List<String> filePaths = _currentImages.map((imageFile) {
          final fileExt = imageFile.path.split('.').last;
          final fileName = '${DateTime.now().toIso8601String()}.$fileExt';
          return '${user.id}/$fileName';
        }).toList();

        // 압축된 이미지의 경로 리스트 생성
        List<String> compressedFilePaths = _currentImages.map((imageFile) {
          final fileExt = imageFile.path.split('.').last;
          final fileName =
              '${DateTime.now().toIso8601String()}_compressed.$fileExt';
          return '${user.id}/$fileName';
        }).toList();

        // 이미지 업로드
        for (int i = 0; i < _currentImages.length; i++) {
          var imageFile = _currentImages[i];
          var filePath = filePaths[i];
          var compressedFilePath = compressedFilePaths[i];

          final imageBytes = await imageFile.readAsBytes();
          final fileExt = imageFile.path.split('.').last;

          // 이미지 압축
          final compressedImageBytes =
              await FlutterImageCompress.compressWithList(
            imageBytes,
            quality: 80, // 70% 품질로 압축
          );

          await supabase.storage.from('post_photo').uploadBinary(
              filePath, imageBytes,
              fileOptions: FileOptions(contentType: 'image/$fileExt'));

          // 압축된 이미지 업로드
          await supabase.storage.from('post_compressed_photo').uploadBinary(
              compressedFilePath, compressedImageBytes,
              fileOptions:
                  FileOptions(contentType: 'compressedImage/$fileExt'));
        }

        // 이미지 업로드 후 서명된 URL 생성
        List<SignedUrl> signedUrls = await supabase.storage
            .from('post_photo')
            .createSignedUrls(filePaths, 60 * 60 * 24 * 365 * 10);

        // 서명된 URL 추출 및 저장
        imageUrls.addAll(signedUrls.map((e) => e.signedUrl));

        // 압축된 이미지의 서명된 URL 생성
        List<SignedUrl> compressedSignedUrls = await supabase.storage
            .from('post_compressed_photo')
            .createSignedUrls(compressedFilePaths, 60 * 60 * 24 * 365 * 10);

        compressedImageUrls
            .addAll(compressedSignedUrls.map((e) => e.signedUrl));
      }

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
        'image_urls': imageUrls,
        'compressed_image_urls': compressedImageUrls,
      });

      widget.onUpload(imageUrls);

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
    if (widget.images != null) {
      _currentImages = widget.images!;
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
    // 이미지 표시 부분
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
          itemCount: min(_currentImages.length + 1, 6),
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
            } else if (_currentImages.length < 6) {
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
          '글쓰기',
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
                      '게시',
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
            buildImageGrid(),

            // 제목과 내용 입력
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
                          '${_contentEditingController.text.length}/120',
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
                        maxLines: 5,
                        maxLength: 120,
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
