import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_widgets.dart';

class CandidatesScreen extends StatelessWidget {
  final String vagaId;
  const CandidatesScreen({super.key, required this.vagaId});

  Color _statusColor(String s) {
    switch (s) {
      case 'aprovado': return AppColors.aprovado;
      case 'concluido': return AppColors.concluido;
      default: return AppColors.analise;
    }
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'aprovado': return 'Aprovado';
      case 'concluido': return 'Concluído';
      default: return 'Em Análise';
    }
  }

  // Atualiza status tanto na vaga quanto no índice do freelancer
  Future<void> _updateStatus(BuildContext ctx, String candidaturaId, String freelancerId, String newStatus) async {
    final batch = FirebaseFirestore.instance.batch();

    // Atualiza na coleção da vaga
    final vagaRef = FirebaseFirestore.instance
        .collection('vagas').doc(vagaId).collection('candidaturas').doc(candidaturaId);
    batch.update(vagaRef, {'status': newStatus});

    // Atualiza no índice do freelancer (resolve consistência e myJobsPage)
    if (freelancerId.isNotEmpty) {
      final indexRef = FirebaseFirestore.instance
          .collection('users').doc(freelancerId).collection('candidaturas_index').doc(vagaId);
      batch.update(indexRef, {'status': newStatus});
    }

    await batch.commit();

    if (ctx.mounted) {
      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
        content: Row(children: [
          Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text('Status atualizado: ${_statusLabel(newStatus)}'),
        ]),
        backgroundColor: _statusColor(newStatus),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Candidatos')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('vagas').doc(vagaId).collection('candidaturas').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const EmptyState(
              icon: Icons.people_outline_rounded,
              title: 'Nenhum candidato ainda',
              subtitle: 'Quando freelancers se candidatarem, eles aparecerão aqui.',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              final candidaturaId = docs[i].id;
              final status = data['status'] as String? ?? 'em_analise';
              final name = data['freelancerName'] as String? ?? 'Freelancer';
              final email = data['freelancerEmail'] as String? ?? '';
              final freelancerId = data['freelancerId'] as String? ?? '';

              return _CandidatoCard(
                name: name,
                email: email,
                status: status,
                freelancerId: freelancerId,
                statusColor: _statusColor(status),
                statusLabel: _statusLabel(status),
                onAprovar: status != 'aprovado'
                    ? () => _updateStatus(context, candidaturaId, freelancerId, 'aprovado')
                    : null,
                onConcluir: status == 'aprovado'
                    ? () => _updateStatus(context, candidaturaId, freelancerId, 'concluido')
                    : null,
              ).animate(delay: Duration(milliseconds: i * 70)).fadeIn().slideY(begin: 0.1);
            },
          );
        },
      ),
    );
  }
}

class _CandidatoCard extends StatelessWidget {
  final String name;
  final String email;
  final String status;
  final String freelancerId;
  final Color statusColor;
  final String statusLabel;
  final VoidCallback? onAprovar;
  final VoidCallback? onConcluir;

  const _CandidatoCard({
    required this.name,
    required this.email,
    required this.status,
    required this.freelancerId,
    required this.statusColor,
    required this.statusLabel,
    this.onAprovar,
    this.onConcluir,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgCardDark : AppColors.bgCardLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight, width: 0.8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IFreeAvatar(name: name, size: 48),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, fontFamily: 'Sora', color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary)),
                      Text(email, style: TextStyle(fontSize: 12, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary, fontFamily: 'Sora')),
                    ],
                  ),
                ),
                StatusBadge(status: status),
              ],
            ),

            // Ver perfil do freelancer
            if (freelancerId.isNotEmpty) ...[
              const SizedBox(height: 10),
              FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('users').doc(freelancerId).get(),
                builder: (context, snap) {
                  if (!snap.hasData || !snap.data!.exists) return const SizedBox.shrink();
                  final d = snap.data!.data() as Map<String, dynamic>? ?? {};
                  final bio = d['bio'] as String? ?? '';
                  final media = (d['avaliacaoMedia'] as num?)?.toDouble() ?? 0;
                  if (bio.isEmpty && media == 0) return const SizedBox.shrink();
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.bgCard2Dark : AppColors.bgCard2Light,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (media > 0) Row(children: [
                          StarRating(rating: media, size: 14),
                          const SizedBox(width: 6),
                          Text(media.toStringAsFixed(1), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.gold, fontFamily: 'Sora')),
                        ]),
                        if (bio.isNotEmpty) ...[
                          if (media > 0) const SizedBox(height: 4),
                          Text(bio, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary, fontFamily: 'Sora')),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ],

            const SizedBox(height: 14),

            Row(
              children: [
                if (onAprovar != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onAprovar,
                      icon: const Icon(Icons.check_rounded, size: 16, color: AppColors.aprovado),
                      label: const Text('Aprovar', style: TextStyle(color: AppColors.aprovado)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.aprovado),
                        minimumSize: const Size(double.infinity, 42),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                if (onConcluir != null)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onConcluir,
                      icon: const Icon(Icons.task_alt_rounded, size: 16),
                      label: const Text('Marcar como Concluído'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 42),
                        backgroundColor: AppColors.concluido,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        textStyle: const TextStyle(fontSize: 13, fontFamily: 'Sora', fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
