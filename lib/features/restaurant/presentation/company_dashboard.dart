import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/vaga_model.dart';
import '../../jobs/data/vaga_repository.dart';

class CompanyDashboard extends StatefulWidget {
  const CompanyDashboard({super.key});

  @override
  State<CompanyDashboard> createState() => _CompanyDashboardState();
}

class _CompanyDashboardState extends State<CompanyDashboard> {
  final VagaRepository _repository = VagaRepository();

  User? get _user => FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    final user = _user;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('FaÃƒÂ§a login para acessar o painel da empresa.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Painel da empresa'),
        centerTitle: false,
        actions: [
          IconButton(
            onPressed: () => context.go('/notifications'),
            icon: const Icon(Icons.notifications_rounded),
            tooltip: 'Notificações',
          ),
          IconButton(
            onPressed: () => context.go('/company/profile'),
            icon: const Icon(Icons.storefront_rounded),
            tooltip: 'Perfil da empresa',
          ),
          IconButton(
            onPressed: () => setState(() {}),
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Atualizar',
          ),
        ],
      ),
      body: StreamBuilder<List<VagaModel>>(
        stream: _repository.watchVagasDaEmpresa(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _DashboardLoading();
          }

          if (snapshot.hasError) {
            return _ErrorState(
              message: 'Não foi possível carregar suas vagas.',
              onRetry: () => setState(() {}),
            );
          }

          final vagas = snapshot.data ?? [];

          final vagasAtivas = vagas
              .where((vaga) => vaga.status == 'ativa')
              .length;
          final vagasFinalizadas = vagas
              .where((vaga) => vaga.status == 'finalizada')
              .length;
          final vagasCanceladas = vagas
              .where((vaga) => vaga.status == 'cancelada')
              .length;

          return FutureBuilder<_CandidatesSummary>(
            future: _loadCandidatesSummary(vagas),
            builder: (context, summarySnapshot) {
              final summary =
                  summarySnapshot.data ?? const _CandidatesSummary();

              return RefreshIndicator(
                onRefresh: () async => setState(() {}),
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _HeaderCard(
                      companyName: user.displayName?.trim().isNotEmpty == true
                          ? user.displayName!.trim()
                          : 'Sua empresa',
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            title: 'Ativas',
                            value: vagasAtivas.toString(),
                            icon: Icons.work_rounded,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            title: 'Candidatos',
                            value: summary.total.toString(),
                            icon: Icons.groups_rounded,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            title: 'Aprovados',
                            value: summary.aprovados.toString(),
                            icon: Icons.check_circle_rounded,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _MiniStatusCard(
                            title: 'Em análise',
                            value: summary.emAnalise.toString(),
                            icon: Icons.hourglass_top_rounded,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _MiniStatusCard(
                            title: 'Recusados',
                            value: summary.recusados.toString(),
                            icon: Icons.cancel_rounded,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _MiniStatusCard(
                            title: 'Canceladas',
                            value: vagasCanceladas.toString(),
                            icon: Icons.block_rounded,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    FilledButton.icon(
                      onPressed: () => context.go('/company/create-vacancy'),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Criar nova vaga'),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Suas vagas',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Text(
                          '${vagas.length} publicadas',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.62),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (vagas.isEmpty)
                      const _EmptyState()
                    else
                      ...vagas.map(
                        (vaga) => Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _CompanyVagaCard(
                            vaga: vaga,
                            onViewCandidates: () {
                              context.push('/company/candidates/${vaga.id}');
                            },
                            onFinish: vaga.status == 'ativa'
                                ? () => _finishVaga(vaga.id)
                                : null,
                            onCancel: vaga.status == 'ativa'
                                ? () => _cancelVaga(vaga.id)
                                : null,
                          ),
                        ),
                      ),
                    if (vagasFinalizadas > 0) ...[
                      const SizedBox(height: 6),
                      Text(
                        '$vagasFinalizadas vaga(s) finalizada(s) no histÃƒÂ³rico.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.58),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<_CandidatesSummary> _loadCandidatesSummary(
    List<VagaModel> vagas,
  ) async {
    if (vagas.isEmpty) {
      return const _CandidatesSummary();
    }

    int total = 0;
    int aprovados = 0;
    int recusados = 0;
    int emAnalise = 0;

    for (final vaga in vagas) {
      try {
        final snapshot = await FirebaseFirestore.instance
            .collection('vagas')
            .doc(vaga.id)
            .collection('candidaturas')
            .get();

        for (final doc in snapshot.docs) {
          total++;
          final status = doc.data()['status']?.toString() ?? 'em_analise';

          switch (status) {
            case 'aprovado':
              aprovados++;
              break;
            case 'recusado':
              recusados++;
              break;
            default:
              emAnalise++;
          }
        }
      } catch (_) {
        // MantÃƒÂ©m o painel funcionando mesmo se alguma subcoleÃƒÂ§ÃƒÂ£o falhar.
      }
    }

    return _CandidatesSummary(
      total: total,
      aprovados: aprovados,
      recusados: recusados,
      emAnalise: emAnalise,
    );
  }

  Future<void> _finishVaga(String vagaId) async {
    final confirm = await _confirmAction(
      title: 'Finalizar vaga?',
      message:
          'A vaga serÃƒÂ¡ marcada como finalizada e não aparecerÃƒÂ¡ mais como ativa.',
      confirmText: 'Finalizar',
    );

    if (!confirm) return;

    try {
      await _repository.encerrarVaga(vagaId);

      if (!mounted) return;
      _showSnackBar('Vaga finalizada com sucesso.');
    } catch (_) {
      if (!mounted) return;
      _showSnackBar('Não foi possível finalizar a vaga.', isError: true);
    }
  }

  Future<void> _cancelVaga(String vagaId) async {
    final confirm = await _confirmAction(
      title: 'Cancelar vaga?',
      message:
          'A vaga serÃƒÂ¡ marcada como cancelada e não aparecerÃƒÂ¡ mais como ativa.',
      confirmText: 'Cancelar vaga',
    );

    if (!confirm) return;

    try {
      await _repository.cancelarVaga(vagaId);

      if (!mounted) return;
      _showSnackBar('Vaga cancelada com sucesso.');
    } catch (_) {
      if (!mounted) return;
      _showSnackBar('Não foi possível cancelar a vaga.', isError: true);
    }
  }

  Future<bool> _confirmAction({
    required String title,
    required String message,
    required String confirmText,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Voltar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(confirmText),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  void _showSnackBar(String message, {bool isError = false}) {
    final colorScheme = Theme.of(context).colorScheme;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? colorScheme.error : Colors.green.shade700,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}

class _CandidatesSummary {
  final int total;
  final int aprovados;
  final int recusados;
  final int emAnalise;

  const _CandidatesSummary({
    this.total = 0,
    this.aprovados = 0,
    this.recusados = 0,
    this.emAnalise = 0,
  });
}

class _HeaderCard extends StatelessWidget {
  final String companyName;

  const _HeaderCard({required this.companyName});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary,
            colorScheme.primary.withValues(alpha: 0.78),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.storefront_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  companyName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Gerencie vagas e acompanhe candidatos.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.86),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _StatCard({
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
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: colorScheme.primary),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurface.withValues(alpha: 0.62),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStatusCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _MiniStatusCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: colorScheme.primary),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
            ),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _CompanyVagaCard extends StatelessWidget {
  final VagaModel vaga;
  final VoidCallback onViewCandidates;
  final VoidCallback? onFinish;
  final VoidCallback? onCancel;

  const _CompanyVagaCard({
    required this.vaga,
    required this.onViewCandidates,
    required this.onFinish,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isActive = vaga.status == 'ativa';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.22)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _CategoryIcon(tipo: vaga.tipo),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  vaga.titulo,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _StatusBadge(status: vaga.status),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoChip(icon: Icons.category_outlined, label: vaga.tipo),
              _InfoChip(icon: Icons.location_on_outlined, label: vaga.local),
              if (vaga.data.isNotEmpty)
                _InfoChip(
                  icon: Icons.calendar_month_outlined,
                  label: vaga.data,
                ),
              if (vaga.horario.isNotEmpty)
                _InfoChip(icon: Icons.access_time_rounded, label: vaga.horario),
              _InfoChip(
                icon: Icons.people_outline_rounded,
                label: '${vaga.quantidade} vaga(s)',
              ),
            ],
          ),
          if (vaga.descricao.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              vaga.descricao,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                height: 1.4,
                color: colorScheme.onSurface.withValues(alpha: 0.72),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  'R\$ ${vaga.valor}',
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: onViewCandidates,
                icon: const Icon(Icons.groups_rounded),
                label: const Text('Candidatos'),
              ),
            ],
          ),
          if (isActive) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onCancel,
                    icon: const Icon(Icons.close_rounded),
                    label: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onFinish,
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('Finalizar'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _CategoryIcon extends StatelessWidget {
  final String tipo;

  const _CategoryIcon({required this.tipo});

  IconData get icon {
    switch (tipo.toLowerCase()) {
      case 'garçom':
        return Icons.room_service_rounded;
      case 'auxiliar':
        return Icons.soup_kitchen_rounded;
      case 'pizzaiolo':
        return Icons.local_pizza_rounded;
      case 'barista':
        return Icons.coffee_rounded;
      case 'chapeiro':
        return Icons.outdoor_grill_rounded;
      case 'atendente':
        return Icons.point_of_sale_rounded;
      default:
        return Icons.work_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(icon, color: colorScheme.primary),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 15,
            color: colorScheme.onSurface.withValues(alpha: 0.62),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurface.withValues(alpha: 0.72),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final normalized = status.toLowerCase();

    final color = switch (normalized) {
      'ativa' => Colors.green,
      'finalizada' => Colors.blueGrey,
      'cancelada' => Colors.red,
      _ => Colors.orange,
    };

    final label = switch (normalized) {
      'ativa' => 'Ativa',
      'finalizada' => 'Finalizada',
      'cancelada' => 'Cancelada',
      _ => status,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.22)),
      ),
      child: Column(
        children: [
          Icon(Icons.post_add_rounded, size: 48, color: colorScheme.primary),
          const SizedBox(height: 12),
          const Text(
            'Nenhuma vaga criada ainda',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            'Crie sua primeira vaga para comeÃƒÂ§ar a receber candidatos.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colorScheme.onSurface.withValues(alpha: 0.64),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardLoading extends StatelessWidget {
  const _DashboardLoading();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: List.generate(
        4,
        (index) => Container(
          margin: const EdgeInsets.only(bottom: 14),
          height: index == 0 ? 130 : 180,
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(22),
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}
