import 'package:cloud_firestore/cloud_firestore.dart';

class UserRoleService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static Future<String> getInitialRoute(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();

      if (!doc.exists) {
        return '/auth';
      }

      final data = doc.data();
      final role = data?['role'];

      if (role == 'company' || role == 'restaurant' || role == 'empresa') {
        return '/company';
      }

      return '/freelancer';
    } catch (_) {
      return '/auth';
    }
  }
}
