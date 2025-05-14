import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../modeles/post.dart';
import '../modeles/membre.dart';
import '../services_firebase/service_firestore.dart';
import '../services_firebase/service_authentification.dart';
import 'avatar.dart';
import '../modeles/formatage_date.dart';
import '../pages/page_detail_post_page.dart';

class WidgetPost extends StatelessWidget {
  final Post post;
  const WidgetPost({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    String? myId = ServiceAuthentification().myId;
    bool iLiked = (myId != null) && post.likes.contains(myId);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 5),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Post Header: Author Info ---
            StreamBuilder<DocumentSnapshot>(
              // Stream to get author details
              stream: ServiceFirestore().specificMember(post.memberId),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const SizedBox(height: 40); // Placeholder height
                final authorData = snapshot.data!;
                final author = Membre(
                  reference: authorData.reference,
                  id: authorData.id,
                  map: authorData.data() as Map<String, dynamic>,
                );
                return Row(
                  children: [
                    Avatar(radius: 20, url: author.profilePicture),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          author.fullName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        DateHandler(
                          timestamp: post.date.millisecondsSinceEpoch,
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 8),

            // --- Post Content ---
            if (post.text.isNotEmpty) Text(post.text),
            if (post.text.isNotEmpty &&
                post.imageUrl != null &&
                post.imageUrl!.isNotEmpty)
              const SizedBox(height: 8), // Spacing if both text and image
            if (post.imageUrl != null && post.imageUrl!.isNotEmpty)
              Center(
                child: Image.network(
                  post.imageUrl!,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value:
                            loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                      ),
                    );
                  },
                  errorBuilder:
                      (context, error, stackTrace) => const Center(
                        child: Text("Impossible de charger l'image"),
                      ),
                ),
              ),

            const Divider(),

            // --- Post Footer: Likes and Comments ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Like Button
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        iLiked ? Icons.star : Icons.star_border,
                        color:
                            iLiked
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey,
                      ),
                      onPressed: () {
                        if (myId != null) {
                          print(
                            "LIKE DEBUG - MyId: $myId, PostId: ${post.id}, Author: ${post.memberId}, Already liked: $iLiked",
                          );

                          ServiceFirestore().addLike(
                            memberID: myId,
                            post: post,
                          ); // Call like method

                          // Send notification if this is not our own post
                          if (myId != post.memberId && !iLiked) {
                            print(
                              "LIKE NOTIFICATION - Sending notification from $myId to ${post.memberId}",
                            );
                            ServiceFirestore().sendNotification(
                              to: post.memberId,
                              text: "a aimé votre publication",
                              postId: post.id,
                            );
                          } else {
                            print(
                              "LIKE NOTIFICATION SKIP - myId: $myId, authorId: ${post.memberId}, already liked: $iLiked",
                            );
                          }
                        }
                      },
                    ),
                    Text('${post.likes.length} Likes'), // Display like count
                  ],
                ),

                // Comment Button
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.messenger_outline),
                      onPressed: () {
                        // Navigate to Comment Page
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PageDetailPost(post: post),
                          ),
                        );
                      },
                    ),
                    const Text('Commenter'),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
