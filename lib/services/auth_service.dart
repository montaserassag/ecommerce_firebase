import 'package:firebase_auth/firebase_auth.dart';

// ✅ Best Practice: Keep Firebase logic in a service class — screens never
//    call FirebaseAuth directly.
// ✅ Map raw error codes to friendly messages — never show
//    "permission-denied" etc. to the user (Common Mistake #7).
class AuthException implements Exception {
  final String message; // safe to show in UI
  final String code;    // original code for logs only
  AuthException(this.message, this.code);
  @override
  String toString() => message;
}

class AuthService {
  AuthService._();
  static final _auth = FirebaseAuth.instance;

  // ✅ Exercise 1: Auth state stream used by StreamBuilder in main.dart
  static Stream<User?> get authStateChanges => _auth.authStateChanges();
  static User? get currentUser => _auth.currentUser;
  static String? get uid => _auth.currentUser?.uid;

  // ✅ Exercise 1: Sign Up
  static Future<void> signUp({required String email, required String password}) async {
    try {
      await _auth.createUserWithEmailAndPassword(email: email.trim(), password: password);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_friendly(e.code), e.code);
    }
  }

  // ✅ Exercise 1: Sign In
  static Future<void> signIn({required String email, required String password}) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_friendly(e.code), e.code);
    }
  }

  static Future<void> signOut() => _auth.signOut();

  static String _friendly(String code) {
    switch (code) {
      case 'invalid-email':          return 'Please enter a valid email address.';
      case 'user-not-found':         return 'No account found with this email.';
      case 'wrong-password':
      case 'invalid-credential':     return 'Incorrect email or password.';
      case 'email-already-in-use':   return 'An account already exists with this email.';
      case 'weak-password':          return 'Password must be at least 6 characters.';
      case 'network-request-failed': return 'Network error. Check your connection.';
      case 'too-many-requests':      return 'Too many attempts. Please wait and try again.';
      default:                       return 'Something went wrong. Please try again.';
    }
  }
}
