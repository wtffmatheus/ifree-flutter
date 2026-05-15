import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

// google_sign_in v6
class AuthRepository {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;
  final _googleSignIn = GoogleSignIn();

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  // ── Email / Senha ─────────────────────────────────────────────────────────
  Future<UserCredential> signInWithEmail(
    String email,
    String password,
  ) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<UserCredential> signUp({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    await _db.collection('users').doc(cred.user!.uid).set({
      'name': name.trim(),
      'email': email.trim(),
      'role': role,
      'bio': '',
      'skills': <String>[],
      'photoUrl': null,
      'profileComplete': false,
      'avaliacaoMedia': 0.0,
      'totalJobs': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return cred;
  }

  // ── Google Sign-In ────────────────────────────────────────────────────────
  Future<UserCredential> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();

    if (googleUser == null) {
      throw Exception('Login cancelado pelo usuário');
    }

    final googleAuth = await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final cred = await _auth.signInWithCredential(credential);

    // Cria perfil se for primeiro acesso
    final doc = await _db.collection('users').doc(cred.user!.uid).get();

    if (!doc.exists) {
      await _db.collection('users').doc(cred.user!.uid).set({
        'name': cred.user!.displayName ?? '',
        'email': cred.user!.email ?? '',
        'role': 'freelancer',
        'bio': '',
        'skills': <String>[],
        'photoUrl': cred.user!.photoURL,
        'profileComplete': false,
        'avaliacaoMedia': 0.0,
        'totalJobs': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    return cred;
  }

  // ── Reset de senha ────────────────────────────────────────────────────────
  Future<void> sendPasswordResetEmail(String email) {
    return _auth.sendPasswordResetEmail(
      email: email.trim(),
    );
  }

  // ── Dados do usuário ──────────────────────────────────────────────────────
  Future<String?> getUserRole(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();

    return doc.data()?['role'] as String?;
  }

  Future<Map<String, dynamic>?> getUserData(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();

    return doc.data();
  }

  Future<void> updateUserData(
    String uid,
    Map<String, dynamic> data,
  ) {
    return _db.collection('users').doc(uid).update(data);
  }

  // ── Logout ────────────────────────────────────────────────────────────────
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}

    await _auth.signOut();
  }
}