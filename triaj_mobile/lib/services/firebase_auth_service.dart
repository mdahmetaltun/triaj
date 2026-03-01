import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class FirebaseAuthService {
  FirebaseAuthService._();

  static final FirebaseAuthService instance = FirebaseAuthService._();

  FirebaseAuth get _auth => FirebaseAuth.instance;
  bool _googleInitialized = false;

  Stream<User?> get authChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<void> _ensureGoogleInitialized() async {
    if (_googleInitialized) {
      return;
    }
    await GoogleSignIn.instance.initialize();
    _googleInitialized = true;
  }

  Future<UserCredential> signInWithGoogle() async {
    await _ensureGoogleInitialized();

    if (kIsWeb) {
      return _auth.signInWithPopup(GoogleAuthProvider());
    }

    final GoogleSignInAccount account = await GoogleSignIn.instance
        .authenticate();
    final String? idToken = account.authentication.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw StateError('Google idToken alınamadı.');
    }

    final credential = GoogleAuthProvider.credential(idToken: idToken);
    return _auth.signInWithCredential(credential);
  }

  Future<void> signOut() async {
    await _auth.signOut();
    await _ensureGoogleInitialized();
    await GoogleSignIn.instance.signOut();
  }
}
