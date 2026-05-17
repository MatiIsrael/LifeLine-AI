import "dart:async";

import "package:flutter/material.dart";
import "package:flutter/services.dart";

import "../../core/models/trigger_source.dart";

/// Modal countdown with cancel to prevent accidental SOS activation.
class EmergencyCountdownDialog extends StatefulWidget {
  final int seconds;
  final TriggerSource source;

  const EmergencyCountdownDialog({
    super.key,
    required this.seconds,
    required this.source,
  });

  static Future<bool> show(
    BuildContext context, {
    required int seconds,
    required TriggerSource source,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => EmergencyCountdownDialog(seconds: seconds, source: source),
    ).then((value) => value ?? false);
  }

  @override
  State<EmergencyCountdownDialog> createState() => _EmergencyCountdownDialogState();
}

class _EmergencyCountdownDialogState extends State<EmergencyCountdownDialog> {
  late int _remaining;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _remaining = widget.seconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_remaining <= 1) {
        t.cancel();
        if (mounted) Navigator.of(context).pop(true);
        return;
      }
      if (_remaining <= 3) {
        HapticFeedback.heavyImpact();
      }
      setState(() => _remaining -= 1);
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
      backgroundColor: const Color(0xFF161B22),
      title: const Text("Emergency countdown"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "$_remaining",
            style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.redAccent),
          ),
          const SizedBox(height: 8),
          Text("Source: ${widget.source.label}"),
          const SizedBox(height: 8),
          const Text("Tap cancel if this was accidental."),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text("Cancel alert"),
        ),
      ],
    );
  }
}
