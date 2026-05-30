import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/theme_provider.dart';
import '../../../core/services/image_upload_service.dart';
import '../../auth/data/auth_repository.dart';

class ProfileFreelancerPage extends ConsumerStatefulWidget {
  const ProfileFreelancerPage({super.key});

  @override
  ConsumerState<ProfileFreelancerPage> createState() =>
      _ProfileFreelancerPageState();
}

class _ProfileFreelancerPageState extends ConsumerState<ProfileFreelancerPage> {
  final AuthRepository _authRepository = AuthRepository();
  final ImageUploadService _imageUploadService = ImageUploadService();

  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();
  final _bioController = TextEditingController();
  final _skillsController = TextEditingController();
  final _photoUrlController = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  bool _uploadingPhoto = false;
  bool _editing = false;
  bool _available = true;

  double _avaliacaoMedia = 0.0;
  int _totalJobs = 0;
  List<Map<String, dynamic>> _reviews = [];

  User? get _user => FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _bioController.dispose();
    _skillsController.dispose();
    _photoUrlController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final user = _user;

    if (user == null) {
      setState(() {
        _loading = false;
      });
      return;
    }

    try {
      final data = await _authRepository.getUserData(user.uid);

      if (!mounted) return;

      _nameController.text =
          data?['name']?.toString() ?? user.displayName ?? '';
      _phoneController.text = data?['phone']?.toString() ?? '';
      _cityController.text = data?['city']?.toString() ?? '';
      _bioController.text = data?['bio']?.toString() ?? '';
      _photoUrlController.text =
          data?['photoUrl']?.toString() ?? user.photoURL ?? '';

      final skills = data?['skills'];
      if (skills is List) {
        _skillsController.text = skills
            .map((item) => item.toString())
            .join(', ');
      } else {
        _skillsController.text = '';
      }

      final reviews = data?['reviews'];
      if (reviews is List) {
        _reviews = reviews
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      } else {
        _reviews = [];
      }

      _available = data?['available'] is bool
          ? data!['available'] as bool
          : true;
      _avaliacaoMedia = (data?['avaliacaoMedia'] as num?)?.toDouble() ?? 0.0;
      _totalJobs = (data?['totalJobs'] as num?)?.toInt() ?? _reviews.length;

      setState(() {
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      _showSnackBar('Não foi possível carregar seu perfil.', isError: true);
    }
  }

  Future<void> _pickProfilePhoto() async {
    final user = _user;

    if (user == null) {
      _showSnackBar('Faça login para alterar sua foto.', isError: true);
      return;
    }

    setState(() {
      _uploadingPhoto = true;
    });

    try {
      final photoUrl = await _imageUploadService.pickAndUploadProfileImage(
        uid: user.uid,
      );

      if (!mounted) return;

      if (photoUrl == null) {
        _showSnackBar('Nenhuma foto selecionada.');
        return;
      }

      _photoUrlController.text = photoUrl;

      await _authRepository.createOrUpdateUserData(user.uid, {
        'name': _nameController.text.trim().isEmpty
            ? user.displayName ?? ''
            : _nameController.text.trim(),
        'email': user.email ?? '',
        'photoUrl': photoUrl,
        'role': 'freelancer',
      });

      if (!mounted) return;

      setState(() {});

      _showSnackBar('Foto de perfil atualizada.');
    } catch (_) {
      if (!mounted) return;

      _showSnackBar('Não foi possível atualizar a foto.', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _uploadingPhoto = false;
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    final user = _user;

    if (user == null) {
      _showSnackBar('Faça login para editar seu perfil.', isError: true);
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _saving = true;
    });

    final skills = _skillsController.text
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();

    try {
      await user.updateDisplayName(_nameController.text.trim());

      await _authRepository.createOrUpdateUserData(user.uid, {
        'name': _nameController.text.trim(),
        'email': user.email ?? '',
        'phone': _phoneController.text.trim(),
        'city': _cityController.text.trim(),
        'bio': _bioController.text.trim(),
        'skills': skills,
        'photoUrl': _photoUrlController.text.trim(),
        'available': _available,
        'role': 'freelancer',
        'profileComplete':
            _nameController.text.trim().isNotEmpty &&
            _cityController.text.trim().isNotEmpty &&
            skills.isNotEmpty,
        'avaliacaoMedia': _avaliacaoMedia,
        'totalJobs': _totalJobs,
        'reviews': _reviews,
      });

      if (!mounted) return;

      setState(() {
        _editing = false;
      });

      _showSnackBar('Perfil atualizado com sucesso.');
    } catch (_) {
      if (!mounted) return;

      _showSnackBar('Não foi possível salvar seu perfil.', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Sair da conta?'),
          content: const Text(
            'Você precisará fazer login novamente para acessar o iFree.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Sair'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    await _authRepository.signOut();
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
    final user = _user;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Faça login para acessar seu perfil.')),
      );
    }

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final themeMode = ref.watch(themeControllerProvider);
    final darkEnabled = themeMode == ThemeMode.dark;
    final email = user.email ?? 'E-mail não informado';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
        centerTitle: false,
        actions: [
          IconButton(
            onPressed: _saving
                ? null
                : () {
                    setState(() {
                      _editing = !_editing;
                    });
                  },
            icon: Icon(_editing ? Icons.close_rounded : Icons.edit_rounded),
            tooltip: _editing ? 'Cancelar edição' : 'Editar perfil',
          ),
          if (_editing)
            IconButton(
              onPressed: _saving ? null : _saveProfile,
              icon: const Icon(Icons.save_rounded),
              tooltip: 'Salvar',
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _ProfileHeader(
              name: _nameController.text.trim().isEmpty
                  ? 'Freelancer'
                  : _nameController.text.trim(),
              email: email,
              photoUrl: _photoUrlController.text.trim(),
              available: _available,
              uploadingPhoto: _uploadingPhoto,
              onPickPhoto: _pickProfilePhoto,
            ),
            const SizedBox(height: 14),
            _SectionCard(
              title: 'Preferências',
              icon: Icons.tune_rounded,
              children: [
                SwitchListTile(
                  value: darkEnabled,
                  onChanged: (value) {
                    ref
                        .read(themeControllerProvider.notifier)
                        .toggleDarkMode(value);
                  },
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Modo escuro',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: const Text('Alternar entre tema claro e escuro.'),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (_editing)
              _EditProfileForm(
                nameController: _nameController,
                phoneController: _phoneController,
                cityController: _cityController,
                bioController: _bioController,
                skillsController: _skillsController,
                photoUrlController: _photoUrlController,
                available: _available,
                saving: _saving,
                onAvailabilityChanged: (value) {
                  setState(() {
                    _available = value;
                  });
                },
                onChanged: () => setState(() {}),
              )
            else
              _ReadProfileView(
                phone: _phoneController.text,
                city: _cityController.text,
                bio: _bioController.text,
                skills: _skillsController.text,
                available: _available,
              ),
            const SizedBox(height: 14),
            _StatsCard(avaliacaoMedia: _avaliacaoMedia, totalJobs: _totalJobs),
            const SizedBox(height: 14),
            _ReviewsSection(reviews: _reviews),
            const SizedBox(height: 18),
            if (_editing)
              FilledButton.icon(
                onPressed: _saving ? null : _saveProfile,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_rounded),
                label: Text(_saving ? 'Salvando...' : 'Salvar alterações'),
              )
            else
              FilledButton.icon(
                onPressed: () {
                  setState(() {
                    _editing = true;
                  });
                },
                icon: const Icon(Icons.edit_rounded),
                label: const Text('Editar perfil'),
              ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _saving ? null : _logout,
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Sair da conta'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final String name;
  final String email;
  final String photoUrl;
  final bool available;
  final bool uploadingPhoto;
  final VoidCallback onPickPhoto;

  const _ProfileHeader({
    required this.name,
    required this.email,
    required this.photoUrl,
    required this.available,
    required this.uploadingPhoto,
    required this.onPickPhoto,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    ImageProvider? image;

    if (photoUrl.isNotEmpty) {
      if (photoUrl.startsWith('data:image')) {
        final base64Data = photoUrl.split(',').last;
        image = MemoryImage(base64Decode(base64Data));
      } else {
        image = NetworkImage(photoUrl);
      }
    }

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
          Stack(
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: Colors.white.withValues(alpha: 0.18),
                backgroundImage: image,
                child: image == null
                    ? Text(
                        name.isNotEmpty ? name[0].toUpperCase() : 'F',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                        ),
                      )
                    : null,
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: InkWell(
                  onTap: uploadingPhoto ? null : onPickPhoto,
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: colorScheme.primary, width: 2),
                    ),
                    child: uploadingPhoto
                        ? const Padding(
                            padding: EdgeInsets.all(7),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            Icons.camera_alt_rounded,
                            color: colorScheme.primary,
                            size: 17,
                          ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
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
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.86),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    available ? 'Disponível para freelas' : 'Indisponível',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
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

class _EditProfileForm extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController phoneController;
  final TextEditingController cityController;
  final TextEditingController bioController;
  final TextEditingController skillsController;
  final TextEditingController photoUrlController;
  final bool available;
  final bool saving;
  final ValueChanged<bool> onAvailabilityChanged;
  final VoidCallback onChanged;

  const _EditProfileForm({
    required this.nameController,
    required this.phoneController,
    required this.cityController,
    required this.bioController,
    required this.skillsController,
    required this.photoUrlController,
    required this.available,
    required this.saving,
    required this.onAvailabilityChanged,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SectionCard(
          title: 'Informações pessoais',
          icon: Icons.person_rounded,
          children: [
            TextFormField(
              controller: nameController,
              textInputAction: TextInputAction.next,
              enabled: !saving,
              decoration: const InputDecoration(
                labelText: 'Nome completo',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Informe seu nome.';
                }

                return null;
              },
              onChanged: (_) => onChanged(),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: photoUrlController,
              textInputAction: TextInputAction.next,
              enabled: !saving,
              decoration: const InputDecoration(
                labelText: 'URL da foto de perfil',
                prefixIcon: Icon(Icons.image_outlined),
                hintText:
                    'Ou toque na câmera da foto para enviar do dispositivo',
              ),
              onChanged: (_) => onChanged(),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: phoneController,
              textInputAction: TextInputAction.next,
              keyboardType: TextInputType.phone,
              enabled: !saving,
              decoration: const InputDecoration(
                labelText: 'Telefone',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: cityController,
              textInputAction: TextInputAction.next,
              enabled: !saving,
              decoration: const InputDecoration(
                labelText: 'Cidade',
                prefixIcon: Icon(Icons.location_city_outlined),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _SectionCard(
          title: 'Perfil profissional',
          icon: Icons.work_rounded,
          children: [
            TextFormField(
              controller: bioController,
              maxLines: 4,
              enabled: !saving,
              decoration: const InputDecoration(
                labelText: 'Bio',
                alignLabelWithHint: true,
                prefixIcon: Icon(Icons.description_outlined),
                hintText: 'Conte um pouco sobre sua experiência...',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: skillsController,
              enabled: !saving,
              decoration: const InputDecoration(
                labelText: 'Habilidades',
                prefixIcon: Icon(Icons.star_border_rounded),
                hintText: 'Garçom, Barista, Cozinha...',
              ),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              value: available,
              onChanged: saving ? null : onAvailabilityChanged,
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Disponível para freelas',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                available
                    ? 'Empresas podem considerar você disponível.'
                    : 'Seu perfil ficará como indisponível.',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ReadProfileView extends StatelessWidget {
  final String phone;
  final String city;
  final String bio;
  final String skills;
  final bool available;

  const _ReadProfileView({
    required this.phone,
    required this.city,
    required this.bio,
    required this.skills,
    required this.available,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Sobre você',
      icon: Icons.account_circle_rounded,
      children: [
        _InfoTile(
          icon: Icons.phone_outlined,
          title: 'Telefone',
          value: phone.trim().isEmpty ? 'Não informado' : phone.trim(),
        ),
        const SizedBox(height: 10),
        _InfoTile(
          icon: Icons.location_city_outlined,
          title: 'Cidade',
          value: city.trim().isEmpty ? 'Não informada' : city.trim(),
        ),
        const SizedBox(height: 10),
        _InfoTile(
          icon: Icons.description_outlined,
          title: 'Bio',
          value: bio.trim().isEmpty ? 'Nenhuma bio adicionada.' : bio.trim(),
        ),
        const SizedBox(height: 10),
        _InfoTile(
          icon: Icons.star_border_rounded,
          title: 'Habilidades',
          value: skills.trim().isEmpty ? 'Nenhuma habilidade.' : skills.trim(),
        ),
        const SizedBox(height: 10),
        _InfoTile(
          icon: available ? Icons.check_circle_outline : Icons.pause_circle,
          title: 'Status',
          value: available ? 'Disponível para freelas' : 'Indisponível',
        ),
      ],
    );
  }
}

class _ReviewsSection extends StatelessWidget {
  final List<Map<String, dynamic>> reviews;

  const _ReviewsSection({required this.reviews});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Avaliações',
      icon: Icons.reviews_rounded,
      children: [
        if (reviews.isEmpty)
          const Text(
            'Nenhuma avaliação ainda. Quando uma empresa aprovar ou avaliar você, aparecerá aqui.',
            style: TextStyle(fontWeight: FontWeight.w700),
          )
        else
          ...reviews.map(
            (review) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ReviewCard(review: review),
            ),
          ),
      ],
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final Map<String, dynamic> review;

  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final name = review['name']?.toString() ?? 'Empresa';
    final job = review['job']?.toString() ?? 'Job';
    final comment = review['comment']?.toString() ?? '';
    final createdAtText = review['createdAtText']?.toString() ?? '';
    final rating = (review['rating'] as num?)?.toDouble() ?? 5.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: colorScheme.primary.withValues(alpha: 0.12),
                child: Icon(
                  Icons.storefront_rounded,
                  size: 18,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                  const SizedBox(width: 3),
                  Text(
                    rating.toStringAsFixed(1),
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            job,
            style: TextStyle(
              color: colorScheme.primary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              comment,
              style: const TextStyle(height: 1.35, fontWeight: FontWeight.w600),
            ),
          ],
          if (createdAtText.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              createdAtText,
              style: TextStyle(
                color: colorScheme.onSurface.withValues(alpha: 0.56),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: colorScheme.primary, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: colorScheme.onSurface.withValues(alpha: 0.62),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

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
        children: [
          Row(
            children: [
              Icon(icon, color: colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  final double avaliacaoMedia;
  final int totalJobs;

  const _StatsCard({required this.avaliacaoMedia, required this.totalJobs});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Resumo',
      icon: Icons.insights_rounded,
      children: [
        Row(
          children: [
            Expanded(
              child: _MiniStat(
                title: 'Avaliação',
                value: avaliacaoMedia.toStringAsFixed(1),
                icon: Icons.star_rounded,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MiniStat(
                title: 'Jobs',
                value: totalJobs.toString(),
                icon: Icons.work_rounded,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _MiniStat({
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
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(icon, color: colorScheme.primary),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              color: colorScheme.onSurface.withValues(alpha: 0.62),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
