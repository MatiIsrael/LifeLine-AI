import "package:cloud_firestore/cloud_firestore.dart";

class EmergencyEvent {
  final String id;
  final String status;
  final double latitude;
  final double longitude;
  final DateTime? triggeredAt;
  final DateTime? resolvedAt;

  EmergencyEvent({
    required this.id,
    required this.status,
    required this.latitude,
    required this.longitude,
    this.triggeredAt,
    this.resolvedAt,
  });

  factory EmergencyEvent.fromJson(Map<String, dynamic> json, String id) {
    DateTime? parseTs(dynamic value) =>
        value is Timestamp ? value.toDate() : null;

    return EmergencyEvent(
      id: id,
      status: json["status"] ?? "active",
      latitude: (json["latitude"] ?? 0).toDouble(),
      longitude: (json["longitude"] ?? 0).toDouble(),
      triggeredAt: parseTs(json["triggeredAt"]),
      resolvedAt: parseTs(json["resolvedAt"]),
    );
  }
}
