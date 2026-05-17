import "api_service.dart";

/// Backend helpers for emergency contact linking (FCM delivery).
class ProfileApiService {
  final ApiService _api = ApiService();

  Future<String?> linkContactByEmail(String email) async {
    if (email.trim().isEmpty) return null;
    try {
      final result = await _api.post("/profile/contact/link", {"email": email.trim()});
      return result["contactUid"] as String?;
    } catch (_) {
      return null;
    }
  }
}
