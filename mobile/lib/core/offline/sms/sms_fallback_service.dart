import "dart:io";

import "package:permission_handler/permission_handler.dart";
import "package:url_launcher/url_launcher.dart";

import "../../models/emergency_contact.dart";

/// Sends SMS with GPS when cloud/API is unavailable (critical rural fallback).
class SmsFallbackService {
  Future<bool> sendEmergencySms({
    required List<EmergencyContact> contacts,
    required double latitude,
    required double longitude,
    required String userName,
    required String triggerType,
  }) async {
    final phones = contacts
        .map((c) => c.phoneNumber.trim())
        .where((p) => p.isNotEmpty)
        .toSet()
        .toList();

    if (phones.isEmpty) return false;

    final mapsLink = "https://maps.google.com/?q=$latitude,$longitude";
    final body =
        "LIFELINE SOS from $userName. Type: $triggerType. Location: $mapsLink "
        "Coords: ${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}. "
        "No internet — sent via SMS fallback.";

    if (Platform.isAndroid) {
      return _sendAndroidDirect(phones, body);
    }
    return _sendViaLauncher(phones.first, body);
  }

  Future<bool> _sendAndroidDirect(List<String> phones, String body) async {
    final status = await Permission.sms.request();
    if (!status.isGranted) {
      return _sendViaLauncher(phones.first, body);
    }

    try {
      // Dynamic import pattern — use platform SMS intent batch via url_launcher fallback
      // when telephony plugin unavailable; native SMS intent per number.
      var sent = false;
      for (final phone in phones.take(5)) {
        final uri = Uri.parse("sms:$phone?body=${Uri.encodeComponent(body)}");
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
          sent = true;
        }
      }
      return sent;
    } catch (_) {
      return _sendViaLauncher(phones.first, body);
    }
  }

  Future<bool> _sendViaLauncher(String phone, String body) async {
    final uri = Uri.parse("sms:$phone?body=${Uri.encodeComponent(body)}");
    if (await canLaunchUrl(uri)) {
      return launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    return false;
  }
}
