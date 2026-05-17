import "package:flutter/material.dart";

import "../models/trigger_source.dart";
import "../../features/sos/emergency_help_screen.dart";

/// Opens the Step 2 emergency help UI (volume 3x and similar triggers).
class EmergencyFlowLauncher {
  static bool _isOpen = false;

  static Future<void> launch({
    required BuildContext context,
    required TriggerSource source,
    int countdownSeconds = 15,
  }) async {
    if (_isOpen) return;
    _isOpen = true;

    await Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => EmergencyHelpScreen(
          source: source,
          countdownSeconds: countdownSeconds,
        ),
      ),
    );

    _isOpen = false;
  }
}
