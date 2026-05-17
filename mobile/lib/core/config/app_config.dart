import "../services/firebase_options.dart";

/// Global runtime configuration for Lifeline AI.
class AppConfig {
  static bool firebaseReady = false;

  static bool get isFirebaseConfigured => DefaultFirebaseOptions.isConfigured;

  static bool get canUseBackend => firebaseReady && isFirebaseConfigured;
}
