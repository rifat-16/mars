
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
    apiKey: 'AIzaSyAHYUOKzwnxIirSjBQexRAlJikDPXZMy2c',
    appId: '1:346571920317:web:304d8464931d5ea3aef8d4',
    messagingSenderId: '346571920317',
    projectId: 'mars-272dc',
    authDomain: 'mars-272dc.firebaseapp.com',
    storageBucket: 'mars-272dc.firebasestorage.app',
    measurementId: 'G-YXMEKFYN3V',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBvZm8i2JzSvZXQwE-SdE_oLLA-EFoC5eU',
    appId: '1:346571920317:android:a1e87dd6b21dc3d5aef8d4',
    messagingSenderId: '346571920317',
    projectId: 'mars-272dc',
    storageBucket: 'mars-272dc.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyB7GQTAaOMlA0F5qZVSDOGBYalo0ZM_eOY',
    appId: '1:346571920317:ios:d887e94d1869de87aef8d4',
    messagingSenderId: '346571920317',
    projectId: 'mars-272dc',
    storageBucket: 'mars-272dc.firebasestorage.app',
    iosBundleId: 'com.mars.mars',
  );
}
