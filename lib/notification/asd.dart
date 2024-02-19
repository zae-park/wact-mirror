import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// Function to get the device's FCM token
Future<String> getFCMToken() async {
  // Check current notification settings
  NotificationSettings settings =
      await FirebaseMessaging.instance.getNotificationSettings();

  // Check if notification permission is approved
  if (settings.authorizationStatus != AuthorizationStatus.authorized) {
    print('Not Approved');
    return 'Not Approved';
  }

  String? fcmToken = await FirebaseMessaging.instance.getToken();

  print(fcmToken);
  return fcmToken;
}

Future<void> onTokenRefreshFCM() async {
  FirebaseMessaging.instance.onTokenRefresh.listen((String fcmToken) async {
    print("New token: $fcmToken");
    FFAppState().fcmTokenRefresh = true;
  }, onError: (err) async {
    print("Error getting token");
  });


  