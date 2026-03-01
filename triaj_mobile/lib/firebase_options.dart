import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
        'you can reconfigure this by running the FlutterFire CLI again.',
      );
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

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCnnzEoIVJn9KTQ137F6-k0zgo6C5kPneY',
    appId: '1:780836079890:android:f9655d4513fc064b5e0bcb',
    messagingSenderId: '780836079890',
    projectId: 'triaj-fabaa',
    storageBucket: 'triaj-fabaa.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCUS2-jxxaK6lanvpdgsd3yXNseCjjQObs',
    appId: '1:780836079890:ios:a65317e98a7574b55e0bcb',
    messagingSenderId: '780836079890',
    projectId: 'triaj-fabaa',
    storageBucket: 'triaj-fabaa.firebasestorage.app',
    iosBundleId: 'com.example.triajMobile',
    iosClientId:
        '780836079890-299f1kj2jklhuugopvr8psn33siccf3r.apps.googleusercontent.com',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCUS2-jxxaK6lanvpdgsd3yXNseCjjQObs',
    appId: '1:780836079890:ios:a65317e98a7574b55e0bcb',
    messagingSenderId: '780836079890',
    projectId: 'triaj-fabaa',
    storageBucket: 'triaj-fabaa.firebasestorage.app',
    iosBundleId: 'com.example.triajMobile',
    iosClientId:
        '780836079890-299f1kj2jklhuugopvr8psn33siccf3r.apps.googleusercontent.com',
  );
}
