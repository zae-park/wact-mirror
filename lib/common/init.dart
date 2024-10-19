import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wact/firebase_options.dart';

Future<void> initializeApp() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 카톡앱 '캄피-TEST' 키
  KakaoSdk.init(
    nativeAppKey: '5d4cef15a6813674d5a8e4fd5907ac4f',
    javaScriptAppKey: '9f1a4a118913974e699835637ce11dca',
  );

  await Supabase.initialize(
    url: 'https://tucpydftldyqknodgghy.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR1Y3B5ZGZ0bGR5cWtub2RnZ2h5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MDQ3OTI0NTgsImV4cCI6MjAyMDM2ODQ1OH0.iCo1iAtV55fZjNpiYI-ccH6Hcrzhi55UB-yZYNtkKsg',
  );
}

final supabase = Supabase.instance.client;
