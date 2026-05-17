import "dart:async";
import "dart:math";
import "dart:ui";

import "package:flutter/material.dart";
import "package:flutter_background_service/flutter_background_service.dart";
import "package:flutter_local_notifications/flutter_local_notifications.dart";
import "package:sensors_plus/sensors_plus.dart";

import "../../motion_ai/config/motion_detection_thresholds.dart";
import "../../motion_ai/pipeline/motion_detection_pipeline.dart";
import "../../motion_ai/pipeline/motion_sensor_sample.dart";
import "../../models/emergency_trigger_settings.dart";
import "../triggers/trigger_settings_repository.dart";

/// Foreground service: edge AI motion pipeline + legacy shake fallback.
class BackgroundMonitorService {
  static const _notificationChannelId = "lifeline_protection";
  static const _notificationId = 9911;

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    await _notifications.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings("@mipmap/ic_launcher"),
      ),
    );

    final service = FlutterBackgroundService();
    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onBackgroundStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: _notificationChannelId,
        initialNotificationTitle: "Lifeline AI",
        initialNotificationContent: "AI emergency protection active",
        foregroundServiceNotificationId: _notificationId,
        foregroundServiceTypes: [AndroidForegroundType.location],
      ),
      iosConfiguration: IosConfiguration(
        onForeground: onBackgroundStart,
        onBackground: onIosBackground,
      ),
    );
  }

  Future<void> start() async {
    final service = FlutterBackgroundService();
    if (!await service.isRunning()) {
      await service.startService();
    }
  }

  Future<void> stop() async {
    final service = FlutterBackgroundService();
    if (await service.isRunning()) {
      service.invoke("stop");
    }
  }

  @pragma("vm:entry-point")
  static Future<bool> onIosBackground(ServiceInstance service) async {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();
    return true;
  }

  @pragma("vm:entry-point")
  static void onBackgroundStart(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();

    final settings = await TriggerSettingsRepository().load();
    if (!settings.backgroundMonitoring) {
      service.stopSelf();
      return;
    }

    StreamSubscription<AccelerometerEvent>? accelSub;
    StreamSubscription<GyroscopeEvent>? gyroSub;
    Timer? batchTimer;
    MotionDetectionPipeline? pipeline;

    AccelerometerEvent? latestAccel;
    GyroscopeEvent? latestGyro;

    if (settings.aiDetectionEnabled) {
      final thresholds = MotionDetectionThresholds.fromSensitivity(settings.aiSensitivity);
      pipeline = MotionDetectionPipeline(thresholds: thresholds);

      accelSub = accelerometerEventStream(
        samplingPeriod: SensorInterval.normalInterval,
      ).listen((e) => latestAccel = e);

      gyroSub = gyroscopeEventStream(
        samplingPeriod: SensorInterval.normalInterval,
      ).listen((e) => latestGyro = e);

      batchTimer = Timer.periodic(thresholds.batchInterval, (_) {
        final accel = latestAccel;
        if (accel == null || pipeline == null) return;

        final accelG = sqrt(accel.x * accel.x + accel.y * accel.y + accel.z * accel.z) / 9.81;
        final gyro = latestGyro;
        final gyroRad = gyro == null
            ? 0.0
            : sqrt(gyro.x * gyro.x + gyro.y * gyro.y + gyro.z * gyro.z);

        final result = pipeline.ingestSample(MotionSensorSample(
          accelG: accelG,
          gyroRad: gyroRad,
          timestamp: DateTime.now(),
        ));

        if (result.shouldVerify && result.event != null) {
          service.invoke("motion_detected", {
            "type": result.event!.name,
            "confidence": result.confidence,
          });
        }
      });
    }

    service.on("stop").listen((_) {
      batchTimer?.cancel();
      accelSub?.cancel();
      gyroSub?.cancel();
      pipeline?.stop();
      service.stopSelf();
    });
  }
}
