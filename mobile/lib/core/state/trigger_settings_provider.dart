import "package:flutter/foundation.dart";

import "../models/emergency_trigger_settings.dart";
import "../services/background/background_monitor_service.dart";
import "../services/triggers/emergency_trigger_coordinator.dart";
import "../services/triggers/trigger_settings_repository.dart";

class TriggerSettingsProvider extends ChangeNotifier {
  final TriggerSettingsRepository _repo = TriggerSettingsRepository();
  final BackgroundMonitorService _background = BackgroundMonitorService();

  EmergencyTriggerSettings _settings = const EmergencyTriggerSettings();
  bool _loading = true;

  EmergencyTriggerSettings get settings => _settings;
  bool get loading => _loading;

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    _settings = await _repo.load();
    _loading = false;
    notifyListeners();
  }

  Future<void> update(EmergencyTriggerSettings settings) async {
    _settings = settings;
    await _repo.save(settings);
    await EmergencyTriggerCoordinator.instance.updateSettings(settings);
    await _syncBackgroundService();
    notifyListeners();
  }

  Future<void> _syncBackgroundService() async {
    if (_settings.backgroundMonitoring) {
      await _background.start();
    } else {
      await _background.stop();
    }
  }

  Future<void> initializeBackground() async {
    await _background.initialize();
    await _syncBackgroundService();
  }
}
