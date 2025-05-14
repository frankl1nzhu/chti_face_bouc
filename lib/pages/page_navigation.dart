import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services_firebase/service_authentification.dart';
import '../services_firebase/service_firestore.dart';
import '../modeles/membre.dart';
import '../widgets/widget_vide.dart';
import 'page_accueil.dart';
import 'page_membres.dart';
import 'page_ecrire_post.dart';
import 'page_profil.dart';
import 'page_notifications.dart';

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
    print("Current memberId: $memberId"); // Debug print

    if (memberId == null) {
      // If not logged in, show login prompt
      print("No memberId found, showing login page");
      return Scaffold(
        appBar: AppBar(title: const Text("Authentication")),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Please login to access the application"),
              SizedBox(height: 20),
              CircularProgressIndicator(),
            ],
          ),
        ),
      );
    }

    // Use FutureBuilder to first check if document exists
    return FutureBuilder<DocumentSnapshot>(
      future: ServiceFirestore().firestoreMember.doc(memberId).get(),
      builder: (context, docSnapshot) {
        print(
          "FutureBuilder state: ${docSnapshot.connectionState}, hasData: ${docSnapshot.hasData}",
        );

        // If loading, show loading screen
        if (docSnapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: const Text("Loading...")),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        // Handle errors
        if (docSnapshot.hasError) {
          print("FutureBuilder error: ${docSnapshot.error}");
          return Scaffold(
            appBar: AppBar(
              title: const Text("Error"),
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () async {
                    await ServiceAuthentification().signOut();
                  },
                ),
              ],
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Loading error: ${docSnapshot.error}",
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {}); // Retry by rebuilding
                    },
                    child: const Text("Retry"),
                  ),
                ],
              ),
            ),
          );
        }

        // Check user ID validity again (may have changed during data fetch)
        final currentMemberId = ServiceAuthentification().myId;
        if (currentMemberId == null || currentMemberId != memberId) {
          print("User ID changed during data loading, rebuilding");
          Future.microtask(() => setState(() {}));
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Check if document exists
        if (!docSnapshot.hasData || !docSnapshot.data!.exists) {
          print("Document doesn't exist for ID: $memberId - creating new user");
          // Create new user record
          Map<String, dynamic> defaultUserData = {
            "name": "",
            "surname": "",
            "profilePicture": "",
            "coverPicture": "",
            "description": "",
          };

          // Create document
          ServiceFirestore()
              .addMember(id: memberId, data: defaultUserData)
              .then((_) {
                print("User document created successfully");
                if (mounted) setState(() {});
              })
              .catchError((error) {
                print("Error creating user document: $error");
              });

          // Show profile creation interface
          return Scaffold(
            appBar: AppBar(
              title: const Text("New Profile"),
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () async {
                    await ServiceAuthentification().signOut();
                  },
                ),
              ],
            ),
            body: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text("Creating your profile..."),
                ],
              ),
            ),
          );
        }

        // Document exists, use StreamBuilder for real-time updates
        return StreamBuilder<DocumentSnapshot>(
          stream: ServiceFirestore().specificMember(memberId),
          builder: (
            BuildContext context,
            AsyncSnapshot<DocumentSnapshot> snapshot,
          ) {
            // Debug prints
            print("StreamBuilder state: ${snapshot.connectionState}");
            if (snapshot.hasError) {
              print("StreamBuilder error: ${snapshot.error}");
            }

            // Final check if user ID is still valid
            final finalMemberId = ServiceAuthentification().myId;
            if (finalMemberId == null || finalMemberId != memberId) {
              print("User ID changed before display, rebuilding");
              Future.microtask(() => setState(() {}));
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            // Check connection state
            if (snapshot.connectionState == ConnectionState.waiting) {
              // Use already fetched document data to build Member instead of showing loading
              // This avoids flickering during transitions
              try {
                final data = docSnapshot.data!;
                print("Using cached document data");
                final Membre member = Membre(
                  reference: data.reference,
                  id: data.id,
                  map: data.data() as Map<String, dynamic>,
                );

                return buildScaffoldWithMember(member);
              } catch (e) {
                print("Error using cached data: $e");
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
            }

            // Handle errors or empty data
            if (snapshot.hasError ||
                !snapshot.hasData ||
                snapshot.data?.data() == null) {
              print("Error or empty data in stream: ${snapshot.error}");

              // Try using cached document data
              try {
                final data = docSnapshot.data!;
                print("Using cached document data on error");
                final Membre member = Membre(
                  reference: data.reference,
                  id: data.id,
                  map: data.data() as Map<String, dynamic>,
                );

                return buildScaffoldWithMember(member);
              } catch (e) {
                print("Error using cached data on error: $e");

                // Show error message
                return Scaffold(
                  appBar: AppBar(
                    title: const Text("Error"),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.logout),
                        onPressed: () async {
                          await ServiceAuthentification().signOut();
                        },
                      ),
                    ],
                  ),
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Error loading profile: ${snapshot.error}",
                          style: const TextStyle(fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {}); // Retry
                          },
                          child: const Text("Retry"),
                        ),
                      ],
                    ),
                  ),
                );
              }
            }

            // Have data, create Member object
            try {
              final data = snapshot.data!;
              print("Creating member from stream data: ${data.id}");
              final Membre member = Membre(
                reference: data.reference,
                id: data.id,
                map: data.data() as Map<String, dynamic>,
              );

              print("Member created successfully: ${member.fullName}");
              return buildScaffoldWithMember(member);
            } catch (e) {
              print("Exception in PageNavigation build: $e");

              // Try using cached document data
              try {
                final data = docSnapshot.data!;
                print("Using cached document data after exception");
                final Membre member = Membre(
                  reference: data.reference,
                  id: data.id,
                  map: data.data() as Map<String, dynamic>,
                );

                return buildScaffoldWithMember(member);
              } catch (fallbackError) {
                // Show error message
                return Scaffold(
                  appBar: AppBar(
                    title: const Text("Error"),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.logout),
                        onPressed: () async {
                          await ServiceAuthentification().signOut();
                        },
                      ),
                    ],
                  ),
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Error while loading: $e",
                          style: const TextStyle(fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {}); // Retry
                          },
                          child: const Text("Retry"),
                        ),
                      ],
                    ),
                  ),
                );
              }
            }
          },
        );
      },
    );
  }

  // Extract method to build Scaffold
  Widget buildScaffoldWithMember(Membre member) {
    // Define navigation bar pages
    List<Widget> bodies = [
      const PageAccueil(title: "Home"), // Home page
      const PageMembres(), // Members page
      PageEcrirePost(
        member: member,
        newSelection: (int index) {
          setState(() {
            this.index = index;
          });
        },
      ), // Write post page
      const PageNotifications(), // Notifications page
      PageProfil(member: member), // Profile page with current user
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          member.fullName.isNotEmpty ? member.fullName : "Ch'ti Face Book",
        ), // Show username or default title
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ServiceAuthentification().signOut();
            },
          ),
        ],
      ),
      body: bodies[index], // Show selected page
      bottomNavigationBar: NavigationBar(
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        selectedIndex: index,
        onDestinationSelected: (int newValue) {
          setState(() {
            index = newValue; // Update selected index
          });
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: "Home"),
          NavigationDestination(icon: Icon(Icons.group), label: "Members"),
          NavigationDestination(icon: Icon(Icons.border_color), label: "Write"),
          NavigationDestination(
            icon: Icon(Icons.notifications),
            label: "Notifications",
          ),
          NavigationDestination(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}
