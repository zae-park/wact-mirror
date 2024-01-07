import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wact/common/const/color.dart';

class HomePostPage extends StatelessWidget {
  final Map<String, dynamic> post;

  HomePostPage({Key? key, required this.post}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final createdAt =
        DateFormat('MM/dd').format(DateTime.parse(post['created_at']));
    // 이미지 URL 리스트
    List<dynamic>? imageUrls = post['image_urls'];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(''),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    post['title'],
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                  ),
                  Column(
                    children: [
                      Text(
                        '${post['author']}',
                        style: TextStyle(
                            fontSize: 10, fontWeight: FontWeight.w500),
                      ),
                      Text(
                        '$createdAt',
                        style: TextStyle(fontSize: 10, color: bg_70),
                      ),
                    ],
                  )
                ],
              ),

              SizedBox(height: 10),
              Text(
                post['content'],
                style: TextStyle(
                  fontSize: 16,
                ),
              ),
              SizedBox(
                height: 20,
              ),
              // 이미지 리스트 표시
// 이미지 리스트 표시
              if (imageUrls != null && imageUrls.isNotEmpty)
                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: imageUrls.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: EdgeInsets.only(bottom: 10),
                      child: GestureDetector(
                        onTap: () {},
                        child: Image.network(
                          imageUrls[index],
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
