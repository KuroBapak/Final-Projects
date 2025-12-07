// This file is a placeholder.
// Please run `flutterfire configure` to generate the actual file.
// Or place your google-services.json / GoogleService-Info.plist in the respective folders.

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
    apiKey: 'AIzaSyD6HalzLJthzczhKLxJOv9KhP_r9IRw_rU',
    appId: '1:251255919647:web:41f99cc23af0233670b12a',
    messagingSenderId: '251255919647',
    projectId: 'android-studio-dd4e4',
    authDomain: 'android-studio-dd4e4.firebaseapp.com',
    storageBucket: 'android-studio-dd4e4.firebasestorage.app',
    measurementId: 'G-60ZSNYS6VT',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyB1s76pHxsI8P0xWCAu5PMFJiN3WqvYnUg',
    appId: '1:251255919647:ios:d429de61fa63991e70b12a',
    messagingSenderId: '251255919647',
    projectId: 'android-studio-dd4e4',
    storageBucket: 'android-studio-dd4e4.firebasestorage.app',
    iosBundleId: 'com.example.flutter1',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyB1s76pHxsI8P0xWCAu5PMFJiN3WqvYnUg',
    appId: '1:251255919647:ios:d429de61fa63991e70b12a',
    messagingSenderId: '251255919647',
    projectId: 'android-studio-dd4e4',
    storageBucket: 'android-studio-dd4e4.firebasestorage.app',
    iosBundleId: 'com.example.flutter1',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBaRCncusnckVFnRoiI3lSsQsfY_8r_diI',
    appId: '1:251255919647:android:210ff111af9c795870b12a',
    messagingSenderId: '251255919647',
    projectId: 'android-studio-dd4e4',
    storageBucket: 'android-studio-dd4e4.firebasestorage.app',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyD6HalzLJthzczhKLxJOv9KhP_r9IRw_rU',
    appId: '1:251255919647:web:f92f5af8ec5867e270b12a',
    messagingSenderId: '251255919647',
    projectId: 'android-studio-dd4e4',
    authDomain: 'android-studio-dd4e4.firebaseapp.com',
    storageBucket: 'android-studio-dd4e4.firebasestorage.app',
    measurementId: 'G-KLVVFP9FPN',
  );

}