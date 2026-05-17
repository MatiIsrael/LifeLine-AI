import "dart:async";

import "package:flutter/material.dart";
import "package:flutter_background_service/flutter_background_service.dart";

import "../../../shared/widgets/emergency_countdown_dialog.dart";
import "../../../shared/widgets/emergency_verification_dialog.dart";
import "../../motion_ai/models/motion_event_type.dart";
import "../../motion_ai/motion_ai_bridge.dart";
import "../../motion_ai/services/motion_ai_monitor_service.dart";
import "../../models/emergency_trigger_settings.dart";
import "../../models/trigger_source.dart";
import "../../platform/power_button_channel.dart";
import "../../platform/volume_button_channel.dart";
import "../emergency_flow_launcher.dart";
import "../audio/emergency_audio_service.dart";
import "../permissions/permission_service.dart";
import "shake_detector_service.dart";
import "trigger_settings_repository.dart";
import "voice_trigger_service.dart";

typedef EmergencyActivateCallback = Future<void> Function({
  required TriggerSource source,
  required bool silent,
  required bool recordAudio,
});

/// Orchestrates all trigger inputs, countdown cancellation, and activation.
class EmergencyTriggerCoordinator {
  EmergencyTriggerCoordinator._();
  static final EmergencyTriggerCoordinator instance = EmergencyTriggerCoordinator._();

  final TriggerSettingsRepository _settingsRepo = TriggerSettingsRepository();
  final PermissionService _permissions = PermissionService();
  final ShakeDetectorService _shakeDetector = ShakeDetectorService();
  final VoiceTriggerService _voiceTrigger = VoiceTriggerService();
  final PowerButtonChannel _powerButton = PowerButtonChannel();
  final VolumeButtonChannel _volumeButton = VolumeButtonChannel();
  final EmergencyAudioService _audioService = EmergencyAudioService();
  final MotionAiMonitorService _motionAi = MotionAiMonitorService();

  EmergencyTriggerSettings _settings = const EmergencyTriggerSettings();
  EmergencyActivateCallback? _onActivate;
  GlobalKey<NavigatorState>? _navigatorKey;

  StreamSubscription<int>? _powerSub;
  StreamSubscription<int>? _volumeSub;
  StreamSubscription<Map<String, dynamic>?>? _backgroundSub;
  StreamSubscription<Map<String, dynamic>?>? _motionBackgroundSub;
  bool _armed = false;
  bool _countdownActive = false;
  bool _verificationActive = false;

  EmergencyTriggerSettings get settings => _settings;

  Future<void> initialize({
    required GlobalKey<NavigatorState> navigatorKey,
    required EmergencyActivateCallback onActivate,
  }) async {
    _navigatorKey = navigatorKey;
    _onActivate = onActivate;
    _settings = await _settingsRepo.load();
  }

  Future<void> reloadSettings() async {
    _settings = await _settingsRepo.load();
    if (_armed) {
      await disarm();
      await arm();
    }
  }

  Future<void> updateSettings(EmergencyTriggerSettings settings) async {
    _settings = settings;
    await _settingsRepo.save(settings);
    if (_armed) {
      await disarm();
      await arm();
    }
  }

  /// Starts passive detectors according to current settings.
  Future<void> arm() async {
    if (_armed || _onActivate == null) return;
    await _permissions.ensureBackgroundCapabilities();
    _armed = true;

    if (_settings.shakeEnabled) {
      _shakeDetector.start(
        settings: _settings,
        onShakeDetected: () => requestTrigger(TriggerSource.shake),
      );
    }

    if (_settings.voiceEnabled) {
      await _permissions.ensureSpeech();
      await _voiceTrigger.startListening(
        settings: _settings,
        onPhraseDetected: (_) => requestTrigger(TriggerSource.voice),
      );
    }

    if (_settings.powerButtonEnabled) {
      const requiredPresses = 3;
      await _powerButton.startListening(requiredPresses: requiredPresses);
      _powerSub = _powerButton.pressStream.listen((count) {
        if (count >= requiredPresses) {
          requestTrigger(TriggerSource.powerButton);
        }
      });
    }

    if (_settings.volumeButtonEnabled) {
      const requiredPresses = 3;
      await _volumeButton.startListening(requiredPresses: requiredPresses);
      _volumeSub = _volumeButton.pressStream.listen((count) {
        if (count >= requiredPresses) {
          _openVolumeEmergencyFlow();
        }
      });
    }

    _backgroundSub = FlutterBackgroundService().on("shake_detected").listen((_) {
      requestTrigger(TriggerSource.background);
    });

    if (_settings.aiDetectionEnabled) {
      _motionAi.start(
        settings: _settings,
        onDetection: (event, confidence) {
          requestAiVerification(event, confidence);
        },
      );

      _motionBackgroundSub =
          FlutterBackgroundService().on("motion_detected").listen((data) {
        final typeName = data?["type"] as String?;
        final confidence = (data?["confidence"] as num?)?.toDouble() ?? 0.8;
        final event = _parseMotionEvent(typeName);
        if (event != null) {
          requestAiVerification(event, confidence);
        }
      });
    }
  }

  Future<void> disarm() async {
    _armed = false;
    _shakeDetector.stop();
    await _voiceTrigger.stopListening();
    await _powerButton.stopListening();
    await _volumeButton.stopListening();
    await _powerSub?.cancel();
    _powerSub = null;
    await _volumeSub?.cancel();
    _volumeSub = null;
    await _backgroundSub?.cancel();
    _backgroundSub = null;
    _motionAi.stop();
    await _motionBackgroundSub?.cancel();
    _motionBackgroundSub = null;
  }

  MotionEventType? _parseMotionEvent(String? name) {
    if (name == null) return null;
    for (final e in MotionEventType.values) {
      if (e.name == name) return e;
    }
    return null;
  }

  /// AI motion detection → verification popup → auto SOS if no response.
  Future<void> requestAiVerification(
    MotionEventType event,
    double confidence,
  ) async {
    if (_verificationActive || _countdownActive || _onActivate == null) return;

    final context = _navigatorKey?.currentContext;
    if (context == null) return;

    _verificationActive = true;
    final triggerSos = await EmergencyVerificationDialog.show(
      context,
      eventType: event,
      confidence: confidence,
      responseTimeoutSeconds: _settings.verificationTimeoutSeconds,
      autoSosOnTimeout: _settings.autoSosOnNoResponse,
    );
    _verificationActive = false;

    if (triggerSos) {
      await requestTrigger(event.triggerSource, bypassCountdown: true);
    }
  }

  /// Volume 3x opens the full emergency help flow (Step 2 → 3 → 4).
  void _openVolumeEmergencyFlow() {
    final context = _navigatorKey?.currentContext;
    if (context == null) return;

    EmergencyFlowLauncher.launch(
      context: context,
      source: TriggerSource.volumeButton,
      countdownSeconds: _settings.emergencyCountdownSeconds,
    );
  }

  /// Entry point for any trigger source; applies countdown unless manual + disabled.
  Future<void> requestTrigger(
    TriggerSource source, {
    bool bypassCountdown = false,
  }) async {
    if (_countdownActive || _onActivate == null) return;

    final useCountdown = _settings.countdownEnabled && !bypassCountdown;

    if (useCountdown) {
      await _runCountdown(source);
      return;
    }

    await _activate(source);
  }

  Future<void> _runCountdown(TriggerSource source) async {
    final context = _navigatorKey?.currentContext;
    if (context == null) {
      await _activate(source);
      return;
    }

    _countdownActive = true;
    final confirmed = await EmergencyCountdownDialog.show(
      context,
      seconds: _settings.countdownSeconds,
      source: source,
    );
    _countdownActive = false;

    if (confirmed) {
      await _activate(source);
    }
  }

  Future<void> _activate(TriggerSource source) async {
    final silent = _settings.silentMode || source != TriggerSource.manual;
    var recordAudio = _settings.recordAudioOnTrigger;

    if (recordAudio) {
      final granted = await _permissions.ensureMicrophone();
      recordAudio = granted;
      if (granted) {
        await _audioService.startRecording();
      }
    }

    await _onActivate!(
      source: source,
      silent: silent,
      recordAudio: recordAudio,
    );
  }

  Future<String?> stopAudioCapture() => _audioService.stopRecording();

  void dispose() {
    disarm();
    _motionAi.stop();
    _voiceTrigger.dispose();
    _audioService.dispose();
  }
}
