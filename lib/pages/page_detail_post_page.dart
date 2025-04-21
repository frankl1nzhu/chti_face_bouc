import 'package:flutter/material.dart';
import '../modeles/post.dart';
import '../services_firebase/service_firestore.dart';
import '../widgets/post_widget.dart';
import '../widgets/liste_commentaire.dart';

class PageDetailPost extends StatefulWidget {
  final Post post;

  const PageDetailPost({super.key, required this.post});

  @override
  State<PageDetailPost> createState() => _PageDetailPostState();
}

class _PageDetailPostState extends State<PageDetailPost> {
  final TextEditingController commentController = TextEditingController();

  @override
  void dispose() {
    commentController.dispose();
    super.dispose();
  }

  void _addComment() {
    final text = commentController.text;
    if (text.trim().isEmpty) return; // Don't add empty comments

    ServiceFirestore().addComment(post: widget.post, text: text).then((_) {
      commentController.clear(); // Clear input field after sending
      FocusScope.of(context).requestFocus(FocusNode()); // Dismiss keyboard
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Commentaires')),
      body: GestureDetector(
        // Dismiss keyboard when tapping outside text field
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Display the original post
              WidgetPost(post: widget.post),

              // Comment input field
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: commentController,
                        decoration: const InputDecoration(
                          hintText: 'Ajouter un commentaire...',
                          border: OutlineInputBorder(),
                        ),
                        minLines: 1,
                        maxLines: 3,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: _addComment,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // Display comments
              ListeCommentaire(postId: widget.post.id),

              // Add padding at the bottom to ensure visibility when keyboard appears
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }
}
