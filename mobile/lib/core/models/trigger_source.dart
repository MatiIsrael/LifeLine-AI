/// Identifies which detection path initiated an emergency flow.
enum TriggerSource {
  manual("manual"),
  shake("shake"),
  powerButton("power_button"),
  volumeButton("volume_button"),
  voice("voice"),
  calculator("calculator"),
  background("background"),
  fallDetection("fall_detection"),
  crashDetection("crash_detection"),
  panicMovement("panic_movement"),
  abnormalMovement("abnormal_movement"),
  inactivityDetection("inactivity_detection");

  const TriggerSource(this.apiValue);
  final String apiValue;

  String get label {
    switch (this) {
      case TriggerSource.manual:
        return "Manual SOS";
      case TriggerSource.shake:
        return "Shake detection";
      case TriggerSource.powerButton:
        return "Power button";
      case TriggerSource.volumeButton:
        return "Volume button (3x)";
      case TriggerSource.voice:
        return "Voice command";
      case TriggerSource.calculator:
        return "Calculator disguise";
      case TriggerSource.background:
        return "Background monitor";
      case TriggerSource.fallDetection:
        return "Fall detection";
      case TriggerSource.crashDetection:
        return "Crash detection";
      case TriggerSource.panicMovement:
        return "Panic movement";
      case TriggerSource.abnormalMovement:
        return "Abnormal movement";
      case TriggerSource.inactivityDetection:
        return "Inactivity detection";
    }
  }
}
