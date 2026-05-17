import "motion_event_type.dart";

/// Output of the edge classifier for one analysis window.
class MotionDetectionResult {
  final MotionEventType? event;
  final double confidence;
  final bool shouldVerify;

  const MotionDetectionResult({
    this.event,
    required this.confidence,
    required this.shouldVerify,
  });

  static const none = MotionDetectionResult(confidence: 0, shouldVerify: false);
}
