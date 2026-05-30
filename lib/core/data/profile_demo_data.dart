import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileDemoData {
  static Future<void> addReviewsForUser({required String uid}) async {
    final reviews = [
      {
        'name': 'Restaurante Centro Sorocaba',
        'rating': 5.0,
        'comment':
            'Excelente profissional. Chegou no horÃƒÂ¡rio, atendeu muito bem os clientes e ajudou na organizaÃƒÂ§ÃƒÂ£o do salÃƒÂ£o.',
        'job': 'Garçom para evento',
        'createdAtText': 'Hoje',
      },
      {
        'name': 'BistrÃƒÂ´ Campolim',
        'rating': 4.8,
        'comment':
            'Muito prestativo na cozinha, ÃƒÂ¡gil e organizado. Chamaremos novamente para próximas diárias.',
        'job': 'Auxiliar de cozinha',
        'createdAtText': 'Semana passada',
      },
      {
        'name': 'Burger House Sorocaba',
        'rating': 4.9,
        'comment':
            'Trabalhou bem sob pressÃƒÂ£o, manteve a ÃƒÂ¡rea limpa e colaborou com a equipe durante todo o turno.',
        'job': 'Atendente de balcÃƒÂ£o',
        'createdAtText': 'HÃƒÂ¡ 2 semanas',
      },
    ];

    final avg =
        reviews
            .map((review) => review['rating'] as double)
            .reduce((a, b) => a + b) /
        reviews.length;

    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'avaliacaoMedia': double.parse(avg.toStringAsFixed(1)),
      'totalJobs': reviews.length,
      'reviews': reviews,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
