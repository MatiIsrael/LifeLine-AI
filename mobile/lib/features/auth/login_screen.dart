import "package:flutter/material.dart";
import "package:provider/provider.dart";

import "../../core/state/auth_provider.dart";
import "../../shared/widgets/lifeline_text_field.dart";
import "../../shared/widgets/primary_button.dart";
import "../home/home_screen.dart";
import "register_screen.dart";

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Lifeline AI",
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text("Emergency response, one tap away."),
              const SizedBox(height: 24),
              LifelineTextField(controller: _email, label: "Email"),
              const SizedBox(height: 12),
              LifelineTextField(
                controller: _password,
                label: "Password",
                obscure: true,
              ),
              const SizedBox(height: 16),
              PrimaryButton(
                label: "Login",
                loading: auth.isLoading,
                onPressed: () async {
                  await auth.signIn(_email.text.trim(), _password.text.trim());
                  if (!mounted) return;
                  if (auth.error == null) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const HomeScreen()),
                    );
                  }
                },
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RegisterScreen()),
                  );
                },
                child: const Text("Create account"),
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
      ),
    );
  }
}
