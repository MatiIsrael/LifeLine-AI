/// Single fused accelerometer + gyroscope reading (device frame).
class MotionSensorSample {
  final double accelG;
  final double gyroRad;
  final DateTime timestamp;

  const MotionSensorSample({
    required this.accelG,
    required this.gyroRad,
    required this.timestamp,
  });
}
