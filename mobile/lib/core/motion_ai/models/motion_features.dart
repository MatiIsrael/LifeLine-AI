/// Engineered feature vector from a sensor window (edge ML input).
class MotionFeatures {
  final double maxAccelG;
  final double minAccelG;
  final double meanAccelG;
  final double accelVariance;
  final double maxJerk;
  final double maxGyroRad;
  final double gyroVariance;
  final int freeFallSamples;
  final int highPeakCount;
  final double postPeakVariance;
  final int sampleCount;

  const MotionFeatures({
    required this.maxAccelG,
    required this.minAccelG,
    required this.meanAccelG,
    required this.accelVariance,
    required this.maxJerk,
    required this.maxGyroRad,
    required this.gyroVariance,
    required this.freeFallSamples,
    required this.highPeakCount,
    required this.postPeakVariance,
    required this.sampleCount,
  });

  static const empty = MotionFeatures(
    maxAccelG: 0,
    minAccelG: 0,
    meanAccelG: 0,
    accelVariance: 0,
    maxJerk: 0,
    maxGyroRad: 0,
    gyroVariance: 0,
    freeFallSamples: 0,
    highPeakCount: 0,
    postPeakVariance: 0,
    sampleCount: 0,
  );
}
