import "package:flutter/material.dart";
import "package:provider/provider.dart";

import "../../core/models/emergency_trigger_settings.dart";
import "../../core/services/permissions/permission_service.dart";
import "../../core/models/trigger_source.dart";
import "../../core/services/emergency_flow_launcher.dart";
import "../../core/offline/models/offline_emergency_settings.dart";
import "../../core/state/offline_provider.dart";
import "../../core/state/trigger_settings_provider.dart";
import "../../shared/widgets/primary_button.dart";

class EmergencySettingsScreen extends StatefulWidget {
  const EmergencySettingsScreen({super.key});

  @override
  State<EmergencySettingsScreen> createState() => _EmergencySettingsScreenState();
}

class _EmergencySettingsScreenState extends State<EmergencySettingsScreen> {
  final PermissionService _permissions = PermissionService();
  late EmergencyTriggerSettings _draft;
  late OfflineEmergencySettings _offlineDraft;
  late TextEditingController _voiceController;
  late TextEditingController _secretController;

  @override
  void initState() {
    super.initState();
    _draft = context.read<TriggerSettingsProvider>().settings;
    _offlineDraft = context.read<OfflineProvider>().settings;
    _voiceController = TextEditingController(text: _draft.voicePhrase);
    _secretController = TextEditingController(text: _draft.calculatorSecret);
  }

  @override
  void dispose() {
    _voiceController.dispose();
    _secretController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    _draft = _draft.copyWith(
      voicePhrase: _voiceController.text.trim(),
      calculatorSecret: _secretController.text.trim(),
    );
    await context.read<TriggerSettingsProvider>().update(_draft);
    await context.read<OfflineProvider>().updateSettings(_offlineDraft);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Emergency settings saved.")),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TriggerSettingsProvider>();
    if (provider.loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Emergency triggers")),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _sectionTitle("Activation modes"),
          SwitchListTile(
            title: const Text("Silent SOS mode"),
            subtitle: const Text("No UI alerts; hidden location + contact notify"),
            value: _draft.silentMode,
            onChanged: (v) => setState(() => _draft = _draft.copyWith(silentMode: v)),
          ),
          SwitchListTile(
            title: const Text("Shake to trigger"),
            value: _draft.shakeEnabled,
            onChanged: (v) => setState(() => _draft = _draft.copyWith(shakeEnabled: v)),
          ),
          SwitchListTile(
            title: const Text("Power button (3 presses)"),
            subtitle: const Text("Legacy screen-off detection"),
            value: _draft.powerButtonEnabled,
            onChanged: (v) => setState(() => _draft = _draft.copyWith(powerButtonEnabled: v)),
          ),
          SwitchListTile(
            title: const Text("Volume button (3 presses)"),
            subtitle: const Text("Opens emergency help → track → alert flow"),
            value: _draft.volumeButtonEnabled,
            onChanged: (v) => setState(() => _draft = _draft.copyWith(volumeButtonEnabled: v)),
          ),
          ListTile(
            title: Text("Emergency help timer (${_draft.emergencyCountdownSeconds}s)"),
            subtitle: Slider(
              min: 10,
              max: 30,
              divisions: 4,
              value: _draft.emergencyCountdownSeconds.toDouble(),
              onChanged: (v) =>
                  setState(() => _draft = _draft.copyWith(emergencyCountdownSeconds: v.round())),
            ),
          ),
          SwitchListTile(
            title: const Text("Voice activation"),
            value: _draft.voiceEnabled,
            onChanged: (v) => setState(() => _draft = _draft.copyWith(voiceEnabled: v)),
          ),
          SwitchListTile(
            title: const Text("Background monitoring"),
            subtitle: const Text("Foreground service for shake while app closed"),
            value: _draft.backgroundMonitoring,
            onChanged: (v) => setState(() => _draft = _draft.copyWith(backgroundMonitoring: v)),
          ),
          SwitchListTile(
            title: const Text("Record audio on trigger"),
            value: _draft.recordAudioOnTrigger,
            onChanged: (v) => setState(() => _draft = _draft.copyWith(recordAudioOnTrigger: v)),
          ),
          const SizedBox(height: 16),
          _sectionTitle("AI motion detection (edge)"),
          SwitchListTile(
            title: const Text("AI emergency detection"),
            subtitle: const Text("Accelerometer + gyroscope on-device"),
            value: _draft.aiDetectionEnabled,
            onChanged: (v) => setState(() => _draft = _draft.copyWith(aiDetectionEnabled: v)),
          ),
          SwitchListTile(
            title: const Text("Fall detection"),
            value: _draft.fallDetectionEnabled,
            onChanged: (v) => setState(() => _draft = _draft.copyWith(fallDetectionEnabled: v)),
          ),
          SwitchListTile(
            title: const Text("Car crash detection"),
            value: _draft.crashDetectionEnabled,
            onChanged: (v) => setState(() => _draft = _draft.copyWith(crashDetectionEnabled: v)),
          ),
          SwitchListTile(
            title: const Text("Panic movement analysis"),
            value: _draft.panicMovementEnabled,
            onChanged: (v) => setState(() => _draft = _draft.copyWith(panicMovementEnabled: v)),
          ),
          SwitchListTile(
            title: const Text("Abnormal movement"),
            value: _draft.abnormalMovementEnabled,
            onChanged: (v) => setState(() => _draft = _draft.copyWith(abnormalMovementEnabled: v)),
          ),
          SwitchListTile(
            title: const Text("Unconscious inactivity"),
            value: _draft.inactivityDetectionEnabled,
            onChanged: (v) =>
                setState(() => _draft = _draft.copyWith(inactivityDetectionEnabled: v)),
          ),
          ListTile(
            title: Text("AI sensitivity (${(_draft.aiSensitivity * 100).round()}%)"),
            subtitle: Slider(
              value: _draft.aiSensitivity,
              onChanged: (v) => setState(() => _draft = _draft.copyWith(aiSensitivity: v)),
            ),
          ),
          ListTile(
            title: Text("Verification timeout (${_draft.verificationTimeoutSeconds}s)"),
            subtitle: Slider(
              min: 10,
              max: 45,
              divisions: 7,
              value: _draft.verificationTimeoutSeconds.toDouble(),
              onChanged: (v) =>
                  setState(() => _draft = _draft.copyWith(verificationTimeoutSeconds: v.round())),
            ),
          ),
          SwitchListTile(
            title: const Text("Auto SOS if no response"),
            value: _draft.autoSosOnNoResponse,
            onChanged: (v) => setState(() => _draft = _draft.copyWith(autoSosOnNoResponse: v)),
          ),
          const SizedBox(height: 16),
          _sectionTitle("Offline & rural connectivity"),
          SwitchListTile(
            title: const Text("Offline-first SOS"),
            subtitle: const Text("Queue locally, sync when signal returns"),
            value: _offlineDraft.offlineFirstEnabled,
            onChanged: (v) =>
                setState(() => _offlineDraft = _offlineDraft.copyWith(offlineFirstEnabled: v)),
          ),
          SwitchListTile(
            title: const Text("SMS fallback with GPS"),
            subtitle: const Text("Opens SMS to trusted contacts when internet fails"),
            value: _offlineDraft.smsFallbackEnabled,
            onChanged: (v) =>
                setState(() => _offlineDraft = _offlineDraft.copyWith(smsFallbackEnabled: v)),
          ),
          SwitchListTile(
            title: const Text("Bluetooth mesh relay"),
            subtitle: const Text("Relay SOS through nearby Lifeline devices"),
            value: _offlineDraft.meshRelayEnabled,
            onChanged: (v) =>
                setState(() => _offlineDraft = _offlineDraft.copyWith(meshRelayEnabled: v)),
          ),
          SwitchListTile(
            title: const Text("Weak internet optimization"),
            subtitle: const Text("Defer heavy uploads; prioritize alert delivery"),
            value: _offlineDraft.weakInternetOptimization,
            onChanged: (v) => setState(
              () => _offlineDraft = _offlineDraft.copyWith(weakInternetOptimization: v),
            ),
          ),
          const SizedBox(height: 16),
          _sectionTitle("Accident prevention"),
          SwitchListTile(
            title: const Text("Countdown before alert"),
            value: _draft.countdownEnabled,
            onChanged: (v) => setState(() => _draft = _draft.copyWith(countdownEnabled: v)),
          ),
          ListTile(
            title: Text("Countdown duration (${_draft.countdownSeconds}s)"),
            subtitle: Slider(
              min: 3,
              max: 10,
              divisions: 7,
              value: _draft.countdownSeconds.toDouble(),
              onChanged: (v) => setState(() => _draft = _draft.copyWith(countdownSeconds: v.round())),
            ),
          ),
          ListTile(
            title: const Text("Shake sensitivity"),
            subtitle: Slider(
              value: _draft.shakeSensitivity,
              onChanged: (v) => setState(() => _draft = _draft.copyWith(shakeSensitivity: v)),
            ),
          ),
          const SizedBox(height: 16),
          _sectionTitle("Voice & disguise"),
          ListTile(
            title: const Text("Voice phrase"),
            subtitle: TextField(controller: _voiceController),
          ),
          ListTile(
            title: const Text("Calculator secret code"),
            subtitle: TextField(controller: _secretController),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => _permissions.openBatteryOptimizationSettings(),
            child: const Text("Battery optimization settings"),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () {
              EmergencyFlowLauncher.launch(
                context: context,
                source: TriggerSource.volumeButton,
                countdownSeconds: _draft.emergencyCountdownSeconds,
              );
            },
            child: const Text("Preview emergency flow"),
          ),
          const SizedBox(height: 20),
          PrimaryButton(label: "Save settings", onPressed: _save),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      );
}
