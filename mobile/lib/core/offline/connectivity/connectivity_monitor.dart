import "dart:async";

import "package:connectivity_plus/connectivity_plus.dart";
import "package:http/http.dart" as http;

import "../../services/app_constants.dart";
import "../models/connectivity_quality.dart";

/// Monitors network presence and quality (weak vs online) for rural use.
class ConnectivityMonitor {
  final Connectivity _connectivity = Connectivity();
  ConnectivityQuality _quality = ConnectivityQuality.offline;
  final _controller = StreamController<ConnectivityQuality>.broadcast();

  Stream<ConnectivityQuality> get stream => _controller.stream;
  ConnectivityQuality get current => _quality;

  Timer? _probeTimer;

  void start({Duration probeInterval = const Duration(seconds: 30)}) {
    _probeTimer?.cancel();
    _probe();
    _probeTimer = Timer.periodic(probeInterval, (_) => _probe());
    _connectivity.onConnectivityChanged.listen((_) => _probe());
  }

  void stop() {
    _probeTimer?.cancel();
    _probeTimer = null;
  }

  Future<void> _probe() async {
    final results = await _connectivity.checkConnectivity();
    final hasInterface = results.any((r) => r != ConnectivityResult.none);

    if (!hasInterface) {
      _emit(ConnectivityQuality.offline);
      return;
    }

    try {
      final stopwatch = Stopwatch()..start();
      final response = await http
          .get(Uri.parse("${AppConstants.apiBaseUrl.replaceAll("/api", "")}/health"))
          .timeout(const Duration(seconds: 5));
      stopwatch.stop();

      if (response.statusCode == 200) {
        _emit(stopwatch.elapsedMilliseconds > 2500
            ? ConnectivityQuality.weak
            : ConnectivityQuality.online);
      } else {
        _emit(ConnectivityQuality.weak);
      }
    } catch (_) {
      _emit(ConnectivityQuality.offline);
    }
  }

  void _emit(ConnectivityQuality q) {
    if (_quality == q) return;
    _quality = q;
    _controller.add(q);
  }

  void dispose() {
    stop();
    _controller.close();
  }
}
