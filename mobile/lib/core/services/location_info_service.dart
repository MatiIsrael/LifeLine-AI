import "package:geocoding/geocoding.dart";

import "location_service.dart";

class LocationInfo {
  final double latitude;
  final double longitude;
  final String addressLine;
  final String plusCode;
  final String coordinates;

  LocationInfo({
    required this.latitude,
    required this.longitude,
    required this.addressLine,
    required this.plusCode,
    required this.coordinates,
  });
}

/// Resolves GPS into human-readable address for the emergency help screen.
class LocationInfoService {
  final LocationService _location = LocationService();

  Future<LocationInfo> getCurrentLocationInfo() async {
    final position = await _location.getCurrentPosition();
    final lat = position.latitude;
    final lng = position.longitude;

    var addressLine = "Fetching address…";
    try {
      final marks = await placemarkFromCoordinates(lat, lng);
      if (marks.isNotEmpty) {
        final p = marks.first;
        addressLine = [
          p.street,
          p.subLocality,
          p.locality,
          p.administrativeArea,
        ].whereType<String>().where((e) => e.isNotEmpty).join(", ");
        if (addressLine.isEmpty) {
          addressLine = p.name ?? "Unknown location";
        }
      }
    } catch (_) {
      addressLine = "Location available via GPS";
    }

    return LocationInfo(
      latitude: lat,
      longitude: lng,
      addressLine: addressLine,
      plusCode: _approxPlusCode(lat, lng),
      coordinates: "${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}",
    );
  }
}

String _approxPlusCode(double lat, double lng) {
  // Lightweight readable location code for MVP (not official Open Location Code).
  final latCode = lat >= 0 ? "N" : "S";
  final lngCode = lng >= 0 ? "E" : "W";
  return "${lat.abs().toStringAsFixed(3)}$latCode ${lng.abs().toStringAsFixed(3)}$lngCode";
}
