import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationRepository {
  final FirebaseFirestore _db;

  NotificationRepository({FirebaseFirestore? db})
    : _db = db ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _notificationsRef(String uid) {
    return _db.collection('users').doc(uid).collection('notifications');
  }

  Stream<List<AppNotification>> watchNotifications(String uid) {
    return _notificationsRef(
      uid,
    ).orderBy('createdAt', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map(AppNotification.fromDoc).toList();
    });
  }

  Future<void> createNotification({
    required String uid,
    required String title,
    required String message,
    required String type,
    String? vagaId,
    String? conversationId,
  }) {
    return _notificationsRef(uid).add({
      'title': title,
      'message': message,
      'type': type,
      'vagaId': vagaId,
      'conversationId': conversationId,
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> markAsRead({
    required String uid,
    required String notificationId,
  }) {
    return _notificationsRef(uid).doc(notificationId).update({
      'read': true,
      'readAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> markAllAsRead(String uid) async {
    final snapshot = await _notificationsRef(
      uid,
    ).where('read', isEqualTo: false).get();

    final batch = _db.batch();

    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {
        'read': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }
}

class AppNotification {
  final String id;
  final String title;
  final String message;
  final String type;
  final String? vagaId;
  final String? conversationId;
  final bool read;
  final DateTime? createdAt;

  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.vagaId,
    required this.conversationId,
    required this.read,
    required this.createdAt,
  });

  factory AppNotification.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    return AppNotification(
      id: doc.id,
      title: data['title']?.toString() ?? '',
      message: data['message']?.toString() ?? '',
      type: data['type']?.toString() ?? 'info',
      vagaId: data['vagaId']?.toString(),
      conversationId: data['conversationId']?.toString(),
      read: data['read'] is bool ? data['read'] as bool : false,
      createdAt: _parseDate(data['createdAt']),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;

    return DateTime.tryParse(value.toString());
  }
}
