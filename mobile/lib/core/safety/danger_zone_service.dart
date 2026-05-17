import "dart:convert";

import "package:http/http.dart" as http;

import "../services/app_constants.dart";

/// AI danger-zone predictions from Lifeline backend.
class DangerZoneService {
  static const _publicBase = "/api/public/safety";

  Future<Map<String, dynamic>> getRiskAt(double lat, double lng) async {
    final res = await http.get(
      Uri.parse("${AppConstants.apiBaseUrl}$_publicBase/risk?lat=$lat&lng=$lng"),
    );
    return _decode(res);
  }

  Future<Map<String, dynamic>> getAlerts({
    required double lat,
    required double lng,
    double speedKmh = 0,
  }) async {
    final res = await http.get(
      Uri.parse(
        "${AppConstants.apiBaseUrl}$_publicBase/alerts?lat=$lat&lng=$lng&speedKmh=$speedKmh",
      ),
    );
    return _decode(res);
  }

  Future<Map<String, dynamic>> analyzeRoute({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
  }) async {
    final res = await http.post(
      Uri.parse("${AppConstants.apiBaseUrl}$_publicBase/route-safety"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "origin": {"lat": originLat, "lng": originLng},
        "destination": {"lat": destLat, "lng": destLng},
      }),
    );
    return _decode(res);
  }

  Map<String, dynamic> _decode(http.Response res) {
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(data["message"] ?? "Safety API failed");
    }
    return data;
  }
}
