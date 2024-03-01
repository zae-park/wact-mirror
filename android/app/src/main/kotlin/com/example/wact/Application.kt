// import io.flutter.plugins.firebasemessaging.FirebaseMessagingPlugin
// import io.flutter.view.FlutterMain
// import com.dexterous.flutterlocalnotifications.FlutterLocalNotificationsPlugin

// class Application : FlutterApplication(), PluginRegistrantCallback {

//     override fun onCreate() {
//         super.onCreate()
//         FlutterFirebaseMessagingService.setPluginRegistrant(this); // 기존 파베 코드
//         FlutterMain.startInitialization(this) // 추가!
//     }
    
//     // 파베 메시징이랑 local noti 플러그인 연동
//     override fun registerWith(registry: PluginRegistry?) {
//         FirebaseMessagingPlugin.registerWith(registry!!.registrarFor("io.flutter.plugins.firebasemessaging.FirebaseMessagingPlugin"));
//         FlutterLocalNotificationsPlugin.registerWith(registry!!.registrarFor("com.dexterous.flutterlocalnotifications.FlutterLocalNotificationsPlugin"));
//     }
// }