import "package:flutter/material.dart";

import "../../core/models/emergency_contact.dart";
import "../../core/models/emergency_type.dart";
import "../../core/services/location_info_service.dart";

/// Step 4 — Outgoing alert messages preview (SMS-style).
class SendAlertsScreen extends StatelessWidget {
  final List<EmergencyContact> contacts;
  final LocationInfo? location;
  final EmergencyType emergencyType;

  const SendAlertsScreen({
    super.key,
    required this.contacts,
    this.location,
    required this.emergencyType,
  });

  String get _mapsLink =>
      "https://maps.google.com/?q=${location?.latitude ?? 0},${location?.longitude ?? 0}";

  @override
  Widget build(BuildContext context) {
    final names = contacts.isEmpty
        ? "your emergency contacts"
        : contacts.map((c) => c.name).where((n) => n.isNotEmpty).join(", ");

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: const Text("Send Alerts", style: TextStyle(color: Colors.black)),
        elevation: 0.5,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _bubble(
                  "Note: Location info will be updated in real time while the Emergency SOS feature is active. Remember that the person who needs help might not be able to return your call.",
                  isNote: true,
                ),
                const SizedBox(height: 12),
                _bubble(
                  "You are my emergency contact ($names). I need ${emergencyType.label.toLowerCase()} help. "
                  "This is my approximate location: $_mapsLink",
                ),
                const SizedBox(height: 8),
                if (location != null)
                  _bubble(
                    "Address: ${location!.addressLine}\nGPS: ${location!.coordinates}",
                  ),
              ],
            ),
          ),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
            child: Row(
              children: [
                const Icon(Icons.add_circle_outline, color: Color(0xFF8E8E93)),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE9E9EB),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Text(
                      "Alerts sent automatically",
                      style: TextStyle(color: Color(0xFF8E8E93)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFF2196F3),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.send, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bubble(String text, {bool isNote = false}) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 320),
        margin: const EdgeInsets.only(left: 48),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isNote ? const Color(0xFFFFE082) : const Color(0xFF2196F3),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(18),
            bottomRight: Radius.circular(4),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isNote ? Colors.black87 : Colors.white,
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}
