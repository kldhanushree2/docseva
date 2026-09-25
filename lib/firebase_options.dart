import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDtQ0Oy3VGM1hlXDazP9FcvvtfOQihK0dU',
    appId: '1:1008441648787:web:16abf5c87062f476a60f66',
    messagingSenderId: '1008441648787',
    projectId: 'docseva-67315',
    authDomain: 'docseva-67315.firebaseapp.com',
    storageBucket: 'docseva-67315.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDtQ0Oy3VGM1hlXDazP9FcvvtfOQihK0dU',
    appId: '1:1008441648787:android:16abf5c87062f476a60f66',
    messagingSenderId: '1008441648787',
    projectId: 'docseva-67315',
    storageBucket: 'docseva-67315.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDtQ0Oy3VGM1hlXDazP9FcvvtfOQihK0dU',
    appId: '1:1008441648787:ios:16abf5c87062f476a60f66',
    messagingSenderId: '1008441648787',
    projectId: 'docseva-67315',
    storageBucket: 'docseva-67315.firebasestorage.app',
    iosBundleId: 'com.example.docseva',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDtQ0Oy3VGM1hlXDazP9FcvvtfOQihK0dU',
    appId: '1:1008441648787:ios:16abf5c87062f476a60f66',
    messagingSenderId: '1008441648787',
    projectId: 'docseva-67315',
    storageBucket: 'docseva-67315.firebasestorage.app',
    iosBundleId: 'com.example.docseva',
  );
}
