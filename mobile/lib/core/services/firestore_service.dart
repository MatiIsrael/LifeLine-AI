import "package:cloud_firestore/cloud_firestore.dart";
import "package:firebase_auth/firebase_auth.dart";

import "../models/emergency_contact.dart";
import "../models/emergency_event.dart";
import "../models/user_profile.dart";

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String get _uid {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("User not authenticated.");
    return user.uid;
  }

  Future<void> saveProfile(UserProfile profile) async {
    await _db.collection("users").doc(_uid).set(
          {
            ...profile.toJson(),
            "updatedAt": FieldValue.serverTimestamp(),
            "createdAt": FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
  }

  Future<UserProfile?> getProfile() async {
    final doc = await _db.collection("users").doc(_uid).get();
    if (!doc.exists) return null;
    return UserProfile.fromJson(doc.data()!);
  }

  Future<void> addContact(EmergencyContact contact) async {
    await _db
        .collection("users")
        .doc(_uid)
        .collection("contacts")
        .add({
      ...contact.toJson(),
      "createdAt": FieldValue.serverTimestamp(),
    });
  }

  Future<List<EmergencyContact>> getContacts() async {
    final snap = await _db.collection("users").doc(_uid).collection("contacts").get();
    return snap.docs
        .map((doc) => EmergencyContact.fromJson(doc.data(), id: doc.id))
        .toList();
  }

  Stream<List<EmergencyEvent>> streamHistory() {
    return _db
        .collection("emergencies")
        .where("uid", isEqualTo: _uid)
        .orderBy("triggeredAt", descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => EmergencyEvent.fromJson(doc.data(), doc.id))
            .toList());
  }
}
