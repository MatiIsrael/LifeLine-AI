import "dart:async";

import "package:flutter/services.dart";

/// Native bridge for triple volume-button press detection (Android).
class VolumeButtonChannel {
  static const _method = MethodChannel("lifeline/volume_button");
  static const _events = EventChannel("lifeline/volume_button_events");

  Stream<int>? _pressStream;

  Stream<int> get pressStream {
    _pressStream ??= _events.receiveBroadcastStream().map((e) => e as int);
    return _pressStream!;
  }

  Future<void> startListening({required int requiredPresses, int windowMs = 2500}) async {
    await _method.invokeMethod("startListening", {
      "requiredPresses": requiredPresses,
      "windowMs": windowMs,
    });
  }

  Future<void> stopListening() async {
    await _method.invokeMethod("stopListening");
  }
}
