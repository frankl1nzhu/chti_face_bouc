import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart'; // Needed for XFile
import '../modeles/constantes.dart'; // Adjust path if necessary
import '../modeles/membre.dart'; // Needed for Membre type
import '../modeles/post.dart'; // Needed for Post type
import 'service_storage.dart'; // Assuming service_storage.dart is in the same directory
import '../services_firebase/service_authentification.dart'; // For myId

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
      print(
        "Updating image for user: $memberId, folder: $folder, imageName: $imageName",
      );

      // 检查文件大小
      final fileSize = await file.length();
      if (fileSize > 5 * 1024 * 1024) {
        // 5MB限制
        print("File too large: $fileSize bytes");
        throw Exception("Le fichier est trop volumineux (max: 5MB)");
      }

      // 获取当前文档，检查是否有旧图片需要删除
      final docSnapshot = await firestoreMember.doc(memberId).get();
      if (docSnapshot.exists) {
        final data = docSnapshot.data() as Map<String, dynamic>?;
        final String? oldImageUrl = data?[imageName] as String?;

        // 如果存在旧图片URL，尝试删除它
        if (oldImageUrl != null && oldImageUrl.isNotEmpty) {
          print("Found old image URL: $oldImageUrl, attempting to delete");
          try {
            await ServiceStorage().deleteImage(imageUrl: oldImageUrl);
          } catch (e) {
            print("Warning: Could not delete old image: $e");
            // 继续处理，即使旧图片删除失败
          }
        }
      }

      // Use ServiceStorage to upload the image
      print("Starting upload of new image");
      String? imageUrl = await ServiceStorage().addImage(
        file: file,
        folder: folder,
        userId: memberId,
        imageName: imageName,
      );

      if (imageUrl != null) {
        print("Upload successful, updating document with new URL: $imageUrl");
        // Update the member document with the new image URL
        await updateMember(id: memberId, data: {imageName: imageUrl});
        print("Document updated successfully");
      } else {
        throw Exception("Échec de l'upload, aucune URL retournée");
      }
    } catch (e) {
      print("Error updating image URL in Firestore: $e");
      rethrow; // Rethrow so the UI can handle it
    }
  }

  // Method to get a specific member document stream
  Stream<DocumentSnapshot<Object?>> specificMember(String? memberId) {
    if (memberId == null) {
      // Return an empty stream or handle appropriately if memberId is null
      return Stream.empty();
    }

    // 首先检查文档是否存在
    DocumentReference docRef = firestoreMember.doc(memberId);

    // 创建一个包含文档检查逻辑的流
    return docRef.snapshots().handleError((error) {
      print("Error in specificMember stream: $error");
      return Stream.empty();
    });
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
      print(
        "Creating post for user: ${member.id}, with image: ${image != null}",
      );
      final date = DateTime.now().millisecondsSinceEpoch; // Use timestamp

      Map<String, dynamic> map = {
        memberIdKey: member.id, // Store author's ID
        likesKey: [], // Initialize likes array
        dateKey: date,
        textKey: text,
      };

      String? imageUrl;
      if (image != null) {
        // 检查文件大小
        final file = File(image.path);
        final fileSize = await file.length();

        if (fileSize > 10 * 1024 * 1024) {
          // 10MB限制
          print("Post image too large: $fileSize bytes");
          throw Exception("L'image est trop volumineuse (max: 10MB)");
        }

        print("Uploading post image, size: $fileSize bytes");
        // Upload image using ServiceStorage
        imageUrl = await ServiceStorage().addImage(
          file: file,
          folder: postCollectionKey, // Store in 'posts' folder
          userId: member.id, // Subfolder by user ID
          imageName: date.toString(), // Use timestamp as image name
        );

        if (imageUrl != null) {
          print("Post image uploaded successfully: $imageUrl");
          map[postImageKey] = imageUrl; // Add image URL to map
        } else {
          print("Post image upload failed, continuing without image");
        }
      }

      // Add the post data to Firestore
      print("Adding post to Firestore");
      DocumentReference postRef = await firestorePost.add(map);
      print("Post created with ID: ${postRef.id}");
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

  // Ajouter un commentaire sur un post
  Future<void> addComment({required Post post, required String text}) async {
    final memberId = ServiceAuthentification().myId; // Get current user ID
    if (memberId == null || text.trim().isEmpty) return; // Need user and text

    Map<String, dynamic> map = {
      memberIdKey: memberId,
      dateKey: DateTime.now().millisecondsSinceEpoch,
      textKey: text.trim(), // Trim whitespace
    };

    try {
      // Add comment to the subcollection of the post
      await post.reference.collection(commentCollectionKey).add(map);
    } catch (e) {
      print("Error adding comment: $e");
    }
  }

  // Lire les commentaires sur un post, ordered by date ascending
  Stream<QuerySnapshot<Object?>> postComment(String postId) =>
      firestorePost
          .doc(postId)
          .collection(commentCollectionKey)
          .orderBy(dateKey, descending: false) // Show oldest comments first
          .snapshots();

  // Envoyer une notification à un utilisateur specific ('to' is the recipient's member ID)
  Future<void> sendNotification({
    required String to, // Recipient Member ID
    required String text, // Notification message
    required String?
    postId, // Related Post ID (can be null for other notifications)
  }) async {
    final memberId = ServiceAuthentification().myId; // Sender ID
    print(
      "NOTIFICATION DEBUG - Sender: $memberId, Recipient: $to, Text: $text, PostId: $postId",
    );

    if (memberId == null) {
      print("NOTIFICATION ERROR - No sender ID available");
      return;
    }

    if (to == memberId) {
      print(
        "NOTIFICATION SKIP - Cannot notify yourself (to: $to, memberId: $memberId)",
      );
      return; // Cannot notify yourself
    }

    Map<String, dynamic> map = {
      dateKey: DateTime.now().millisecondsSinceEpoch,
      isReadKey: false, // Initially unread
      fromKey: memberId,
      textKey: text,
      if (postId != null)
        postIdKey: postId, // Only include if postId is provided
    };

    try {
      print("NOTIFICATION SENDING - to=$to from=$memberId text=$text");
      // Add notification to the recipient's notification subcollection
      final DocumentReference notifRef = await firestoreMember
          .doc(to)
          .collection(notificationCollectionKey)
          .add(map); // Use add() for auto-ID
      print("NOTIFICATION SENT - ID: ${notifRef.id}");
    } catch (e) {
      print("NOTIFICATION ERROR - Failed to send: $e");
    }
  }

  // Marquer une notification comme lue
  Future<void> markRead(DocumentReference reference) async {
    try {
      print("Marking notification as read: ${reference.path}");
      await reference.update({isReadKey: true});
      print("Notification marked as read");
    } catch (e) {
      print("Error marking notification as read: $e");
    }
  }

  // Liste des notifications pour un membre specific, ordered by date descending
  Stream<QuerySnapshot<Object?>> notificationForUser(String id) {
    print("Getting notifications for user: $id");
    return firestoreMember
        .doc(id)
        .collection(notificationCollectionKey)
        .orderBy(dateKey, descending: true) // Show newest first
        .snapshots();
  }

  // --- Add methods for Posts, Comments, Notifications later ---
}
