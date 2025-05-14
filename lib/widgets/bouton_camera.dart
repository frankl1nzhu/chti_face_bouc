import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services_firebase/service_firestore.dart';
import '../modeles/constantes.dart';

class BoutonCamera extends StatefulWidget {
  final String type; // profilePictureKey or coverPictureKey
  final String id; // user ID

  const BoutonCamera({super.key, required this.type, required this.id});

  @override
  State<BoutonCamera> createState() => _BoutonCameraState();
}

class _BoutonCameraState extends State<BoutonCamera> {
  bool _isUploading = false;

  // Select and upload image
  Future<void> _takePicture(ImageSource source, BuildContext context) async {
    try {
      final ImagePicker picker = ImagePicker();

      // Choose image, limit size based on type
      final XFile? xFile = await picker.pickImage(
        source: source,
        maxWidth:
            widget.type == profilePictureKey
                ? 500
                : 1000, // Profile smaller, cover larger
        imageQuality: 80, // Appropriate image compression
      );

      if (xFile == null) {
        print("User cancelled image picker");
        return; // User cancelled selection
      }

      setState(() {
        _isUploading = true;
      });

      // Show upload indicator
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 10),
              Text('Uploading image...'),
            ],
          ),
          duration: Duration(minutes: 1), // Long display until upload completes
        ),
      );

      // Convert to File object
      File imageFile = File(xFile.path);
      print(
        "Image selected: ${imageFile.path}, size: ${await imageFile.length()} bytes",
      );

      // Determine folder name
      String folder =
          widget.type == profilePictureKey || widget.type == coverPictureKey
              ? memberCollectionKey
              : postCollectionKey;

      // Execute upload
      await ServiceFirestore().updateImage(
        file: imageFile,
        folder: folder,
        memberId: widget.id,
        imageName: widget.type,
      );

      // Hide loading indicator and show success message
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
        scaffoldMessenger.hideCurrentSnackBar();
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Image updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print("Error during image selection/upload: $e");
      // Set upload status to false when error occurs
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Display different icons based on upload status
    return _isUploading
        ? Container(
          decoration: BoxDecoration(
            color: Colors.black45,
            shape: BoxShape.circle,
          ),
          padding: const EdgeInsets.all(8.0),
          child: const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2,
            ),
          ),
        )
        : IconButton(
          icon: const Icon(
            Icons.camera_alt,
            color: Colors.white,
            shadows: [Shadow(blurRadius: 5.0, color: Colors.black)],
          ),
          onPressed: () {
            if (_isUploading) return; // If uploading, prevent new operations

            // Show options: camera or gallery
            showModalBottomSheet(
              context: context,
              builder: (BuildContext bc) {
                return SafeArea(
                  child: Wrap(
                    children: <Widget>[
                      ListTile(
                        leading: const Icon(Icons.photo_library),
                        title: const Text('Gallery'),
                        onTap: () {
                          _takePicture(ImageSource.gallery, context);
                          Navigator.of(context).pop();
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.photo_camera),
                        title: const Text('Camera'),
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
