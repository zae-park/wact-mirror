// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDIzmO1_x77zzvQulibPv5JzoKeI0dnqcA',
    appId: '1:866308159640:web:e24ed82b3f6992ed2a38ed',
    messagingSenderId: '866308159640',
    projectId: 'wact-b34ab',
    authDomain: 'wact-b34ab.firebaseapp.com',
    storageBucket: 'wact-b34ab.appspot.com',
    measurementId: 'G-3Y3LTLQS1M',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDsvyPj7WZOz-3qEu7QImrFb_TkncmRUsw',
    appId: '1:866308159640:android:49f8cff6f3283b042a38ed',
    messagingSenderId: '866308159640',
    projectId: 'wact-b34ab',
    storageBucket: 'wact-b34ab.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCkMxnLdqm0c3hkKeGUimucC7SrwADfqU8',
    appId: '1:866308159640:ios:418fa82ac7fe4ce82a38ed',
    messagingSenderId: '866308159640',
    projectId: 'wact-b34ab',
    storageBucket: 'wact-b34ab.appspot.com',
    androidClientId: '866308159640-nrcokahnl6fk3hcqie4t0efa0cdf2tf5.apps.googleusercontent.com',
    iosClientId: '866308159640-eo30bqc5ssl849h0h3jpao25pf06qg2u.apps.googleusercontent.com',
    iosBundleId: 'com.one.wact',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCkMxnLdqm0c3hkKeGUimucC7SrwADfqU8',
    appId: '1:866308159640:ios:89f4d40b4c1f7a692a38ed',
    messagingSenderId: '866308159640',
    projectId: 'wact-b34ab',
    storageBucket: 'wact-b34ab.appspot.com',
    androidClientId: '866308159640-nrcokahnl6fk3hcqie4t0efa0cdf2tf5.apps.googleusercontent.com',
    iosBundleId: 'com.example.wact',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDIzmO1_x77zzvQulibPv5JzoKeI0dnqcA',
    appId: '1:866308159640:web:82b4408d4ec4c52d2a38ed',
    messagingSenderId: '866308159640',
    projectId: 'wact-b34ab',
    authDomain: 'wact-b34ab.firebaseapp.com',
    storageBucket: 'wact-b34ab.appspot.com',
    measurementId: 'G-WL567XGGSP',
  );

}