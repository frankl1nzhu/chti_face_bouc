import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../modeles/notification.dart'; // Use NotificationModel
import '../modeles/post.dart'; // For navigating to post
import '../services_firebase/service_firestore.dart';
import '../pages/page_detail_post.dart'; // To navigate to post detail
import '../modeles/membre.dart'; // For sender info
import 'avatar.dart';
import '../modeles/formatage_date.dart'; // For DateHandler

class WidgetNotif extends StatelessWidget {
  final NotificationModel notif;

  const WidgetNotif({super.key, required this.notif});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        // Mark as read and navigate to the post if postId exists
        ServiceFirestore().markRead(notif.reference);
        if (notif.postId.isNotEmpty) {
          ServiceFirestore().firestorePost
              .doc(notif.postId)
              .get()
              .then((snapshot) {
                if (snapshot.exists) {
                  final post = Post(
                    reference: snapshot.reference,
                    id: snapshot.id,
                    map: snapshot.data() as Map<String, dynamic>,
                  );
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) {
                        return PageDetailPost(
                          post: post,
                        ); // Navigate to the post detail
                      },
                    ),
                  );
                } else {
                  print("Post ${notif.postId} not found for notification");
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Ce post n\'existe plus')),
                  );
                }
              })
              .catchError((error) {
                print("Error fetching post for notification: $error");
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Erreur: $error')));
              });
        }
      },
      child: Container(
        color:
            notif.isRead
                ? Colors.transparent
                : Theme.of(
                  context,
                ).primaryColor.withOpacity(0.1), // Highlight unread
        width: MediaQuery.of(context).size.width,
        margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        padding: const EdgeInsets.all(8),
        child: Row(
          // Use Row for Avatar + Text/Date
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sender Avatar
            StreamBuilder<DocumentSnapshot>(
              stream: ServiceFirestore().specificMember(notif.from),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircleAvatar(radius: 20);

                if (snapshot.data?.data() == null) {
                  return const CircleAvatar(
                    radius: 20,
                    child: Icon(Icons.person),
                  );
                }

                final senderData = snapshot.data!;
                final sender = Membre(
                  reference: senderData.reference,
                  id: senderData.id,
                  map: senderData.data() as Map<String, dynamic>,
                );
                return Avatar(radius: 20, url: sender.profilePicture);
              },
            ),
            const SizedBox(width: 8),
            // Notification Text and Date
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(notif.text), // Display notification text
                  const SizedBox(height: 4),
                  DateHandler(timestamp: notif.date), // Display time
                ],
              ),
            ),
          ],
        ), // Row
      ), // Container
    ); // InkWell
  }
}
