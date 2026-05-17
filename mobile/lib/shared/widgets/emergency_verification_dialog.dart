import "dart:async";

import "package:flutter/material.dart";
import "package:flutter/services.dart";

import "../../core/motion_ai/models/motion_event_type.dart";

/// AI detection verification — user must respond or SOS auto-triggers.
class EmergencyVerificationDialog extends StatefulWidget {
  final MotionEventType eventType;
  final double confidence;
  final int responseTimeoutSeconds;
  final bool autoSosOnTimeout;

  const EmergencyVerificationDialog({
    super.key,
    required this.eventType,
    required this.confidence,
    this.responseTimeoutSeconds = 20,
    this.autoSosOnTimeout = true,
  });

  /// Returns true if user confirmed emergency (SOS), false if dismissed safe.
  static Future<bool> show(
    BuildContext context, {
    required MotionEventType eventType,
    required double confidence,
    int responseTimeoutSeconds = 20,
    bool autoSosOnTimeout = true,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => EmergencyVerificationDialog(
        eventType: eventType,
        confidence: confidence,
        responseTimeoutSeconds: responseTimeoutSeconds,
        autoSosOnTimeout: autoSosOnTimeout,
      ),
    ).then((v) => v ?? autoSosOnTimeout);
  }

  @override
  State<EmergencyVerificationDialog> createState() => _EmergencyVerificationDialogState();
}

class _EmergencyVerificationDialogState extends State<EmergencyVerificationDialog> {
  Timer? _timer;
  int _secondsLeft = 20;

  @override
  void initState() {
    super.initState();
    _secondsLeft = widget.responseTimeoutSeconds;
    HapticFeedback.heavyImpact();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (_secondsLeft <= 1) {
        t.cancel();
        if (mounted) Navigator.of(context).pop(widget.autoSosOnTimeout);
        return;
      }
      setState(() => _secondsLeft -= 1);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF141418),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          const Icon(Icons.sensors, color: Color(0xFF42A5F5)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              widget.eventType.label,
              style: const TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.eventType.description),
          const SizedBox(height: 12),
          Text(
            "Confidence: ${(widget.confidence * 100).toStringAsFixed(0)}%",
            style: const TextStyle(color: Colors.white54, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Text(
            "Auto-alert in $_secondsLeft s if no response",
            style: const TextStyle(
              color: Color(0xFFE53935),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text("I'm OK"),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: const Color(0xFFE53935)),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text("Need Help"),
        ),
      ],
    );
  }
}
