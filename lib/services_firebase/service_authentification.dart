import 'package:firebase_auth/firebase_auth.dart';
import '../modeles/constantes.dart';
import 'service_firestore.dart';

class ServiceAuthentification {
  // Singleton pattern implementation
  static final ServiceAuthentification _instance =
      ServiceAuthentification._internal();

  factory ServiceAuthentification() {
    return _instance;
  }

  ServiceAuthentification._internal();

  // Get an instance of auth
  final instance = FirebaseAuth.instance;

  // Sign in to Firebase
  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    String? result;
    try {
      print("Attempting to sign in user: $email");
      // Implementation for signing in
      await instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      print("Sign in successful for $email");
      result = null; // Indicate success (no error message)
    } on FirebaseAuthException catch (e) {
      print("FirebaseAuthException during sign in: ${e.code} - ${e.message}");
      // Provide more useful error messages
      switch (e.code) {
        case 'user-not-found':
          result = "No user found with this email address.";
          break;
        case 'wrong-password':
          result = "Incorrect password.";
          break;
        case 'invalid-email':
          result = "Invalid email format.";
          break;
        case 'user-disabled':
          result = "This account has been disabled.";
          break;
        default:
          result = e.message;
      }
    } catch (e) {
      print("Generic error during sign in: $e");
      result = "Connection error: $e"; // Return generic error message
    }
    return result;
  }

  // Create an account on Firebase
  Future<String?> createAccount({
    required String email,
    required String password,
    required String surname, // First name
    required String name, // Last name
  }) async {
    String? result;
    try {
      print("Attempting to create account for: $email");
      // Implementation for creating account
      UserCredential userCredential = await instance
          .createUserWithEmailAndPassword(email: email, password: password);

      // Add user data to Firestore
      if (userCredential.user != null) {
        String userId = userCredential.user!.uid;
        Map<String, dynamic> userData = {
          nameKey: name,
          surnameKey: surname,
          // Initialize other fields as needed
          profilePictureKey: "",
          coverPictureKey: "",
          descriptionKey: "",
        };

        print("Creating Firestore document for new user: $userId");
        // Call Firestore service to add member details
        await ServiceFirestore().addMember(id: userId, data: userData);
        print("Firestore document created successfully");
      }

      result = null; // Indicate success
    } on FirebaseAuthException catch (e) {
      print(
        "FirebaseAuthException during account creation: ${e.code} - ${e.message}",
      );
      // Provide more useful error messages
      switch (e.code) {
        case 'weak-password':
          result = "The password provided is too weak.";
          break;
        case 'email-already-in-use':
          result = "An account already exists for this email address.";
          break;
        case 'invalid-email':
          result = "Invalid email format.";
          break;
        case 'operation-not-allowed':
          result = "Account creation is disabled.";
          break;
        default:
          result = e.message;
      }
    } catch (e) {
      print("Generic error during account creation: $e");
      result = "Error creating account: $e";
    }
    return result;
  }

  // Sign out from Firebase
  Future<bool> signOut() async {
    bool result = false;
    try {
      print("Attempting to sign out user");
      await instance.signOut();
      print("Sign out successful");
      // Delay a short time to ensure state updates
      await Future.delayed(const Duration(milliseconds: 500));
      result = true;
    } catch (e) {
      // Handle error if needed
      print("Error during sign out: $e");
    }
    return result;
  }

  // Get the unique ID of the user
  String? get myId {
    final user = instance.currentUser;
    if (user != null) {
      print("Current user ID: ${user.uid}");
      return user.uid;
    }
    print("No current user");
    return null;
  }

  // Check if you are the user
  bool isMe(String profileId) {
    bool result = false;
    final currentId = myId;
    if (currentId != null && currentId == profileId) {
      result = true;
    }
    return result;
  }

  // Get the current user's email
  String? get currentEmail => instance.currentUser?.email;

  // Check if user is logged in
  bool get isUserLoggedIn => instance.currentUser != null;
}
