import "dart:convert";

/// Peer-to-peer / BLE mesh emergency relay payload.
class RelayPacket {
  final String packetId;
  final String localEventId;
  final String senderDeviceId;
  final double latitude;
  final double longitude;
  final String message;
  final int hopCount;
  final DateTime timestamp;

  RelayPacket({
    required this.packetId,
    required this.localEventId,
    required this.senderDeviceId,
    required this.latitude,
    required this.longitude,
    required this.message,
    this.hopCount = 0,
    required this.timestamp,
  });

  static const maxHops = 3;

  Map<String, dynamic> toJson() => {
        "packetId": packetId,
        "localEventId": localEventId,
        "senderDeviceId": senderDeviceId,
        "latitude": latitude,
        "longitude": longitude,
        "message": message,
        "hopCount": hopCount,
        "timestamp": timestamp.toIso8601String(),
        "type": "LIFELINE_SOS_RELAY",
      };

  factory RelayPacket.fromJson(Map<String, dynamic> json) => RelayPacket(
        packetId: json["packetId"] as String,
        localEventId: json["localEventId"] as String,
        senderDeviceId: json["senderDeviceId"] as String,
        latitude: (json["latitude"] as num).toDouble(),
        longitude: (json["longitude"] as num).toDouble(),
        message: json["message"] as String? ?? "",
        hopCount: json["hopCount"] as int? ?? 0,
        timestamp: DateTime.parse(json["timestamp"] as String),
      );

  String encode() => jsonEncode(toJson());

  static RelayPacket? decode(String raw) {
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      if (json["type"] != "LIFELINE_SOS_RELAY") return null;
      return RelayPacket.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  RelayPacket nextHop(String relayDeviceId) => RelayPacket(
        packetId: packetId,
        localEventId: localEventId,
        senderDeviceId: relayDeviceId,
        latitude: latitude,
        longitude: longitude,
        message: message,
        hopCount: hopCount + 1,
        timestamp: timestamp,
      );
}
