import "package:firebase_messaging/firebase_messaging.dart";

import "api_service.dart";

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final ApiService _apiService = ApiService();

  Future<void> initialize() async {
    await _messaging.requestPermission(alert: true, badge: true, sound: true);
    final token = await _messaging.getToken();
    if (token != null) {
      await _apiService.post("/device-token", {"token": token});
    }

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // Hook point for local notification display if needed.
      // In MVP we rely on platform push tray behavior.
      print("Foreground push: ${message.notification?.title}");
    });
  }
}
