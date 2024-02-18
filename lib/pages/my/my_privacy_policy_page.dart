import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';

class PrivacyPolicyPage extends StatefulWidget {
  const PrivacyPolicyPage({Key? key}) : super(key: key);

  @override
  _PrivacyPolicyPageState createState() => _PrivacyPolicyPageState();
}

class _PrivacyPolicyPageState extends State<PrivacyPolicyPage> {
  String? _pdfPath;

  @override
  void initState() {
    super.initState();
    _loadPdfFile();
  }

  Future<void> _loadPdfFile() async {
    try {
      final bytes = await rootBundle.load('assets/wact_privacy_policy.pdf');
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/wact_privacy_policy.pdf');

      await file.writeAsBytes(bytes.buffer.asUint8List());
      setState(() {
        _pdfPath = file.path;
      });
    } catch (e) {
      print("PDF 파일 로드 중 오류: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('개인정보처리방침'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: _pdfPath == null
          ? const Center(child: CircularProgressIndicator())
          : PDFView(
              filePath: _pdfPath,
            ),
    );
  }
}
