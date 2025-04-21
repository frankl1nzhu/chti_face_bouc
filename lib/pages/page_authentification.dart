import 'package:flutter/material.dart';
import '../services_firebase/service_authentification.dart';

class PageAuthentification extends StatefulWidget {
  const PageAuthentification({super.key});

  @override
  State<PageAuthentification> createState() => _PageAuthentificationState();
}

class _PageAuthentificationState extends State<PageAuthentification> {
  // Variables
  bool accountExists = true; // Default to login view
  final TextEditingController mailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController surnameController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final ServiceAuthentification _auth = ServiceAuthentification();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    mailController.dispose();
    passwordController.dispose();
    surnameController.dispose();
    nameController.dispose();
    super.dispose();
  }

  // Function to handle segmented button selection
  void _onSelectedChanged(Set<bool> newValue) {
    setState(() {
      accountExists = !newValue.first;
    });
  }

  // Handle authentication (login or create account)
  Future<void> _handleAuth() async {
    String? errorMessage;

    if (accountExists) {
      // Login with existing account
      errorMessage = await _auth.signIn(
        email: mailController.text.trim(),
        password: passwordController.text,
      );
    } else {
      // Create new account
      errorMessage = await _auth.createAccount(
        email: mailController.text.trim(),
        password: passwordController.text,
        surname: surnameController.text.trim(),
        name: nameController.text.trim(),
      );
    }

    if (errorMessage != null && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage)));
    } else if (mounted) {
      Navigator.pop(context); // Return to previous page after successful auth
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              // Logo or image
              Image.asset(
                'assets/images/logo.jpg', // Using .jpg extension for the logo file
                height: 150,
              ),
              const SizedBox(height: 20),

              // SegmentedButton to choose between login and signup
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment<bool>(
                    value: true,
                    label: Text("Créer t'in compte"),
                  ),
                  ButtonSegment<bool>(
                    value: false,
                    label: Text("Y va connecter"),
                  ),
                ],
                selected: {!accountExists},
                onSelectionChanged: _onSelectedChanged,
              ),
              const SizedBox(height: 20),

              // Card with form fields
              Card(
                margin: const EdgeInsets.all(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Email field
                      TextField(
                        controller: mailController,
                        decoration: const InputDecoration(
                          labelText: 'Adresse mail',
                          prefixIcon: Icon(Icons.email),
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 10),

                      // Password field
                      TextField(
                        controller: passwordController,
                        decoration: const InputDecoration(
                          labelText: 'Mot de passe',
                          prefixIcon: Icon(Icons.lock),
                        ),
                        obscureText: true,
                      ),

                      // Conditional fields for account creation
                      if (!accountExists) ...[
                        const SizedBox(height: 10),
                        // Prénom field
                        TextField(
                          controller: surnameController,
                          decoration: const InputDecoration(
                            labelText: 'Prénom',
                            prefixIcon: Icon(Icons.person),
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Nom field
                        TextField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: 'Nom',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                        ),
                      ],

                      const SizedBox(height: 20),
                      // Submit button
                      ElevatedButton(
                        onPressed: _handleAuth,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                        ),
                        child: Text(
                          accountExists ? "C'est parti!" : "Je crée min compte",
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
