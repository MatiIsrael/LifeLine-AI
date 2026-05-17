import "dart:async";

import "package:shared_preferences/shared_preferences.dart";
import "package:uuid/uuid.dart";

import "../cache/relay_cache_dao.dart";
import "../models/relay_packet.dart";
import "bluetooth_mesh_service.dart";

/// Coordinates P2P emergency relay through nearby devices.
class PeerRelayService {
  final BluetoothMeshService _ble = BluetoothMeshService();
  final RelayCacheDao _cache = RelayCacheDao();
  final _uuid = const Uuid();

  StreamSubscription<RelayPacket>? _incomingSub;
  String? _deviceId;

  final _onRelayReceived = StreamController<RelayPacket>.broadcast();
  Stream<RelayPacket> get onRelayReceived => _onRelayReceived.stream;

  Future<void> start() async {
    _deviceId ??= await _loadDeviceId();
    await _ble.start();
    _incomingSub = _ble.incoming.listen(_handleIncoming);
    await _cache.purgeOld();
  }

  Future<String> _loadDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString("lifeline_device_id");
    if (id == null) {
      id = _uuid.v4();
      await prefs.setString("lifeline_device_id", id);
    }
    return id;
  }

  Future<void> relayEmergency({
    required String localEventId,
    required double latitude,
    required double longitude,
    required String message,
  }) async {
    _deviceId ??= await _loadDeviceId();
    final packet = RelayPacket(
      packetId: _uuid.v4(),
      localEventId: localEventId,
      senderDeviceId: _deviceId!,
      latitude: latitude,
      longitude: longitude,
      message: message,
      hopCount: 0,
      timestamp: DateTime.now(),
    );
    await _ble.broadcast(packet);
  }

  Future<void> _handleIncoming(RelayPacket packet) async {
    if (await _cache.hasSeen(packet.packetId)) return;
    await _cache.markSeen(packet.packetId);
    _onRelayReceived.add(packet);

    if (packet.hopCount < RelayPacket.maxHops) {
      _deviceId ??= await _loadDeviceId();
      final next = packet.nextHop(_deviceId!);
      await _ble.broadcast(next);
    }
  }

  Future<void> stop() async {
    await _incomingSub?.cancel();
    await _ble.stop();
  }

  void dispose() {
    stop();
    _ble.dispose();
    _onRelayReceived.close();
  }
}
