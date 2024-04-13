import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wact/common/const/color.dart';
import 'package:wact/main.dart';

class PostEditPage extends StatefulWidget {
  final Map<String, dynamic> post;
  final void Function(String) onUpload;
  final Function() onUpdateSuccess;

  const PostEditPage(
      {Key? key,
      required this.onUpload,
      required this.post,
      required this.onUpdateSuccess})
      : super(key: key);

  @override
  State<PostEditPage> createState() => _PostEditPageState();
}

class _PostEditPageState extends State<PostEditPage> {
  late TextEditingController _titleEditingController;
  late TextEditingController _contentEditingController;
  late List<XFile> images;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    _titleEditingController = TextEditingController(text: widget.post['title']);
    _contentEditingController =
        TextEditingController(text: widget.post['content']);

    var imageUrls = widget.post['compressed_image_urls'];
    debugPrint('테스트 중인 JSON 문자열: $imageUrls'); // JSON 데이터 출력

    try {
      if (imageUrls is String) {
        // JSON 문자열을 파싱하여 이미지 URL 리스트로 변환
        images = (jsonDecode(imageUrls) as List<dynamic>)
            .map((item) => XFile(item as String))
            .toList();
        debugPrint('파싱된 이미지 리스트: $images');
      } else if (imageUrls is List<dynamic>) {
        images = imageUrls.map((item) => XFile(item as String)).toList();
        debugPrint('이미 리스트 타입인 경우 처리된 이미지 리스트: $images');
      } else {
        images = [];
        debugPrint('예상치 못한 데이터 타입으로 인한 빈 이미지 리스트 초기화');
      }
    } catch (e) {
      // JSON 파싱 중 예외 발생 시 로그 출력
      debugPrint('JSON 파싱 중 오류 발생: $e');
      images = []; // 오류가 발생하면 이미지 리스트를 비움
    }
  }

  Future<void> _pickImages() async {
    final pickedFiles = await ImagePicker().pickMultiImage();

    // 현재 이미지 수와 새로 선택된 이미지 수의 합이 6을 초과하는지 확인
    if (images.length + pickedFiles.length > 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('최대 6장의 이미지만 선택할 수 있습니다.'),
        ),
      );
    } else {
      setState(() {
        images.addAll(pickedFiles);
        print('선택된 이미지들: $images');
      });
    }
  }

  Future<void> _updatePost() async {
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception('사용자를 찾지 못했습니다.');

    if (_isLoading) return;

    setState(() => _isLoading = true);

    // 작업 시작 Dialog 표시
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          backgroundColor: Colors.white,
          content: Column(
            children: [
              Text('수정된 정보를 저장중입니다•••'),
            ],
          ),
        );
      },
    );

    // 수정된 값과 기존의 값이 다른지 확인. 다르다면 true로 설정하고 updateData 맵에 변경사항을 추가
    bool shouldUpdate = false;
    Map<String, dynamic> updateData = {};

    if (_titleEditingController.text != widget.post['title']) {
      updateData['title'] = _titleEditingController.text;
      shouldUpdate = true;
    }

    if (_contentEditingController.text != widget.post['content']) {
      updateData['content'] = _contentEditingController.text;
      shouldUpdate = true;
    }

    List<String> imageUrls = [];
    List<String> compressedImageUrls = [];
    var originalImageUrls = widget.post['compressed_image_urls'];

    if (images.length !=
        (originalImageUrls is List ? originalImageUrls.length : 0)) {
      shouldUpdate = true; // 이미지 개수가 변경되었음을 감지
    }

    if (images.isNotEmpty) {
      for (XFile image in images) {
        // URL인 경우
        if (image.path.startsWith('http')) {
          imageUrls.add(image.path);
          compressedImageUrls.add(image.path); // 압축된 이미지 URL도 처리
        } else {
          // 로컬 파일 처리
          final imageBytes = await image.readAsBytes();
          final compressedImageBytes =
              await FlutterImageCompress.compressWithList(
            imageBytes,
            quality: 92,
          );

          final fileExt = image.name.split('.').last;
          final fileName = '${DateTime.now().toIso8601String()}.$fileExt';
          final compressedFileName =
              '${DateTime.now().toIso8601String()}_compressed.$fileExt';
          final filePath = 'post_images/$fileName';
          final compressedFilePath =
              'post_compressed_images/$compressedFileName';

          await supabase.storage
              .from('post_photo')
              .uploadBinary(filePath, imageBytes);
          await supabase.storage
              .from('post_compressed_photo')
              .uploadBinary(compressedFilePath, compressedImageBytes);

          final imageUrlResponse = await supabase.storage
              .from('post_photo')
              .createSignedUrl(filePath, 60 * 60 * 24 * 365 * 10);

          final compressedImageUrlResponse = await supabase.storage
              .from('post_compressed_photo')
              .createSignedUrl(compressedFilePath, 60 * 60 * 24 * 365 * 10);

          imageUrls.add(imageUrlResponse);
          print('스토리지에 저장된 원본 이미지들: $imageUrls');
          compressedImageUrls.add(compressedImageUrlResponse);
          print('스토리지에 저장된 압축 이미지들: $compressedImageUrls');
          widget.onUpload(imageUrlResponse);
        }
      }

      updateData['image_urls'] = imageUrls; // 이미지 URL 리스트 업데이트
      updateData['compressed_image_urls'] =
          compressedImageUrls; // 압축된 이미지 URL 리스트 업데이트
    } else {
      updateData['image_urls'] = []; // 이미지를 전부 삭제한 경우 빈 배열로 설정
      updateData['compressed_image_urls'] = [];
    }
    if (shouldUpdate) {
      final response = await supabase
          .from('posts')
          .update(updateData)
          .eq('id', widget.post['id']);

      print('업데이트 response: $response');

      final updatedpost = {
        ...widget.post,
        ...updateData,
        'image_url': imageUrls,
        'compressed_image_url': compressedImageUrls,
      };
      print('업데이트 결과: $updatedpost');

      widget.onUpdateSuccess();

      Navigator.of(context, rootNavigator: true).pop();

      if (!mounted) return;

      setState(() => _isLoading = false);
      Navigator.of(context).pop(updatedpost);
    } else {
      if (!mounted) return;

      // 상태 업데이트 없이 페이지 종료
      setState(() => _isLoading = false);
      Navigator.of(context).pop();
    }
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
          itemCount: min(images.length + 1, 6),
          itemBuilder: (BuildContext context, int index) {
            if (index < images.length) {
              // URL인 경우 Image.network 사용, 아니면 Image.file 사용
              Widget imageWidget;
              if (Uri.parse(images[index].path).isAbsolute) {
                imageWidget =
                    Image.network(images[index].path, fit: BoxFit.cover);
              } else {
                imageWidget =
                    Image.file(File(images[index].path), fit: BoxFit.cover);
              }
              return DragTarget<XFile>(
                onWillAccept: (data) => true,
                onAccept: (data) {
                  setState(() {
                    final oldIndex = images.indexOf(data);
                    images.remove(data);
                    if (index > oldIndex) {
                      images.insert(index - 1, data);
                    } else {
                      images.insert(index, data);
                    }
                  });
                },
                builder: (context, candidateData, rejectedData) {
                  return LongPressDraggable<XFile>(
                    data: images[index],
                    feedback: Material(
                      child: images[index].path.startsWith('http')
                          ? Image.network(images[index].path,
                              fit: BoxFit.cover, width: 100, height: 100)
                          : Image.file(File(images[index].path),
                              fit: BoxFit.cover, width: 100, height: 100),
                    ),
                    childWhenDragging: Container(),
                    child: Stack(
                      children: [
                        Positioned.fill(child: imageWidget),
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
                                images.removeAt(index);
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
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
        surfaceTintColor: Colors.white,
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
        iconTheme: const IconThemeData(color: bg_70),
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          '게시글 수정',
          style: TextStyle(
              color: Colors.black, fontSize: 20, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        actions: <Widget>[
          IconButton(
            onPressed: () async {
              // 모든 조건이 충족되는지 확인
              if (_titleEditingController.text.isNotEmpty &&
                  _contentEditingController.text.isNotEmpty) {
                ScaffoldMessenger.of(context).removeCurrentSnackBar();
                await _updatePost();
              } else {
                // 충족되지 않은 조건에 대한 알림
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    backgroundColor: primary,
                    content: Text(
                      '빈 내용을 작성해주세요.',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                );
              }
            },
            icon: SizedBox(
              width: 52,
              height: 38,
              child: Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(19),
                    color: Colors.black),
                child: const Center(
                  child: Text(
                    '수정',
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
    );
  }
}
