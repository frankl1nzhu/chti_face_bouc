import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart'; // Needed for XFile
import '../modeles/constantes.dart'; // Adjust path if necessary
import '../modeles/membre.dart'; // Needed for Membre type
import '../modeles/post.dart'; // Needed for Post type
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

  // Lire la liste de tous les posts, ordered by date descending
  Stream<QuerySnapshot<Object?>> allPosts() =>
      firestorePost.orderBy(dateKey, descending: true).snapshots();

  // Lire des posts d'un utilisateur specific
  Stream<QuerySnapshot<Object?>> postForMember(String id) =>
      firestorePost
          .where(memberIdKey, isEqualTo: id)
          .orderBy(dateKey, descending: true)
          .snapshots();

  // Lire la liste de tous les membres
  Stream<QuerySnapshot<Object?>> allMembers() => firestoreMember.snapshots();

  // Create a new post with optional image
  Future<void> createPost({
    required Membre member, // Pass the author's Membre object
    required String text,
    required XFile? image, // Image file (can be null)
  }) async {
    try {
      final date = DateTime.now().millisecondsSinceEpoch; // Use timestamp
      Map<String, dynamic> map = {
        memberIdKey: member.id, // Store author's ID
        likesKey: [], // Initialize likes array
        dateKey: date,
        textKey: text,
      };

      String? imageUrl;
      if (image != null) {
        // Upload image using ServiceStorage if provided
        File imageFile = File(image.path);
        imageUrl = await ServiceStorage().addImage(
          file: imageFile,
          folder: postCollectionKey, // Store in 'posts' folder
          userId: member.id, // Subfolder by user ID
          imageName: date.toString(), // Use timestamp as image name
        );
        if (imageUrl != null) {
          map[postImageKey] =
              imageUrl; // Add image URL to map if upload successful
        }
      }

      // Add the post data to Firestore
      await firestorePost.add(map); // Use add() to auto-generate document ID
    } catch (e) {
      print("Error creating post: $e");
      // Handle error appropriately
      rethrow; // Re-throw to let caller handle the error
    }
  }

  // Add or remove a like from a post
  Future<void> addLike({required String memberID, required Post post}) async {
    try {
      if (post.likes.contains(memberID)) {
        // If already liked, remove the like
        await post.reference.update({
          likesKey: FieldValue.arrayRemove([memberID]),
        });
      } else {
        // If not liked, add the like
        await post.reference.update({
          likesKey: FieldValue.arrayUnion([memberID]),
        });
      }
    } catch (e) {
      print("Error updating like: $e");
    }
  }

  // --- Add methods for Posts, Comments, Notifications later ---
}
