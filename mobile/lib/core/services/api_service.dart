import "dart:convert";

import "package:http/http.dart" as http;

import "app_constants.dart";
import "auth_service.dart";

class ApiService {
  final AuthService _authService = AuthService();

  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) async {
    final token = await _authService.getIdToken();
    final response = await http.post(
      Uri.parse("${AppConstants.apiBaseUrl}$path"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> get(String path) async {
    final token = await _authService.getIdToken();
    final response = await http.get(
      Uri.parse("${AppConstants.apiBaseUrl}$path"),
      headers: {
        "Authorization": "Bearer $token",
      },
    );
    return _handleResponse(response);
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(data["message"] ?? "Request failed.");
    }
    return data;
  }
}
