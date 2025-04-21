import 'package:cloud_firestore/cloud_firestore.dart';
import 'constantes.dart';

class Membre {
  // Firestore reference and ID
  final DocumentReference reference;
  final String id;

  // Member data from Firestore
  final Map<String, dynamic> map;

  // Constructor
  Membre({required this.reference, required this.id, required this.map});

  // Getters for member properties
  String get name => map[nameKey] ?? "";
  String get surname => map[surnameKey] ?? "";
  String get fullName => "$surname $name";
  String get profilePicture => map[profilePictureKey] ?? "";
  String get coverPicture => map[coverPictureKey] ?? "";
  String get description => map[descriptionKey] ?? "";

  // Factory constructor to create Membre from a DocumentSnapshot
  factory Membre.fromSnapshot(DocumentSnapshot snapshot) {
    return Membre(
      reference: snapshot.reference,
      id: snapshot.id,
      map: snapshot.data() as Map<String, dynamic>,
    );
  }
}
