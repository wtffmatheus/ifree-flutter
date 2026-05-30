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
        ],
      ),
      body: StreamBuilder<List<VagaModel>>(
        stream: _repository.watchVagasDaEmpresa(user.uid),
        builder: (context, snapshot) {
          final loading = snapshot.connectionState == ConnectionState.waiting;
          final vagas = snapshot.data ?? [];

          final ativas = vagas.where((vaga) => vaga.status == 'ativa').length;
          final finalizadas = vagas
              .where((vaga) => vaga.status == 'finalizada')
              .length;
          final canceladas = vagas
              .where((vaga) => vaga.status == 'cancelada')
              .length;

          return RefreshIndicator(
            onRefresh: () async => setState(() {}),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _HeaderCard(
                  title: 'Olá, empresa',
                  subtitle: 'Gerencie suas vagas, candidatos e contratações.',
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        title: 'Publicadas',
                        value: vagas.length.toString(),
                        icon: Icons.work_rounded,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatCard(
                        title: 'Ativas',
                        value: ativas.toString(),
                        icon: Icons.check_circle_rounded,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatCard(
                        title: 'Finalizadas',
                        value: finalizadas.toString(),
                        icon: Icons.flag_rounded,
                      ),
                    ),
                  ],
                ),
                if (canceladas > 0) ...[
                  const SizedBox(height: 10),
                  _MiniInfoCard(
                    icon: Icons.cancel_rounded,
                    text: '$canceladas vaga(s) cancelada(s)',
                  ),
                ],
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => context.go('/company/create-vacancy'),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Criar nova vaga'),
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Suas vagas',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Text(
                      vagas.length == 1
                          ? '1 publicada'
                          : '${vagas.length} publicadas',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (loading)
                  const _LoadingList()
                else if (vagas.isEmpty)
                  const _EmptyState()
                else
                  ...vagas.map(
                    (vaga) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _CompanyVagaCard(
                        vaga: vaga,
                        updating: _updating,
                        onCandidates: () {
                          context.go('/company/candidates/${vaga.id}');
                        },
                        onCancel: vaga.status == 'ativa'
                            ? () => _cancelarVaga(vaga)
                            : null,
                        onFinish: vaga.status == 'ativa'
                            ? () => _finalizarVaga(vaga)
                            : null,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
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
          'A vaga "${vaga.titulo}" será marcada como finalizada. Use esta opção quando a contratação já tiver sido concluída.',
      confirmText: 'Finalizar',
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
    setState(() {
      _updating = true;
    });

    try {
      await action();

      if (!mounted) return;

      _showSnackBar(successMessage);
    } catch (_) {
      if (!mounted) return;

      _showSnackBar(errorMessage, isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _updating = false;
        });
      }
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

class _HeaderCard extends StatelessWidget {
  final String title;
  final String subtitle;

  const _HeaderCard({required this.title, required this.subtitle});

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
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.86),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
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
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurface.withValues(alpha: 0.62),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniInfoCard extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MiniInfoCard({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.46),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: colorScheme.primary, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompanyVagaCard extends StatelessWidget {
  final VagaModel vaga;
  final bool updating;
  final VoidCallback onCandidates;
  final VoidCallback? onCancel;
  final VoidCallback? onFinish;

  const _CompanyVagaCard({
    required this.vaga,
    required this.updating,
    required this.onCandidates,
    required this.onCancel,
    required this.onFinish,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
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
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 8),
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
              style: TextStyle(
                height: 1.35,
                color: colorScheme.onSurface.withValues(alpha: 0.76),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 14),
          Text(
            'R\$ ${vaga.valor}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colorScheme.primary,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          if (updating)
            const LinearProgressIndicator()
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: onCandidates,
                  icon: const Icon(Icons.groups_rounded),
                  label: const Text('Candidatos'),
                ),
                if (onCancel != null)
                  OutlinedButton.icon(
                    onPressed: onCancel,
                    icon: const Icon(Icons.close_rounded),
                    label: const Text('Cancelar'),
                  ),
                if (onFinish != null)
                  FilledButton.icon(
                    onPressed: onFinish,
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('Finalizar'),
                  ),
              ],
            ),
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
              fontWeight: FontWeight.w700,
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
      'finalizada' => Colors.blue,
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

class _LoadingList extends StatelessWidget {
  const _LoadingList();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        4,
        (index) => Container(
          margin: const EdgeInsets.only(bottom: 14),
          height: 178,
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
          Icon(Icons.work_off_outlined, size: 48, color: colorScheme.primary),
          const SizedBox(height: 12),
          const Text(
            'Nenhuma vaga publicada',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            'Crie sua primeira vaga para receber candidatos.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colorScheme.onSurface.withValues(alpha: 0.64),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
