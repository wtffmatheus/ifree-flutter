import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/utils/location_helper.dart';

class JobSearchScreen extends StatefulWidget {
  const JobSearchScreen({super.key});

  @override
  State<JobSearchScreen> createState() => _JobSearchScreenState();
}

class _JobSearchScreenState extends State<JobSearchScreen> {
  final _searchCtrl = TextEditingController();
  final _uid = FirebaseAuth.instance.currentUser?.uid ?? '';
  String _query = '';
  String _filterTipo = 'Todos';
  bool _loadingLocation = false;
  bool _loadingVagas = true;
  List<DocumentSnapshot> _allVagas = [];
  Position? _userPosition;

  static const _tipos = ['Todos', 'Bartender', 'Garçom', 'Chef', 'Barista', 'Sommelier', 'Pizzaiolo', 'Auxiliar', 'Recepcionista'];

  @override
  void initState() {
    super.initState();
    _fetchVagas();
    _fetchLocation();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchVagas() async {
    final snap = await FirebaseFirestore.instance.collection('vagas').get();
    if (mounted) setState(() { _allVagas = snap.docs; _loadingVagas = false; });
  }

  Future<void> _fetchLocation() async {
    setState(() => _loadingLocation = true);
    final pos = await LocationHelper.getUserCoords();
    if (mounted) setState(() { _userPosition = pos; _loadingLocation = false; });
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _loadingLocation = true);
    final address = await LocationHelper.getCurrentAddress();
    final pos = await LocationHelper.getUserCoords();
    if (mounted) {
      if (address != null) {
        _searchCtrl.text = address;
        setState(() { _query = address.toLowerCase(); _userPosition = pos; });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Não foi possível obter sua localização.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
      setState(() => _loadingLocation = false);
    }
  }

  List<DocumentSnapshot> get _filtered {
    var list = _allVagas.where((doc) {
      final d = doc.data() as Map<String, dynamic>;
      final local = (d['local'] as String? ?? '').toLowerCase();
      final titulo = (d['titulo'] as String? ?? '').toLowerCase();
      final tipo = d['tipo'] as String? ?? '';
      final matchQuery = _query.isEmpty || local.contains(_query) || titulo.contains(_query);
      final matchTipo = _filterTipo == 'Todos' || tipo == _filterTipo;
      return matchQuery && matchTipo;
    }).toList();

    // Ordena por distância se tiver posição
    if (_userPosition != null) {
      list.sort((a, b) {
        final ad = a.data() as Map<String, dynamic>;
        final bd = b.data() as Map<String, dynamic>;
        final aLat = (ad['lat'] as num?)?.toDouble();
        final aLng = (ad['lng'] as num?)?.toDouble();
        final bLat = (bd['lat'] as num?)?.toDouble();
        final bLng = (bd['lng'] as num?)?.toDouble();
        if (aLat == null || bLat == null) return 0;
        final da = LocationHelper.distanceKm(fromLat: _userPosition!.latitude, fromLng: _userPosition!.longitude, toLat: aLat, toLng: aLng!);
        final db = LocationHelper.distanceKm(fromLat: _userPosition!.latitude, fromLng: _userPosition!.longitude, toLat: bLat, toLng: bLng!);
        return da.compareTo(db);
      });
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Buscar Vagas')),
      body: Column(
        children: [
          // ── Search bar ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Cidade, bairro ou cargo...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _query.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => _query = '');
                              },
                            )
                          : null,
                    ),
                    onChanged: (v) => setState(() => _query = v.toLowerCase()),
                  ),
                ),
                const SizedBox(width: 10),
                // GPS button
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: _loadingLocation
                        ? null
                        : const LinearGradient(
                            colors: [AppColors.freelancerPrimary, AppColors.freelancerDark],
                          ),
                    color: _loadingLocation
                        ? (isDark ? AppColors.bgCard2Dark : AppColors.bgCard2Light)
                        : null,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: _loadingLocation
                        ? null
                        : [
                            BoxShadow(
                              color: AppColors.freelancerPrimary.withOpacity(0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                  ),
                  child: InkWell(
                    onTap: _loadingLocation ? null : _useCurrentLocation,
                    borderRadius: BorderRadius.circular(14),
                    child: Center(
                      child: _loadingLocation
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.freelancerPrimary,
                              ),
                            )
                          : const Icon(Icons.my_location_rounded,
                              color: Colors.white, size: 22),
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 300.ms),

          // ── Filtros por tipo ──────────────────────────────────────────────
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemCount: _tipos.length,
              itemBuilder: (context, i) {
                final tipo = _tipos[i];
                final selected = _filterTipo == tipo;
                return GestureDetector(
                  onTap: () => setState(() => _filterTipo = tipo),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.freelancerPrimary
                          : (isDark ? AppColors.bgCardDark : AppColors.bgCardLight),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selected
                            ? AppColors.freelancerPrimary
                            : (isDark ? AppColors.borderDark : AppColors.borderLight),
                      ),
                    ),
                    child: Text(
                      tipo,
                      style: TextStyle(
                        color: selected ? Colors.white : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondary),
                        fontSize: 12,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                        fontFamily: 'Sora',
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 12),

          // ── Resultados ────────────────────────────────────────────────────
          if (_userPosition != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  Icon(Icons.near_me_rounded, size: 14, color: AppColors.success),
                  const SizedBox(width: 4),
                  Text(
                    'Ordenado por proximidade · ${_filtered.length} vaga${_filtered.length != 1 ? "s" : ""}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.success,
                      fontFamily: 'Sora',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

          Expanded(
            child: _loadingVagas
                ? ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: 5,
                    itemBuilder: (_, __) => const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: ShimmerCard(),
                    ),
                  )
                : _filtered.isEmpty
                    ? EmptyState(
                        icon: Icons.search_off_rounded,
                        title: 'Nenhuma vaga encontrada',
                        subtitle: 'Tente outro bairro, cidade ou categoria.',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, i) {
                          final doc = _filtered[i];
                          final data = doc.data() as Map<String, dynamic>;
                          double? dist;
                          if (_userPosition != null) {
                            final lat = (data['lat'] as num?)?.toDouble();
                            final lng = (data['lng'] as num?)?.toDouble();
                            if (lat != null && lng != null) {
                              dist = LocationHelper.distanceKm(
                                fromLat: _userPosition!.latitude,
                                fromLng: _userPosition!.longitude,
                                toLat: lat,
                                toLng: lng,
                              );
                            }
                          }
                          return _SearchVagaCard(
                            vagaId: doc.id,
                            data: data,
                            uid: _uid,
                            distKm: dist,
                          ).animate(delay: Duration(milliseconds: i * 50))
                            .fadeIn()
                            .slideY(begin: 0.15, duration: 300.ms);
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _SearchVagaCard extends StatelessWidget {
  final String vagaId;
  final Map<String, dynamic> data;
  final String uid;
  final double? distKm;

  const _SearchVagaCard({
    required this.vagaId,
    required this.data,
    required this.uid,
    this.distKm,
  });

  String _tipoEmoji(String tipo) {
    switch (tipo) {
      case 'Bartender': return '🍸';
      case 'Garçom': return '🍽';
      case 'Chef': return '👨‍🍳';
      case 'Barista': return '☕';
      case 'Sommelier': return '🍷';
      case 'Pizzaiolo': return '🍕';
      default: return '🍴';
    }
  }

  Future<void> _candidatar(BuildContext ctx) async {
    if (uid.isEmpty) return;
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (!userDoc.exists) return;
    final ud = userDoc.data() as Map<String, dynamic>;

    final existing = await FirebaseFirestore.instance
        .collection('vagas').doc(vagaId).collection('candidaturas').doc(uid).get();
    if (existing.exists && ctx.mounted) {
      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Já candidatado!')));
      return;
    }

    await FirebaseFirestore.instance
        .collection('vagas').doc(vagaId).collection('candidaturas').doc(uid)
        .set({
      'freelancerId': uid,
      'status': 'em_analise',
      'appliedAt': FieldValue.serverTimestamp(),
      'freelancerName': ud['name'] ?? '',
      'freelancerEmail': ud['email'] ?? '',
    });

    await FirebaseFirestore.instance
        .collection('users').doc(uid).collection('candidaturas_index').doc(vagaId)
        .set({
      'vagaId': vagaId,
      'titulo': data['titulo'] ?? '',
      'empresa': data['empresa'] ?? '',
      'local': data['local'] ?? '',
      'valor': data['valor'] ?? '',
      'status': 'em_analise',
      'appliedAt': FieldValue.serverTimestamp(),
    });

    if (ctx.mounted) {
      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
        content: const Row(children: [
          Icon(Icons.check_circle_outline_rounded, color: Colors.white),
          SizedBox(width: 8),
          Text('Candidatura enviada!'),
        ]),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tipo = data['tipo'] as String? ?? '';

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgCardDark : AppColors.bgCardLight,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight, width: 0.8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_tipoEmoji(tipo), style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['titulo'] as String? ?? '',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Sora',
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                        ),
                      ),
                      if ((data['empresa'] as String? ?? '').isNotEmpty)
                        Text(
                          data['empresa'] as String,
                          style: TextStyle(fontSize: 12, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary, fontFamily: 'Sora'),
                        ),
                    ],
                  ),
                ),
                if ((data['valor'] as String? ?? '').isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'R\$ ${data['valor']}',
                      style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.w700, fontSize: 13, fontFamily: 'Sora'),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                InfoChip(
                  icon: Icons.location_on_outlined,
                  label: data['local'] as String? ?? '',
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                ),
                if (distKm != null)
                  InfoChip(
                    icon: Icons.near_me_rounded,
                    label: LocationHelper.formatDistance(distKm!),
                    color: distKm! < 3 ? AppColors.success : distKm! < 8 ? AppColors.gold : AppColors.textSecondary,
                  ),
                if (tipo.isNotEmpty)
                  InfoChip(icon: Icons.work_outline_rounded, label: tipo, color: AppColors.freelancerPrimary),
                if ((data['data'] as String? ?? '').isNotEmpty)
                  InfoChip(icon: Icons.calendar_today_outlined, label: data['data'] as String, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _candidatar(context),
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 44)),
                child: const Text('Candidatar-se'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
