/// User preferences for offline / rural emergency delivery.
class OfflineEmergencySettings {
  final bool offlineFirstEnabled;
  final bool smsFallbackEnabled;
  final bool meshRelayEnabled;
  final bool weakInternetOptimization;

  const OfflineEmergencySettings({
    this.offlineFirstEnabled = true,
    this.smsFallbackEnabled = true,
    this.meshRelayEnabled = true,
    this.weakInternetOptimization = true,
  });

  OfflineEmergencySettings copyWith({
    bool? offlineFirstEnabled,
    bool? smsFallbackEnabled,
    bool? meshRelayEnabled,
    bool? weakInternetOptimization,
  }) {
    return OfflineEmergencySettings(
      offlineFirstEnabled: offlineFirstEnabled ?? this.offlineFirstEnabled,
      smsFallbackEnabled: smsFallbackEnabled ?? this.smsFallbackEnabled,
      meshRelayEnabled: meshRelayEnabled ?? this.meshRelayEnabled,
      weakInternetOptimization: weakInternetOptimization ?? this.weakInternetOptimization,
    );
  }
}
