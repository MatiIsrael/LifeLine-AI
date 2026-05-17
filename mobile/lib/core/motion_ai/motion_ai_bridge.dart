import "../models/trigger_source.dart";
import "models/motion_event_type.dart";

/// Maps motion AI events to SOS trigger sources for the API layer.
extension MotionEventTriggerBridge on MotionEventType {
  TriggerSource get triggerSource {
    switch (this) {
      case MotionEventType.fall:
        return TriggerSource.fallDetection;
      case MotionEventType.carCrash:
        return TriggerSource.crashDetection;
      case MotionEventType.panicMovement:
        return TriggerSource.panicMovement;
      case MotionEventType.abnormalMovement:
        return TriggerSource.abnormalMovement;
      case MotionEventType.unconsciousInactivity:
        return TriggerSource.inactivityDetection;
    }
  }
}
