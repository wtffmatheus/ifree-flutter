import 'package:cloud_firestore/cloud_firestore.dart';

/// Popula o Firestore com vagas fictícias na região de Sorocaba.
/// Execute uma única vez em modo debug: SeedData.run();
class SeedData {
  static Future<void> run() async {
    final db = FirebaseFirestore.instance;

    const vagas = [
      {
        'titulo': 'Bartender para Evento Corporativo',
        'empresa': 'Espaço Vila Nova',
        'local': 'Vila Nova, Sorocaba',
        'bairro': 'Vila Nova',
        'valor': '280',
        'descricao':
            'Evento corporativo de grande porte. Experiência com coquetéis clássicos e flair bartending. Uniforme fornecido.',
        'data': '14/05/2026',
        'turno': '19h – 01h',
        'tipo': 'Bartender',
        'lat': -23.4950,
        'lng': -47.4480,
        'vagas': 2,
        'companyId': 'seed_company_1',
      },
      {
        'titulo': 'Garçom para Restaurante Italiano',
        'empresa': 'Trattoria del Sol',
        'local': 'Centro, Sorocaba',
        'bairro': 'Centro',
        'valor': '190',
        'descricao':
            'Restaurante fino no centro. Necessário experiência mínima de 1 ano e boa apresentação pessoal.',
        'data': '15/05/2026',
        'turno': '11h – 15h e 19h – 23h',
        'tipo': 'Garçom',
        'lat': -23.5020,
        'lng': -47.4560,
        'vagas': 3,
        'companyId': 'seed_company_2',
      },
      {
        'titulo': 'Chef de Cozinha para Casamento',
        'empresa': 'Buffet Recanto Real',
        'local': 'Éden, Sorocaba',
        'bairro': 'Éden',
        'valor': '450',
        'descricao':
            'Casamento com 200 convidados. Cardápio já definido. Procuramos chef experiente em banquetes.',
        'data': '17/05/2026',
        'turno': '10h – 22h',
        'tipo': 'Chef',
        'lat': -23.5200,
        'lng': -47.4200,
        'vagas': 1,
        'companyId': 'seed_company_3',
      },
      {
        'titulo': 'Auxiliar de Cozinha – Final de Semana',
        'empresa': 'Churrascaria Pampa',
        'local': 'Campolim, Sorocaba',
        'bairro': 'Campolim',
        'valor': '160',
        'descricao':
            'Apoio na mise en place, cortes e limpeza. Sem exigência de experiência — treinamento fornecido.',
        'data': '18/05/2026',
        'turno': '10h – 17h',
        'tipo': 'Auxiliar',
        'lat': -23.4780,
        'lng': -47.4350,
        'vagas': 4,
        'companyId': 'seed_company_4',
      },
      {
        'titulo': 'Sommelier para Jantar Especial',
        'empresa': 'Wine & Dine Sorocaba',
        'local': 'Jardim Vera Cruz, Sorocaba',
        'bairro': 'Jardim Vera Cruz',
        'valor': '350',
        'descricao':
            'Jantar temático de vinhos italianos. Exige certificação WSET ou Sommelier Brasil.',
        'data': '16/05/2026',
        'turno': '18h – 00h',
        'tipo': 'Sommelier',
        'lat': -23.5100,
        'lng': -47.4700,
        'vagas': 1,
        'companyId': 'seed_company_5',
      },
      {
        'titulo': 'Barista para Café Boutique',
        'empresa': 'Grão & Arte Café',
        'local': 'Aparecidinha, Sorocaba',
        'bairro': 'Aparecidinha',
        'valor': '140',
        'descricao':
            'Café especial de alto padrão. Sábado e domingo 7h-14h. Experiência com café coado e espresso.',
        'data': '17/05/2026',
        'turno': '07h – 14h',
        'tipo': 'Barista',
        'lat': -23.4900,
        'lng': -47.4600,
        'vagas': 2,
        'companyId': 'seed_company_6',
      },
      {
        'titulo': 'Recepcionista para Restaurante Gourmet',
        'empresa': 'La Maison Sorocaba',
        'local': 'Wanel Ville, Sorocaba',
        'bairro': 'Wanel Ville',
        'valor': '180',
        'descricao':
            'Recepção e alocação de mesas, gestão de reservas. Inglês básico desejável.',
        'data': '19/05/2026',
        'turno': '18h – 00h',
        'tipo': 'Recepcionista',
        'lat': -23.5080,
        'lng': -47.4820,
        'vagas': 1,
        'companyId': 'seed_company_7',
      },
      {
        'titulo': 'Pizzaiolo para Restaurante Temático',
        'empresa': 'Forno di Roma',
        'local': 'Cerrado, Sorocaba',
        'bairro': 'Cerrado',
        'valor': '220',
        'descricao':
            'Forno a lenha autêntico. Experiência com pizzas napolitanas. Turno único noturno.',
        'data': '20/05/2026',
        'turno': '17h – 23h',
        'tipo': 'Pizzaiolo',
        'lat': -23.5150,
        'lng': -47.4650,
        'vagas': 1,
        'companyId': 'seed_company_8',
      },
    ];

    final batch = db.batch();
    for (final vaga in vagas) {
      final ref = db.collection('vagas').doc();
      batch.set(ref, {
        ...vaga,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();

    // Seed de avaliações fictícias para user.matheus169@gmail.com
    final matheusUid = 'matheus169_uid'; // substitua pelo UID real após login
    final avals = [
      {
        'autorNome': 'Buffet Recanto Real',
        'nota': 5,
        'comentario':
            'Excelente profissional! Pontual, organizado e muito habilidoso.',
        'tipo': 'Chef',
        'data': Timestamp.fromDate(DateTime(2026, 4, 10)),
      },
      {
        'autorNome': 'Trattoria del Sol',
        'nota': 5,
        'comentario':
            'Um dos melhores garçons que já contratamos. Super recomendo!',
        'tipo': 'Garçom',
        'data': Timestamp.fromDate(DateTime(2026, 3, 15)),
      },
      {
        'autorNome': 'Espaço Vila Nova',
        'nota': 4,
        'comentario': 'Ótimo serviço, clientes adoraram os drinks.',
        'tipo': 'Bartender',
        'data': Timestamp.fromDate(DateTime(2026, 2, 20)),
      },
    ];
    for (final av in avals) {
      await db
          .collection('users')
          .doc(matheusUid)
          .collection('avaliacoes')
          .add(av);
    }

    // Jobs fictícios para matheus169
    final jobsBatch = db.batch();
    const jobsData = [
      {'status': 'aprovado',   'titulo': 'Chef de Cozinha para Casamento',     'empresa': 'Buffet Recanto Real', 'local': 'Éden, Sorocaba',       'valor': '450', 'data': '17/05/2026'},
      {'status': 'em_analise', 'titulo': 'Garçom para Restaurante Italiano',   'empresa': 'Trattoria del Sol',  'local': 'Centro, Sorocaba',      'valor': '190', 'data': '15/05/2026'},
      {'status': 'concluido',  'titulo': 'Recepcionista para Rest. Gourmet',   'empresa': 'La Maison Sorocaba', 'local': 'Wanel Ville, Sorocaba', 'valor': '180', 'data': 'Abr/2026'},
      {'status': 'concluido',  'titulo': 'Bartender para Evento Corporativo',  'empresa': 'Espaço Vila Nova',   'local': 'Vila Nova, Sorocaba',   'valor': '280', 'data': 'Mar/2026'},
    ];
    // Nota: em produção as candidaturas ficam em vagas/{vagaId}/candidaturas/{uid}
    // Aqui adicionamos também na subcoleção do usuário para facilitar a query em MyJobsPage
    for (final job in jobsData) {
      final ref = db
          .collection('users')
          .doc(matheusUid)
          .collection('candidaturas_index')
          .doc();
      jobsBatch.set(ref, {
        ...job,
        'freelancerId': matheusUid,
        'appliedAt': FieldValue.serverTimestamp(),
      });
    }
    await jobsBatch.commit();
  }
}
