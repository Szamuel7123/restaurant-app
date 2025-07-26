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
    apiKey: 'AIzaSyBKTylzf5we6cB-hSW2Xp8I6RG-Nv0CQ6w',
    appId: '1:739012522636:web:e34523e8e72f05190e01a9',
    messagingSenderId: '739012522636',
    projectId: 'restaurant-4caf9',
    authDomain: 'restaurant-4caf9.firebaseapp.com',
    storageBucket: 'restaurant-4caf9.firebasestorage.app',
    measurementId: 'G-KL0HHJFWRB',
  );

  // TODO: Replace with your Firebase configuration

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBMQ_vwMiFV6lRBIGJYMIszR7RM9hVicfk',
    appId: '1:739012522636:android:e973a859b70b02620e01a9',
    messagingSenderId: '739012522636',
    projectId: 'restaurant-4caf9',
    storageBucket: 'restaurant-4caf9.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCyLsy0EfytXI7OLWGGPcpOMbjmjEmAMjw',
    appId: '1:739012522636:ios:3e9272d3b84587850e01a9',
    messagingSenderId: '739012522636',
    projectId: 'restaurant-4caf9',
    storageBucket: 'restaurant-4caf9.firebasestorage.app',
    iosBundleId: 'com.example.retaurant',
  );

} 