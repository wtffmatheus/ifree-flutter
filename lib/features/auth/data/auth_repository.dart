import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _db;
  final GoogleSignIn _googleSignIn;

  AuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? db,
    GoogleSignIn? googleSignIn,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _db = db ?? FirebaseFirestore.instance,
       _googleSignIn = googleSignIn ?? GoogleSignIn();

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signInWithEmail(String email, String password) {
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
    final normalizedRole = _normalizeRole(role);

    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = credential.user;

    if (user == null) {
      throw Exception('Não foi possível criar o usuário.');
    }

    await user.updateDisplayName(name.trim());

    await _db.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'name': name.trim(),
      'email': email.trim(),
      'role': normalizedRole,
      'bio': '',
      'skills': <String>[],
      'phone': '',
      'city': '',
      'photoUrl': user.photoURL,
      'profileComplete': false,
      'avaliacaoMedia': 0.0,
      'totalJobs': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    return credential;
  }

  Future<UserCredential> signInWithGoogle({
    String defaultRole = 'freelancer',
  }) async {
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

    if (googleUser == null) {
      throw Exception('Login cancelado pelo usuário.');
    }

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    final OAuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final UserCredential userCredential = await _auth.signInWithCredential(
      credential,
    );

    final user = userCredential.user;

    if (user == null) {
      throw Exception('Não foi possível autenticar com o Google.');
    }

    final userRef = _db.collection('users').doc(user.uid);
    final userDoc = await userRef.get();

    if (!userDoc.exists) {
      await userRef.set({
        'uid': user.uid,
        'name': user.displayName ?? '',
        'email': user.email ?? '',
        'role': _normalizeRole(defaultRole),
        'bio': '',
        'skills': <String>[],
        'phone': '',
        'city': '',
        'photoUrl': user.photoURL,
        'profileComplete': false,
        'avaliacaoMedia': 0.0,
        'totalJobs': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } else {
      await userRef.set({
        'email': user.email ?? userDoc.data()?['email'] ?? '',
        'photoUrl': user.photoURL ?? userDoc.data()?['photoUrl'],
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    return userCredential;
  }

  Future<void> sendPasswordResetEmail(String email) {
    return _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<String?> getUserRole(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();

    if (!doc.exists) {
      return null;
    }

    return doc.data()?['role'] as String?;
  }

  Future<Map<String, dynamic>?> getUserData(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();

    if (!doc.exists) {
      return null;
    }

    return doc.data();
  }

  Future<void> updateUserData(String uid, Map<String, dynamic> data) {
    return _db.collection('users').doc(uid).set({
      ...data,
      'uid': uid,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> createOrUpdateUserData(String uid, Map<String, dynamic> data) {
    return _db.collection('users').doc(uid).set({
      ...data,
      'uid': uid,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {
      // Ignora erro caso o usuário não tenha logado com Google.
    }

    await _auth.signOut();
  }

  String _normalizeRole(String role) {
    final value = role.trim().toLowerCase();

    if (value == 'empresa' ||
        value == 'restaurante' ||
        value == 'restaurant' ||
        value == 'company') {
      return 'company';
    }

    return 'freelancer';
  }
}
