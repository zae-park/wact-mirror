import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class BugReportPage extends StatelessWidget {
  BugReportPage({Key? key}) : super(key: key);

  final Uri _kakaoChannelUrl =
      Uri.parse('http://qr.kakao.com/talk/HgDTBptJELWoeWiBG_lz4pfmQmI-');
  final Uri _kakaoChannelUrl2 =
      Uri.parse('http://qr.kakao.com/talk/eI8aw3depvmYyaQC95basewtsuw-');
  final Uri _kakaoChannelUrl3 =
      Uri.parse('http://qr.kakao.com/talk/hhvvD3VSrse0eDohJWJ1J77YufE-');
  final Uri _kakaoChannelUrl4 =
      Uri.parse('http://qr.kakao.com/talk/vjV8mhYW1DwMo2PBD1x_79EzNcc-');

  Future<void> _launchURL(Uri url) async {
    if (!await launchUrl(url)) {
      throw '$url을 실행할 수 없습니다.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          '고객센터',
          style: TextStyle(
              color: Colors.black, fontSize: 20, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => _launchURL(_kakaoChannelUrl),
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xffF9E54C)),
              child: const Text('남성현에게 문의하기',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Colors.white)),
            ),
            SizedBox(height: 8), // 버튼 사이의 간격 추가
            ElevatedButton(
              onPressed: () => _launchURL(_kakaoChannelUrl2),
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xffF9E54C)),
              child: const Text('박성재에게 문의하기',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Colors.white)),
            ),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => _launchURL(_kakaoChannelUrl3),
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xffF9E54C)),
              child: const Text('정한결에게 문의하기',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Colors.white)),
            ),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => _launchURL(_kakaoChannelUrl4),
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xffF9E54C)),
              child: const Text('이강원에게 문의하기',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
