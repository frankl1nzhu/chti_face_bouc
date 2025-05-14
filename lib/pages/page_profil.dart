import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services_firebase/service_authentification.dart';
import '../services_firebase/service_firestore.dart';
import '../modeles/membre.dart';
import '../modeles/post.dart';
import '../modeles/constantes.dart';
import '../widgets/avatar.dart';
import '../widgets/bouton_camera.dart';
import '../widgets/post_widget.dart';
import 'page_edit_profil.dart';

class PageProfil extends StatefulWidget {
  final Membre member; // Pass the member whose profile is being viewed
  const PageProfil({super.key, required this.member});

  @override
  State<PageProfil> createState() => _PageProfilState();
}

class _PageProfilState extends State<PageProfil> {
  @override
  Widget build(BuildContext context) {
    final bool isMe = ServiceAuthentification().isMe(widget.member.id);

    return StreamBuilder<QuerySnapshot>(
      // Stream for the member's posts
      stream: ServiceFirestore().postForMember(
        widget.member.id,
      ), // Use postForMember
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        final postDocs = snapshot.data?.docs;
        final postCount = postDocs?.length ?? 0;
        // Determine the number of items in ListView: header + edit button (if isMe) + posts
        final int headerItems = 1; // Always show the header
        final int indexToAdd = headerItems; // Start with header

        return ListView.builder(
          itemCount:
              postCount + indexToAdd, // Total items = header items + post count
          itemBuilder: (context, index) {
            if (index == 0) {
              // --- Build Profile Header ---
              return Column(
                children: [
                  SizedBox(
                    // Container for Cover Photo and Profile Pic
                    height: 225, // Adjust height as needed
                    child: Stack(
                      alignment: Alignment.bottomLeft,
                      children: [
                        // Cover Photo Container
                        Container(
                          height: 200,
                          width: MediaQuery.of(context).size.width,
                          color:
                              Theme.of(context)
                                  .colorScheme
                                  .primaryContainer, // Placeholder color
                          child:
                              widget.member.coverPicture.isNotEmpty
                                  ? Image.network(
                                    widget.member.coverPicture,
                                    fit: BoxFit.cover,
                                  )
                                  : const Center(
                                    child: Icon(Icons.landscape, size: 50),
                                  ), // Placeholder Icon
                        ),
                        // Cover Photo Edit Button (Bottom Right of Cover)
                        if (isMe)
                          Positioned(
                            bottom: 30, // Adjust position relative to avatar
                            right: 5,
                            child: BoutonCamera(
                              type: coverPictureKey,
                              id: widget.member.id,
                            ),
                          ),

                        // Profile Picture Avatar (Overlapping bottom left)
                        Positioned(
                          bottom: 0,
                          left: 10,
                          child: Avatar(
                            radius: 50, // Adjust size
                            url: widget.member.profilePicture,
                          ),
                        ),

                        // Profile Pic Edit Button (Bottom Right of Avatar)
                        if (isMe)
                          Positioned(
                            bottom: 5,
                            left: 70, // Adjust position
                            child: BoutonCamera(
                              type: profilePictureKey,
                              id: widget.member.id,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10), // Spacing
                  // User Name and Edit Button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          widget.member.fullName,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        if (isMe)
                          OutlinedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) =>
                                          PageEditProfil(member: widget.member),
                                ),
                              );
                            },
                            child: const Text("Modifier le profil"),
                          ),
                      ],
                    ),
                  ),
                  const Divider(),
                  // Description
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      widget.member.description.isNotEmpty
                          ? widget.member.description
                          : "Aucune description",
                    ),
                  ),
                  const Divider(), // Separator before posts
                ],
              ); // End Profile Header Column
            } else {
              // --- Build Post Item ---
              final postIndex =
                  index - indexToAdd; // Adjust index for posts array
              if (postDocs == null || postIndex >= postDocs.length) {
                return Container(); // Should not happen if itemCount is correct
              }
              final currentDoc = postDocs[postIndex];
              final post = Post(
                reference: currentDoc.reference,
                id: currentDoc.id,
                map: currentDoc.data() as Map<String, dynamic>,
              );
              // Return WidgetPost instead of the placeholder Card
              return WidgetPost(post: post);
            }
          }, // itemBuilder
        ); // ListView.builder
      }, // builder for StreamBuilder
    ); // StreamBuilder
  } // build method
} // _PageProfilState class
