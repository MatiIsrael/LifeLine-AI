import "package:flutter/material.dart";

import "../../core/models/emergency_contact.dart";
import "../../core/models/user_profile.dart";
import "../../core/config/app_config.dart";
import "../../core/services/firestore_service.dart";
import "../../core/services/profile_api_service.dart";
import "../../shared/widgets/lifeline_text_field.dart";
import "../../shared/widgets/primary_button.dart";
import "../home/home_screen.dart";

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final FirestoreService _firestore = FirestoreService();

  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _bloodGroup = TextEditingController();
  final _medicalNotes = TextEditingController();
  final _contactName = TextEditingController();
  final _contactPhone = TextEditingController();
  final _contactRelation = TextEditingController();
  final _contactEmail = TextEditingController();
  final ProfileApiService _profileApi = ProfileApiService();

  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _bloodGroup.dispose();
    _medicalNotes.dispose();
    _contactName.dispose();
    _contactPhone.dispose();
    _contactRelation.dispose();
    _contactEmail.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    setState(() => _saving = true);
    try {
      await _firestore.saveProfile(
        UserProfile(
          fullName: _name.text.trim(),
          email: "",
          phoneNumber: _phone.text.trim(),
          bloodGroup: _bloodGroup.text.trim(),
          medicalNotes: _medicalNotes.text.trim(),
        ),
      );

      if (_contactName.text.trim().isNotEmpty) {
        String? contactUid;
        if (AppConfig.firebaseReady && _contactEmail.text.trim().isNotEmpty) {
          contactUid = await _profileApi.linkContactByEmail(_contactEmail.text.trim());
        }

        await _firestore.addContact(
          EmergencyContact(
            id: "",
            name: _contactName.text.trim(),
            phoneNumber: _contactPhone.text.trim(),
            relationship: _contactRelation.text.trim(),
            contactEmail: _contactEmail.text.trim(),
            contactUid: contactUid ?? "",
          ),
        );
      }

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (_) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to save profile: $e")),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Emergency profile setup")),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            "Personal details",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          LifelineTextField(controller: _name, label: "Full name"),
          const SizedBox(height: 10),
          LifelineTextField(
            controller: _phone,
            label: "Phone number",
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 10),
          LifelineTextField(controller: _bloodGroup, label: "Blood group"),
          const SizedBox(height: 10),
          LifelineTextField(controller: _medicalNotes, label: "Medical notes"),
          const SizedBox(height: 20),
          const Text(
            "Primary emergency contact",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          LifelineTextField(controller: _contactName, label: "Contact name"),
          const SizedBox(height: 10),
          LifelineTextField(
            controller: _contactPhone,
            label: "Contact phone",
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 10),
          LifelineTextField(controller: _contactRelation, label: "Relationship"),
          const SizedBox(height: 10),
          LifelineTextField(
            controller: _contactEmail,
            label: "Contact Lifeline email (for push alerts)",
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            label: "Save and continue",
            loading: _saving,
            onPressed: _saveProfile,
          ),
        ],
      ),
    );
  }
}
