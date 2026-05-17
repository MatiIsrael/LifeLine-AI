import "dart:async";

import "../../models/emergency_trigger_settings.dart";
import "../config/motion_detection_thresholds.dart";
import "../models/motion_event_type.dart";
import "../pipeline/motion_detection_pipeline.dart";

typedef MotionAiCallback = void Function(MotionEventType event, double confidence);

/// Foreground motion AI monitor — wraps the detection pipeline.
class MotionAiMonitorService {
  MotionDetectionPipeline? _pipeline;
  StreamSubscription? _backgroundSub;

  bool get isRunning => _pipeline != null;

  void start({
    required EmergencyTriggerSettings settings,
    required MotionAiCallback onDetection,
  }) {
    if (!settings.aiDetectionEnabled) return;
    stop();

    final thresholds = MotionDetectionThresholds.fromSensitivity(settings.aiSensitivity);
    _pipeline = MotionDetectionPipeline(thresholds: thresholds);

    _pipeline!.start(onDetection: (event, confidence) {
      if (!_isEnabledForEvent(settings, event)) return;
      onDetection(event, confidence);
    });
  }

  void stop() {
    _pipeline?.stop();
    _pipeline = null;
    _backgroundSub?.cancel();
    _backgroundSub = null;
  }

  bool _isEnabledForEvent(EmergencyTriggerSettings s, MotionEventType event) {
    switch (event) {
      case MotionEventType.fall:
        return s.fallDetectionEnabled;
      case MotionEventType.carCrash:
        return s.crashDetectionEnabled;
      case MotionEventType.abnormalMovement:
        return s.abnormalMovementEnabled;
      case MotionEventType.panicMovement:
        return s.panicMovementEnabled;
      case MotionEventType.unconsciousInactivity:
        return s.inactivityDetectionEnabled;
    }
  }
}
