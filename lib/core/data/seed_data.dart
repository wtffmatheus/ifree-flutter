import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class SeedData {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Future<void> run({bool force = false}) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('FaÃƒÂ§a login antes de carregar vagas exemplo.');
    }

    try {
      final existing = await _db
          .collection('vagas')
          .where('empresaId', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (!force && existing.docs.isNotEmpty) {
        if (kDebugMode) {
          debugPrint(
            'Seed ignorada: jÃƒÂ¡ existem vagas exemplo para este usuário.',
          );
        }
        return;
      }

      final vagas = [
        {
          'titulo': 'Garçom para evento',
          'empresa': 'Restaurante Centro Sorocaba',
          'tipo': 'Garçom',
          'local': 'Centro, Sorocaba - SP',
          'valor': '120,00',
          'data': 'Hoje',
          'horario': '18:00 ÃƒÂ s 23:00',
          'descricao':
              'Atendimento ao pÃƒºblico, organizaÃƒÂ§ÃƒÂ£o de mesas e apoio geral no salÃƒÂ£o.',
          'quantidade': 2,
          'lat': -23.5015,
          'lng': -47.4526,
          'status': 'ativa',
        },
        {
          'titulo': 'Auxiliar de cozinha',
          'empresa': 'BistrÃƒÂ´ Campolim',
          'tipo': 'Auxiliar',
          'local': 'Campolim, Sorocaba - SP',
          'valor': '110,00',
          'data': 'AmanhÃƒÂ£',
          'horario': '09:00 ÃƒÂ s 17:00',
          'descricao':
              'Apoio no prÃƒÂ©-preparo, limpeza da cozinha e organizaÃƒÂ§ÃƒÂ£o dos ingredientes.',
          'quantidade': 1,
          'lat': -23.5367,
          'lng': -47.4772,
          'status': 'ativa',
        },
        {
          'titulo': 'Pizzaiolo freelancer',
          'empresa': 'Pizzaria Zona Norte',
          'tipo': 'Pizzaiolo',
          'local': 'Zona Norte, Sorocaba - SP',
          'valor': '180,00',
          'data': 'SÃƒÂ¡bado',
          'horario': '17:00 ÃƒÂ s 00:00',
          'descricao':
              'Preparo de massas, montagem de pizzas e operaÃƒÂ§ÃƒÂ£o de forno.',
          'quantidade': 1,
          'lat': -23.4788,
          'lng': -47.4424,
          'status': 'ativa',
        },
        {
          'titulo': 'Barista para cafeteria',
          'empresa': 'CafÃƒÂ© Premium',
          'tipo': 'Barista',
          'local': 'Jardim Faculdade, Sorocaba - SP',
          'valor': '130,00',
          'data': 'Sexta-feira',
          'horario': '08:00 ÃƒÂ s 15:00',
          'descricao':
              'Preparo de cafÃƒÂ©s, atendimento ao cliente e organizaÃƒÂ§ÃƒÂ£o do balcÃƒÂ£o.',
          'quantidade': 1,
          'lat': -23.5128,
          'lng': -47.4634,
          'status': 'ativa',
        },
        {
          'titulo': 'Chapeiro para hamburgueria',
          'empresa': 'Burger House Sorocaba',
          'tipo': 'Chapeiro',
          'local': 'Vila HortÃƒªncia, Sorocaba - SP',
          'valor': '150,00',
          'data': 'Hoje',
          'horario': '18:00 ÃƒÂ s 01:00',
          'descricao':
              'Preparo de hambÃƒºrgueres, organizaÃƒÂ§ÃƒÂ£o da chapa e apoio na cozinha.',
          'quantidade': 1,
          'lat': -23.5058,
          'lng': -47.4292,
          'status': 'ativa',
        },
        {
          'titulo': 'Atendente de balcÃƒÂ£o',
          'empresa': 'Lanchonete Avenida',
          'tipo': 'Atendente',
          'local': 'Avenida Itavuvu, Sorocaba - SP',
          'valor': '100,00',
          'data': 'AmanhÃƒÂ£',
          'horario': '10:00 ÃƒÂ s 18:00',
          'descricao':
              'Atendimento no balcÃƒÂ£o, organizaÃƒÂ§ÃƒÂ£o de pedidos e suporte ao caixa.',
          'quantidade': 2,
          'lat': -23.4685,
          'lng': -47.4632,
          'status': 'ativa',
        },
      ];

      final batch = _db.batch();

      for (var i = 0; i < vagas.length; i++) {
        batch.set(
          _db.collection('vagas').doc('demo_${user.uid}_${i + 1}'),
          {
            ...vagas[i],
            'empresaId': user.uid,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }

      await batch.commit();

      if (kDebugMode) {
        debugPrint('Vagas exemplo criadas com sucesso.');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Erro ao criar vagas exemplo: $e');
      }

      rethrow;
    }
  }
}
