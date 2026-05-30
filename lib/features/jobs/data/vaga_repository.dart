import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/models/vaga_model.dart';
import '../../notifications/data/notification_repository.dart';

class VagaRepository {
  final FirebaseFirestore _db;
  final NotificationRepository _notifications = NotificationRepository();

  VagaRepository({FirebaseFirestore? db})
    : _db = db ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _vagasRef {
    return _db.collection('vagas');
  }

  Future<List<VagaModel>> getVagasAtivas() async {
    final snapshot = await _vagasRef.where('status', isEqualTo: 'ativa').get();

    final vagas = snapshot.docs.map(VagaModel.fromDoc).toList();

    vagas.sort((a, b) {
      final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });

    return vagas;
  }

  Stream<List<VagaModel>> watchVagasAtivas() {
    return _vagasRef.where('status', isEqualTo: 'ativa').snapshots().map((
      snapshot,
    ) {
      final vagas = snapshot.docs.map(VagaModel.fromDoc).toList();

      vagas.sort((a, b) {
        final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });

      return vagas;
    });
  }

  Future<List<VagaModel>> getVagasDaEmpresa(String empresaId) async {
    final snapshot = await _vagasRef
        .where('empresaId', isEqualTo: empresaId)
        .get();

    final vagas = snapshot.docs.map(VagaModel.fromDoc).toList();

    vagas.sort((a, b) {
      final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });

    return vagas;
  }

  Stream<List<VagaModel>> watchVagasDaEmpresa(String empresaId) {
    return _vagasRef.where('empresaId', isEqualTo: empresaId).snapshots().map((
      snapshot,
    ) {
      final vagas = snapshot.docs.map(VagaModel.fromDoc).toList();

      vagas.sort((a, b) {
        final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });

      return vagas;
    });
  }

  Future<VagaModel?> getVagaById(String vagaId) async {
    final doc = await _vagasRef.doc(vagaId).get();

    if (!doc.exists) {
      return null;
    }

    return VagaModel.fromDoc(doc);
  }

  Future<String> criarVaga({
    required String titulo,
    required String empresa,
    required String empresaId,
    required String tipo,
    required String local,
    required String valor,
    required String data,
    required String horario,
    required String descricao,
    required int quantidade,
    double? lat,
    double? lng,
  }) async {
    final doc = await _vagasRef.add({
      'titulo': titulo.trim(),
      'empresa': empresa.trim(),
      'empresaId': empresaId,
      'tipo': tipo.trim(),
      'local': local.trim(),
      'valor': valor.trim(),
      'data': data.trim(),
      'horario': horario.trim(),
      'descricao': descricao.trim(),
      'quantidade': quantidade,
      'lat': lat,
      'lng': lng,
      'status': 'ativa',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return doc.id;
  }

  Future<void> atualizarVaga({
    required String vagaId,
    required Map<String, dynamic> data,
  }) {
    return _vagasRef.doc(vagaId).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> encerrarVaga(String vagaId) {
    return _vagasRef.doc(vagaId).update({
      'status': 'finalizada',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> cancelarVaga(String vagaId) {
    return _vagasRef.doc(vagaId).update({
      'status': 'cancelada',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> candidatar({
    required String vagaId,
    required String freelancerId,
    required Map<String, dynamic> freelancerData,
  }) async {
    final vaga = await getVagaById(vagaId);

    if (vaga == null) {
      throw Exception('Vaga não encontrada.');
    }

    if (!vaga.isAtiva) {
      throw Exception('Esta vaga não estÃƒÂ¡ mais ativa.');
    }

    final candidaturaRef = _vagasRef
        .doc(vagaId)
        .collection('candidaturas')
        .doc(freelancerId);

    final candidaturaDoc = await candidaturaRef.get();

    if (candidaturaDoc.exists) {
      throw Exception('Você jÃƒÂ¡ se candidatou para esta vaga.');
    }

    final freelancerRef = _db
        .collection('users')
        .doc(freelancerId)
        .collection('candidaturas_index')
        .doc(vagaId);

    final batch = _db.batch();

    batch.set(candidaturaRef, {
      'freelancerId': freelancerId,
      'vagaId': vagaId,
      'empresaId': vaga.empresaId,
      'status': 'em_analise',
      'freelancerName': freelancerData['name'] ?? '',
      'freelancerEmail': freelancerData['email'] ?? '',
      'freelancerPhotoUrl': freelancerData['photoUrl'],
      'freelancerPhone': freelancerData['phone'] ?? '',
      'freelancerCity': freelancerData['city'] ?? '',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    batch.set(freelancerRef, {
      'vagaId': vagaId,
      'empresaId': vaga.empresaId,
      'titulo': vaga.titulo,
      'empresa': vaga.empresa,
      'tipo': vaga.tipo,
      'local': vaga.local,
      'valor': vaga.valor,
      'data': vaga.data,
      'horario': vaga.horario,
      'status': 'em_analise',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();

    await _notifications.createNotification(
      uid: vaga.empresaId,
      title: 'Nova candidatura',
      message:
          '${freelancerData['name'] ?? 'Um freelancer'} se candidatou para "${vaga.titulo}".',
      type: 'candidatura',
      vagaId: vagaId,
    );
  }

  Future<void> cancelarCandidatura({
    required String vagaId,
    required String freelancerId,
  }) async {
    final vaga = await getVagaById(vagaId);

    if (vaga == null) {
      throw Exception('Vaga não encontrada.');
    }

    final candidaturaRef = _vagasRef
        .doc(vagaId)
        .collection('candidaturas')
        .doc(freelancerId);

    final candidaturaDoc = await candidaturaRef.get();

    if (!candidaturaDoc.exists) {
      throw Exception('Candidatura não encontrada.');
    }

    final currentStatus = candidaturaDoc.data()?['status']?.toString();

    if (currentStatus == 'aprovado' || currentStatus == 'concluido') {
      throw Exception('Esta candidatura não pode ser cancelada neste status.');
    }

    final freelancerRef = _db
        .collection('users')
        .doc(freelancerId)
        .collection('candidaturas_index')
        .doc(vagaId);

    final batch = _db.batch();

    batch.update(candidaturaRef, {
      'status': 'cancelada_pelo_freelancer',
      'updatedAt': FieldValue.serverTimestamp(),
    });

    batch.update(freelancerRef, {
      'status': 'cancelada_pelo_freelancer',
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();

    await _notifications.createNotification(
      uid: vaga.empresaId,
      title: 'Candidatura cancelada',
      message: 'Um freelancer cancelou a candidatura para "${vaga.titulo}".',
      type: 'cancelada',
      vagaId: vagaId,
    );
  }

  Future<void> atualizarStatusCandidatura({
    required String vagaId,
    required String freelancerId,
    required String status,
  }) async {
    final vaga = await getVagaById(vagaId);

    final candidaturaRef = _vagasRef
        .doc(vagaId)
        .collection('candidaturas')
        .doc(freelancerId);

    final freelancerRef = _db
        .collection('users')
        .doc(freelancerId)
        .collection('candidaturas_index')
        .doc(vagaId);

    final batch = _db.batch();

    batch.update(candidaturaRef, {
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    batch.update(freelancerRef, {
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();

    if (vaga != null) {
      final notificationTitle = switch (status) {
        'aprovado' => 'Candidatura aprovada',
        'recusado' => 'Candidatura recusada',
        _ => 'Candidatura em análise',
      };

      final notificationMessage = switch (status) {
        'aprovado' =>
          'Você foi aprovado para "${vaga.titulo}" em ${vaga.empresa}.',
        'recusado' => 'Sua candidatura para "${vaga.titulo}" foi recusada.',
        _ => 'Sua candidatura para "${vaga.titulo}" voltou para análise.',
      };

      await _notifications.createNotification(
        uid: freelancerId,
        title: notificationTitle,
        message: notificationMessage,
        type: status,
        vagaId: vagaId,
      );
    }
  }

  Future<void> finalizarJobComAvaliacao({
    required String vagaId,
    required String freelancerId,
    required double rating,
    required String comment,
  }) async {
    final vaga = await getVagaById(vagaId);

    if (vaga == null) {
      throw Exception('Vaga não encontrada.');
    }

    if (rating < 1 || rating > 5) {
      throw Exception('A nota precisa estar entre 1 e 5.');
    }

    final candidaturaRef = _vagasRef
        .doc(vagaId)
        .collection('candidaturas')
        .doc(freelancerId);

    final freelancerRef = _db
        .collection('users')
        .doc(freelancerId)
        .collection('candidaturas_index')
        .doc(vagaId);

    final userRef = _db.collection('users').doc(freelancerId);
    final userDoc = await userRef.get();
    final userData = userDoc.data() ?? {};

    final currentReviews = userData['reviews'];
    final reviews = currentReviews is List
        ? currentReviews
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList()
        : <Map<String, dynamic>>[];

    final alreadyExists = reviews.any((review) => review['vagaId'] == vagaId);

    if (!alreadyExists) {
      reviews.insert(0, {
        'vagaId': vagaId,
        'name': vaga.empresa,
        'rating': rating,
        'comment': comment.trim().isEmpty
            ? 'Job finalizado com sucesso.'
            : comment.trim(),
        'job': vaga.titulo,
        'createdAtText': 'Avaliação recebida',
      });
    }

    final ratings = reviews
        .map((review) => review['rating'])
        .whereType<num>()
        .map((rating) => rating.toDouble())
        .toList();

    final average = ratings.isEmpty
        ? 0.0
        : ratings.reduce((a, b) => a + b) / ratings.length;

    final batch = _db.batch();

    batch.update(candidaturaRef, {
      'status': 'concluido',
      'rating': rating,
      'reviewComment': comment.trim(),
      'completedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    batch.update(freelancerRef, {
      'status': 'concluido',
      'rating': rating,
      'reviewComment': comment.trim(),
      'completedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    batch.set(userRef, {
      'reviews': reviews,
      'avaliacaoMedia': double.parse(average.toStringAsFixed(1)),
      'totalJobs': reviews.length,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await batch.commit();

    await _notifications.createNotification(
      uid: freelancerId,
      title: 'Job finalizado',
      message:
          'A empresa finalizou "${vaga.titulo}" e deixou uma avaliação para você.',
      type: 'concluido',
      vagaId: vagaId,
    );
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchCandidaturas(String vagaId) {
    return _vagasRef
        .doc(vagaId)
        .collection('candidaturas')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchMinhasCandidaturas(
    String freelancerId,
  ) {
    return _db
        .collection('users')
        .doc(freelancerId)
        .collection('candidaturas_index')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
}
