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
  bool _updating = false;

  User? get _user => FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    final user = _user;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('Faça login para acessar o painel da empresa.'),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: StreamBuilder<List<VagaModel>>(
          stream: _repository.watchVagasDaEmpresa(user.uid),
          builder: (context, snapshot) {
            final loading = snapshot.connectionState == ConnectionState.waiting;
            final vagas = snapshot.data ?? <VagaModel>[];

            final ativas = vagas.where((v) => v.status == 'ativa').length;
            final finalizadas =
                vagas.where((v) => v.status == 'finalizada').length;
            final canceladas =
                vagas.where((v) => v.status == 'cancelada').length;

            return RefreshIndicator(
              onRefresh: () async => setState(() {}),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 34),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1220),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Header(
                          onNotifications: () => context.go('/notifications'),
                          onProfile: () => context.go('/company/profile'),
                        ),
                        const SizedBox(height: 22),
                        _Hero(
                          onCreate: () =>
                              context.go('/company/create-vacancy'),
                        ),
                        const SizedBox(height: 18),
                        _Metrics(
                          total: vagas.length,
                          active: ativas,
                          finished: finalizadas,
                          cancelled: canceladas,
                        ),
                        const SizedBox(height: 30),
                        _SectionHeading(
                          eyebrow: 'GESTÃO DE VAGAS',
                          title: 'Suas oportunidades',
                          subtitle:
                              'Acompanhe o status das vagas e acesse os candidatos.',
                          trailing: FilledButton.icon(
                            onPressed: () =>
                                context.go('/company/create-vacancy'),
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: const Text('Nova vaga'),
                          ),
                        ),
                        const SizedBox(height: 14),
                        if (loading)
                          const _Loading()
                        else if (vagas.isEmpty)
                          _Empty(
                            onCreate: () =>
                                context.go('/company/create-vacancy'),
                          )
                        else
                          _VacancyGrid(
                            vagas: vagas,
                            updating: _updating,
                            onCandidates: (vaga) => context.go(
                              '/company/candidates/${vaga.id}',
                            ),
                            onCancel: _cancelarVaga,
                            onFinish: _finalizarVaga,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _cancelarVaga(VagaModel vaga) async {
    final confirm = await _confirmAction(
      title: 'Cancelar vaga?',
      message:
          'A vaga "${vaga.titulo}" será marcada como cancelada e deixará de aparecer como ativa.',
      confirmText: 'Cancelar vaga',
    );

    if (!confirm) return;

    await _updateVaga(
      action: () => _repository.cancelarVaga(vaga.id),
      successMessage: 'Vaga cancelada com sucesso.',
      errorMessage: 'Não foi possível cancelar a vaga.',
    );
  }

  Future<void> _finalizarVaga(VagaModel vaga) async {
    final confirm = await _confirmAction(
      title: 'Finalizar vaga?',
      message:
          'A vaga "${vaga.titulo}" será marcada como finalizada.',
      confirmText: 'Finalizar vaga',
    );

    if (!confirm) return;

    await _updateVaga(
      action: () => _repository.encerrarVaga(vaga.id),
      successMessage: 'Vaga finalizada com sucesso.',
      errorMessage: 'Não foi possível finalizar a vaga.',
    );
  }

  Future<void> _updateVaga({
    required Future<void> Function() action,
    required String successMessage,
    required String errorMessage,
  }) async {
    setState(() => _updating = true);

    try {
      await action();
      if (mounted) _showSnackBar(successMessage);
    } catch (_) {
      if (mounted) _showSnackBar(errorMessage, isError: true);
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  Future<bool> _confirmAction({
    required String title,
    required String message,
    required String confirmText,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
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
      ),
    );

    return result ?? false;
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? Theme.of(context).colorScheme.error : Colors.green.shade700,
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onNotifications;
  final VoidCallback onProfile;

  const _Header({
    required this.onNotifications,
    required this.onProfile,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Painel da empresa',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                'Publique vagas, gerencie candidatos e acompanhe contratações.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        _ActionIcon(
          icon: Icons.notifications_none_rounded,
          onTap: onNotifications,
        ),
        const SizedBox(width: 8),
        _ActionIcon(
          icon: Icons.storefront_outlined,
          onTap: onProfile,
        ),
      ],
    );
  }
}

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ActionIcon({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Icon(icon, size: 21),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  final VoidCallback onCreate;

  const _Hero({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            scheme.primary,
            scheme.primary.withValues(alpha: 0.8),
            const Color(0xFF6670E8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            bottom: -35,
            child: Icon(
              Icons.groups_3_rounded,
              size: 190,
              color: Colors.white.withValues(alpha: 0.07),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'CONTRATE COM MAIS AGILIDADE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Sua próxima contratação começa aqui.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  height: 1.1,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.1,
                ),
              ),
              const SizedBox(height: 10),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: Text(
                  'Crie oportunidades, receba candidaturas e acompanhe todo o processo em um único lugar.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 22),
              FilledButton.icon(
                onPressed: onCreate,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: scheme.primary,
                ),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Criar nova vaga'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Metrics extends StatelessWidget {
  final int total;
  final int active;
  final int finished;
  final int cancelled;

  const _Metrics({
    required this.total,
    required this.active,
    required this.finished,
    required this.cancelled,
  });

  @override
  Widget build(BuildContext context) {
    final data = [
      ('Publicadas', total, Icons.inventory_2_outlined),
      ('Ativas', active, Icons.play_circle_outline_rounded),
      ('Finalizadas', finished, Icons.check_circle_outline_rounded),
      ('Canceladas', cancelled, Icons.cancel_outlined),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 880 ? 4 : 2;
        final width = (constraints.maxWidth - ((columns - 1) * 12)) / columns;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: data
              .map(
                (item) => SizedBox(
                  width: width,
                  child: _Metric(
                    title: item.$1,
                    value: item.$2.toString(),
                    icon: item.$3,
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _Metric extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _Metric({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: scheme.primary, size: 20),
          ),
          const SizedBox(width: 11),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                title,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String subtitle;
  final Widget trailing;

  const _SectionHeading({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eyebrow,
                style: TextStyle(
                  color: scheme.primary,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        trailing,
      ],
    );
  }
}

class _VacancyGrid extends StatelessWidget {
  final List<VagaModel> vagas;
  final bool updating;
  final ValueChanged<VagaModel> onCandidates;
  final ValueChanged<VagaModel> onCancel;
  final ValueChanged<VagaModel> onFinish;

  const _VacancyGrid({
    required this.vagas,
    required this.updating,
    required this.onCandidates,
    required this.onCancel,
    required this.onFinish,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 860 ? 2 : 1;
        final width = (constraints.maxWidth - ((columns - 1) * 12)) / columns;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: vagas
              .map(
                (vaga) => SizedBox(
                  width: width,
                  child: _VacancyCard(
                    vaga: vaga,
                    updating: updating,
                    onCandidates: () => onCandidates(vaga),
                    onCancel:
                        vaga.status == 'ativa' ? () => onCancel(vaga) : null,
                    onFinish:
                        vaga.status == 'ativa' ? () => onFinish(vaga) : null,
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _VacancyCard extends StatelessWidget {
  final VagaModel vaga;
  final bool updating;
  final VoidCallback onCandidates;
  final VoidCallback? onCancel;
  final VoidCallback? onFinish;

  const _VacancyCard({
    required this.vaga,
    required this.updating,
    required this.onCandidates,
    required this.onCancel,
    required this.onFinish,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.work_outline_rounded,
                  color: scheme.primary,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  vaga.titulo,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _Status(status: vaga.status),
            ],
          ),
          const SizedBox(height: 15),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              _Tag(icon: Icons.category_outlined, label: vaga.tipo),
              _Tag(icon: Icons.location_on_outlined, label: vaga.local),
              if (vaga.data.isNotEmpty)
                _Tag(icon: Icons.calendar_today_outlined, label: vaga.data),
              _Tag(
                icon: Icons.people_outline_rounded,
                label: '${vaga.quantidade} vaga(s)',
              ),
            ],
          ),
          if (vaga.descricao.isNotEmpty) ...[
            const SizedBox(height: 15),
            Text(
              vaga.descricao,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 16),
          Text(
            'R\$ ${vaga.valor}',
            style: TextStyle(
              color: scheme.primary,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 15),
          if (updating)
            const LinearProgressIndicator()
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: onCandidates,
                  icon: const Icon(Icons.groups_2_outlined, size: 18),
                  label: const Text('Candidatos'),
                ),
                if (onCancel != null)
                  TextButton.icon(
                    onPressed: onCancel,
                    icon: const Icon(Icons.close_rounded, size: 18),
                    label: const Text('Cancelar'),
                  ),
                if (onFinish != null)
                  FilledButton.icon(
                    onPressed: onFinish,
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text('Finalizar'),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _Status extends StatelessWidget {
  final String status;

  const _Status({required this.status});

  @override
  Widget build(BuildContext context) {
    final normalized = status.toLowerCase();
    final color = switch (normalized) {
      'ativa' => Colors.green,
      'finalizada' => Colors.blue,
      'cancelada' => Colors.red,
      _ => Colors.orange,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final IconData icon;
  final String label;

  const _Tag({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: scheme.onSurfaceVariant),
          const SizedBox(width: 5),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 145),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      children: List.generate(
        3,
        (_) => Container(
          height: 180,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(22),
          ),
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  final VoidCallback onCreate;

  const _Empty({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(34),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              Icons.add_business_outlined,
              color: scheme.primary,
              size: 28,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Publique sua primeira vaga',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Comece criando uma oportunidade e receba candidatos pelo iFree.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Criar vaga'),
          ),
        ],
      ),
    );
  }
}
