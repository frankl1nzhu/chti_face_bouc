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
  bool _isLoading = false; // 添加加载状态标志
  final TextEditingController mailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController surnameController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final ServiceAuthentification _auth = ServiceAuthentification();

  @override
  void initState() {
    super.initState();
    // 清除任何旧的登录信息
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
    // 检查表单是否有效
    if (mailController.text.trim().isEmpty || passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Veuillez remplir tous les champs requis"),
        ),
      );
      return;
    }

    // 设置加载状态
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
        // 检查创建账户的必填字段
        if (surnameController.text.trim().isEmpty ||
            nameController.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Veuillez remplir tous les champs requis"),
            ),
          );
          setState(() {
            _isLoading = false;
          });
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
      // 处理未捕获的异常
      errorMessage = "Une erreur inattendue s'est produite: $e";
    } finally {
      // 设置为非加载状态
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }

    if (errorMessage != null && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage)));
    }
    // 不再需要手动导航，StreamBuilder 会处理
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
                onSelectionChanged:
                    _isLoading ? null : _onSelectedChanged, // 加载时禁用
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
                        enabled: !_isLoading, // 加载时禁用
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
                        enabled: !_isLoading, // 加载时禁用
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
                          enabled: !_isLoading, // 加载时禁用
                          decoration: const InputDecoration(
                            labelText: 'Prénom',
                            prefixIcon: Icon(Icons.person),
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Nom field
                        TextField(
                          controller: nameController,
                          enabled: !_isLoading, // 加载时禁用
                          decoration: const InputDecoration(
                            labelText: 'Nom',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                        ),
                      ],

                      const SizedBox(height: 20),
                      // Submit button
                      ElevatedButton(
                        onPressed: _isLoading ? null : _handleAuth, // 加载时禁用
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
                                    Text("Traitement en cours..."),
                                  ],
                                )
                                : Text(
                                  accountExists
                                      ? "C'est parti!"
                                      : "Je crée min compte",
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
