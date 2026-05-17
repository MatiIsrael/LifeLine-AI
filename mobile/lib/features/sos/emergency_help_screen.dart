import "dart:async";

import "package:firebase_auth/firebase_auth.dart";
import "package:flutter/material.dart";
import "package:provider/provider.dart";

import "../../core/models/emergency_contact.dart";
import "../../core/models/emergency_type.dart";
import "../../core/models/trigger_source.dart";
import "../../core/services/firestore_service.dart";
import "../../core/services/location_info_service.dart";
import "../../core/state/sos_provider.dart";
import "track_help_screen.dart";

/// Step 2 — Emergency help screen with countdown, location, contacts, and type.
class EmergencyHelpScreen extends StatefulWidget {
  final TriggerSource source;
  final int countdownSeconds;

  const EmergencyHelpScreen({
    super.key,
    required this.source,
    this.countdownSeconds = 15,
  });

  @override
  State<EmergencyHelpScreen> createState() => _EmergencyHelpScreenState();
}

class _EmergencyHelpScreenState extends State<EmergencyHelpScreen> {
  final _locationInfo = LocationInfoService();
  final _firestore = FirestoreService();

  Timer? _timer;
  int _secondsLeft = 15;
  LocationInfo? _location;
  List<EmergencyContact> _contacts = [];
  EmergencyType _selectedType = EmergencyType.medical;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _secondsLeft = widget.countdownSeconds;
    _loadData();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft <= 1) {
        t.cancel();
        _sendHelp();
        return;
      }
      setState(() => _secondsLeft -= 1);
    });
  }

  Future<void> _loadData() async {
    try {
      final loc = await _locationInfo.getCurrentLocationInfo();
      final contacts = await _firestore.getContacts();
      if (mounted) {
        setState(() {
          _location = loc;
          _contacts = contacts;
        });
      }
    } catch (_) {}
  }

  String get _timerLabel {
    final m = (_secondsLeft ~/ 60).toString().padLeft(2, "0");
    final s = (_secondsLeft % 60).toString().padLeft(2, "0");
    return "$m:$s";
  }

  Future<void> _sendHelp() async {
    if (_sending) return;
    setState(() => _sending = true);
    _timer?.cancel();

    final sos = context.read<SosProvider>();
    await sos.activateFromCoordinator(
      source: widget.source,
      silent: false,
      recordAudio: false,
    );

    if (!mounted) return;

    if (sos.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(sos.error!)));
      Navigator.pop(context);
      return;
    }

    final eventId = sos.activeEventId;
    if (eventId == null) {
      Navigator.pop(context);
      return;
    }

    if (!mounted) return;
    await Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => TrackHelpScreen(
          eventId: eventId,
          location: _location,
          emergencyType: _selectedType,
          contacts: _contacts,
        ),
      ),
    );
    if (mounted) Navigator.pop(context);
  }

  void _cancel() {
    _timer?.cancel();
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final phone = FirebaseAuth.instance.currentUser?.phoneNumber ?? "+91 ••••• •••••";

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0C),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(icon: const Icon(Icons.close), onPressed: _cancel),
        title: Column(
          children: [
            const Text("Emergency Number", style: TextStyle(fontSize: 16)),
            Text(
              _timerLabel,
              style: const TextStyle(
                color: Color(0xFF42A5F5),
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _sectionTitle("You are here", color: const Color(0xFF42A5F5)),
          const SizedBox(height: 10),
          _locationCard(),
          const SizedBox(height: 20),
          Text("This phone number: $phone", style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 20),
          _sectionTitle("Emergency Contacts:"),
          const SizedBox(height: 10),
          _contactsRow(),
          const SizedBox(height: 24),
          _sectionTitle("Select Emergency Type"),
          const SizedBox(height: 12),
          _typeSelector(),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: FilledButton(
              onPressed: _sending ? null : _sendHelp,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF2196F3),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _sending
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text("Send Help", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _cancel,
            child: const Text("Cancel alert", style: TextStyle(color: Colors.white54)),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text, {Color color = Colors.white}) {
    return Text(
      text,
      style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w700),
    );
  }

  Widget _locationCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF141418),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2A30)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _location?.addressLine ?? "Loading location…",
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                ),
                const SizedBox(height: 6),
                Text(
                  "Plus Code: ${_location?.plusCode ?? "—"}",
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
                Text(
                  _location?.coordinates ?? "",
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFF1E2A38),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF42A5F5).withOpacity(0.4)),
            ),
            child: const Icon(Icons.location_on, color: Colors.redAccent, size: 36),
          ),
        ],
      ),
    );
  }

  Widget _contactsRow() {
    if (_contacts.isEmpty) {
      return const Text("No contacts added yet.", style: TextStyle(color: Colors.white54));
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _contacts.map((c) {
        return Chip(
          label: Text(c.name.isNotEmpty ? c.name : c.phoneNumber),
          backgroundColor: const Color(0xFF1E3A5F),
          labelStyle: const TextStyle(color: Colors.white),
          side: BorderSide.none,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        );
      }).toList(),
    );
  }

  Widget _typeSelector() {
    return Row(
      children: EmergencyType.values.map((type) {
        final selected = _selectedType == type;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: InkWell(
              onTap: () => setState(() => _selectedType = type),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: selected ? const Color(0xFF1565C0) : const Color(0xFF141418),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selected ? const Color(0xFF42A5F5) : const Color(0xFF2A2A30),
                    width: selected ? 2 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(type.icon, color: selected ? Colors.white : Colors.white54),
                    const SizedBox(height: 6),
                    Text(
                      type.label,
                      style: TextStyle(
                        color: selected ? Colors.white : Colors.white54,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
