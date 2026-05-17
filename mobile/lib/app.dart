import "package:firebase_auth/firebase_auth.dart";
import "package:flutter/material.dart";
import "package:provider/provider.dart";

import "core/services/triggers/emergency_trigger_coordinator.dart";
import "core/state/auth_provider.dart";
import "core/state/sos_provider.dart";
import "core/state/offline_provider.dart";
import "core/state/trigger_settings_provider.dart";
import "core/theme/app_theme.dart";
import "core/config/app_config.dart";
import "features/auth/login_screen.dart";
import "features/home/home_screen.dart";
import "features/setup/setup_required_screen.dart";
import "features/sos/live_tracking_screen.dart";

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

class LifelineApp extends StatefulWidget {
  const LifelineApp({super.key});

  @override
  State<LifelineApp> createState() => _LifelineAppState();
}

class _LifelineAppState extends State<LifelineApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrapTriggers());
  }

  Future<void> _bootstrapTriggers() async {
    if (!AppConfig.firebaseReady) return;

    final sos = context.read<SosProvider>();
    final triggers = context.read<TriggerSettingsProvider>();
    final offline = context.read<OfflineProvider>();

    await offline.initialize();
    await triggers.load();
    await triggers.initializeBackground();

    await EmergencyTriggerCoordinator.instance.initialize(
      navigatorKey: rootNavigatorKey,
      onActivate: ({required source, required silent, required recordAudio}) async {
        await sos.activateFromCoordinator(
          source: source,
          silent: silent,
          recordAudio: recordAudio,
        );

        final ctx = rootNavigatorKey.currentContext;
        if (ctx == null) return;

        if (sos.error != null) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(content: Text(sos.error!)),
          );
          return;
        }

        final offlineState = context.read<OfflineProvider>();
        if (offlineState.isOffline) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            const SnackBar(
              content: Text(
                "No internet — SOS queued. SMS & nearby device relay activated; cloud sync will retry automatically.",
              ),
              duration: Duration(seconds: 5),
            ),
          );
          return;
        }

        if (silent) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            const SnackBar(
              content: Text("Silent emergency activated. Contacts notified."),
            ),
          );
          return;
        }

        if (sos.activeEventId != null) {
          rootNavigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (_) => LiveTrackingScreen(eventId: sos.activeEventId!),
            ),
          );
        }
      },
    );

    if (FirebaseAuth.instance.currentUser != null) {
      await EmergencyTriggerCoordinator.instance.arm();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: rootNavigatorKey,
      title: "Lifeline AI",
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: !AppConfig.firebaseReady
          ? const SetupRequiredScreen()
          : Consumer<AuthProvider>(
              builder: (context, auth, _) {
                final user = FirebaseAuth.instance.currentUser;
                if (user != null && auth.isInitialized) {
                  return const HomeScreen();
                }
                return const LoginScreen();
              },
            ),
    );
  }
}
