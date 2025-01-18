import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class SermonNoteDetailPage extends StatefulWidget {
  final Map<String, dynamic> post;
  final Function refreshCallback;

  const SermonNoteDetailPage({
    Key? key,
    required this.post,
    required this.refreshCallback,
  }) : super(key: key);

  @override
  State<SermonNoteDetailPage> createState() => _SermonNoteDetailPageState();
}

class _SermonNoteDetailPageState extends State<SermonNoteDetailPage> {
  late TextEditingController commentController;
  late User? user;
  List<dynamic>? imageUrls;
  List<dynamic> comments = [];

  @override
  void initState() {
    super.initState();
    commentController = TextEditingController();
    user = Supabase.instance.client.auth.currentUser;

    // 이미지 URL 처리
    if (widget.post['images'] is String) {
      String jsonString = widget.post['images'];
      imageUrls = json.decode(jsonString);
    } else if (widget.post['images'] is List) {
      imageUrls = widget.post['images'];
    } else {
      imageUrls = [];
    }

    fetchComments();
  }

  Future<void> fetchComments() async {
    final response = await Supabase.instance.client
        .from('comments')
        .select()
        .eq('target_id', widget.post['id'])
        .order('created_at', ascending: true);

    setState(() {
      comments = List<dynamic>.from(response);
    });
  }

  Future<void> addComment(String content) async {
    try {
      final profileResponse = await Supabase.instance.client
          .from('profiles')
          .select('username')
          .eq('id', user!.id)
          .single();

      final username = profileResponse['username'] as String;
      final uuid = Uuid();

      await Supabase.instance.client.from('comments').insert({
        'id': uuid.v4(),
        'target_id': widget.post['id'],
        'author_id': user!.id,
        'author': username,
        'content': content,
        'created_at': DateTime.now().toIso8601String(),
      });

      commentController.clear();
      fetchComments();
    } catch (error) {
      print('댓글 추가 오류: $error');
    }
  }

  void _showImagePopup(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (BuildContext context) {
        return GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Center(
            child: Image.network(imageUrl, fit: BoxFit.contain),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final createdAt = DateFormat('yyyy-MM-dd HH:mm')
        .format(DateTime.parse(widget.post['created_at']));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('설교노트 상세', style: TextStyle(color: Colors.black)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '설교자: ${widget.post['preacher']}',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '장소: ${widget.post['location'] ?? "미입력"}',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '작성일: $createdAt',
                      style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                    ),
                    SizedBox(height: 16),
                    Text(
                      '내용',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      widget.post['content'],
                      style: TextStyle(fontSize: 16, height: 1.5),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              if (imageUrls != null && imageUrls!.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: imageUrls!.map((url) {
                    return GestureDetector(
                      onTap: () => _showImagePopup(context, url),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          url,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              Divider(height: 32, color: Colors.grey[300]),
              Text(
                '댓글',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              ...comments.map((comment) {
                final createdAt = DateFormat('yyyy-MM-dd HH:mm')
                    .format(DateTime.parse(comment['created_at']));
                return Container(
                  margin: EdgeInsets.only(bottom: 16),
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 5,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        comment['author'] ?? '알 수 없음',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        comment['content'] ?? '',
                        style: TextStyle(fontSize: 14),
                      ),
                      SizedBox(height: 8),
                      Text(
                        createdAt,
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            left: 16,
            right: 16),
        child: TextField(
          controller: commentController,
          decoration: InputDecoration(
            hintText: '댓글 작성',
            suffixIcon: IconButton(
              icon: Icon(Icons.send, color: Colors.blue),
              onPressed: () {
                if (commentController.text.isNotEmpty) {
                  addComment(commentController.text);
                }
              },
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            filled: true,
            fillColor: Colors.grey[100],
          ),
        ),
      ),
    );
  }
}
