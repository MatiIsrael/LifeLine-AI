/// Types of AI-inferred emergency motion events.
enum MotionEventType {
  fall,
  carCrash,
  abnormalMovement,
  panicMovement,
  unconsciousInactivity,
}

extension MotionEventTypeX on MotionEventType {
  String get label {
    switch (this) {
      case MotionEventType.fall:
        return "Fall detected";
      case MotionEventType.carCrash:
        return "Possible car crash";
      case MotionEventType.abnormalMovement:
        return "Sudden abnormal movement";
      case MotionEventType.panicMovement:
        return "Panic movement pattern";
      case MotionEventType.unconsciousInactivity:
        return "Unconscious inactivity";
    }
  }

  String get description {
    switch (this) {
      case MotionEventType.fall:
        return "A free-fall followed by high impact was detected.";
      case MotionEventType.carCrash:
        return "A high-impact deceleration pattern was detected.";
      case MotionEventType.abnormalMovement:
        return "A sudden irregular motion spike was detected.";
      case MotionEventType.panicMovement:
        return "Rapid erratic movement consistent with distress.";
      case MotionEventType.unconsciousInactivity:
        return "No movement after a possible incident.";
    }
  }
}
