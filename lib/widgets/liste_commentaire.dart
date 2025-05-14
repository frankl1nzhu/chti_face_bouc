import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services_firebase/service_firestore.dart';
import '../modeles/commentaire.dart';
import '../modeles/membre.dart';
import 'avatar.dart';
import '../modeles/formatage_date.dart';
import '../widgets/widget_vide.dart';

class ListeCommentaire extends StatelessWidget {
  final String postId;
  const ListeCommentaire({super.key, required this.postId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: ServiceFirestore().postComment(postId), // Stream for comments
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError ||
            !snapshot.hasData ||
            snapshot.data!.docs.isEmpty) {
          // Optionally show a message if no comments
          return const Padding(
            padding: EdgeInsets.all(8.0),
            child: Center(child: Text("Aucun commentaire pour le moment.")),
          );
        }

        final docs = snapshot.data!.docs;

        // Use ListView.builder or Column for comments
        return ListView.separated(
          shrinkWrap: true,
          physics:
              const NeverScrollableScrollPhysics(), // Disable scrolling if inside another scroll view
          itemCount: docs.length,
          separatorBuilder:
              (context, index) => const Divider(height: 1, indent: 50),
          itemBuilder: (context, index) {
            final doc = docs[index];
            final commentaire = Commentaire(
              reference: doc.reference,
              id: doc.id,
              map: doc.data() as Map<String, dynamic>,
            );

            // Fetch author info for each comment
            return StreamBuilder<DocumentSnapshot>(
              stream: ServiceFirestore().specificMember(commentaire.memberId),
              builder: (context, authorSnapshot) {
                if (!authorSnapshot.hasData)
                  return const ListTile(title: Text("..."));
                final authorData = authorSnapshot.data!;
                final author = Membre(
                  reference: authorData.reference,
                  id: authorData.id,
                  map: authorData.data() as Map<String, dynamic>,
                );
                return ListTile(
                  leading: Avatar(radius: 18, url: author.profilePicture),
                  title: Text(
                    author.fullName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Text(commentaire.text),
                  trailing: DateHandler(
                    timestamp: commentaire.date,
                  ), // Show comment time
                );
              },
            );
          },
        ); // ListView.separated
      }, // builder
    ); // StreamBuilder
  }
}
