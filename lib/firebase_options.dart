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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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
    apiKey: 'AIzaSyB3JyMSCr6zuQ3gZMRlOtY4AkwYMHajHBQ',
    appId: '1:551458738646:web:df95489388488c6cbd5477',
    messagingSenderId: '551458738646',
    projectId: 'graduationproject-cde3f',
    authDomain: 'graduationproject-cde3f.firebaseapp.com',
    storageBucket: 'graduationproject-cde3f.appspot.com',
    measurementId: 'G-Y4802WJXGT',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDXV_SuM91Ff5kyBiuZfL1OOTNpHzZnAd8',
    appId: '1:551458738646:android:c4ac4f114e4bd12bbd5477',
    messagingSenderId: '551458738646',
    projectId: 'graduationproject-cde3f',
    storageBucket: 'graduationproject-cde3f.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAm93vkyU9z62Hrpev8hBycil7V2oQ9d8M',
    appId: '1:551458738646:ios:f295d07de7ce9125bd5477',
    messagingSenderId: '551458738646',
    projectId: 'graduationproject-cde3f',
    storageBucket: 'graduationproject-cde3f.appspot.com',
    iosBundleId: 'com.example.flutterFirebase',
  );

}