import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  Future<bool> _isAdmin() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return false;
    }

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    return doc.data()?['role'] == 'admin';
  }

  Future<int> _count(String collection) async {
    final snapshot = await FirebaseFirestore.instance
        .collection(collection)
        .get();

    return snapshot.docs.length;
  }

  Future<int> _countVagasAtivas() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('vagas')
        .where('status', isEqualTo: 'ativa')
        .get();

    return snapshot.docs.length;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _isAdmin(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final isAdmin = snapshot.data ?? false;

        if (!isAdmin) {
          return const Scaffold(
            body: Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Acesso restrito. Este painel ÃƒÂ© apenas para administradores.',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Painel administrativo'),
            centerTitle: false,
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              FutureBuilder<List<int>>(
                future: Future.wait([
                  _count('users'),
                  _count('vagas'),
                  _countVagasAtivas(),
                ]),
                builder: (context, countSnapshot) {
                  final values = countSnapshot.data ?? [0, 0, 0];

                  return Row(
                    children: [
                      Expanded(
                        child: _AdminStatCard(
                          title: 'Usuários',
                          value: values[0].toString(),
                          icon: Icons.people_rounded,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _AdminStatCard(
                          title: 'Vagas',
                          value: values[1].toString(),
                          icon: Icons.work_rounded,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _AdminStatCard(
                          title: 'Ativas',
                          value: values[2].toString(),
                          icon: Icons.check_circle_rounded,
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 22),
              const Text(
                'ÃƒÅ¡ltimas vagas',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('vagas')
                    .limit(20)
                    .snapshots(),
                builder: (context, snapshot) {
                  final docs = snapshot.data?.docs ?? [];

                  if (docs.isEmpty) {
                    return const Text('Nenhuma vaga encontrada.');
                  }

                  return Column(
                    children: docs.map((doc) {
                      final data = doc.data();

                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.work_rounded),
                          title: Text(data['titulo']?.toString() ?? 'Vaga'),
                          subtitle: Text(
                            '${data['empresa'] ?? 'Empresa'} ââ‚¬Â¢ ${data['status'] ?? 'status'}',
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 22),
              const Text(
                'ÃƒÅ¡ltimos usuários',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .limit(20)
                    .snapshots(),
                builder: (context, snapshot) {
                  final docs = snapshot.data?.docs ?? [];

                  if (docs.isEmpty) {
                    return const Text('Nenhum usuário encontrado.');
                  }

                  return Column(
                    children: docs.map((doc) {
                      final data = doc.data();

                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.person_rounded),
                          title: Text(data['name']?.toString() ?? 'Usuário'),
                          subtitle: Text(data['email']?.toString() ?? doc.id),
                          trailing: Text(data['role']?.toString() ?? ''),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AdminStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _AdminStatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.22)),
      ),
      child: Column(
        children: [
          Icon(icon, color: colorScheme.primary),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          Text(
            title,
            style: TextStyle(
              color: colorScheme.onSurface.withValues(alpha: 0.62),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
