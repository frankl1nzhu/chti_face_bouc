import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services_firebase/service_firestore.dart';
import '../modeles/membre.dart';
import '../widgets/widget_vide.dart';
import '../widgets/avatar.dart'; // Use Avatar widget
import 'page_profil.dart'; // To navigate to member's profile

class PageMembres extends StatefulWidget {
  const PageMembres({super.key});

  @override
  State<PageMembres> createState() => _PageMembresState();
}

class _PageMembresState extends State<PageMembres> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: ServiceFirestore().allMembers(), // Fetch all members
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError ||
            !snapshot.hasData ||
            snapshot.data!.docs.isEmpty) {
          return const EmptyBody();
        }

        final docs = snapshot.data!.docs;

        return ListView.separated(
          itemCount: docs.length,
          separatorBuilder: (context, index) => const Divider(),
          itemBuilder: (context, index) {
            final doc = docs[index];
            final member = Membre(
              reference: doc.reference,
              id: doc.id,
              map: doc.data() as Map<String, dynamic>,
            );

            // Display each member in a ListTile
            return ListTile(
              leading: Avatar(
                radius: 25,
                url: member.profilePicture,
              ), // Show member avatar
              title: Text(member.fullName),
              subtitle:
                  member.description.isNotEmpty
                      ? Text(
                        member.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )
                      : null,
              onTap: () {
                // Navigate to the selected member's profile page
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PageProfil(member: member),
                  ),
                );
              },
            ); // ListTile
          }, // itemBuilder
        ); // ListView.separated
      }, // builder
    ); // StreamBuilder
  }
}
