/// Tunable thresholds for edge motion classification (scales with sensitivity).
class MotionDetectionThresholds {
  final double impactG;
  final double fallImpactG;
  final double freeFallG;
  final int minFreeFallSamples;
  final double crashImpactG;
  final double panicGyroVariance;
  final int panicPeakCount;
  final double abnormalJerkG;
  final double inactivityVariance;
  final int inactivitySamples;
  final double minConfidence;
  final Duration cooldown;
  final Duration batchInterval;
  final int windowSize;

  const MotionDetectionThresholds({
    required this.impactG,
    required this.fallImpactG,
    required this.freeFallG,
    required this.minFreeFallSamples,
    required this.crashImpactG,
    required this.panicGyroVariance,
    required this.panicPeakCount,
    required this.abnormalJerkG,
    required this.inactivityVariance,
    required this.inactivitySamples,
    required this.minConfidence,
    required this.cooldown,
    required this.batchInterval,
    required this.windowSize,
  });

  /// sensitivity 0 = strict (fewer false positives), 1 = sensitive.
  factory MotionDetectionThresholds.fromSensitivity(double sensitivity) {
    final s = sensitivity.clamp(0.0, 1.0);
    final strict = 1.0 - s;

    return MotionDetectionThresholds(
      impactG: 2.4 + strict * 0.8,
      fallImpactG: 2.6 + strict * 0.6,
      freeFallG: 0.45 + strict * 0.1,
      minFreeFallSamples: (4 - s * 2).round().clamp(2, 4),
      crashImpactG: 4.0 + strict * 1.2,
      panicGyroVariance: 0.8 + strict * 0.6,
      panicPeakCount: (5 - s * 2).round().clamp(3, 5),
      abnormalJerkG: 2.8 + strict * 1.0,
      inactivityVariance: 0.04 + strict * 0.04,
      inactivitySamples: (50 - s * 15).round().clamp(30, 50),
      minConfidence: 0.72 + strict * 0.12,
      cooldown: Duration(seconds: (300 - s * 120).round()),
      batchInterval: Duration(milliseconds: (220 - s * 40).round()),
      windowSize: 64,
    );
  }
}
