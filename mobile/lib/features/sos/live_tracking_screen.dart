import "dart:async";

import "package:geolocator/geolocator.dart";
import "package:flutter/material.dart";
import "package:google_maps_flutter/google_maps_flutter.dart";
import "package:provider/provider.dart";

import "../../core/services/location_service.dart";
import "../../core/state/sos_provider.dart";
import "../../shared/widgets/primary_button.dart";

class LiveTrackingScreen extends StatefulWidget {
  final String eventId;

  const LiveTrackingScreen({super.key, required this.eventId});

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
  final LocationService _locationService = LocationService();
  final Completer<GoogleMapController> _mapController = Completer();

  Position? _latestPosition;
  StreamSubscription<Position>? _locationSub;

  @override
  void initState() {
    super.initState();
    _locationSub = _locationService.positionStream().listen((pos) async {
      setState(() => _latestPosition = pos);
      if (_mapController.isCompleted) {
        final controller = await _mapController.future;
        await controller.animateCamera(
          CameraUpdate.newLatLng(
            LatLng(pos.latitude, pos.longitude),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _locationSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sos = context.watch<SosProvider>();
    final target = _latestPosition != null
        ? LatLng(_latestPosition!.latitude, _latestPosition!.longitude)
        : const LatLng(24.7136, 46.6753);

    return Scaffold(
      appBar: AppBar(title: const Text("Live emergency tracking")),
      body: Column(
        children: [
          Expanded(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(target: target, zoom: 15),
              myLocationEnabled: true,
              onMapCreated: (controller) => _mapController.complete(controller),
              markers: {
                Marker(
                  markerId: const MarkerId("user"),
                  position: target,
                  infoWindow: const InfoWindow(title: "Your live location"),
                ),
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: PrimaryButton(
              label: sos.isBusy ? "Resolving..." : "Resolve Emergency",
              color: Colors.green,
              onPressed: sos.isBusy
                  ? null
                  : () async {
                      await sos.resolveSos(notes: "Resolved from app");
                      if (!context.mounted) return;
                      Navigator.pop(context);
                    },
            ),
          ),
        ],
      ),
    );
  }
}
