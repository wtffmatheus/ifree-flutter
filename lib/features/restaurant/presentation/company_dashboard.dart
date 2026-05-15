import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_widgets.dart';

class CompanyDashboard extends StatelessWidget {
  const CompanyDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: ShaderMask(
          shaderCallback: (b) => const LinearGradient(
            colors: [AppColors.companyPrimary, AppColors.companySecondary],
          ).createShader(b),
          child: const Text('iFree', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded),
            onPressed: () => context.go('/company/create-vacancy'),
            tooltip: 'Postar nova vaga',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/company/create-vacancy'),
        backgroundColor: AppColors.companyPrimary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Nova Vaga', style: TextStyle(color: Colors.white, fontFamily: 'Sora', fontWeight: FontWeight.w600)),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
        builder: (context, userSnap) {
          String companyName = 'Restaurante';
          if (userSnap.hasData && userSnap.data!.exists) {
            final d = userSnap.data!.data() as Map<String, dynamic>? ?? {};
            companyName = d['name'] as String? ?? 'Restaurante';
          }

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('vagas')
                .where('companyId', isEqualTo: uid)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: 3,
                  itemBuilder: (_, __) => const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: ShimmerCard(),
                  ),
                );
              }

              final vagas = snapshot.data!.docs;

              return CustomScrollView(
                slivers: [
                  // ── Header ───────────────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.companyPrimary, AppColors.companySecondary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.companyPrimary.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Olá,', style: TextStyle(color: Colors.white70, fontSize: 13, fontFamily: 'Sora')),
                                Text(companyName, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800, fontFamily: 'Sora')),
                                const SizedBox(height: 4),
                                Text('${vagas.length} vaga${vagas.length != 1 ? "s" : ""} publicada${vagas.length != 1 ? "s" : ""}',
                                    style: const TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'Sora')),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 28),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1),
                  ),

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                      child: Text(
                        'Suas vagas',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ),

                  if (vagas.isEmpty)
                    SliverToBoxAdapter(
                      child: EmptyState(
                        icon: Icons.work_off_outlined,
                        title: 'Nenhuma vaga publicada',
                        subtitle: 'Crie sua primeira vaga e conecte-se com freelancers.',
                        actionLabel: 'Postar vaga',
                        onAction: () => context.go('/company/create-vacancy'),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, i) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _VagaCompanyCard(vagaId: vagas[i].id, data: vagas[i].data() as Map<String, dynamic>)
                                .animate(delay: Duration(milliseconds: i * 80))
                                .fadeIn()
                                .slideX(begin: -0.1),
                          ),
                          childCount: vagas.length,
                        ),
                      ),
                    ),

                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _VagaCompanyCard extends StatelessWidget {
  final String vagaId;
  final Map<String, dynamic> data;
  const _VagaCompanyCard({required this.vagaId, required this.data});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () => context.go('/company/candidates/$vagaId'),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.bgCardDark : AppColors.bgCardLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight, width: 0.8),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.companyPrimary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.work_outline_rounded, color: AppColors.companyPrimary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(data['titulo'] as String? ?? 'Sem título',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, fontFamily: 'Sora', color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary)),
                  Row(children: [
                    Icon(Icons.location_on_outlined, size: 12, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(data['local'] as String? ?? '', style: TextStyle(fontSize: 12, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary, fontFamily: 'Sora')),
                  ]),
                ],
              ),
            ),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('vagas').doc(vagaId).collection('candidaturas').snapshots(),
              builder: (context, snap) {
                final count = snap.data?.docs.length ?? 0;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: count > 0 ? AppColors.companyPrimary.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: count > 0 ? AppColors.companyPrimary.withOpacity(0.3) : Colors.transparent),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.people_outline_rounded, size: 15, color: count > 0 ? AppColors.companyPrimary : AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text('$count', style: TextStyle(fontWeight: FontWeight.w700, color: count > 0 ? AppColors.companyPrimary : AppColors.textSecondary, fontFamily: 'Sora')),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
