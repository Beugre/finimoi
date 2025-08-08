// firebase_options.dart
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
    apiKey: 'AIzaSyBVz1bihjp_3PR9hkKiHG1pNFFbXw_n4PA',
    appId: '1:363043806234:web:d69892032496ce192f85a3',
    messagingSenderId: '363043806234',
    projectId: 'finimoi',
    authDomain: 'finimoi.firebaseapp.com',
    storageBucket: 'finimoi.firebasestorage.app',
    measurementId: 'G-9VW295WBZD',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA9nsz1gvlVXyjmvYtPJRTKJR-BzhTdurE',
    appId: '1:363043806234:android:08d871ad9f3a8c2b2f85a3',
    messagingSenderId: '363043806234',
    projectId: 'finimoi',
    storageBucket: 'finimoi.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAD9GPgdjvrX4JAPznEjrbTYyTmkR3ELqU',
    appId: '1:363043806234:ios:55ffc18e7c14d6eb2f85a3',
    messagingSenderId: '363043806234',
    projectId: 'finimoi',
    storageBucket: 'finimoi.firebasestorage.app',
    iosBundleId: 'com.finimoi.app.finimoi',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAD9GPgdjvrX4JAPznEjrbTYyTmkR3ELqU',
    appId: '1:363043806234:ios:55ffc18e7c14d6eb2f85a3',
    messagingSenderId: '363043806234',
    projectId: 'finimoi',
    storageBucket: 'finimoi.firebasestorage.app',
    iosBundleId: 'com.finimoi.app.finimoi',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBVz1bihjp_3PR9hkKiHG1pNFFbXw_n4PA',
    appId: '1:363043806234:web:6cf47618c3b7e0e12f85a3',
    messagingSenderId: '363043806234',
    projectId: 'finimoi',
    authDomain: 'finimoi.firebaseapp.com',
    storageBucket: 'finimoi.firebasestorage.app',
    measurementId: 'G-3PK55Q1S9X',
  );

}