/// User-configurable emergency trigger preferences persisted locally.
class EmergencyTriggerSettings {
  final bool silentMode;
  final bool shakeEnabled;
  final bool powerButtonEnabled;
  final bool volumeButtonEnabled;
  final bool voiceEnabled;
  final int emergencyCountdownSeconds;
  final bool backgroundMonitoring;
  final bool recordAudioOnTrigger;
  final bool countdownEnabled;
  final int countdownSeconds;
  final double shakeSensitivity;
  final String voicePhrase;
  final String calculatorSecret;

  // AI motion detection
  final bool aiDetectionEnabled;
  final bool fallDetectionEnabled;
  final bool crashDetectionEnabled;
  final bool panicMovementEnabled;
  final bool abnormalMovementEnabled;
  final bool inactivityDetectionEnabled;
  final double aiSensitivity;
  final int verificationTimeoutSeconds;
  final bool autoSosOnNoResponse;

  const EmergencyTriggerSettings({
    this.silentMode = false,
    this.shakeEnabled = true,
    this.powerButtonEnabled = false,
    this.volumeButtonEnabled = true,
    this.voiceEnabled = false,
    this.emergencyCountdownSeconds = 15,
    this.backgroundMonitoring = true,
    this.recordAudioOnTrigger = false,
    this.countdownEnabled = true,
    this.countdownSeconds = 5,
    this.shakeSensitivity = 0.5,
    this.voicePhrase = "help me now",
    this.calculatorSecret = "911=",
    this.aiDetectionEnabled = true,
    this.fallDetectionEnabled = true,
    this.crashDetectionEnabled = true,
    this.panicMovementEnabled = true,
    this.abnormalMovementEnabled = true,
    this.inactivityDetectionEnabled = true,
    this.aiSensitivity = 0.45,
    this.verificationTimeoutSeconds = 20,
    this.autoSosOnNoResponse = true,
  });

  double get shakeThreshold => 3.2 - (shakeSensitivity * 1.4);

  int get shakePeaksRequired => shakeSensitivity < 0.35 ? 4 : (shakeSensitivity < 0.7 ? 3 : 2);

  EmergencyTriggerSettings copyWith({
    bool? silentMode,
    bool? shakeEnabled,
    bool? powerButtonEnabled,
    bool? volumeButtonEnabled,
    bool? voiceEnabled,
    int? emergencyCountdownSeconds,
    bool? backgroundMonitoring,
    bool? recordAudioOnTrigger,
    bool? countdownEnabled,
    int? countdownSeconds,
    double? shakeSensitivity,
    String? voicePhrase,
    String? calculatorSecret,
    bool? aiDetectionEnabled,
    bool? fallDetectionEnabled,
    bool? crashDetectionEnabled,
    bool? panicMovementEnabled,
    bool? abnormalMovementEnabled,
    bool? inactivityDetectionEnabled,
    double? aiSensitivity,
    int? verificationTimeoutSeconds,
    bool? autoSosOnNoResponse,
  }) {
    return EmergencyTriggerSettings(
      silentMode: silentMode ?? this.silentMode,
      shakeEnabled: shakeEnabled ?? this.shakeEnabled,
      powerButtonEnabled: powerButtonEnabled ?? this.powerButtonEnabled,
      volumeButtonEnabled: volumeButtonEnabled ?? this.volumeButtonEnabled,
      voiceEnabled: voiceEnabled ?? this.voiceEnabled,
      emergencyCountdownSeconds: emergencyCountdownSeconds ?? this.emergencyCountdownSeconds,
      backgroundMonitoring: backgroundMonitoring ?? this.backgroundMonitoring,
      recordAudioOnTrigger: recordAudioOnTrigger ?? this.recordAudioOnTrigger,
      countdownEnabled: countdownEnabled ?? this.countdownEnabled,
      countdownSeconds: countdownSeconds ?? this.countdownSeconds,
      shakeSensitivity: shakeSensitivity ?? this.shakeSensitivity,
      voicePhrase: voicePhrase ?? this.voicePhrase,
      calculatorSecret: calculatorSecret ?? this.calculatorSecret,
      aiDetectionEnabled: aiDetectionEnabled ?? this.aiDetectionEnabled,
      fallDetectionEnabled: fallDetectionEnabled ?? this.fallDetectionEnabled,
      crashDetectionEnabled: crashDetectionEnabled ?? this.crashDetectionEnabled,
      panicMovementEnabled: panicMovementEnabled ?? this.panicMovementEnabled,
      abnormalMovementEnabled: abnormalMovementEnabled ?? this.abnormalMovementEnabled,
      inactivityDetectionEnabled: inactivityDetectionEnabled ?? this.inactivityDetectionEnabled,
      aiSensitivity: aiSensitivity ?? this.aiSensitivity,
      verificationTimeoutSeconds: verificationTimeoutSeconds ?? this.verificationTimeoutSeconds,
      autoSosOnNoResponse: autoSosOnNoResponse ?? this.autoSosOnNoResponse,
    );
  }

  Map<String, dynamic> toJson() => {
        "silentMode": silentMode,
        "shakeEnabled": shakeEnabled,
        "powerButtonEnabled": powerButtonEnabled,
        "volumeButtonEnabled": volumeButtonEnabled,
        "voiceEnabled": voiceEnabled,
        "emergencyCountdownSeconds": emergencyCountdownSeconds,
        "backgroundMonitoring": backgroundMonitoring,
        "recordAudioOnTrigger": recordAudioOnTrigger,
        "countdownEnabled": countdownEnabled,
        "countdownSeconds": countdownSeconds,
        "shakeSensitivity": shakeSensitivity,
        "voicePhrase": voicePhrase,
        "calculatorSecret": calculatorSecret,
        "aiDetectionEnabled": aiDetectionEnabled,
        "fallDetectionEnabled": fallDetectionEnabled,
        "crashDetectionEnabled": crashDetectionEnabled,
        "panicMovementEnabled": panicMovementEnabled,
        "abnormalMovementEnabled": abnormalMovementEnabled,
        "inactivityDetectionEnabled": inactivityDetectionEnabled,
        "aiSensitivity": aiSensitivity,
        "verificationTimeoutSeconds": verificationTimeoutSeconds,
        "autoSosOnNoResponse": autoSosOnNoResponse,
      };

  factory EmergencyTriggerSettings.fromJson(Map<String, dynamic> json) {
    return EmergencyTriggerSettings(
      silentMode: json["silentMode"] as bool? ?? false,
      shakeEnabled: json["shakeEnabled"] as bool? ?? true,
      powerButtonEnabled: json["powerButtonEnabled"] as bool? ?? false,
      volumeButtonEnabled: json["volumeButtonEnabled"] as bool? ?? true,
      voiceEnabled: json["voiceEnabled"] as bool? ?? false,
      emergencyCountdownSeconds: json["emergencyCountdownSeconds"] as int? ?? 15,
      backgroundMonitoring: json["backgroundMonitoring"] as bool? ?? true,
      recordAudioOnTrigger: json["recordAudioOnTrigger"] as bool? ?? false,
      countdownEnabled: json["countdownEnabled"] as bool? ?? true,
      countdownSeconds: json["countdownSeconds"] as int? ?? 5,
      shakeSensitivity: (json["shakeSensitivity"] as num?)?.toDouble() ?? 0.5,
      voicePhrase: json["voicePhrase"] as String? ?? "help me now",
      calculatorSecret: json["calculatorSecret"] as String? ?? "911=",
      aiDetectionEnabled: json["aiDetectionEnabled"] as bool? ?? true,
      fallDetectionEnabled: json["fallDetectionEnabled"] as bool? ?? true,
      crashDetectionEnabled: json["crashDetectionEnabled"] as bool? ?? true,
      panicMovementEnabled: json["panicMovementEnabled"] as bool? ?? true,
      abnormalMovementEnabled: json["abnormalMovementEnabled"] as bool? ?? true,
      inactivityDetectionEnabled: json["inactivityDetectionEnabled"] as bool? ?? true,
      aiSensitivity: (json["aiSensitivity"] as num?)?.toDouble() ?? 0.45,
      verificationTimeoutSeconds: json["verificationTimeoutSeconds"] as int? ?? 20,
      autoSosOnNoResponse: json["autoSosOnNoResponse"] as bool? ?? true,
    );
  }
}
