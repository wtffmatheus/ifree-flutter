import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_widgets.dart';

class MyJobsPage extends StatefulWidget {
  const MyJobsPage({super.key});

  @override
  State<MyJobsPage> createState() => _MyJobsPageState();
}

class _MyJobsPageState extends State<MyJobsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _uid = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Jobs'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            _StatusTab(label: 'Em Análise', color: AppColors.analise),
            _StatusTab(label: 'Aprovado', color: AppColors.aprovado),
            _StatusTab(label: 'Concluído', color: AppColors.concluido),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _JobsList(uid: _uid, status: 'em_analise'),
          _JobsList(uid: _uid, status: 'aprovado'),
          _JobsList(uid: _uid, status: 'concluido'),
        ],
      ),
    );
  }
}

class _StatusTab extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusTab({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

// CORREÇÃO: usa candidaturas_index (subcoleção do próprio user) em vez de
// collectionGroup que causava loading infinito por falta de índice composto.
class _JobsList extends StatelessWidget {
  final String uid;
  final String status;
  const _JobsList({required this.uid, required this.status});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('candidaturas_index')
          .where('status', isEqualTo: status)
          .orderBy('appliedAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline_rounded,
                      size: 48, color: AppColors.error),
                  const SizedBox(height: 12),
                  Text(
                    'Erro ao carregar: ${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return EmptyState(
            icon: status == 'em_analise'
                ? Icons.hourglass_empty_rounded
                : status == 'aprovado'
                    ? Icons.thumb_up_outlined
                    : Icons.flag_outlined,
            title: status == 'em_analise'
                ? 'Nenhuma candidatura em análise'
                : status == 'aprovado'
                    ? 'Nenhum job aprovado ainda'
                    : 'Nenhum job concluído ainda',
            subtitle: 'Candidate-se a vagas para ver seus jobs aqui.',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            return _JobCard(data: data, status: status)
                .animate(delay: Duration(milliseconds: i * 60))
                .fadeIn()
                .slideY(begin: 0.1, curve: Curves.easeOut);
          },
        );
      },
    );
  }
}

class _JobCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String status;
  const _JobCard({required this.data, required this.status});

  Color get _statusColor {
    switch (status) {
      case 'aprovado': return AppColors.aprovado;
      case 'concluido': return AppColors.concluido;
      default: return AppColors.analise;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titulo = data['titulo'] as String? ?? 'Vaga';
    final empresa = data['empresa'] as String? ?? '';
    final local = data['local'] as String? ?? '';
    final valor = data['valor'] as String? ?? '';

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgCardDark : AppColors.bgCardLight,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
          width: 0.8,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Ícone status
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: _statusColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _statusColor.withOpacity(0.25)),
              ),
              child: Icon(
                status == 'aprovado'
                    ? Icons.check_circle_outline_rounded
                    : status == 'concluido'
                        ? Icons.flag_outlined
                        : Icons.hourglass_empty_rounded,
                color: _statusColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Sora',
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                    ),
                  ),
                  if (empresa.isNotEmpty)
                    Text(
                      empresa,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                        fontFamily: 'Sora',
                      ),
                    ),
                  if (local.isNotEmpty)
                    Row(children: [
                      Icon(Icons.location_on_outlined, size: 12,
                          color: isDark ? AppColors.textDimDark : AppColors.textDim),
                      const SizedBox(width: 3),
                      Text(
                        local,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? AppColors.textDimDark : AppColors.textDim,
                          fontFamily: 'Sora',
                        ),
                      ),
                    ]),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                StatusBadge(status: status),
                if (valor.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    'R\$ $valor',
                    style: const TextStyle(
                      color: AppColors.success,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      fontFamily: 'Sora',
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
