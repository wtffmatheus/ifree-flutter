import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/vaga_model.dart';
import '../../jobs/data/vaga_repository.dart';

class FreelancerDashboard extends StatefulWidget {
  const FreelancerDashboard({super.key});

  @override
  State<FreelancerDashboard> createState() => _FreelancerDashboardState();
}

class _FreelancerDashboardState extends State<FreelancerDashboard> {
  final VagaRepository _repository = VagaRepository();

  User? get _user => FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    final user = _user;
    final name = user?.displayName?.trim().isNotEmpty == true
        ? user!.displayName!.trim()
        : 'Freelancer';

    return Scaffold(
      body: SafeArea(
        child: StreamBuilder<List<VagaModel>>(
          stream: _repository.watchVagasAtivas(),
          builder: (context, vagasSnapshot) {
            final loading =
                vagasSnapshot.connectionState == ConnectionState.waiting;
            final vagas = vagasSnapshot.data ?? <VagaModel>[];

            return StreamBuilder(
              stream: user == null
                  ? const Stream.empty()
                  : _repository.watchMinhasCandidaturas(user.uid),
              builder: (context, jobsSnapshot) {
                final candidaturas = jobsSnapshot.data?.docs ?? [];
                final aprovadas = candidaturas
                    .where((d) => d.data()['status']?.toString() == 'aprovado')
                    .length;
                final analise = candidaturas
                    .where((d) => d.data()['status']?.toString() == 'em_analise')
                    .length;

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
                              name: name,
                              onNotifications: () =>
                                  context.go('/notifications'),
                              onProfile: () =>
                                  context.go('/freelancer/profile'),
                            ),
                            const SizedBox(height: 22),
                            _Hero(
                              name: name,
                              onSearch: () =>
                                  context.go('/freelancer/search'),
                              onJobs: () =>
                                  context.go('/freelancer/my-jobs'),
                            ),
                            const SizedBox(height: 18),
                            _Metrics(
                              vagas: vagas.length,
                              candidaturas: candidaturas.length,
                              aprovadas: aprovadas,
                              analise: analise,
                            ),
                            const SizedBox(height: 30),
                            const _SectionHeading(
                              eyebrow: 'ATALHOS',
                              title: 'Explore por função',
                              subtitle:
                                  'Encontre oportunidades alinhadas ao seu perfil.',
                            ),
                            const SizedBox(height: 14),
                            _Categories(
                              onTap: () =>
                                  context.go('/freelancer/search'),
                            ),
                            const SizedBox(height: 30),
                            _SectionHeading(
                              eyebrow: 'OPORTUNIDADES',
                              title: 'Vagas recentes',
                              subtitle:
                                  'As últimas oportunidades publicadas no iFree.',
                              trailing: TextButton.icon(
                                onPressed: () =>
                                    context.go('/freelancer/search'),
                                icon: const Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 18,
                                ),
                                label: const Text('Ver todas'),
                              ),
                            ),
                            const SizedBox(height: 14),
                            if (loading)
                              const _Loading()
                            else if (vagas.isEmpty)
                              const _Empty()
                            else
                              _Jobs(vagas: vagas.take(4).toList()),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String name;
  final VoidCallback onNotifications;
  final VoidCallback onProfile;

  const _Header({
    required this.name,
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
                'Painel do freelancer',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                'O seu trabalho, organizado em um só lugar.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        _SquareAction(
          icon: Icons.notifications_none_rounded,
          onTap: onNotifications,
        ),
        const SizedBox(width: 8),
        InkWell(
          onTap: onProfile,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            padding: const EdgeInsets.fromLTRB(6, 6, 12, 6),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 17,
                  backgroundColor: scheme.primary.withValues(alpha: 0.1),
                  child: Text(
                    name.isEmpty ? '?' : name.substring(0, 1).toUpperCase(),
                    style: TextStyle(
                      color: scheme.primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 110),
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SquareAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _SquareAction({required this.icon, required this.onTap});

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
  final String name;
  final VoidCallback onSearch;
  final VoidCallback onJobs;

  const _Hero({
    required this.name,
    required this.onSearch,
    required this.onJobs,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final desktop = constraints.maxWidth >= 780;

        final hero = Container(
          padding: const EdgeInsets.all(28),
          constraints: const BoxConstraints(minHeight: 260),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                scheme.primary,
                scheme.primary.withValues(alpha: 0.8),
                const Color(0xFF7C3AED),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -28,
                bottom: -38,
                child: Icon(
                  Icons.work_history_rounded,
                  size: 190,
                  color: Colors.white.withValues(alpha: 0.07),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HeroPill(
                    label: 'SEU ESPAÇO DE TRABALHO',
                    icon: Icons.auto_awesome_rounded,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Olá, $name.',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 31,
                      height: 1.08,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Encontre novas oportunidades e acompanhe suas candidaturas sem perder tempo.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 14,
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: onSearch,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: scheme.primary,
                    ),
                    icon: const Icon(Icons.search_rounded),
                    label: const Text('Encontrar uma vaga'),
                  ),
                ],
              ),
            ],
          ),
        );

        final actions = Container(
          padding: const EdgeInsets.all(18),
          constraints: const BoxConstraints(minHeight: 260),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ações rápidas',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Continue de onde parou.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 18),
              Expanded(
                child: _QuickAction(
                  icon: Icons.search_rounded,
                  title: 'Buscar vagas',
                  subtitle: 'Veja oportunidades abertas',
                  onTap: onSearch,
                  highlighted: true,
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: _QuickAction(
                  icon: Icons.assignment_turned_in_outlined,
                  title: 'Minhas candidaturas',
                  subtitle: 'Acompanhe seus retornos',
                  onTap: onJobs,
                ),
              ),
            ],
          ),
        );

        if (!desktop) {
          return Column(
            children: [
              hero,
              const SizedBox(height: 14),
              SizedBox(height: 260, child: actions),
            ],
          );
        }

        return SizedBox(
          height: 260,
          child: Row(
            children: [
              Expanded(flex: 7, child: hero),
              const SizedBox(width: 14),
              Expanded(flex: 4, child: actions),
            ],
          ),
        );
      },
    );
  }
}

class _HeroPill extends StatelessWidget {
  final String label;
  final IconData icon;

  const _HeroPill({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.7,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool highlighted;

  const _QuickAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: highlighted
              ? scheme.primary.withValues(alpha: 0.08)
              : scheme.surfaceContainerHighest.withValues(alpha: 0.58),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: highlighted ? scheme.primary : scheme.surface,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                icon,
                size: 20,
                color: highlighted ? Colors.white : scheme.primary,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}

class _Metrics extends StatelessWidget {
  final int vagas;
  final int candidaturas;
  final int aprovadas;
  final int analise;

  const _Metrics({
    required this.vagas,
    required this.candidaturas,
    required this.aprovadas,
    required this.analise,
  });

  @override
  Widget build(BuildContext context) {
    final data = [
      ('Vagas abertas', vagas, Icons.work_outline_rounded),
      ('Candidaturas', candidaturas, Icons.send_outlined),
      ('Aprovadas', aprovadas, Icons.verified_outlined),
      ('Em análise', analise, Icons.schedule_rounded),
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
                    label: item.$1,
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
  final String label;
  final String value;
  final IconData icon;

  const _Metric({
    required this.label,
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
            child: Icon(icon, color: scheme.primary, size: 19),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
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
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
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

class _SectionHeading extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String subtitle;
  final Widget? trailing;

  const _SectionHeading({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    this.trailing,
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
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _Categories extends StatelessWidget {
  final VoidCallback onTap;

  const _Categories({required this.onTap});

  @override
  Widget build(BuildContext context) {
    const data = [
      ('Garçom', Icons.room_service_outlined),
      ('Cozinha', Icons.soup_kitchen_outlined),
      ('Pizzaiolo', Icons.local_pizza_outlined),
      ('Barista', Icons.coffee_outlined),
      ('Atendimento', Icons.point_of_sale_outlined),
      ('Outros', Icons.grid_view_rounded),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 980
            ? 6
            : constraints.maxWidth >= 620
                ? 3
                : 2;
        final width = (constraints.maxWidth - ((columns - 1) * 10)) / columns;

        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: data
              .map(
                (item) => SizedBox(
                  width: width,
                  child: _Category(
                    title: item.$1,
                    icon: item.$2,
                    onTap: onTap,
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _Category extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _Category({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: scheme.primary, size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Jobs extends StatelessWidget {
  final List<VagaModel> vagas;

  const _Jobs({required this.vagas});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 820 ? 2 : 1;
        final width = (constraints.maxWidth - ((columns - 1) * 12)) / columns;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: vagas
              .map(
                (vaga) => SizedBox(
                  width: width,
                  child: _JobCard(vaga: vaga),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _JobCard extends StatelessWidget {
  final VagaModel vaga;

  const _JobCard({required this.vaga});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: () => context.go('/freelancer/search'),
      borderRadius: BorderRadius.circular(22),
      child: Container(
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vaga.titulo,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        vaga.empresa,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_outward_rounded, size: 18),
              ],
            ),
            const SizedBox(height: 15),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                _Tag(
                  icon: Icons.location_on_outlined,
                  label: vaga.local,
                ),
                if (vaga.data.isNotEmpty)
                  _Tag(
                    icon: Icons.calendar_today_outlined,
                    label: vaga.data,
                  ),
                if (vaga.horario.isNotEmpty)
                  _Tag(
                    icon: Icons.schedule_rounded,
                    label: vaga.horario,
                  ),
              ],
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Text(
                  'R\$ ${vaga.valor}',
                  style: TextStyle(
                    color: scheme.primary,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Spacer(),
                Text(
                  vaga.tipo,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
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
          height: 150,
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
  const _Empty();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        children: [
          Icon(
            Icons.work_outline_rounded,
            size: 44,
            color: scheme.primary,
          ),
          const SizedBox(height: 12),
          const Text(
            'Nenhuma vaga disponível agora',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Quando novas oportunidades forem publicadas, elas aparecem aqui.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
