import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError('DefaultFirebaseOptions не настроен для этой платформы.');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD0S298VC7PYwnYtXBgd9H9t8VRnJXJfiw',
    appId: '1:445586183665:android:e571fd8009def13b3a6050',
    messagingSenderId: '445586183665',
    projectId: 'mmdms-3f657',
    storageBucket: 'mmdms-3f657.firebasestorage.app',
  );
}
