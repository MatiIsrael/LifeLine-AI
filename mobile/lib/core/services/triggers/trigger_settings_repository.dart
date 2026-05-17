import "dart:convert";

import "package:shared_preferences/shared_preferences.dart";

import "../../models/emergency_trigger_settings.dart";

/// Persists trigger configuration locally for offline access.
class TriggerSettingsRepository {
  static const _key = "emergency_trigger_settings_v1";

  Future<EmergencyTriggerSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return const EmergencyTriggerSettings();
    return EmergencyTriggerSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> save(EmergencyTriggerSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(settings.toJson()));
  }
}
