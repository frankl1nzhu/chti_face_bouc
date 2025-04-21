import 'package:cloud_firestore/cloud_firestore.dart';
import 'constantes.dart'; // Import constants for field keys

class Post {
  DocumentReference reference;
  String id;
  Map<String, dynamic> map;

  Post({required this.reference, required this.id, required this.map});

  // Getters for post fields using keys from constantes.dart
  String get memberId => map[memberIdKey] ?? ""; // ID of the author (member)
  String get text => map[textKey] ?? "";
  String? get imageUrl => map[postImageKey]; // Image URL can be null
  DateTime get date =>
      map[dateKey] != null
          ? DateTime.fromMillisecondsSinceEpoch(map[dateKey] as int)
          : DateTime.now(); // Convert timestamp to DateTime
  List<dynamic> get likes => map[likesKey] ?? []; // List of user IDs who liked
}
