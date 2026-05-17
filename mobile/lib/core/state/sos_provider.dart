import "package:flutter/foundation.dart";

import "../models/trigger_source.dart";
import "../services/sos_service.dart";
import "../services/triggers/emergency_trigger_coordinator.dart";

class SosProvider extends ChangeNotifier {
  final SosService _sosService = SosService();

  bool _isActive = false;
  bool _isBusy = false;
  String? _activeEventId;
  String? _error;
  TriggerSource? _lastSource;
  bool _lastSilent = false;

  bool get isActive => _isActive;
  bool get isBusy => _isBusy;
  String? get activeEventId => _activeEventId;
  String? get error => _error;
  TriggerSource? get lastSource => _lastSource;
  bool get lastSilent => _lastSilent;

  /// Manual SOS button — routes through countdown + anti-accident flow.
  Future<void> requestManualSos() async {
    await EmergencyTriggerCoordinator.instance.requestTrigger(TriggerSource.manual);
  }

  /// Invoked by [EmergencyTriggerCoordinator] after countdown completes.
  Future<void> activateFromCoordinator({
    required TriggerSource source,
    required bool silent,
    required bool recordAudio,
  }) async {
    _setBusy(true);
    _error = null;
    try {
      String? audioPath;
      if (recordAudio) {
        audioPath = await EmergencyTriggerCoordinator.instance.stopAudioCapture();
      }

      _activeEventId = await _sosService.triggerSos(
        silent: silent,
        source: source,
        recordAudio: recordAudio,
        audioPath: audioPath,
      );
      _isActive = true;
      _lastSource = source;
      _lastSilent = silent;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setBusy(false);
    }
  }

  Future<void> resolveSos({String notes = ""}) async {
    if (_activeEventId == null) return;
    _setBusy(true);
    try {
      await _sosService.resolveSos(_activeEventId!, notes: notes);
      _isActive = false;
      _activeEventId = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setBusy(false);
    }
  }

  Future<List<Map<String, dynamic>>> loadHistory() => _sosService.fetchHistory();

  void _setBusy(bool value) {
    _isBusy = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _sosService.dispose();
    super.dispose();
  }
}
