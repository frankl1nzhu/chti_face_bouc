import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services_firebase/service_firestore.dart'; // For updateImage
import '../modeles/constantes.dart'; // For collection key

class BoutonCamera extends StatelessWidget {
  final String type; // e.g., profilePictureKey or coverPictureKey
  final String id; // Member ID

  const BoutonCamera({super.key, required this.type, required this.id});

  // Method to pick and upload image
  Future<void> _takePicture(ImageSource source, BuildContext context) async {
    final ImagePicker picker = ImagePicker();
    // Pick an image
    final XFile? xFile = await picker.pickImage(
      source: source,
      maxWidth: 500,
    ); // Limit width

    if (xFile == null) return; // User cancelled picker

    File imageFile = File(xFile.path);

    // Call Firestore service to upload and update the member document
    // Show loading indicator?
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Téléchargement de l\'image...')),
    );

    await ServiceFirestore().updateImage(
      file: imageFile,
      folder:
          memberCollectionKey, // Or a specific folder like 'profile_pics'/'cover_pics'
      memberId: id,
      imageName: type, // Use the type as the field name to update
    );
    ScaffoldMessenger.of(context).hideCurrentSnackBar(); // Hide loading
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Image mise à jour!')));
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(
        Icons.camera_alt,
        color: Colors.white,
        shadows: [Shadow(blurRadius: 5.0, color: Colors.black)],
      ), // Add shadow for visibility
      onPressed: () {
        // Show options: Camera or Gallery
        showModalBottomSheet(
          context: context,
          builder: (BuildContext bc) {
            return SafeArea(
              child: Wrap(
                children: <Widget>[
                  ListTile(
                    leading: const Icon(Icons.photo_library),
                    title: const Text('Galerie'),
                    onTap: () {
                      _takePicture(ImageSource.gallery, context);
                      Navigator.of(context).pop();
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.photo_camera),
                    title: const Text('Caméra'),
                    onTap: () {
                      _takePicture(ImageSource.camera, context);
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
