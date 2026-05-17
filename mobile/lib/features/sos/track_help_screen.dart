import "dart:async";

import "package:flutter/material.dart";
import "package:google_maps_flutter/google_maps_flutter.dart";

import "../../core/models/emergency_contact.dart";
import "../../core/models/emergency_type.dart";
import "../../core/services/location_info_service.dart";
import "send_alerts_screen.dart";

/// Step 3 — Circular map tracking with ETA countdown.
class TrackHelpScreen extends StatefulWidget {
  final String eventId;
  final LocationInfo? location;
  final EmergencyType emergencyType;
  final List<EmergencyContact> contacts;

  const TrackHelpScreen({
    super.key,
    required this.eventId,
    this.location,
    required this.emergencyType,
    this.contacts = const [],
  });

  @override
  State<TrackHelpScreen> createState() => _TrackHelpScreenState();
}

class _TrackHelpScreenState extends State<TrackHelpScreen> {
  Timer? _etaTimer;
  int _etaSeconds = 204;

  @override
  void initState() {
    super.initState();
    _etaTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_etaSeconds > 0 && mounted) setState(() => _etaSeconds -= 1);
    });
    Future.delayed(const Duration(seconds: 4), _goToAlerts);
  }

  void _goToAlerts() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => SendAlertsScreen(
          contacts: widget.contacts,
          location: widget.location,
          emergencyType: widget.emergencyType,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _etaTimer?.cancel();
    super.dispose();
  }

  String get _etaLabel {
    final m = _etaSeconds ~/ 60;
    final s = _etaSeconds % 60;
    return "${m}m ${s.toString().padLeft(2, "0")}s";
  }

  @override
  Widget build(BuildContext context) {
    final lat = widget.location?.latitude ?? 30.7333;
    final lng = widget.location?.longitude ?? 76.7794;
    final target = LatLng(lat, lng);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),
            Text(
              widget.emergencyType.label,
              style: const TextStyle(color: Colors.white54, fontSize: 14),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Center(
                child: Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF42A5F5).withOpacity(0.5), width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2196F3).withOpacity(0.25),
                        blurRadius: 40,
                        spreadRadius: 8,
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(target: target, zoom: 15),
                    myLocationEnabled: true,
                    zoomControlsEnabled: false,
                    markers: {
                      Marker(markerId: const MarkerId("you"), position: target),
                    },
                  ),
                ),
              ),
            ),
            Text(
              "Sending help in $_etaLabel",
              style: const TextStyle(
                color: Color(0xFF42A5F5),
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
