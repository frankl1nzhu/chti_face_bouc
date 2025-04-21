import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../modeles/constantes.dart'; // Adjust path if necessary
import 'service_storage.dart'; // Assuming service_storage.dart is in the same directory

class ServiceFirestore {
  // Accès a la BDD
  static final instance = FirebaseFirestore.instance;

  // Accès spécifique collections
  final CollectionReference firestoreMember = instance.collection(
    memberCollectionKey,
  );
  final CollectionReference firestorePost = instance.collection(
    postCollectionKey,
  );
  // Add other collections if needed (comments, notifications)

  // Ajouter un membre (call this after successful account creation)
  Future<void> addMember({
    required String id,
    required Map<String, dynamic> data,
  }) async {
    try {
      await firestoreMember.doc(id).set(data);
    } catch (e) {
      print("Error adding member: $e");
    }
  }

  // Mettre à jour un membre
  Future<void> updateMember({
    required String id,
    required Map<String, dynamic> data,
  }) async {
    try {
      await firestoreMember.doc(id).update(data);
    } catch (e) {
      print("Error updating member: $e");
    }
  }

  // Stockage et mise à jour d'une image pour un membre (profile or cover)
  Future<void> updateImage({
    required File file,
    required String folder, // e.g., memberCollectionKey
    required String memberId,
    required String imageName, // e.g., profilePictureKey or coverPictureKey
  }) async {
    try {
      // Use ServiceStorage to upload the image
      String? imageUrl = await ServiceStorage().addImage(
        file: file,
        folder:
            folder, // Use collection key as base folder? Or specific folders like 'profile_pics'
        userId: memberId,
        imageName: imageName, // Or generate a unique name if needed
      );

      if (imageUrl != null) {
        // Update the member document with the new image URL
        await updateMember(
          id: memberId,
          data: {imageName: imageUrl},
        ); // Use imageName as the field key
      }
    } catch (e) {
      print("Error updating image URL in Firestore: $e");
    }
  }

  // Method to get a specific member document stream
  Stream<DocumentSnapshot<Object?>> specificMember(String? memberId) {
    if (memberId == null) {
      // Return an empty stream or handle appropriately if memberId is null
      return Stream.empty();
    }
    return firestoreMember.doc(memberId).snapshots();
  }

  // --- Add methods for Posts, Comments, Notifications later ---
}
