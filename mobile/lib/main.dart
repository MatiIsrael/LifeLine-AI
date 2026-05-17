import "package:firebase_core/firebase_core.dart";
import "package:flutter/material.dart";
import "package:provider/provider.dart";

import "app.dart";
import "core/config/app_config.dart";
import "core/services/firebase_options.dart";
import "core/state/auth_provider.dart";
import "core/state/sos_provider.dart";
import "core/state/offline_provider.dart";
import "core/state/safety_provider.dart";
import "core/state/trigger_settings_provider.dart";

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (DefaultFirebaseOptions.isConfigured) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      AppConfig.firebaseReady = true;
    } catch (_) {
      AppConfig.firebaseReady = false;
    }
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => SosProvider()),
        ChangeNotifierProvider(create: (_) => TriggerSettingsProvider()),
        ChangeNotifierProvider(create: (_) => OfflineProvider()),
        ChangeNotifierProvider(create: (_) => SafetyProvider()..refreshLocationRisk()),
      ],
      child: const LifelineApp(),
    ),
  );
}
