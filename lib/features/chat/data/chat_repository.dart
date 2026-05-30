import 'package:cloud_firestore/cloud_firestore.dart';

class ChatRepository {
  final FirebaseFirestore _db;

  ChatRepository({FirebaseFirestore? db})
    : _db = db ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _chatsRef {
    return _db.collection('chats');
  }

  String buildConversationId({
    required String vagaId,
    required String empresaId,
    required String freelancerId,
  }) {
    return '${vagaId}_${empresaId}_$freelancerId';
  }

  Future<String> createOrGetConversation({
    required String vagaId,
    required String empresaId,
    required String freelancerId,
    required String empresaName,
    required String freelancerName,
    required String vagaTitulo,
  }) async {
    final conversationId = buildConversationId(
      vagaId: vagaId,
      empresaId: empresaId,
      freelancerId: freelancerId,
    );

    await _chatsRef.doc(conversationId).set({
      'vagaId': vagaId,
      'empresaId': empresaId,
      'freelancerId': freelancerId,
      'empresaName': empresaName,
      'freelancerName': freelancerName,
      'vagaTitulo': vagaTitulo,
      'participants': [empresaId, freelancerId],
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    return conversationId;
  }

  Stream<List<ChatMessage>> watchMessages(String conversationId) {
    return _chatsRef
        .doc(conversationId)
        .collection('messages')
        .orderBy('createdAt')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map(ChatMessage.fromDoc).toList();
        });
  }

  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String text,
  }) async {
    final cleanText = text.trim();

    if (cleanText.isEmpty) {
      return;
    }

    final batch = _db.batch();

    final messageRef = _chatsRef
        .doc(conversationId)
        .collection('messages')
        .doc();

    batch.set(messageRef, {
      'senderId': senderId,
      'text': cleanText,
      'createdAt': FieldValue.serverTimestamp(),
    });

    batch.set(_chatsRef.doc(conversationId), {
      'lastMessage': cleanText,
      'lastSenderId': senderId,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await batch.commit();
  }
}

class ChatMessage {
  final String id;
  final String senderId;
  final String text;
  final DateTime? createdAt;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    required this.createdAt,
  });

  factory ChatMessage.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    return ChatMessage(
      id: doc.id,
      senderId: data['senderId']?.toString() ?? '',
      text: data['text']?.toString() ?? '',
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
