import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services_firebase/service_authentification.dart';
import '../services_firebase/service_firestore.dart';
import '../modeles/membre.dart'; // Import Membre model
import '../widgets/widget_vide.dart'; // Import helper widgets
// Import page widgets (PageAccueil, PageMembres, PageEcrirePost, PageNotif, PageProfil)
import 'page_accueil.dart';
import 'page_membres.dart';
import 'page_ecrire_post.dart';
import 'page_profil.dart';

class PageNavigation extends StatefulWidget {
  const PageNavigation({super.key});

  @override
  State<PageNavigation> createState() => _PageNavigationState();
}

class _PageNavigationState extends State<PageNavigation> {
  int index = 0; // Current page index

  @override
  Widget build(BuildContext context) {
    final memberId = ServiceAuthentification().myId;

    return (memberId == null)
        ? const EmptyScaffold() // Show loading/empty scaffold if not logged in
        : StreamBuilder<DocumentSnapshot>(
          stream: ServiceFirestore().specificMember(
            memberId,
          ), // Stream to get current user data
          builder: (
            BuildContext context,
            AsyncSnapshot<DocumentSnapshot> snapshot,
          ) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const EmptyScaffold(); // Show loading while fetching user data
            }
            if (snapshot.hasError ||
                !snapshot.hasData ||
                snapshot.data?.data() == null) {
              print("Error fetching member: ${snapshot.error}");
              // Handle error state, maybe show an error message or retry option
              return const Scaffold(
                body: Center(child: Text("Erreur de chargement du profil")),
              );
            }

            // If data is available, create the Membre object
            final data = snapshot.data!;
            final Membre member = Membre(
              reference: data.reference,
              id: data.id,
              map: data.data() as Map<String, dynamic>,
            ); // Membre

            // Define the different pages (bodies) for the navigation bar
            List<Widget> bodies = [
              const PageAccueil(title: "Accueil"), // Home page
              const PageMembres(), // Members page
              PageEcrirePost(
                member: member,
                newSelection: (int index) {
                  setState(() {
                    this.index = index;
                  });
                },
              ), // Write post page
              const Center(
                child: Text("Notifications"),
              ), // Placeholder - Replace in Step 12
              PageProfil(member: member), // Profile page with current user
              // Replace placeholders with actual Page Widgets later, passing 'member' if needed
            ];

            return Scaffold(
              appBar: AppBar(
                title: Text(
                  member.fullName.isNotEmpty
                      ? member.fullName
                      : "Cht'i Face Bouc",
                ), // Show user name or default title
                // Add logout button?
                actions: [
                  IconButton(
                    icon: const Icon(Icons.logout),
                    onPressed: () async {
                      await ServiceAuthentification().signOut();
                      // Navigator might need adjustment depending on how auth state is handled (e.g., StreamBuilder in main)
                    },
                  ),
                ],
              ), // AppBar
              body: bodies[index], // Show the selected page
              bottomNavigationBar: NavigationBar(
                labelBehavior:
                    NavigationDestinationLabelBehavior.onlyShowSelected,
                selectedIndex: index,
                onDestinationSelected: (int newValue) {
                  setState(() {
                    index = newValue; // Update the selected index
                  });
                },
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.home),
                    label: "Accueil",
                  ), // NavigationDestination
                  NavigationDestination(
                    icon: Icon(Icons.group),
                    label: "Membres",
                  ), // NavigationDestination
                  NavigationDestination(
                    icon: Icon(Icons.border_color), // Or Icons.edit
                    label: "Ecrire",
                  ), // NavigationDestination
                  NavigationDestination(
                    icon: Icon(Icons.notifications),
                    label: "Notification",
                  ), // NavigationDestination
                  NavigationDestination(
                    icon: Icon(Icons.person),
                    label: "Profil",
                  ), // NavigationDestination
                ],
              ), // NavigationBar
            ); // Scaffold
          },
        ); // StreamBuilder
  }
}
