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
  bool _isLoading = false; // Loading state flag
  final TextEditingController mailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController surnameController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final ServiceAuthentification _auth = ServiceAuthentification();

  @override
  void initState() {
    super.initState();

    // Clear any old login info
    mailController.clear();
    passwordController.clear();
    surnameController.clear();
    nameController.clear();
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
    if (mailController.text.trim().isEmpty || passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all required fields")),
      );
      return;
    }

    // Set loading state
    setState(() {
      _isLoading = true;
    });

    String? errorMessage;

    try {
      if (accountExists) {
        // Login with existing account
        errorMessage = await _auth.signIn(
          email: mailController.text.trim(),
          password: passwordController.text,
        );
      } else {
        // Check required fields for account creation
        if (surnameController.text.trim().isEmpty ||
            nameController.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Please fill in all required fields")),
          );
          return;
        }

        // Create new account
        errorMessage = await _auth.createAccount(
          email: mailController.text.trim(),
          password: passwordController.text,
          surname: surnameController.text.trim(),
          name: nameController.text.trim(),
        );
      }
    } catch (e) {
      // Handle uncaught exceptions
      errorMessage = "An unexpected error occurred: $e";
    } finally {
      // Set to non-loading state
      setState(() {
        _isLoading = false;
      });
    }

    if (errorMessage != null && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage)));
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
              // Logo
              Image.asset('assets/images/logo.jpg', height: 150),
              const SizedBox(height: 20),

              // SegmentedButton to choose between login and signup
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment<bool>(
                    value: true,
                    label: Text("Create Account"),
                  ),
                  ButtonSegment<bool>(value: false, label: Text("Login")),
                ],
                selected: {!accountExists},
                onSelectionChanged:
                    _isLoading
                        ? null
                        : _onSelectedChanged, // Disabled while loading
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
                        enabled: !_isLoading, // Disabled while loading
                        decoration: const InputDecoration(
                          labelText: 'Email Address',
                          prefixIcon: Icon(Icons.email),
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 10),

                      // Password field
                      TextField(
                        controller: passwordController,
                        enabled: !_isLoading, // Disabled while loading
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          prefixIcon: Icon(Icons.lock),
                        ),
                        obscureText: true,
                      ),

                      // Conditional fields for account creation
                      if (!accountExists) ...[
                        const SizedBox(height: 10),
                        // First name field
                        TextField(
                          controller: surnameController,
                          enabled: !_isLoading, // Disabled while loading
                          decoration: const InputDecoration(
                            labelText: 'First Name',
                            prefixIcon: Icon(Icons.person),
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Last name field
                        TextField(
                          controller: nameController,
                          enabled: !_isLoading, // Disabled while loading
                          decoration: const InputDecoration(
                            labelText: 'Last Name',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                        ),
                      ],

                      const SizedBox(height: 20),
                      // Submit button
                      ElevatedButton(
                        onPressed:
                            _isLoading
                                ? null
                                : _handleAuth, // Disabled while loading
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                        ),
                        child:
                            _isLoading
                                ? const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                    SizedBox(width: 10),
                                    Text("Processing..."),
                                  ],
                                )
                                : Text(
                                  accountExists
                                      ? "Let's go!"
                                      : "Create my account",
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
