import 'package:flutter/material.dart';
import '../modeles/membre.dart';
import '../modeles/constantes.dart';
import '../services_firebase/service_firestore.dart';
import '../services_firebase/service_authentification.dart';

class PageEditProfil extends StatefulWidget {
  final Membre member;
  const PageEditProfil({super.key, required this.member});

  @override
  State<PageEditProfil> createState() => _PageEditProfilState();
}

class _PageEditProfilState extends State<PageEditProfil> {
  // Controllers for the text fields
  late TextEditingController surnameController;
  late TextEditingController nameController;
  late TextEditingController descriptionController;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with current values
    surnameController = TextEditingController(text: widget.member.surname);
    nameController = TextEditingController(text: widget.member.name);
    descriptionController = TextEditingController(
      text: widget.member.description,
    );
  }

  @override
  void dispose() {
    // Clean up controllers
    surnameController.dispose();
    nameController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  // Validate changes and update Firestore
  void _onValidate() {
    FocusScope.of(context).requestFocus(FocusNode()); // Dismiss keyboard
    Map<String, dynamic> map = {};
    final member = widget.member;

    // Check each field if it has changed and is not empty
    if (nameController.text.isNotEmpty && nameController.text != member.name) {
      map[nameKey] = nameController.text;
    }
    if (surnameController.text.isNotEmpty &&
        surnameController.text != member.surname) {
      map[surnameKey] = surnameController.text;
    }
    if (descriptionController.text != member.description) {
      map[descriptionKey] = descriptionController.text;
    }

    // If any changes were made, update Firestore
    if (map.isNotEmpty) {
      ServiceFirestore()
          .updateMember(id: member.id, data: map)
          .then((_) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Profil mis à jour!')));
            Navigator.pop(context); // Go back to profile page after saving
          })
          .catchError((error) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Erreur: $error')));
          });
    } else {
      Navigator.pop(context); // No changes, just go back
    }
  }

  // Handle logout with confirmation
  void _handleLogout() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmation'),
          content: const Text('Voulez-vous vraiment vous déconnecter?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Close dialog
                await ServiceAuthentification().signOut();
                // Navigation will be handled by StreamBuilder in main.dart
              },
              child: const Text('Déconnecter'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier le profil'),
        actions: [
          IconButton(icon: const Icon(Icons.check), onPressed: _onValidate),
        ],
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Prénom field
              TextField(
                controller: surnameController,
                decoration: const InputDecoration(
                  labelText: 'Prénom',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Nom field
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Description field
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 32),

              // Logout button
              ElevatedButton.icon(
                onPressed: _handleLogout,
                icon: const Icon(Icons.logout),
                label: const Text('Se déconnecter'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade100,
                  foregroundColor: Colors.red.shade900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
