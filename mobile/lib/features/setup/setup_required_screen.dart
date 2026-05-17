import "package:flutter/material.dart";

import "../../shared/widgets/primary_button.dart";

/// Shown when Firebase has not been configured yet.
class SetupRequiredScreen extends StatelessWidget {
  const SetupRequiredScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Lifeline AI",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                "Firebase is not configured yet. Complete setup to use authentication, SOS, and push alerts.",
              ),
              const SizedBox(height: 20),
              const Text("1. Create a Firebase project"),
              const Text("2. Run: flutterfire configure"),
              const Text("3. Add google-services.json (Android)"),
              const Text("4. Set backend service account in backend/.env"),
              const Text("5. Run backend: npm run dev"),
              const Spacer(),
              PrimaryButton(
                label: "Open SETUP.md guide",
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }
}
