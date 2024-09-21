// 첫 번째 FAB누르면 나오는 게시글 작성페이지

import 'dart:io';
import 'dart:math';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:wact/common/const/color.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wact/common/init.dart';
import 'package:wact/pages/home/home_page.dart';

class PostAddPage extends StatefulWidget {
  final List<XFile>? images;
  final void Function(List<String>) onUpload;
  final GlobalKey<HomePageState> homePageKey;

  const PostAddPage(
      {Key? key,
      this.images,
      required this.onUpload,
      required this.homePageKey})
      : super(key: key);

  @override
  _PostAddPageState createState() => _PostAddPageState();
}

class _PostAddPageState extends State<PostAddPage> {
  final _titleEditingController = TextEditingController();
  final _contentEditingController = TextEditingController();
  List<XFile> _currentImages = [];
  bool _isLoading = false;
  bool _isUploading = false; // 업로드 상태 추적 플래그 추가
  List<String> uploadedFilePaths = [];
  List<String> uploadedCompressedFilePaths = [];

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
        await supabase.storage.from('post_photo').uploadBinary(
              filePath,
              imageBytes,
              fileOptions: FileOptions(contentType: 'image/$fileExt'),
            );
        uploadedFilePaths.add(filePath); // 업로드된 파일 경로 저장

        // 압축본 이미지 업로드
        await supabase.storage.from('post_compressed_photo').uploadBinary(
              compressedFilePath,
              compressedImageBytes,
              fileOptions: FileOptions(contentType: 'image/$fileExt'),
            );
        uploadedCompressedFilePaths.add(compressedFilePath); // 압축본 경로 저장
      }
    } catch (e) {
      debugPrint('업로드 중 오류 발생: $e');
    } finally {
      setState(() {
        _isUploading = false; // 업로드 종료 시 상태 변경
      });
    }
  }

  // 스토리지에서 이미지를 삭제하는 함수
  Future<void> _deleteUploadedImages() async {
    for (String filePath in uploadedFilePaths) {
      try {
        await supabase.storage.from('post_photo').remove([filePath]);
        debugPrint('원본 이미지 삭제 완료: $filePath');
      } catch (e) {
        debugPrint('원본 이미지 삭제 중 오류 발생: $filePath, $e');
      }
    }
    for (String compressedFilePath in uploadedCompressedFilePaths) {
      try {
        await supabase.storage
            .from('post_compressed_photo')
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

// 게시글 업로드 (이미지 업로드 완료 후 게시글 업로드)
  Future<bool> _uploadPost(List<XFile> images) async {
    if (_isLoading) return false;

    try {
      setState(() => _isLoading = true);

      // AlertDialog로 로딩 상태를 사용자에게 표시
      showDialog(
        context: context,
        barrierDismissible: false, // 사용자가 다이얼로그 외부를 터치해도 닫히지 않도록 설정
        builder: (BuildContext context) {
          return const AlertDialog(
            backgroundColor: Colors.black,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '게시글을 저장중입니다...',
                  style: TextStyle(color: Colors.white),
                )
              ],
            ),
          );
        },
      );

      // 모든 이미지가 업로드될 때까지 대기
      await Future.doWhile(() async {
        await Future.delayed(const Duration(milliseconds: 100));
        return uploadedFilePaths.length != _currentImages.length ||
            uploadedCompressedFilePaths.length != _currentImages.length;
      });

      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('User not found');

      List<String> imageUrls = [];
      List<String> compressedImageUrls = [];

      // 이미지가 있으면 이미지의 경로로 서명된 URL 생성
      if (uploadedFilePaths.isNotEmpty) {
        // 원본 이미지의 서명된 URL 생성
        List<SignedUrl> signedUrls = await supabase.storage
            .from('post_photo')
            .createSignedUrls(uploadedFilePaths, 60 * 60 * 24 * 365 * 10);

        imageUrls.addAll(signedUrls.map((e) => e.signedUrl));

        // 압축 이미지의 서명된 URL 생성
        List<SignedUrl> compressedSignedUrls = await supabase.storage
            .from('post_compressed_photo')
            .createSignedUrls(
                uploadedCompressedFilePaths, 60 * 60 * 24 * 365 * 10);

        compressedImageUrls
            .addAll(compressedSignedUrls.map((e) => e.signedUrl));
      }

      final profileResponse = await supabase
          .from('profiles')
          .select('username')
          .match({'id': user.id}).single();

      final username = profileResponse['username'] as String?;

      // 게시글 데이터 DB에 저장
      await supabase.from('posts').insert({
        'author_id': user.id,
        'author': username,
        'title': _titleEditingController.text,
        'content': _contentEditingController.text,
        'image_urls': imageUrls,
        'compressed_image_urls': compressedImageUrls,
      });

      widget.onUpload(imageUrls);

      return true;
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.pop(context); // AlertDialog 닫기
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
    if (_currentImages.isNotEmpty) {
      // '게시' 버튼을 누르지 않고 페이지를 벗어날 경우 업로드를 중단하고 이미지를 삭제
      _cancelUploadAndDeleteImages();
    }
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

    return WillPopScope(
      onWillPop: () async {
        if (_currentImages.isNotEmpty) {
          // 뒤로가기 누르면 업로드 중지 및 이미지 삭제
          await _cancelUploadAndDeleteImages();
        }
        return true; // true를 반환하여 실제로 뒤로가기를 수행
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          surfaceTintColor: Colors.white,
          iconTheme:
              const IconThemeData(color: Color.fromARGB(255, 42, 31, 31)),
          backgroundColor: Colors.white,
          elevation: 0,
          leading: Transform.translate(
            offset: const Offset(12, 0.0),
            child: IconButton(
              iconSize: 34,
              icon: Image.asset('assets/imgs/icon/btn_back_grey@3x.png'),
              onPressed: () async {
                if (_currentImages.isNotEmpty) {
                  // AppBar 뒤로가기 버튼 클릭 시 이미지 삭제
                  await _deleteUploadedImages();
                }
                Navigator.pop(context); // 페이지에서 벗어남
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
                      debugPrint('게시글 업로드 버튼 클릭');
                      // await _uploadPost().then((_) {
                      //   debugPrint('게시글 업로드 성공');
                      //   // context.findAncestorStateOfType<HomePageState>()를 사용하는 대신 전달된 GlobalKey를 활용합니다.
                      //   final homePageState = widget.homePageKey.currentState;
                      //   debugPrint('homePageState: $homePageState');
                      //   // if (homePageState != null) {
                      //   homePageState?.refreshPostPage();
                      //   debugPrint('PostPage 새로고침 완료');
                      //   // }
                      //   Navigator.pop(context, true);
                      // });
                      bool result = await _uploadPost(_currentImages);
                      Navigator.pop(
                          context, result); // 여기서 새로고침 로직을 제거하고, 결과만 반환합니다.
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          backgroundColor: Colors.black,
                          content: Text(
                            '내용을 작성해주세요.',
                            style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Colors.white),
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
                          maxLines: 5,
                          maxLength: 150,
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
      ),
    );
  }
}
