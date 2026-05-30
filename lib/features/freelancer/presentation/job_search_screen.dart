import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/vaga_model.dart';
import '../../../core/services/location_service.dart';
import '../../jobs/providers/vaga_providers.dart';

class JobSearchScreen extends ConsumerStatefulWidget {
  const JobSearchScreen({super.key});

  @override
  ConsumerState<JobSearchScreen> createState() => _JobSearchScreenState();
}

class _JobSearchScreenState extends ConsumerState<JobSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final LocationService _locationService = LocationService();

  List<VagaModel> _vagas = [];
  UserLocation? _userLocation;

  bool _loading = true;
  bool _loadingLocation = false;
  bool _candidatando = false;
  bool _sortByDistance = true;

  String _selectedFilter = 'Todas';

  final List<String> _filters = const [
    'Todas',
    'Garçom',
    'Auxiliar',
    'Pizzaiolo',
    'Barista',
    'Chapeiro',
    'Atendente',
  ];

  @override
  void initState() {
    super.initState();
    _loadAll();

    _searchController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    await _loadVagas();
    await _loadUserLocation();
  }

  Future<void> _loadVagas() async {
    if (mounted) {
      setState(() {
        _loading = true;
      });
    }

    try {
      final repository = ref.read(vagaRepositoryProvider);
      final vagas = await repository.getVagasAtivas();

      if (!mounted) return;

      setState(() {
        _vagas = vagas;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      final message = e.toString().replaceAll('Exception: ', '');

      _showSnackBar(
        message.isEmpty
            ? 'Não foi possível carregar as vagas. Verifique sua conexão.'
            : message,
        isError: true,
      );
    }
  }

  Future<void> _loadUserLocation() async {
    if (!mounted) return;

    setState(() {
      _loadingLocation = true;
    });

    final location = await _locationService.getCurrentLocation();

    if (!mounted) return;

    setState(() {
      _userLocation = location;
      _loadingLocation = false;
    });

    if (location == null) {
      _showSnackBar(
        'Não foi possível acessar sua localização. As vagas serão exibidas por data.',
        isError: false,
      );
    }
  }

  double? _distanceFor(VagaModel vaga) {
    final userLocation = _userLocation;

    if (userLocation == null || !vaga.hasLocation) {
      return null;
    }

    return _locationService.distanceInKm(
      fromLat: userLocation.latitude,
      fromLng: userLocation.longitude,
      toLat: vaga.lat!,
      toLng: vaga.lng!,
    );
  }

  List<VagaModel> get _filteredVagas {
    final search = _searchController.text.trim().toLowerCase();

    final filtered = _vagas.where((vaga) {
      final matchesSearch =
          search.isEmpty ||
          vaga.titulo.toLowerCase().contains(search) ||
          vaga.empresa.toLowerCase().contains(search) ||
          vaga.local.toLowerCase().contains(search) ||
          vaga.tipo.toLowerCase().contains(search);

      final matchesFilter =
          _selectedFilter == 'Todas' || vaga.tipo == _selectedFilter;

      return matchesSearch && matchesFilter;
    }).toList();

    if (_sortByDistance && _userLocation != null) {
      filtered.sort((a, b) {
        final distanceA = _distanceFor(a);
        final distanceB = _distanceFor(b);

        if (distanceA == null && distanceB == null) {
          final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return bDate.compareTo(aDate);
        }

        if (distanceA == null) return 1;
        if (distanceB == null) return -1;

        return distanceA.compareTo(distanceB);
      });
    }

    return filtered;
  }

  Future<Map<String, dynamic>> _getFreelancerData(String uid) async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    if (!doc.exists) {
      return {};
    }

    return doc.data() ?? {};
  }

  Future<void> _openVagaDetails(VagaModel vaga) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.88,
          child: _VagaDetailsSheet(
            vaga: vaga,
            distanceKm: _distanceFor(vaga),
            loading: _candidatando,
            onCandidatar: () async {
              Navigator.pop(context);
              await _candidatar(vaga);
            },
          ),
        );
      },
    );
  }

  Future<void> _candidatar(VagaModel vaga) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showSnackBar('Faça login para se candidatar.', isError: true);
      return;
    }

    final confirm = await _confirmCandidatura(vaga);

    if (!confirm) return;

    if (mounted) {
      setState(() {
        _candidatando = true;
      });
    }

    try {
      final repository = ref.read(vagaRepositoryProvider);
      final freelancerData = await _getFreelancerData(user.uid);

      await repository.candidatar(
        vagaId: vaga.id,
        freelancerId: user.uid,
        freelancerData: freelancerData,
      );

      if (!mounted) return;

      _showSnackBar('Candidatura enviada com sucesso!');
    } catch (e) {
      if (!mounted) return;

      final message = e.toString().replaceAll('Exception: ', '');

      _showSnackBar(
        message.isEmpty ? 'Não foi possível enviar sua candidatura.' : message,
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _candidatando = false;
        });
      }
    }
  }

  Future<bool> _confirmCandidatura(VagaModel vaga) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirmar candidatura?'),
          content: Text(
            'Você quer se candidatar para "${vaga.titulo}" em ${vaga.empresa}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Voltar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirmar'),
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

  @override
  Widget build(BuildContext context) {
    final filteredVagas = _filteredVagas;
    final orderedByDistance = _sortByDistance && _userLocation != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Buscar vagas'),
        centerTitle: false,
        actions: [
          IconButton(
            onPressed: _loadingLocation ? null : _loadUserLocation,
            icon: _loadingLocation
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.my_location_rounded),
            tooltip: 'Atualizar localização',
          ),
          IconButton(
            onPressed: _loadAll,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Atualizar',
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadAll,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _HeaderCard(
                      total: _vagas.length,
                      orderedByDistance: orderedByDistance,
                    ),
                    const SizedBox(height: 16),
                    _LocationOrderCard(
                      loadingLocation: _loadingLocation,
                      hasLocation: _userLocation != null,
                      sortByDistance: _sortByDistance,
                      onToggle: (value) {
                        setState(() {
                          _sortByDistance = value;
                        });

                        if (value && _userLocation == null) {
                          _loadUserLocation();
                        }
                      },
                      onUpdateLocation: _loadUserLocation,
                    ),
                    const SizedBox(height: 16),
                    _SearchBox(controller: _searchController),
                    const SizedBox(height: 14),
                    _FilterChips(
                      filters: _filters,
                      selectedFilter: _selectedFilter,
                      onSelected: (filter) {
                        setState(() {
                          _selectedFilter = filter;
                        });
                      },
                    ),
                    const SizedBox(height: 18),
                  ]),
                ),
              ),
              if (_loading)
                const SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverToBoxAdapter(child: _LoadingList()),
                )
              else if (filteredVagas.isEmpty)
                const SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverToBoxAdapter(child: _EmptyState()),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  sliver: SliverList.separated(
                    itemCount: filteredVagas.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final vaga = filteredVagas[index];

                      return _VagaCard(
                        vaga: vaga,
                        distanceKm: _distanceFor(vaga),
                        loading: _candidatando,
                        onVerDetalhes: () => _openVagaDetails(vaga),
                        onCandidatar: () => _candidatar(vaga),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final int total;
  final bool orderedByDistance;

  const _HeaderCard({required this.total, required this.orderedByDistance});

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
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.work_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Encontre sua próxima diária',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  orderedByDistance
                      ? '$total vagas ordenadas por proximidade'
                      : total == 1
                      ? '1 vaga ativa disponível'
                      : '$total vagas ativas disponíveis',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.86),
                    fontSize: 13,
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

class _LocationOrderCard extends StatelessWidget {
  final bool loadingLocation;
  final bool hasLocation;
  final bool sortByDistance;
  final ValueChanged<bool> onToggle;
  final VoidCallback onUpdateLocation;

  const _LocationOrderCard({
    required this.loadingLocation,
    required this.hasLocation,
    required this.sortByDistance,
    required this.onToggle,
    required this.onUpdateLocation,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Icon(
            hasLocation ? Icons.near_me_rounded : Icons.location_off_rounded,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              hasLocation
                  ? 'Ordenando restaurantes mais próximos'
                  : 'Permita localização para ordenar por proximidade',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          if (loadingLocation)
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Switch(value: sortByDistance, onChanged: onToggle),
        ],
      ),
    );
  }
}

class _SearchBox extends StatelessWidget {
  final TextEditingController controller;

  const _SearchBox({required this.controller});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: 'Buscar por vaga, empresa ou local...',
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                onPressed: controller.clear,
                icon: const Icon(Icons.close_rounded),
              ),
        filled: true,
        fillColor: colorScheme.surface,
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  final List<String> filters;
  final String selectedFilter;
  final ValueChanged<String> onSelected;

  const _FilterChips({
    required this.filters,
    required this.selectedFilter,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      width: double.infinity,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final selected = filter == selectedFilter;

          return ChoiceChip(
            label: Text(filter),
            selected: selected,
            onSelected: (_) => onSelected(filter),
            labelStyle: TextStyle(
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          );
        },
      ),
    );
  }
}

class _VagaCard extends StatelessWidget {
  final VagaModel vaga;
  final double? distanceKm;
  final bool loading;
  final VoidCallback onVerDetalhes;
  final VoidCallback onCandidatar;

  const _VagaCard({
    required this.vaga,
    required this.distanceKm,
    required this.loading,
    required this.onVerDetalhes,
    required this.onCandidatar,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final distanceText = distanceKm == null
        ? null
        : distanceKm! < 1
        ? '${(distanceKm! * 1000).round()} m de você'
        : '${distanceKm!.toStringAsFixed(1)} km de você';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onVerDetalhes,
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.22),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (distanceText != null) ...[
                _DistanceBadge(text: distanceText),
                const SizedBox(height: 10),
              ],
              Row(
                children: [
                  _CategoryIcon(tipo: vaga.tipo),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vaga.titulo,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          vaga.empresa,
                          style: TextStyle(
                            color: colorScheme.onSurface.withValues(
                              alpha: 0.64,
                            ),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
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
                  _InfoChip(
                    icon: Icons.location_on_outlined,
                    label: vaga.local,
                  ),
                  if (vaga.data.isNotEmpty)
                    _InfoChip(
                      icon: Icons.calendar_month_outlined,
                      label: vaga.data,
                    ),
                  if (vaga.horario.isNotEmpty)
                    _InfoChip(
                      icon: Icons.access_time_rounded,
                      label: vaga.horario,
                    ),
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
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    height: 1.4,
                    color: colorScheme.onSurface.withValues(alpha: 0.72),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Text(
                'R\$ ${vaga.valor}',
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
                    onPressed: onVerDetalhes,
                    icon: const Icon(Icons.visibility_rounded),
                    label: const Text('Detalhes'),
                  ),
                  FilledButton.icon(
                    onPressed: loading ? null : onCandidatar,
                    icon: loading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send_rounded),
                    label: const Text('Candidatar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VagaDetailsSheet extends StatelessWidget {
  final VagaModel vaga;
  final double? distanceKm;
  final bool loading;
  final VoidCallback onCandidatar;

  const _VagaDetailsSheet({
    required this.vaga,
    required this.distanceKm,
    required this.loading,
    required this.onCandidatar,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final distanceText = distanceKm == null
        ? null
        : distanceKm! < 1
        ? '${(distanceKm! * 1000).round()} m de você'
        : '${distanceKm!.toStringAsFixed(1)} km de você';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DetailHeader(vaga: vaga),
          if (distanceText != null) ...[
            const SizedBox(height: 12),
            _DistanceBadge(text: distanceText),
          ],
          const SizedBox(height: 16),
          _DetailSection(
            title: 'Informações da vaga',
            children: [
              _DetailTile(
                icon: Icons.category_outlined,
                title: 'Categoria',
                value: vaga.tipo,
              ),
              _DetailTile(
                icon: Icons.location_on_outlined,
                title: 'Local',
                value: vaga.local,
              ),
              _DetailTile(
                icon: Icons.calendar_month_outlined,
                title: 'Data',
                value: vaga.data.isEmpty ? 'Não informada' : vaga.data,
              ),
              _DetailTile(
                icon: Icons.access_time_rounded,
                title: 'Horário',
                value: vaga.horario.isEmpty ? 'Não informado' : vaga.horario,
              ),
              _DetailTile(
                icon: Icons.people_outline_rounded,
                title: 'Quantidade',
                value: '${vaga.quantidade} vaga(s)',
              ),
            ],
          ),
          const SizedBox(height: 14),
          _DetailSection(
            title: 'Descrição',
            children: [
              Text(
                vaga.descricao.isEmpty
                    ? 'Nenhuma descrição informada.'
                    : vaga.descricao,
                style: const TextStyle(
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _DetailSection(
            title: 'Pagamento',
            children: [
              Row(
                children: [
                  Icon(Icons.payments_rounded, color: colorScheme.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'R\$ ${vaga.valor}',
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: loading ? null : onCandidatar,
              icon: const Icon(Icons.send_rounded),
              label: const Text('Candidatar-se a esta vaga'),
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
}

class _DistanceBadge extends StatelessWidget {
  final String text;

  const _DistanceBadge({required this.text});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.near_me_rounded, color: colorScheme.primary, size: 15),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              color: colorScheme.primary,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailHeader extends StatelessWidget {
  final VagaModel vaga;

  const _DetailHeader({required this.vaga});

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
          _CategoryIconWhite(tipo: vaga.tipo),
          const SizedBox(height: 14),
          Text(
            vaga.titulo,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            vaga.empresa,
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

class _CategoryIconWhite extends StatelessWidget {
  final String tipo;

  const _CategoryIconWhite({required this.tipo});

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
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Icon(icon, color: Colors.white, size: 30),
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
    final bool active = normalized == 'ativa';

    final Color color = active ? Colors.green : Colors.orange;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        active ? 'Ativa' : status,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
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
          height: 170,
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
          Icon(Icons.work_off_outlined, size: 46, color: colorScheme.primary),
          const SizedBox(height: 12),
          const Text(
            'Nenhuma vaga disponível no momento',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            'Assim que uma empresa publicar uma vaga, ela aparecerá aqui.',
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
