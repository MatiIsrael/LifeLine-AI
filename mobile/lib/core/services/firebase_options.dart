import "package:firebase_core/firebase_core.dart";
import "package:flutter/foundation.dart" show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Replace placeholder values using: flutterfire configure
class DefaultFirebaseOptions {
  static bool get isConfigured =>
      android.projectId != "REPLACE_ME" && android.apiKey != "REPLACE_ME";

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
        throw UnsupportedError("Firebase options are not configured for this platform.");
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: "REPLACE_ME",
    appId: "REPLACE_ME",
    messagingSenderId: "REPLACE_ME",
    projectId: "REPLACE_ME",
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: "REPLACE_ME",
    appId: "REPLACE_ME",
    messagingSenderId: "REPLACE_ME",
    projectId: "REPLACE_ME",
    storageBucket: "REPLACE_ME.appspot.com",
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: "REPLACE_ME",
    appId: "REPLACE_ME",
    messagingSenderId: "REPLACE_ME",
    projectId: "REPLACE_ME",
    iosBundleId: "com.example.lifelineAI",
  );
}
