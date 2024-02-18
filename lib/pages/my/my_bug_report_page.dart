import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class BugReportPage extends StatelessWidget {
  BugReportPage({Key? key}) : super(key: key);

  // 카카오톡 채널 연결 URL 예시입니다. 실제 비즈니스 채널의 URL로 변경해야 합니다.
  final Uri _kakaoChannelUrl = Uri.parse('https://pf.kakao.com/_xjyMnG/chat');

  Future<void> _launchURL() async {
    if (!await launchUrl(_kakaoChannelUrl)) {
      throw 'Could not launch $_kakaoChannelUrl';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          '버그리포트',
          style: TextStyle(
              color: Colors.black, fontSize: 20, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: _launchURL,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xffF9E54C),
          ),
          child: const Text(
            '카카오톡 채널로 버그남기기',
            style: TextStyle(
                fontWeight: FontWeight.w600, fontSize: 16, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
