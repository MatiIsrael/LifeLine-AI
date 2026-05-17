import "dart:async";
import "dart:convert";
import "dart:io";

import "package:flutter_blue_plus/flutter_blue_plus.dart";
import "package:permission_handler/permission_handler.dart";

import "../models/relay_packet.dart";

/// BLE peer relay — scans for nearby Lifeline devices and exchanges SOS packets.
class BluetoothMeshService {
  static final Guid serviceUuid = Guid("6e400001-b5a3-f393-e0a9-e50e24dcca9e");
  static final Guid relayCharUuid = Guid("6e400002-b5a3-f393-e0a9-e50e24dcca9e");

  final _incoming = StreamController<RelayPacket>.broadcast();
  Stream<RelayPacket> get incoming => _incoming.stream;

  bool _running = false;
  StreamSubscription? _scanSub;

  Future<bool> ensurePermissions() async {
    if (!Platform.isAndroid && !Platform.isIOS) return false;
    if (Platform.isAndroid) {
      await Permission.bluetoothScan.request();
      await Permission.bluetoothAdvertise.request();
      await Permission.bluetoothConnect.request();
    }
    await Permission.locationWhenInUse.request();
    return FlutterBluePlus.isSupported;
  }

  Future<void> start() async {
    if (_running) return;
    if (!await ensurePermissions()) return;
    _running = true;

    _scanSub = FlutterBluePlus.scanResults.listen((results) async {
      for (final r in results) {
        if (r.device.remoteId.str.isEmpty) continue;
        await _tryReadRelay(r.device);
      }
    });

    _scanLoop();
  }

  Future<void> _scanLoop() async {
    while (_running) {
      try {
        await FlutterBluePlus.startScan(
          timeout: const Duration(seconds: 8),
          withServices: [serviceUuid],
        );
      } catch (_) {}
      await Future.delayed(const Duration(seconds: 10));
    }
  }

  Future<void> broadcast(RelayPacket packet) async {
    if (!_running) return;
    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));
      await Future.delayed(const Duration(seconds: 2));
      final results = FlutterBluePlus.lastScanResults;
      for (final r in results.take(3)) {
        await _tryWriteRelay(r.device, packet);
      }
    } catch (_) {}
  }

  Future<void> _tryWriteRelay(BluetoothDevice device, RelayPacket packet) async {
    try {
      await device.connect(timeout: const Duration(seconds: 4));
      final services = await device.discoverServices();
      for (final s in services) {
        if (s.uuid != serviceUuid) continue;
        for (final c in s.characteristics) {
          if (c.uuid == relayCharUuid && c.properties.write) {
            final bytes = utf8.encode(packet.encode());
            await c.write(bytes, withoutResponse: true);
          }
        }
      }
      await device.disconnect();
    } catch (_) {
      try {
        await device.disconnect();
      } catch (_) {}
    }
  }

  Future<void> _tryReadRelay(BluetoothDevice device) async {
    try {
      await device.connect(timeout: const Duration(seconds: 3));
      final services = await device.discoverServices();
      for (final s in services) {
        if (s.uuid != serviceUuid) continue;
        for (final c in s.characteristics) {
          if (c.uuid == relayCharUuid && c.properties.read) {
            final bytes = await c.read();
            final raw = utf8.decode(bytes);
            final pkt = RelayPacket.decode(raw);
            if (pkt != null) _incoming.add(pkt);
          }
        }
      }
      await device.disconnect();
    } catch (_) {
      try {
        await device.disconnect();
      } catch (_) {}
    }
  }

  Future<void> stop() async {
    _running = false;
    await _scanSub?.cancel();
    await FlutterBluePlus.stopScan();
  }

  void dispose() {
    stop();
    _incoming.close();
  }
}
