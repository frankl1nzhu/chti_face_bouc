import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../modeles/post.dart';
import '../modeles/membre.dart';
import '../services_firebase/service_firestore.dart';
import '../services_firebase/service_authentification.dart';
import '../widgets/widget_vide.dart';
import '../widgets/avatar.dart';
import '../modeles/constantes.dart';
import '../modeles/formatage_date.dart';

class PageDetailPost extends StatefulWidget {
  final Post post;

  const PageDetailPost({super.key, required this.post});

  @override
  State<PageDetailPost> createState() => _PageDetailPostState();
}

class _PageDetailPostState extends State<PageDetailPost> {
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _sendComment() async {
    if (_commentController.text.trim().isEmpty) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      await ServiceFirestore().addComment(
        post: widget.post,
        text: _commentController.text.trim(),
      );

      // Send notification to post owner (unless it's ourselves)
      final currentUserId = ServiceAuthentification().myId;
      if (currentUserId != null && currentUserId != widget.post.memberId) {
        await ServiceFirestore().sendNotification(
          to: widget.post.memberId,
          text: "commented on your post",
          postId: widget.post.id,
        );
      }

      _commentController.clear();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error sending: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Post Details')),
      body: Column(
        children: [
          // Post display
          StreamBuilder<DocumentSnapshot>(
            stream: ServiceFirestore().specificMember(widget.post.memberId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data?.data() == null) {
                return const Center(child: Text('Unable to load post'));
              }

              final data = snapshot.data!;
              final Membre member = Membre(
                reference: data.reference,
                id: data.id,
                map: data.data() as Map<String, dynamic>,
              );

              return Card(
                margin: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      leading: Avatar(radius: 20, url: member.profilePicture),
                      title: Text(member.fullName),
                      subtitle: DateHandler(
                        timestamp: widget.post.date.millisecondsSinceEpoch,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Text(widget.post.text),
                    ),
                    if (widget.post.imageUrl != null &&
                        widget.post.imageUrl!.isNotEmpty)
                      Image.network(
                        widget.post.imageUrl!,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton.icon(
                            icon: Icon(
                              widget.post.likes.contains(
                                    ServiceAuthentification().myId,
                                  )
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: Colors.red,
                            ),
                            label: Text('${widget.post.likes.length}'),
                            onPressed: () {
                              final userId = ServiceAuthentification().myId;
                              if (userId != null) {
                                final bool alreadyLiked = widget.post.likes
                                    .contains(userId);
                                print(
                                  "DETAIL LIKE DEBUG - MyId: $userId, PostId: ${widget.post.id}, Author: ${widget.post.memberId}, Already liked: $alreadyLiked",
                                );

                                ServiceFirestore().addLike(
                                  memberID: userId,
                                  post: widget.post,
                                );

                                // Send notification if this is not our own post
                                if (userId != widget.post.memberId &&
                                    !alreadyLiked) {
                                  print(
                                    "DETAIL LIKE NOTIFICATION - Sending notification from $userId to ${widget.post.memberId}",
                                  );
                                  ServiceFirestore().sendNotification(
                                    to: widget.post.memberId,
                                    text: "liked your post",
                                    postId: widget.post.id,
                                  );
                                } else {
                                  print(
                                    "DETAIL LIKE NOTIFICATION SKIP - myId: $userId, authorId: ${widget.post.memberId}, already liked: $alreadyLiked",
                                  );
                                }
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // Comments list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: ServiceFirestore().postComment(widget.post.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const EmptyBody(); // No comments yet
                }

                final comments = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final comment = comments[index];
                    final commentData = comment.data() as Map<String, dynamic>;
                    final commenterId = commentData[memberIdKey] as String?;
                    final commentText = commentData[textKey] as String? ?? "";
                    final commentDate = commentData[dateKey] as int? ?? 0;

                    return StreamBuilder<DocumentSnapshot>(
                      stream: ServiceFirestore().specificMember(commenterId),
                      builder: (context, memberSnapshot) {
                        String commenterName = "Unknown user";
                        String? commenterPic;

                        if (memberSnapshot.hasData &&
                            memberSnapshot.data?.data() != null) {
                          final member = Membre(
                            reference: memberSnapshot.data!.reference,
                            id: memberSnapshot.data!.id,
                            map:
                                memberSnapshot.data!.data()
                                    as Map<String, dynamic>,
                          );
                          commenterName = member.fullName;
                          commenterPic = member.profilePicture;
                        }

                        return Card(
                          margin: const EdgeInsets.symmetric(
                            vertical: 4,
                            horizontal: 8,
                          ),
                          child: ListTile(
                            leading: Avatar(
                              radius: 16,
                              url: commenterPic ?? "",
                            ),
                            title: Text(commenterName),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(commentText),
                                DateHandler(timestamp: commentDate),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),

          // Comment input
          Container(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: const InputDecoration(
                      hintText: 'Write a comment...',
                      border: OutlineInputBorder(),
                    ),
                    minLines: 1,
                    maxLines: 3,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon:
                      _isSubmitting
                          ? const CircularProgressIndicator()
                          : const Icon(Icons.send),
                  onPressed: _isSubmitting ? null : _sendComment,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
