import "../models/motion_detection_result.dart";
import "../models/motion_features.dart";

/// TensorFlow Lite hook — loads a .tflite model when added to assets.
///
/// Until `assets/models/motion_classifier.tflite` exists, this returns [MotionDetectionResult.none]
/// and the pipeline uses [EdgeMotionClassifier] rules only.
class TfliteMotionClassifier {
  bool _initialized = false;
  bool _available = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    // Future: Interpreter.fromAsset('assets/models/motion_classifier.tflite')
    _available = false;
  }

  MotionDetectionResult classify(MotionFeatures features) {
    if (!_available) return MotionDetectionResult.none;
    // Future: run interpreter with normalized feature vector input.
    return MotionDetectionResult.none;
  }
}
