import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../jobs/data/vaga_repository.dart';

class MyJobsPage extends StatefulWidget {
  const MyJobsPage({super.key});

  @override
  State<MyJobsPage> createState() => _MyJobsPageState();
}

class _MyJobsPageState extends State<MyJobsPage> {
  final VagaRepository _repository = VagaRepository();

  String _selectedStatus = 'todos';
  bool _updating = false;

  User? get _user => FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    final user = _user;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('FaÃƒÂ§a login para visualizar suas candidaturas.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Jobs'),
        centerTitle: false,
        actions: [
          IconButton(
            onPressed: () => setState(() {}),
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Atualizar',
          ),
        ],
      ),
      body: StreamBuilder(
        stream: _repository.watchMinhasCandidaturas(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _LoadingList();
          }

          if (snapshot.hasError) {
            return _ErrorState(
              message: 'Não foi possível carregar seus jobs.',
              onRetry: () => setState(() {}),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          final candidaturas = docs.map((doc) {
            final data = doc.data();
            return {'id': doc.id, ...data};
          }).toList();

          final filtered = _filterCandidaturas(candidaturas);

          return RefreshIndicator(
            onRefresh: () async => setState(() {}),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _HeaderCard(total: candidaturas.length),
                const SizedBox(height: 16),
                _StatusFilters(
                  selected: _selectedStatus,
                  onSelected: (value) {
                    setState(() {
                      _selectedStatus = value;
                    });
                  },
                ),
                const SizedBox(height: 18),
                if (filtered.isEmpty)
                  _EmptyState(
                    hasFilter: _selectedStatus != 'todos',
                    onClear: () {
                      setState(() {
                        _selectedStatus = 'todos';
                      });
                    },
                  )
                else
                  ...filtered.map(
                    (data) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _JobApplicationCard(
                        data: data,
                        updating: _updating,
                        onTap: () => _openApplicationDetails(data),
                        onCancel: _canCancel(data)
                            ? () => _cancelarCandidatura(data)
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

  bool _canCancel(Map<String, dynamic> data) {
    final status = data['status']?.toString() ?? '';

    return status == 'em_analise' || status == 'recusado';
  }

  void _openApplicationDetails(Map<String, dynamic> data) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.82,
          child: _ApplicationDetailsSheet(
            data: data,
            canCancel: _canCancel(data),
            updating: _updating,
            onCancel: () async {
              Navigator.pop(context);
              await _cancelarCandidatura(data);
            },
          ),
        );
      },
    );
  }

  Future<void> _cancelarCandidatura(Map<String, dynamic> data) async {
    final user = _user;

    if (user == null) return;

    final vagaId = data['vagaId']?.toString() ?? data['id']?.toString() ?? '';

    if (vagaId.isEmpty) {
      _showSnackBar(
        'Não foi possível identificar a candidatura.',
        isError: true,
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Cancelar candidatura?'),
          content: const Text(
            'Sua candidatura serÃƒÂ¡ marcada como cancelada e a empresa serÃƒÂ¡ avisada.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Voltar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Cancelar candidatura'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    setState(() {
      _updating = true;
    });

    try {
      await _repository.cancelarCandidatura(
        vagaId: vagaId,
        freelancerId: user.uid,
      );

      if (!mounted) return;

      _showSnackBar('Candidatura cancelada com sucesso.');
    } catch (e) {
      if (!mounted) return;

      final message = e.toString().replaceAll('Exception: ', '');

      _showSnackBar(
        message.isEmpty ? 'Não foi possível cancelar a candidatura.' : message,
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _updating = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> _filterCandidaturas(
    List<Map<String, dynamic>> candidaturas,
  ) {
    if (_selectedStatus == 'todos') {
      return candidaturas;
    }

    return candidaturas.where((data) {
      return data['status']?.toString() == _selectedStatus;
    }).toList();
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
  final int total;

  const _HeaderCard({required this.total});

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
              Icons.assignment_turned_in_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Suas candidaturas',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  total == 1
                      ? '1 candidatura enviada'
                      : '$total candidaturas enviadas',
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

class _StatusFilters extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelected;

  const _StatusFilters({required this.selected, required this.onSelected});

  static const filters = [
    ('todos', 'Todos'),
    ('em_analise', 'Em análise'),
    ('aprovado', 'Aprovados'),
    ('recusado', 'Recusados'),
    ('cancelada_pelo_freelancer', 'Canceladas'),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = filters[index];
          final selectedFilter = item.$1 == selected;

          return ChoiceChip(
            label: Text(item.$2),
            selected: selectedFilter,
            onSelected: (_) => onSelected(item.$1),
            labelStyle: TextStyle(
              fontWeight: selectedFilter ? FontWeight.w800 : FontWeight.w600,
            ),
          );
        },
      ),
    );
  }
}

class _JobApplicationCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool updating;
  final VoidCallback onTap;
  final VoidCallback? onCancel;

  const _JobApplicationCard({
    required this.data,
    required this.updating,
    required this.onTap,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final titulo = _text(data['titulo'], fallback: 'Vaga');
    final empresa = _text(data['empresa'], fallback: 'Empresa');
    final tipo = _text(data['tipo'], fallback: 'Geral');
    final local = _text(data['local'], fallback: 'Local não informado');
    final valor = _text(data['valor'], fallback: '0,00');
    final dataVaga = _text(data['data']);
    final horario = _text(data['horario']);
    final status = _text(data['status'], fallback: 'em_analise');

    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.22),
          ),
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
                _CategoryIcon(tipo: tipo),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titulo,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        empresa,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colorScheme.onSurface.withValues(alpha: 0.62),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                _StatusBadge(status: status),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InfoChip(icon: Icons.category_outlined, label: tipo),
                _InfoChip(icon: Icons.location_on_outlined, label: local),
                if (dataVaga.isNotEmpty)
                  _InfoChip(
                    icon: Icons.calendar_month_outlined,
                    label: dataVaga,
                  ),
                if (horario.isNotEmpty)
                  _InfoChip(icon: Icons.access_time_rounded, label: horario),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'R\$ $valor',
              style: TextStyle(
                color: colorScheme.primary,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: onTap,
                  icon: const Icon(Icons.visibility_rounded),
                  label: const Text('Detalhes'),
                ),
                if (onCancel != null)
                  FilledButton.icon(
                    onPressed: updating ? null : onCancel,
                    icon: updating
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.close_rounded),
                    label: const Text('Cancelar candidatura'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _text(dynamic value, {String fallback = ''}) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }
}

class _ApplicationDetailsSheet extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool canCancel;
  final bool updating;
  final VoidCallback onCancel;

  const _ApplicationDetailsSheet({
    required this.data,
    required this.canCancel,
    required this.updating,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final titulo = _text(data['titulo'], fallback: 'Vaga');
    final empresa = _text(data['empresa'], fallback: 'Empresa');
    final tipo = _text(data['tipo'], fallback: 'Geral');
    final local = _text(data['local'], fallback: 'Local não informado');
    final valor = _text(data['valor'], fallback: '0,00');
    final dataVaga = _text(data['data'], fallback: 'Não informada');
    final horario = _text(data['horario'], fallback: 'Não informado');
    final status = _text(data['status'], fallback: 'em_analise');

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
      child: Column(
        children: [
          _ApplicationHeader(titulo: titulo, empresa: empresa, status: status),
          const SizedBox(height: 14),
          _StatusExplanation(status: status),
          const SizedBox(height: 14),
          _DetailSection(
            title: 'Dados da vaga',
            children: [
              _DetailTile(
                icon: Icons.category_outlined,
                title: 'Categoria',
                value: tipo,
              ),
              _DetailTile(
                icon: Icons.location_on_outlined,
                title: 'Local',
                value: local,
              ),
              _DetailTile(
                icon: Icons.calendar_month_outlined,
                title: 'Data',
                value: dataVaga,
              ),
              _DetailTile(
                icon: Icons.access_time_rounded,
                title: 'HorÃƒÂ¡rio',
                value: horario,
              ),
              _DetailTile(
                icon: Icons.payments_rounded,
                title: 'Valor',
                value: 'R\$ $valor',
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (canCancel)
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: updating ? null : onCancel,
                icon: const Icon(Icons.close_rounded),
                label: const Text('Cancelar candidatura'),
              ),
            ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fechar'),
            ),
          ),
        ],
      ),
    );
  }

  static String _text(dynamic value, {String fallback = ''}) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }
}

class _ApplicationHeader extends StatelessWidget {
  final String titulo;
  final String empresa;
  final String status;

  const _ApplicationHeader({
    required this.titulo,
    required this.empresa,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StatusBadgeWhite(status: status),
          const SizedBox(height: 14),
          Text(
            titulo,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            empresa,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.86),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusExplanation extends StatelessWidget {
  final String status;

  const _StatusExplanation({required this.status});

  @override
  Widget build(BuildContext context) {
    final normalized = status.toLowerCase();

    final icon = switch (normalized) {
      'aprovado' => Icons.check_circle_rounded,
      'recusado' => Icons.cancel_rounded,
      'cancelada_pelo_freelancer' => Icons.do_disturb_rounded,
      'em_analise' => Icons.hourglass_top_rounded,
      _ => Icons.info_rounded,
    };

    final title = switch (normalized) {
      'aprovado' => 'Você foi aprovado!',
      'recusado' => 'Candidatura recusada',
      'cancelada_pelo_freelancer' => 'Candidatura cancelada',
      'em_analise' => 'Aguardando resposta',
      _ => 'Status da candidatura',
    };

    final message = switch (normalized) {
      'aprovado' =>
        'A empresa aprovou sua candidatura. Combine os próximos detalhes com o responsÃƒÂ¡vel pela vaga.',
      'recusado' =>
        'A empresa optou por não seguir com sua candidatura nesta vaga.',
      'cancelada_pelo_freelancer' =>
        'Você cancelou esta candidatura. Ela não seguirÃƒÂ¡ para análise da empresa.',
      'em_analise' =>
        'Sua candidatura foi enviada e a empresa ainda estÃƒÂ¡ analisando.',
      _ => 'Acompanhe o status desta candidatura por aqui.',
    };

    final color = switch (normalized) {
      'aprovado' => Colors.green,
      'recusado' => Colors.red,
      'cancelada_pelo_freelancer' => Colors.blueGrey,
      'em_analise' => Colors.orange,
      _ => Colors.blueGrey,
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: const TextStyle(
                    height: 1.35,
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

class _DetailSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _DetailSection({required this.title, required this.children});

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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _DetailTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _DetailTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, color: colorScheme.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: colorScheme.onSurface.withValues(alpha: 0.62),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
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
      'aprovado' => Colors.green,
      'recusado' => Colors.red,
      'cancelada_pelo_freelancer' => Colors.blueGrey,
      'em_analise' => Colors.orange,
      _ => Colors.blueGrey,
    };

    final label = switch (normalized) {
      'aprovado' => 'Aprovado',
      'recusado' => 'Recusado',
      'cancelada_pelo_freelancer' => 'Cancelada',
      'em_analise' => 'Em análise',
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

class _StatusBadgeWhite extends StatelessWidget {
  final String status;

  const _StatusBadgeWhite({required this.status});

  @override
  Widget build(BuildContext context) {
    final normalized = status.toLowerCase();

    final label = switch (normalized) {
      'aprovado' => 'Aprovado',
      'recusado' => 'Recusado',
      'cancelada_pelo_freelancer' => 'Cancelada',
      'em_analise' => 'Em análise',
      _ => status,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool hasFilter;
  final VoidCallback onClear;

  const _EmptyState({required this.hasFilter, required this.onClear});

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
          Icon(
            hasFilter ? Icons.filter_alt_off_rounded : Icons.work_off_outlined,
            size: 50,
            color: colorScheme.primary,
          ),
          const SizedBox(height: 12),
          Text(
            hasFilter
                ? 'Nenhum job nesse filtro'
                : 'Você ainda não se candidatou',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            hasFilter
                ? 'Tente visualizar todos os status.'
                : 'Busque uma vaga e envie sua primeira candidatura.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colorScheme.onSurface.withValues(alpha: 0.64),
            ),
          ),
          if (hasFilter) ...[
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: onClear,
              icon: const Icon(Icons.cleaning_services_rounded),
              label: const Text('Limpar filtro'),
            ),
          ],
        ],
      ),
    );
  }
}

class _LoadingList extends StatelessWidget {
  const _LoadingList();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: List.generate(
        4,
        (index) => Container(
          margin: const EdgeInsets.only(bottom: 14),
          height: index == 0 ? 120 : 170,
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
