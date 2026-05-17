import "dart:async";
import "dart:math";

import "package:sensors_plus/sensors_plus.dart";

import "../config/motion_detection_thresholds.dart";
import "../models/motion_detection_result.dart";
import "../models/motion_event_type.dart";
import "edge_motion_classifier.dart";
import "motion_feature_extractor.dart";
import "motion_sensor_sample.dart";

typedef MotionDetectionCallback = void Function(MotionEventType event, double confidence);

/// Sensor processing pipeline: sample → window → features → classify.
class MotionDetectionPipeline {
  final MotionDetectionThresholds thresholds;
  final MotionFeatureExtractor _extractor = MotionFeatureExtractor();
  late final EdgeMotionClassifier _classifier;

  final List<MotionSensorSample> _window = [];
  StreamSubscription<AccelerometerEvent>? _accelSub;
  StreamSubscription<GyroscopeEvent>? _gyroSub;
  Timer? _batchTimer;

  AccelerometerEvent? _latestAccel;
  GyroscopeEvent? _latestGyro;
  MotionDetectionCallback? _onDetection;
  bool _running = false;

  MotionDetectionPipeline({required this.thresholds}) {
    _classifier = EdgeMotionClassifier(thresholds);
  }

  void start({required MotionDetectionCallback onDetection}) {
    if (_running) return;
    _running = true;
    _onDetection = onDetection;

    _accelSub = accelerometerEventStream(
      samplingPeriod: SensorInterval.normalInterval,
    ).listen((e) => _latestAccel = e);

    _gyroSub = gyroscopeEventStream(
      samplingPeriod: SensorInterval.normalInterval,
    ).listen((e) => _latestGyro = e);

    _batchTimer = Timer.periodic(thresholds.batchInterval, (_) => _tick());
  }

  void stop() {
    _running = false;
    _batchTimer?.cancel();
    _accelSub?.cancel();
    _gyroSub?.cancel();
    _window.clear();
    _classifier.reset();
    _onDetection = null;
  }

  void _tick() {
    final accel = _latestAccel;
    if (accel == null) return;

    final accelG = sqrt(accel.x * accel.x + accel.y * accel.y + accel.z * accel.z) / 9.81;
    final gyro = _latestGyro;
    final gyroRad = gyro == null
        ? 0.0
        : sqrt(gyro.x * gyro.x + gyro.y * gyro.y + gyro.z * gyro.z);

    _window.add(MotionSensorSample(
      accelG: accelG,
      gyroRad: gyroRad,
      timestamp: DateTime.now(),
    ));

    while (_window.length > thresholds.windowSize) {
      _window.removeAt(0);
    }

    if (_window.length < thresholds.windowSize ~/ 2) return;

    final features = _extractor.extract(_window);
    final result = _classifier.classify(features);

    if (result.shouldVerify && result.event != null) {
      _onDetection?.call(result.event!, result.confidence);
    }
  }

  /// Process a single pre-built sample (for unit tests / background isolate).
  MotionDetectionResult ingestSample(MotionSensorSample sample) {
    _window.add(sample);
    while (_window.length > thresholds.windowSize) {
      _window.removeAt(0);
    }
    final features = _extractor.extract(_window);
    return _classifier.classify(features);
  }
}
