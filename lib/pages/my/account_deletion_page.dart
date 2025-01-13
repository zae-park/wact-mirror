import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class AccountDeletionPage extends StatefulWidget {
  const AccountDeletionPage({super.key});

  @override
  _AccountDeletionPageState createState() => _AccountDeletionPageState();
}

class _AccountDeletionPageState extends State<AccountDeletionPage> {
  bool _isChecked = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text('계정 탈퇴'),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: IconButton(
              onPressed: () async {
                const url =
                    'https://calmpy.notion.site/WACT-14e07d757e788047bd80ddc5e16e0cdb';
                if (await canLaunchUrl(Uri.parse(url))) {
                  await launchUrl(Uri.parse(url),
                      mode: LaunchMode.externalApplication);
                } else {
                  throw 'Could not launch $url';
                }
              },
              icon: Icon(Icons.info_outline_rounded),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '탈퇴 안내 사항',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              '정말로 탈퇴하시겠습니까?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            Text(
              '탈퇴를 진행할 경우, 30일의 유예 기간이 부여되며, 이 기간 동안은 탈퇴를 취소할 수 있습니다.',
            ),
            const SizedBox(height: 5),
            Text(
              '또한 기존에 작성한 모든 글이 비활성화되어, 다른 유저에게 보이지 않습니다.',
            ),
            const SizedBox(height: 5),
            Text(
              '유예 기간이 만료되면 계정 정보와 모든 사진은 영구적으로 삭제됩니다.',
              style: TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 20),
            CheckboxListTile(
              title: Text('안내 사항을 읽고 이해했습니다.'),
              value: _isChecked,
              onChanged: (bool? value) {
                setState(() {
                  _isChecked = value ?? false;
                });
              },
            ),
            Spacer(),
            Center(
              child: ElevatedButton(
                onPressed: _isChecked
                    ? () async {
                        await _requestAccountDeletion();
                        await Supabase.instance.client.auth.signOut();
                        Navigator.of(context).pushReplacementNamed('/login');
                      }
                    : null,
                child: Text('계정 탈퇴'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 탈퇴 요청을 처리하는 함수
  Future<void> _requestAccountDeletion() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final deletionDate =
          DateTime.now().add(Duration(days: 30)); // 30일 후의 날짜 계산
      await Supabase.instance.client.from('profiles').update({
        'scheduled_deletion_date': deletionDate.toIso8601String()
      }).eq('id', user.id);
    }
  }
}

class GoRouter {}
