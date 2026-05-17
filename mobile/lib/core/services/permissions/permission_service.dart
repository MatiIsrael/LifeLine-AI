import "package:permission_handler/permission_handler.dart";

/// Centralized runtime permission requests for emergency features.
class PermissionService {
  Future<bool> ensureLocation() async {
    var status = await Permission.locationWhenInUse.status;
    if (!status.isGranted) {
      status = await Permission.locationWhenInUse.request();
    }
    if (status.isGranted) {
      final bg = await Permission.locationAlways.request();
      return bg.isGranted || status.isGranted;
    }
    return false;
  }

  Future<bool> ensureMicrophone() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  Future<bool> ensureNotifications() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  Future<bool> ensureSpeech() async {
    final mic = await ensureMicrophone();
    return mic;
  }

  /// Android 13+ requires explicit notification permission for foreground service.
  Future<bool> ensureBackgroundCapabilities() async {
    final notifications = await ensureNotifications();
    final location = await ensureLocation();
    return notifications && location;
  }

  Future<void> openBatteryOptimizationSettings() async {
    await openAppSettings();
  }
}
