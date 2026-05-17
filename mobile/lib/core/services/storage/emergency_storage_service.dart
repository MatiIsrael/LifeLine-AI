import "dart:io";

import "package:firebase_storage/firebase_storage.dart";

/// Uploads optional emergency audio evidence to Firebase Storage.
class EmergencyStorageService {
  Future<String?> uploadEmergencyAudio({
    required String eventId,
    required String localPath,
  }) async {
    final file = File(localPath);
    if (!await file.exists()) return null;

    final ref = FirebaseStorage.instance.ref("emergencies/$eventId/audio.m4a");
    await ref.putFile(file);
    return ref.getDownloadURL();
  }
}
