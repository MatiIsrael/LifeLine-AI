import "dart:async";

import "package:speech_to_text/speech_to_text.dart" as stt;

import "../../models/emergency_trigger_settings.dart";

typedef VoiceTriggerCallback = void Function(String phrase);

/// Listens for a configured emergency phrase with partial-result matching.
class VoiceTriggerService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _initialized = false;

  Future<bool> initialize() async {
    if (_initialized) return true;
    _initialized = await _speech.initialize(
      onError: (_) {},
      onStatus: (_) {},
    );
    return _initialized;
  }

  Future<void> startListening({
    required EmergencyTriggerSettings settings,
    required VoiceTriggerCallback onPhraseDetected,
  }) async {
    if (!settings.voiceEnabled) return;
    if (!await initialize()) return;

    final phrase = settings.voicePhrase.trim().toLowerCase();
    if (phrase.isEmpty) return;

    await _speech.stop();
    await _speech.listen(
      onResult: (result) {
        final heard = result.recognizedWords.toLowerCase();
        if (heard.contains(phrase)) {
          onPhraseDetected(phrase);
        }
      },
      listenMode: stt.ListenMode.dictation,
      pauseFor: const Duration(seconds: 2),
      partialResults: true,
    );
  }

  Future<void> stopListening() async {
    if (_speech.isListening) {
      await _speech.stop();
    }
  }

  void dispose() {
    _speech.cancel();
  }
}
