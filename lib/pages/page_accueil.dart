import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services_firebase/service_authentification.dart';
import 'page_authentification.dart';

class PageAccueil extends StatefulWidget {
  const PageAccueil({super.key, required this.title});
  final String title;

  @override
  State<PageAccueil> createState() => _PageAccueilState();
}

class _PageAccueilState extends State<PageAccueil> {
  final ServiceAuthentification _auth = ServiceAuthentification();

  void _navigateToAuth() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PageAuthentification()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ), // AppBar
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.userChanges(),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Center(
                child: Text(
                  (snapshot.hasData) ? "Connecté" : "Non connecté",
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              const SizedBox(height: 20),
              if (snapshot.hasData)
                ElevatedButton(
                  onPressed: () async {
                    await _auth.signOut();
                  },
                  child: const Text("Se déconnecter"),
                )
              else
                ElevatedButton(
                  onPressed: _navigateToAuth,
                  child: const Text("Se connecter"),
                ),
            ],
          );
        },
      ), // StreamBuilder
    ); // Scaffold
  }
}
