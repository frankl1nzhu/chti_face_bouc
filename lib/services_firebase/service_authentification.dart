import 'package:firebase_auth/firebase_auth.dart';
import '../modeles/constantes.dart';
import 'service_firestore.dart';

class ServiceAuthentification {
  // 单例模式实现
  static final ServiceAuthentification _instance =
      ServiceAuthentification._internal();

  factory ServiceAuthentification() {
    return _instance;
  }

  ServiceAuthentification._internal();

  // Récupérer une instance de auth
  final instance = FirebaseAuth.instance;

  // Connecter à Firebase
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
      // 提供更有用的错误消息
      switch (e.code) {
        case 'user-not-found':
          result = "Aucun utilisateur trouvé avec cette adresse e-mail.";
          break;
        case 'wrong-password':
          result = "Mot de passe incorrect.";
          break;
        case 'invalid-email':
          result = "Format d'adresse e-mail invalide.";
          break;
        case 'user-disabled':
          result = "Ce compte a été désactivé.";
          break;
        default:
          result = e.message;
      }
    } catch (e) {
      print("Generic error during sign in: $e");
      result = "Erreur de connexion: $e"; // Return generic error message
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
      // 提供更有用的错误消息
      switch (e.code) {
        case 'weak-password':
          result = "Le mot de passe fourni est trop faible.";
          break;
        case 'email-already-in-use':
          result = "Un compte existe déjà pour cette adresse e-mail.";
          break;
        case 'invalid-email':
          result = "Format d'adresse e-mail invalide.";
          break;
        case 'operation-not-allowed':
          result = "La création de compte est désactivée.";
          break;
        default:
          result = e.message;
      }
    } catch (e) {
      print("Generic error during account creation: $e");
      result = "Erreur lors de la création du compte: $e";
    }
    return result;
  }

  // Déconnecter de Firebase
  Future<bool> signOut() async {
    bool result = false;
    try {
      print("Attempting to sign out user");
      await instance.signOut();
      print("Sign out successful");
      // 延迟一小段时间来确保状态更新
      await Future.delayed(const Duration(milliseconds: 500));
      result = true;
    } catch (e) {
      // Handle error if needed
      print("Error during sign out: $e");
    }
    return result;
  }

  // Récupérer l'id unique de l'utilisateur
  String? get myId {
    final user = instance.currentUser;
    if (user != null) {
      print("Current user ID: ${user.uid}");
      return user.uid;
    }
    print("No current user");
    return null;
  }

  // Voir si vous etes l'utilisateur
  bool isMe(String profileId) {
    bool result = false;
    final currentId = myId;
    if (currentId != null && currentId == profileId) {
      result = true;
    }
    return result;
  }

  // 获取当前用户的电子邮件
  String? get currentEmail => instance.currentUser?.email;

  // 检查用户是否已登录
  bool get isUserLoggedIn => instance.currentUser != null;
}
