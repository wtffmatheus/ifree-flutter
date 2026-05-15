import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/utils/location_helper.dart';
import '../../auth/data/auth_repository.dart';

class FreelancerDashboard extends ConsumerStatefulWidget {
  const FreelancerDashboard({super.key});

  @override
  ConsumerState<FreelancerDashboard> createState() =>
      _FreelancerDashboardState();
}

class _FreelancerDashboardState extends ConsumerState<FreelancerDashboard> {
  final _uid = FirebaseAuth.instance.currentUser!.uid;
  Position? _userPosition;
  bool _loadingLocation = false;

  @override
  void initState() {
    super.initState();
    _fetchLocation();
  }

  Future<void> _fetchLocation() async {
    setState(() => _loadingLocation = true);
    final pos = await LocationHelper.getUserCoords();
    if (mounted) setState(() { _userPosition = pos; _loadingLocation = false; });
  }

  String _greet() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Bom dia';
    if (h < 18) return 'Boa tarde';
    return 'Boa noite';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── SliverAppBar premium ──────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 0,
            floating: true,
            snap: true,
            pinned: false,
            title: Row(
              children: [
                ShaderMask(
                  shaderCallback: (b) => const LinearGradient(
                    colors: [AppColors.freelancerPrimary, AppColors.freelancerSecondary],
                  ).createShader(b),
                  child: const Text(
                    'iFree',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              // Notificação (placeholder)
              IconButton(
                icon: Stack(
                  children: [
                    const Icon(Icons.notifications_outlined),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.freelancerPrimary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
                onPressed: () {},
                tooltip: 'Notificações',
              ),
            ],
          ),

          // ── Hero / Greeting card ──────────────────────────────────────────
          SliverToBoxAdapter(
            child: _GreetingHero(uid: _uid, greet: _greet()),
          ),

          // ── Stats cards ───────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _StatsRow(uid: _uid),
          ),

          // ── Categorias rápidas ────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _QuickCategories(
              onSearch: (q) => context.go('/freelancer/search', extra: q),
            ),
          ),

          // ── Seção: vagas próximas (com distância) ────────────────────────
          SliverToBoxAdapter(
            child: SectionHeader(
              title: '📍 Vagas próximas de você',
              action: 'Ver todas',
              onAction: () => context.go('/freelancer/search'),
            ),
          ),

          // ── Lista vagas ───────────────────────────────────────────────────
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('vagas')
                .orderBy('createdAt', descending: true)
                .limit(15)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: ShimmerCard(),
                    ),
                    childCount: 5,
                  ),
                );
              }

              var vagas = snapshot.data!.docs;

              // Ordena por distância se tiver localização
              if (_userPosition != null) {
                vagas = List.from(vagas)..sort((a, b) {
                  final ad = a.data() as Map<String, dynamic>;
                  final bd = b.data() as Map<String, dynamic>;
                  final aLat = (ad['lat'] as num?)?.toDouble();
                  final aLng = (ad['lng'] as num?)?.toDouble();
                  final bLat = (bd['lat'] as num?)?.toDouble();
                  final bLng = (bd['lng'] as num?)?.toDouble();
                  if (aLat == null || bLat == null) return 0;
                  final da = LocationHelper.distanceKm(
                    fromLat: _userPosition!.latitude,
                    fromLng: _userPosition!.longitude,
                    toLat: aLat, toLng: aLng!,
                  );
                  final db = LocationHelper.distanceKm(
                    fromLat: _userPosition!.latitude,
                    fromLng: _userPosition!.longitude,
                    toLat: bLat, toLng: bLng!,
                  );
                  return da.compareTo(db);
                });
              }

              if (vagas.isEmpty) {
                return SliverToBoxAdapter(
                  child: EmptyState(
                    icon: Icons.work_off_outlined,
                    title: 'Nenhuma vaga disponível',
                    subtitle: 'Novas vagas aparecerão aqui em breve.',
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final data = vagas[i].data() as Map<String, dynamic>;
                      double? dist;
                      if (_userPosition != null) {
                        final lat = (data['lat'] as num?)?.toDouble();
                        final lng = (data['lng'] as num?)?.toDouble();
                        if (lat != null && lng != null) {
                          dist = LocationHelper.distanceKm(
                            fromLat: _userPosition!.latitude,
                            fromLng: _userPosition!.longitude,
                            toLat: lat, toLng: lng,
                          );
                        }
                      }
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _VagaCard(
                          vagaId: vagas[i].id,
                          data: data,
                          freelancerUid: _uid,
                          distanceKm: dist,
                        ).animate(delay: Duration(milliseconds: i * 70))
                          .fadeIn(duration: 350.ms)
                          .slideY(begin: 0.15, curve: Curves.easeOut),
                      );
                    },
                    childCount: vagas.length,
                  ),
                ),
              );
            },
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}

// ── Greeting Hero ─────────────────────────────────────────────────────────────
class _GreetingHero extends StatelessWidget {
  final String uid;
  final String greet;
  const _GreetingHero({required this.uid, required this.greet});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
      builder: (context, snap) {
        // CORREÇÃO: erro "Bad state: cannot get field name on DocumentSnapshot which does not exist"
        // Verificamos se o doc existe antes de chamar .get()
        String name = 'Freelancer';
        double media = 0;
        int totalJobs = 0;

        if (snap.hasData && snap.data!.exists) {
          final d = snap.data!.data() as Map<String, dynamic>? ?? {};
          name = d['name'] as String? ?? 'Freelancer';
          media = (d['avaliacaoMedia'] as num?)?.toDouble() ?? 0;
          totalJobs = (d['totalJobs'] as num?)?.toInt() ?? 0;
        }

        final firstName = name.split(' ').first;

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFE63946), Color(0xFFC1121F)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.freelancerPrimary.withOpacity(0.3),
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
                    Text(
                      '$greet, 👋',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontFamily: 'Sora',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      firstName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Sora',
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Encontre sua próxima oportunidade 🍴',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontFamily: 'Sora',
                      ),
                    ),
                  ],
                ),
              ),
              IFreeAvatar(name: name, size: 56, color: Colors.white),
            ],
          ),
        ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.1);
      },
    );
  }
}

// ── Stats Row ─────────────────────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  final String uid;
  const _StatsRow({required this.uid});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
      builder: (context, snap) {
        double media = 0;
        int total = 0;
        if (snap.hasData && snap.data!.exists) {
          final d = snap.data!.data() as Map<String, dynamic>? ?? {};
          media = (d['avaliacaoMedia'] as num?)?.toDouble() ?? 0;
          total = (d['totalJobs'] as num?)?.toInt() ?? 0;
        }

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('vagas')
              .snapshots(),
          builder: (context, vagasSnap) {
            final totalVagas = vagasSnap.data?.docs.length ?? 0;

            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
              child: Row(
                children: [
                  _StatCard(label: 'Jobs feitos', value: '$total', icon: Icons.check_circle_outline_rounded, color: AppColors.success),
                  const SizedBox(width: 10),
                  _StatCard(
                    label: 'Avaliação',
                    value: media > 0 ? '${media.toStringAsFixed(1)} ★' : '—',
                    icon: Icons.star_outline_rounded,
                    color: AppColors.gold,
                  ),
                  const SizedBox(width: 10),
                  _StatCard(label: 'Vagas hoje', value: '$totalVagas', icon: Icons.work_outline_rounded, color: AppColors.freelancerPrimary),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.bgCardDark : AppColors.bgCardLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
            width: 0.8,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: color,
                fontFamily: 'Sora',
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                fontFamily: 'Sora',
              ),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.95, 0.95)),
    );
  }
}

// ── Categorias rápidas ────────────────────────────────────────────────────────
class _QuickCategories extends StatelessWidget {
  final void Function(String) onSearch;
  const _QuickCategories({required this.onSearch});

  static const _cats = [
    {'icon': '🍸', 'label': 'Bartender'},
    {'icon': '🍽', 'label': 'Garçom'},
    {'icon': '👨‍🍳', 'label': 'Chef'},
    {'icon': '☕', 'label': 'Barista'},
    {'icon': '🍕', 'label': 'Pizzaiolo'},
    {'icon': '🍷', 'label': 'Sommelier'},
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: '⚡ Categorias'),
        SizedBox(
          height: 90,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemCount: _cats.length,
            itemBuilder: (context, i) {
              final cat = _cats[i];
              return GestureDetector(
                onTap: () => onSearch(cat['label']!),
                child: Container(
                  width: 76,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.bgCardDark : AppColors.bgCardLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(cat['icon']!, style: const TextStyle(fontSize: 26)),
                      const SizedBox(height: 4),
                      Text(
                        cat['label']!,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                          fontFamily: 'Sora',
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ).animate(delay: Duration(milliseconds: i * 50)).fadeIn().slideX(begin: 0.2);
            },
          ),
        ),
      ],
    );
  }
}

// ── VagaCard premium com distância ─────────────────────────────────────────────
class _VagaCard extends StatefulWidget {
  final String vagaId;
  final Map<String, dynamic> data;
  final String freelancerUid;
  final double? distanceKm;

  const _VagaCard({
    required this.vagaId,
    required this.data,
    required this.freelancerUid,
    this.distanceKm,
  });

  @override
  State<_VagaCard> createState() => _VagaCardState();
}

class _VagaCardState extends State<_VagaCard> {
  bool _expanded = false;

  Color get _tipoColor {
    switch (widget.data['tipo'] as String? ?? '') {
      case 'Bartender': return AppColors.concluido;
      case 'Garçom': return AppColors.success;
      case 'Chef': return AppColors.freelancerPrimary;
      case 'Barista': return const Color(0xFFa78bfa);
      case 'Sommelier': return AppColors.gold;
      case 'Pizzaiolo': return const Color(0xFFf97316);
      default: return AppColors.textSecondary;
    }
  }

  String get _tipoEmoji {
    switch (widget.data['tipo'] as String? ?? '') {
      case 'Bartender': return '🍸';
      case 'Garçom': return '🍽';
      case 'Chef': return '👨‍🍳';
      case 'Barista': return '☕';
      case 'Sommelier': return '🍷';
      case 'Pizzaiolo': return '🍕';
      case 'Auxiliar': return '🔪';
      case 'Recepcionista': return '💁';
      default: return '🍴';
    }
  }

  Future<void> _candidatar() async {
    // Verificar perfil
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.freelancerUid)
        .get();

    if (!userDoc.exists) return;
    final ud = userDoc.data() as Map<String, dynamic>;
    final profileComplete = ud['profileComplete'] as bool? ?? false;

    if (!profileComplete && mounted) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Complete seu perfil'),
          content: const Text('Preencha seu perfil antes de se candidatar.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Depois')),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                context.go('/freelancer/profile');
              },
              child: const Text('Completar agora'),
            ),
          ],
        ),
      );
      return;
    }

    // Verificar candidatura existente
    final existing = await FirebaseFirestore.instance
        .collection('vagas')
        .doc(widget.vagaId)
        .collection('candidaturas')
        .doc(widget.freelancerUid)
        .get();

    if (existing.exists && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Você já se candidatou a esta vaga.')),
      );
      return;
    }

    await FirebaseFirestore.instance
        .collection('vagas')
        .doc(widget.vagaId)
        .collection('candidaturas')
        .doc(widget.freelancerUid)
        .set({
      'freelancerId': widget.freelancerUid,
      'status': 'em_analise',
      'appliedAt': FieldValue.serverTimestamp(),
      'freelancerName': ud['name'] ?? '',
      'freelancerEmail': ud['email'] ?? '',
      'titulo': widget.data['titulo'] ?? '',
      'local': widget.data['local'] ?? '',
      'valor': widget.data['valor'] ?? '',
    });

    // Índice no perfil do freelancer (resolve infinite loading no MyJobs)
    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.freelancerUid)
        .collection('candidaturas_index')
        .doc(widget.vagaId)
        .set({
      'vagaId': widget.vagaId,
      'titulo': widget.data['titulo'] ?? '',
      'empresa': widget.data['empresa'] ?? '',
      'local': widget.data['local'] ?? '',
      'valor': widget.data['valor'] ?? '',
      'status': 'em_analise',
      'appliedAt': FieldValue.serverTimestamp(),
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(children: [
            Icon(Icons.check_circle_outline_rounded, color: Colors.white),
            SizedBox(width: 8),
            Text('Candidatura enviada! ✓'),
          ]),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titulo = widget.data['titulo'] as String? ?? 'Sem título';
    final empresa = widget.data['empresa'] as String? ?? '';
    final local = widget.data['local'] as String? ?? 'Local não informado';
    final valor = widget.data['valor'] as String? ?? '';
    final descricao = widget.data['descricao'] as String? ?? '';
    final data = widget.data['data'] as String? ?? '';
    final turno = widget.data['turno'] as String? ?? '';
    final vagas = widget.data['vagas'] as int? ?? 1;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgCardDark : AppColors.bgCardLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ícone tipo
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _tipoColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _tipoColor.withOpacity(0.25)),
                  ),
                  child: Center(
                    child: Text(_tipoEmoji, style: const TextStyle(fontSize: 22)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titulo,
                        style: TextStyle(
                          fontSize: 15,
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
                    ],
                  ),
                ),
                // Valor
                if (valor.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.success.withOpacity(0.25)),
                    ),
                    child: Text(
                      'R\$ $valor',
                      style: const TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        fontFamily: 'Sora',
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ── Chips de info ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                InfoChip(
                  icon: Icons.location_on_outlined,
                  label: local,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                ),
                if (widget.distanceKm != null)
                  InfoChip(
                    icon: Icons.near_me_rounded,
                    label: LocationHelper.formatDistance(widget.distanceKm!),
                    color: widget.distanceKm! < 3
                        ? AppColors.success
                        : widget.distanceKm! < 8
                            ? AppColors.gold
                            : AppColors.textSecondary,
                  ),
                InfoChip(icon: Icons.work_outline_rounded, label: widget.data['tipo'] as String? ?? '', color: _tipoColor),
                if (data.isNotEmpty)
                  InfoChip(icon: Icons.calendar_today_outlined, label: data, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary),
              ],
            ),
          ),

          // ── Expanded details ──────────────────────────────────────────────
          if (_expanded) ...[
            Divider(height: 1, color: isDark ? AppColors.borderDark : AppColors.borderLight),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (descricao.isNotEmpty) ...[
                    Text(
                      descricao,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                        fontFamily: 'Sora',
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  Wrap(
                    spacing: 12,
                    children: [
                      if (turno.isNotEmpty)
                        Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.access_time_outlined, size: 14, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(turno, style: TextStyle(fontSize: 12, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary, fontFamily: 'Sora')),
                        ]),
                      Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.people_outline_rounded, size: 14, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text('$vagas vaga${vagas > 1 ? "s" : ""}', style: TextStyle(fontSize: 12, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary, fontFamily: 'Sora')),
                      ]),
                    ],
                  ),
                ],
              ),
            ),
          ],

          // ── Actions ───────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
            child: Row(
              children: [
                TextButton(
                  onPressed: () => setState(() => _expanded = !_expanded),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    foregroundColor: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                  ),
                  child: Text(
                    _expanded ? '▲ Menos' : '▼ Detalhes',
                    style: const TextStyle(fontSize: 12, fontFamily: 'Sora'),
                  ),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: _candidatar,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(130, 40),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, fontFamily: 'Sora'),
                  ),
                  child: const Text('Candidatar-se'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
