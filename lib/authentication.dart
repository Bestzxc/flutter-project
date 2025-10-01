import 'package:firebase_auth/firebase_auth.dart';

class AuthenticationService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static String get currentUserID {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) return user.uid;
    throw Exception("No user is currently logged in");
  }

  Future<bool> login(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user != null;
    } catch (e) {
      print("Login error: $e");
      return false;
    }
  }

  Future<bool> register(String email, String password) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user != null;
    } catch (e) {
      print("Register error: $e");
      return false;
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }


  bool isAuthenticated() {
    return _auth.currentUser != null;
  }
}
