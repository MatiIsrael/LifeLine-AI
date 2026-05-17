import "package:flutter/material.dart";
import "package:provider/provider.dart";

import "../../core/state/auth_provider.dart";
import "../../shared/widgets/lifeline_text_field.dart";
import "../../shared/widgets/primary_button.dart";
import "../profile/profile_setup_screen.dart";

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text("Create account")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            LifelineTextField(controller: _email, label: "Email"),
            const SizedBox(height: 12),
            LifelineTextField(
              controller: _password,
              label: "Password",
              obscure: true,
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              label: "Create account",
              loading: auth.isLoading,
              onPressed: () async {
                await auth.signUp(_email.text.trim(), _password.text.trim());
                if (!mounted) return;
                if (auth.error == null) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfileSetupScreen()),
                    (_) => false,
                  );
                }
              },
            ),
            if (auth.error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  auth.error!,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
