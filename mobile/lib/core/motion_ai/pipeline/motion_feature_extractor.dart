import "dart:math";

import "../models/motion_features.dart";
import "motion_sensor_sample.dart";

/// Converts a sliding window of sensor samples into ML features.
class MotionFeatureExtractor {
  MotionFeatures extract(List<MotionSensorSample> window) {
    if (window.length < 8) return MotionFeatures.empty;

    final magnitudes = window.map((s) => s.accelG).toList();
    final gyros = window.map((s) => s.gyroRad).toList();

    final maxAccel = magnitudes.reduce(max);
    final minAccel = magnitudes.reduce(min);
    final meanAccel = magnitudes.reduce((a, b) => a + b) / magnitudes.length;

    var variance = 0.0;
    for (final m in magnitudes) {
      variance += pow(m - meanAccel, 2);
    }
    variance /= magnitudes.length;

    var maxJerk = 0.0;
    for (var i = 1; i < magnitudes.length; i++) {
      final jerk = (magnitudes[i] - magnitudes[i - 1]).abs();
      if (jerk > maxJerk) maxJerk = jerk;
    }

    final maxGyro = gyros.reduce(max);
    var gyroVar = 0.0;
    final meanGyro = gyros.reduce((a, b) => a + b) / gyros.length;
    for (final g in gyros) {
      gyroVar += pow(g - meanGyro, 2);
    }
    gyroVar /= gyros.length;

    const freeFallG = 0.5;
    final freeFallSamples = magnitudes.where((m) => m < freeFallG).length;
    final highPeakCount = magnitudes.where((m) => m > 2.5).length;

    final peakIndex = magnitudes.indexOf(maxAccel);
    final postPeak = magnitudes.sublist(peakIndex.clamp(0, magnitudes.length - 1));
    var postVariance = 0.0;
    if (postPeak.length > 4) {
      final postMean = postPeak.reduce((a, b) => a + b) / postPeak.length;
      for (final m in postPeak) {
        postVariance += pow(m - postMean, 2);
      }
      postVariance /= postPeak.length;
    }

    return MotionFeatures(
      maxAccelG: maxAccel,
      minAccelG: minAccel,
      meanAccelG: meanAccel,
      accelVariance: variance,
      maxJerk: maxJerk,
      maxGyroRad: maxGyro,
      gyroVariance: gyroVar,
      freeFallSamples: freeFallSamples,
      highPeakCount: highPeakCount,
      postPeakVariance: postVariance,
      sampleCount: window.length,
    );
  }
}
