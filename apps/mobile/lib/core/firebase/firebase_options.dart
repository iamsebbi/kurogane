import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
      default:
        return android;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: String.fromEnvironment(
      'FIREBASE_WEB_API_KEY',
      defaultValue: 'AIzaSy_FIREBASE_WEB_KEY_PLACEHOLDER',
    ),
    appId: '1:141330897882:web:5ce77a022ecfdadbce3ee3',
    messagingSenderId: '141330897882',
    projectId: 'kurogane-c3c14',
    authDomain: 'kurogane-c3c14.firebaseapp.com',
    storageBucket: 'kurogane-c3c14.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: String.fromEnvironment(
      'FIREBASE_ANDROID_API_KEY',
      defaultValue: 'AIzaSy_FIREBASE_ANDROID_KEY_PLACEHOLDER',
    ),
    appId: '1:141330897882:android:d51904299d22aa09ce3ee3',
    messagingSenderId: '141330897882',
    projectId: 'kurogane-c3c14',
    authDomain: 'kurogane-c3c14.firebaseapp.com',
    storageBucket: 'kurogane-c3c14.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: String.fromEnvironment(
      'FIREBASE_IOS_API_KEY',
      defaultValue: 'AIzaSy_FIREBASE_IOS_KEY_PLACEHOLDER',
    ),
    appId: '1:141330897882:ios:5ce77a022ecfdadbce3ee3',
    messagingSenderId: '141330897882',
    projectId: 'kurogane-c3c14',
    authDomain: 'kurogane-c3c14.firebaseapp.com',
    storageBucket: 'kurogane-c3c14.firebasestorage.app',
  );
}
