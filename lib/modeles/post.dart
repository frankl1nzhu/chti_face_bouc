import 'package:cloud_firestore/cloud_firestore.dart';
import 'constantes.dart';

class Post {
  DocumentReference reference;
  String id;
  Map<String, dynamic> map;

  Post({required this.reference, required this.id, required this.map});

  // Getters for post fields using keys from constantes.dart
  String get memberId => map[memberIdKey] ?? "";
  String get text => map[textKey] ?? "";
  String? get imageUrl => map[postImageKey];
  DateTime get date =>
      map[dateKey] != null
          ? DateTime.fromMillisecondsSinceEpoch(map[dateKey] as int)
          : DateTime.now();
  List<dynamic> get likes => map[likesKey] ?? [];
}
