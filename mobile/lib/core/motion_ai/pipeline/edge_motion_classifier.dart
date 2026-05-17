import "../config/motion_detection_thresholds.dart";
import "../models/motion_detection_result.dart";
import "../models/motion_event_type.dart";
import "../models/motion_features.dart";
import "tflite_motion_classifier.dart";

/// Rule-based edge classifier with optional TFLite override hook.
class EdgeMotionClassifier {
  final MotionDetectionThresholds thresholds;
  final TfliteMotionClassifier _tflite = TfliteMotionClassifier();

  DateTime? _lastAlertAt;
  DateTime? _lastHighImpactAt;
  int _inactivityStreak = 0;

  EdgeMotionClassifier(this.thresholds);

  MotionDetectionResult classify(MotionFeatures features) {
    if (features.sampleCount < 16) return MotionDetectionResult.none;

    if (_isInCooldown()) return MotionDetectionResult.none;

    // Optional TFLite path when a model is bundled later.
    final tflite = _tflite.classify(features);
    if (tflite.shouldVerify) return tflite;

    return _ruleBasedClassify(features);
  }

  MotionDetectionResult _ruleBasedClassify(MotionFeatures f) {
    final scores = <MotionEventType, double>{};

    // Fall: free-fall phase then impact.
    if (f.freeFallSamples >= thresholds.minFreeFallSamples &&
        f.minAccelG < thresholds.freeFallG &&
        f.maxAccelG >= thresholds.fallImpactG) {
      scores[MotionEventType.fall] = 0.92;
    }

    // Car crash: very high impact + post-impact stillness.
    if (f.maxAccelG >= thresholds.crashImpactG &&
        f.postPeakVariance < thresholds.inactivityVariance * 2) {
      scores[MotionEventType.carCrash] = 0.88;
    }

    // Panic: repeated high peaks + erratic gyro.
    if (f.highPeakCount >= thresholds.panicPeakCount &&
        f.gyroVariance >= thresholds.panicGyroVariance &&
        f.meanAccelG > 1.1) {
      scores[MotionEventType.panicMovement] = 0.84;
    }

    // Abnormal jerk without matching fall/crash signature.
    if (f.maxJerk >= thresholds.abnormalJerkG &&
        (scores[MotionEventType.fall] ?? 0) < 0.5 &&
        (scores[MotionEventType.carCrash] ?? 0) < 0.5) {
      scores[MotionEventType.abnormalMovement] = 0.78;
    }

    if (f.maxAccelG >= thresholds.impactG) {
      _lastHighImpactAt = DateTime.now();
    }

    // Inactivity after impact: possible unconsciousness.
    if (_lastHighImpactAt != null &&
        DateTime.now().difference(_lastHighImpactAt!) < const Duration(minutes: 3)) {
      if (f.accelVariance < thresholds.inactivityVariance &&
          f.maxAccelG < thresholds.impactG) {
        _inactivityStreak++;
      } else {
        _inactivityStreak = 0;
      }
      if (_inactivityStreak >= thresholds.inactivitySamples) {
        scores[MotionEventType.unconsciousInactivity] = 0.8;
        _inactivityStreak = 0;
      }
    }

    if (scores.isEmpty) return MotionDetectionResult.none;

    final best = scores.entries.reduce((a, b) => a.value >= b.value ? a : b);
    if (best.value < thresholds.minConfidence) return MotionDetectionResult.none;

    _lastAlertAt = DateTime.now();
    return MotionDetectionResult(
      event: best.key,
      confidence: best.value,
      shouldVerify: true,
    );
  }

  bool _isInCooldown() {
    if (_lastAlertAt == null) return false;
    return DateTime.now().difference(_lastAlertAt!) < thresholds.cooldown;
  }

  void reset() {
    _lastAlertAt = null;
    _lastHighImpactAt = null;
    _inactivityStreak = 0;
  }
}
