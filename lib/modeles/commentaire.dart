import 'package:cloud_firestore/cloud_firestore.dart';
import 'constantes.dart';

class Commentaire {
  DocumentReference reference;
  String id;
  Map<String, dynamic> map;

  Commentaire({required this.reference, required this.id, required this.map});

  String get memberId => map[memberIdKey] ?? ""; // Comment author ID
  String get text => map[textKey] ?? "";
  int get date => map[dateKey] ?? 0; // Comment timestamp
}
