import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class ServiceStorage {
  static final instance = FirebaseStorage.instance;
  Reference get ref => instance.ref(); // Base reference

  // Method to upload an image and return the download URL
  Future<String?> addImage({
    required File file, // The image file
    required String folder, // Folder name (e.g., 'profile_pics', 'post_images')
    required String userId, // User ID for subfolder structure
    required String
    imageName, // Unique name for the image (e.g., timestamp, UUID)
  }) async {
    try {
      // Create reference: /folder/userId/imageName.jpg (or other extension)
      final reference = ref.child(folder).child(userId).child(imageName);
      // Upload the file
      UploadTask task = reference.putFile(file);
      // Wait for upload completion
      TaskSnapshot snapshot = await task.whenComplete(() => null);
      // Get the download URL
      String imageUrl = await snapshot.ref.getDownloadURL();
      return imageUrl;
    } catch (e) {
      print("Error uploading image: $e");
      return null; // Return null on error
    }
  }
}
