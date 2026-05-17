import "package:shared_preferences/shared_preferences.dart";

import "models/offline_emergency_settings.dart";

class OfflineSettingsStore {
  static const _prefix = "offline_emergency_";

  Future<OfflineEmergencySettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    return OfflineEmergencySettings(
      offlineFirstEnabled: prefs.getBool("${_prefix}offline_first") ?? true,
      smsFallbackEnabled: prefs.getBool("${_prefix}sms") ?? true,
      meshRelayEnabled: prefs.getBool("${_prefix}mesh") ?? true,
      weakInternetOptimization: prefs.getBool("${_prefix}weak_net") ?? true,
    );
  }

  Future<void> save(OfflineEmergencySettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("${_prefix}offline_first", settings.offlineFirstEnabled);
    await prefs.setBool("${_prefix}sms", settings.smsFallbackEnabled);
    await prefs.setBool("${_prefix}mesh", settings.meshRelayEnabled);
    await prefs.setBool("${_prefix}weak_net", settings.weakInternetOptimization);
  }
}
