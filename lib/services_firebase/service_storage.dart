import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;

class ServiceStorage {
  // Singleton pattern implementation
  static final ServiceStorage _instance = ServiceStorage._internal();

  factory ServiceStorage() {
    return _instance;
  }

  ServiceStorage._internal();

  // Get Firebase Storage instance
  static final instance = FirebaseStorage.instance;
  Reference get ref => instance.ref();

  // Upload image and return download URL
  Future<String?> addImage({
    required File file, // Image file
    required String folder, // Folder name (e.g., 'members', 'posts')
    required String userId, // User ID, used for subfolder structure
    required String imageName, // Image name (e.g., timestamp, UUID)
  }) async {
    try {
      print(
        "Starting upload process for image in folder: $folder, userId: $userId, imageName: $imageName",
      );

      // Get file extension
      final fileExtension = path.extension(file.path).toLowerCase();
      final validExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp'];

      if (!validExtensions.contains(fileExtension)) {
        print("Error: Invalid file extension: $fileExtension");
        return null;
      }

      // Create reference: /folder/userId/imageName.ext
      final String fileName = "$imageName$fileExtension";
      final reference = ref.child(folder).child(userId).child(fileName);

      print("Created storage reference: ${reference.fullPath}");

      // Set metadata
      final metadata = SettableMetadata(
        contentType: 'image/${fileExtension.substring(1)}',
        customMetadata: {
          'userId': userId,
          'uploadDate': DateTime.now().toString(),
        },
      );

      // Upload file
      print("Starting file upload...");
      UploadTask task = reference.putFile(file, metadata);

      // Monitor upload status
      task.snapshotEvents.listen(
        (TaskSnapshot snapshot) {
          final progress =
              (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
          print("Upload progress: ${progress.toStringAsFixed(2)}%");
        },
        onError: (error) {
          print("Upload error during progress monitoring: $error");
        },
      );

      // Wait for upload to complete
      print("Waiting for upload completion...");
      TaskSnapshot snapshot = await task;

      // Get download URL
      print("Upload complete, getting download URL...");
      String imageUrl = await snapshot.ref.getDownloadURL();

      print("Image uploaded successfully: $imageUrl");
      return imageUrl;
    } on FirebaseException catch (e) {
      print("Firebase Storage error: [${e.code}] ${e.message}");
      if (e.code == 'unauthorized') {
        print("User doesn't have permission to access the storage location");
      } else if (e.code == 'canceled') {
        print("Upload was canceled");
      } else if (e.code == 'object-not-found') {
        print("No object exists at the desired reference");
      } else if (e.code == 'quota-exceeded') {
        print("Quota on your Firebase Storage bucket has been exceeded");
      }
      return null;
    } catch (e) {
      print("Error uploading image: $e");
      return null;
    }
  }

  // Delete image from storage
  Future<bool> deleteImage({required String imageUrl}) async {
    try {
      // Get storage reference from URL
      print("Attempting to delete image: $imageUrl");
      Reference ref = FirebaseStorage.instance.refFromURL(imageUrl);
      await ref.delete();
      print("Image deleted successfully");
      return true;
    } on FirebaseException catch (e) {
      print("Firebase delete error: [${e.code}] ${e.message}");
      return false;
    } catch (e) {
      print("Error deleting image: $e");
      return false;
    }
  }
}
