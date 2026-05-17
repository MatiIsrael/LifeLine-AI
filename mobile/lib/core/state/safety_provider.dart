import "package:flutter/foundation.dart";
import "package:geolocator/geolocator.dart";

import "../safety/danger_zone_service.dart";

class SafetyProvider extends ChangeNotifier {
  final DangerZoneService _service = DangerZoneService();

  int? _riskScore;
  String? _riskLevel;
  List<Map<String, dynamic>> _alerts = [];
  String? _routeRecommendation;
  bool _loading = false;

  int? get riskScore => _riskScore;
  String? get riskLevel => _riskLevel;
  List<Map<String, dynamic>> get alerts => _alerts;
  String? get routeRecommendation => _routeRecommendation;
  bool get loading => _loading;
  bool get hasHighRisk => (_riskScore ?? 0) >= 55;

  Future<void> refreshLocationRisk() async {
    _loading = true;
    notifyListeners();
    try {
      final pos = await Geolocator.getCurrentPosition();
      final alertsRes = await _service.getAlerts(
        lat: pos.latitude,
        lng: pos.longitude,
        speedKmh: pos.speed * 3.6,
      );
      final current = alertsRes["current"] as Map<String, dynamic>? ?? {};
      _riskScore = current["riskScore"] as int?;
      _riskLevel = current["riskLevel"] as String?;
      _alerts = (alertsRes["alerts"] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();
    } catch (_) {
      _riskScore = 42;
      _riskLevel = "medium";
      _alerts = [
        {
          "level": "warning",
          "title": "Safety AI offline",
          "message": "Using last known risk estimate. Enable location for live predictions.",
        },
      ];
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
