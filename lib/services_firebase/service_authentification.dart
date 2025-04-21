import 'package:firebase_auth/firebase_auth.dart';

class ServiceAuthentification {
  // Récupérer une instance de auth
  final instance = FirebaseAuth.instance;

  // Connecter à Firebase
  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    String? result = ""; // Initialize with a default or null
    try {
      // Implementation for signing in
      await instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      result = null; // Indicate success (no error message)
    } on FirebaseAuthException catch (e) {
      result = e.message; // Return Firebase error message
    } catch (e) {
      result = e.toString(); // Return generic error message
    }
    return result;
  }

  // Créer un compte sur Firebase
  Future<String?> createAccount({
    required String email,
    required String password,
    required String surname, // Prénom
    required String name, // Nom
  }) async {
    String? result = ""; // Initialize
    try {
      // Implementation for creating account
      UserCredential userCredential = await instance
          .createUserWithEmailAndPassword(email: email, password: password);
      // TODO: Call Firestore service to add member details (name, surname) using userCredential.user.uid
      // For now, just indicate success
      result = null;
    } on FirebaseAuthException catch (e) {
      result = e.message;
    } catch (e) {
      result = e.toString();
    }
    return result;
  }

  // Déconnecter de Firebase
  Future<bool> signOut() async {
    bool result = false;
    try {
      await instance.signOut();
      result = true;
    } catch (e) {
      // Handle error if needed
      print(e); // Or log the error
    }
    return result;
  }

  // Récupérer l'id unique de l'utilisateur
  String? get myId => instance.currentUser?.uid;

  // Voir si vous etes l'utilisateur
  bool isMe(String profileId) {
    bool result = false;
    if (myId != null && myId == profileId) {
      result = true;
    }
    return result;
  }
}
