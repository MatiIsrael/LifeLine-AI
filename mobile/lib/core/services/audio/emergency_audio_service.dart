import "package:path_provider/path_provider.dart";
import "package:record/record.dart";

/// Optional evidence capture during silent emergencies.
class EmergencyAudioService {
  final AudioRecorder _recorder = AudioRecorder();
  String? _activePath;

  Future<bool> startRecording() async {
    if (!await _recorder.hasPermission()) return false;

    final dir = await getApplicationDocumentsDirectory();
    final fileName = "emergency_${DateTime.now().millisecondsSinceEpoch}.m4a";
    _activePath = "${dir.path}/$fileName";

    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 64000),
      path: _activePath!,
    );
    return true;
  }

  Future<String?> stopRecording() async {
    final path = await _recorder.stop();
    _activePath = null;
    return path;
  }

  Future<void> dispose() async {
    if (await _recorder.isRecording()) {
      await stopRecording();
    }
    _recorder.dispose();
  }
}
