import "package:flutter/material.dart";
import "package:provider/provider.dart";

import "../../core/models/trigger_source.dart";
import "../../core/services/triggers/emergency_trigger_coordinator.dart";
import "../../core/state/trigger_settings_provider.dart";

/// Disguised calculator UI; secret sequence triggers hidden SOS.
class FakeCalculatorScreen extends StatefulWidget {
  const FakeCalculatorScreen({super.key});

  @override
  State<FakeCalculatorScreen> createState() => _FakeCalculatorScreenState();
}

class _FakeCalculatorScreenState extends State<FakeCalculatorScreen> {
  String _display = "0";
  String _expression = "";

  void _onTap(String value) {
    setState(() {
      if (value == "C") {
        _display = "0";
        _expression = "";
        return;
      }
      if (value == "=") {
        _expression += "=";
        _display = _evaluate();
      } else {
        _expression += value;
        _display = _expression;
      }
    });

    final secret = context.read<TriggerSettingsProvider>().settings.calculatorSecret;
    if (_expression.endsWith(secret)) {
      _expression = "";
      _display = "0";
      EmergencyTriggerCoordinator.instance.requestTrigger(
        TriggerSource.calculator,
      );
    }
  }

  String _evaluate() {
    try {
      // Simple demo evaluator for disguise screen only.
      final sanitized = _expression.replaceAll("=", "");
      if (sanitized.isEmpty) return "0";
      return "OK";
    } catch (_) {
      return "Error";
    }
  }

  @override
  Widget build(BuildContext context) {
    final keys = ["7", "8", "9", "/", "4", "5", "6", "*", "1", "2", "3", "-", "C", "0", "=", "+"];

    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C1C1E),
        title: const Text("Calculator"),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              alignment: Alignment.bottomRight,
              padding: const EdgeInsets.all(24),
              child: Text(
                _display,
                style: const TextStyle(fontSize: 56, color: Colors.white, fontWeight: FontWeight.w300),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
            ),
            itemCount: keys.length,
            itemBuilder: (context, index) {
              final key = keys[index];
              final isAction = key == "=" || key == "C";
              return ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isAction ? const Color(0xFFFF9F0A) : const Color(0xFF333333),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
                ),
                onPressed: () => _onTap(key),
                child: Text(key, style: const TextStyle(fontSize: 22)),
              );
            },
          ),
        ],
      ),
    );
  }
}
