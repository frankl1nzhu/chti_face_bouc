import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // For date formatting
import '../services_firebase/service_authentification.dart';
import 'page_authentification.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services_firebase/service_firestore.dart';
import '../widgets/widget_vide.dart'; // EmptyBody helper
import '../modeles/constantes.dart'; // Import constants for field keys
// Import WidgetPost (created in Step 9)
import '../widgets/post_widget.dart'; // Import WidgetPost
// Import Post model (created in Step 6)
import '../modeles/post.dart';

class PageAccueil extends StatefulWidget {
  const PageAccueil({super.key, required this.title});
  final String title;

  @override
  State<PageAccueil> createState() => _PageAccueilState();
}

class _PageAccueilState extends State<PageAccueil> {
  final ServiceAuthentification _auth = ServiceAuthentification();

  void _navigateToAuth() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PageAuthentification()),
    );
  }

  // 创建一个函数来获取作者信息
  Widget buildPost(
    BuildContext context,
    Map<String, dynamic> data,
    String docId,
    DocumentReference reference,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 使用FutureBuilder获取作者信息
            FutureBuilder<DocumentSnapshot>(
              future:
                  ServiceFirestore().firestoreMember
                      .doc(data[memberIdKey])
                      .get(),
              builder: (context, memberSnapshot) {
                if (memberSnapshot.connectionState == ConnectionState.waiting) {
                  return const Text("Chargement de l'auteur...");
                }

                String authorName = "Auteur inconnu";
                if (memberSnapshot.hasData && memberSnapshot.data != null) {
                  final memberData =
                      memberSnapshot.data!.data() as Map<String, dynamic>?;
                  if (memberData != null) {
                    final surname = memberData[surnameKey] ?? '';
                    final name = memberData[nameKey] ?? '';
                    authorName = "$surname $name";
                  }
                }

                return Text(
                  "Auteur: $authorName",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                );
              },
            ),
            const SizedBox(height: 8),
            Text("Texte: ${data[textKey] ?? 'No content'}"),
            const SizedBox(height: 8),
            if (data[dateKey] != null)
              Text(
                "Date: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.fromMillisecondsSinceEpoch(data[dateKey] as int))}",
              ),
            const SizedBox(height: 8),
            if (data[likesKey] != null)
              Text("Likes: ${(data[likesKey] as List).length}"),

            // 如果有图片，显示图片
            if (data[postImageKey] != null &&
                data[postImageKey].toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Image.network(
                  data[postImageKey],
                  fit: BoxFit.cover,
                  width: double.infinity,
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
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Text("Impossible de charger l'image"),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ), // AppBar
      body: StreamBuilder<QuerySnapshot>(
        stream: ServiceFirestore().allPosts(), // Use the new method
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError ||
              !snapshot.hasData ||
              snapshot.data!.docs.isEmpty) {
            return const EmptyBody(); // Show message if no posts or error
          }

          // If data is available
          final docs = snapshot.data!.docs;
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              // Create Post object and use WidgetPost
              final post = Post(
                reference: doc.reference,
                id: doc.id,
                map: data,
              );
              return WidgetPost(post: post);
            },
          ); // ListView.builder
        },
      ), // StreamBuilder
    ); // Scaffold
  }
}
