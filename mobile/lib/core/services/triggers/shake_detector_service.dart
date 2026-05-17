import "dart:async";
import "dart:math";

import "package:sensors_plus/sensors_plus.dart";

import "../../models/emergency_trigger_settings.dart";

typedef ShakeCallback = void Function();

/// Detects deliberate shake patterns using accelerometer magnitude peaks.
class ShakeDetectorService {
  StreamSubscription<UserAccelerometerEvent>? _subscription;
  final List<double> _recentPeaks = [];
  DateTime? _lastPeakAt;

  void start({
    required EmergencyTriggerSettings settings,
    required ShakeCallback onShakeDetected,
    Duration sampleInterval = const Duration(milliseconds: 80),
  }) {
    stop();
    _subscription = userAccelerometerEventStream(
      samplingPeriod: SensorInterval.normalInterval,
    ).listen((event) {
      final magnitude = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
      if (magnitude >= settings.shakeThreshold) {
        final now = DateTime.now();
        if (_lastPeakAt != null && now.difference(_lastPeakAt!) < sampleInterval) {
          return;
        }
        _lastPeakAt = now;
        _recentPeaks.add(magnitude);
        if (_recentPeaks.length > 12) {
          _recentPeaks.removeAt(0);
        }
        if (_recentPeaks.length >= settings.shakePeaksRequired) {
          _recentPeaks.clear();
          onShakeDetected();
        }
      }
    });
  }

  void stop() {
    _subscription?.cancel();
    _subscription = null;
    _recentPeaks.clear();
    _lastPeakAt = null;
  }
}
