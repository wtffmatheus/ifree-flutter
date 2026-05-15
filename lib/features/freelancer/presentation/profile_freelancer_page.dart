import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_widgets.dart';

import '../../auth/data/auth_repository.dart';
import '../../../core/providers/app_providers.dart';

class ProfileFreelancerPage extends ConsumerStatefulWidget {
  const ProfileFreelancerPage({super.key});

  @override
  ConsumerState<ProfileFreelancerPage> createState() =>
      _ProfileFreelancerPageState();
}

class _ProfileFreelancerPageState
    extends ConsumerState<ProfileFreelancerPage> {
  final _uid = FirebaseAuth.instance.currentUser!.uid;
  final _repo = AuthRepository();
  bool _isEditMode = false;

  // Edit controllers
  final _nameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;
  bool _saved = false;

  Map<String, dynamic>? _userData;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final data = await _repo.getUserData(_uid);
    if (mounted) {
      setState(() {
        _userData = data;
        _nameCtrl.text = data?['name'] ?? '';
        _bioCtrl.text = data?['bio'] ?? '';
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    await _repo.updateUserData(_uid, {
      'name': _nameCtrl.text.trim(),
      'bio': _bioCtrl.text.trim(),
      'profileComplete': _nameCtrl.text.trim().isNotEmpty && _bioCtrl.text.trim().isNotEmpty,
    });
    await _loadProfile();
    setState(() { _saving = false; _saved = true; _isEditMode = false; });
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _saved = false);
  }

  Future<void> _signOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sair da conta'),
        content: const Text('Tem certeza que deseja sair?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await _repo.signOut();
    if (mounted) {
      ref.read(userRoleProvider.notifier).set('freelancer');
      context.go('/auth');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Editar Perfil' : 'Meu Perfil'),
        leading: _isEditMode
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => setState(() => _isEditMode = false),
              )
            : null,
        actions: [
          if (!_isEditMode) ...[
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => setState(() => _isEditMode = true),
              tooltip: 'Editar perfil',
            ),
            IconButton(
              icon: const Icon(Icons.logout_rounded),
              onPressed: _signOut,
              tooltip: 'Sair',
            ),
          ],
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _isEditMode
              ? _EditView(
                  nameCtrl: _nameCtrl,
                  bioCtrl: _bioCtrl,
                  formKey: _formKey,
                  saving: _saving,
                  saved: _saved,
                  onSave: _save,
                  userData: _userData,
                )
              : _ProfileView(
                  uid: _uid,
                  userData: _userData ?? {},
                  onEdit: () => setState(() => _isEditMode = true),
                  onSignOut: _signOut,
                  ref: ref,
                ),
    );
  }
}

// ── View Mode: perfil rico ─────────────────────────────────────────────────────
class _ProfileView extends StatelessWidget {
  final String uid;
  final Map<String, dynamic> userData;
  final VoidCallback onEdit;
  final VoidCallback onSignOut;
  final WidgetRef ref;

  const _ProfileView({
    required this.uid,
    required this.userData,
    required this.onEdit,
    required this.onSignOut,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeMode = ref.watch(themeModeProvider);
    final name = userData['name'] as String? ?? 'Freelancer';
    final email = userData['email'] as String? ?? '';
    final bio = userData['bio'] as String? ?? '';
    final skills = (userData['skills'] as List?)?.cast<String>() ?? [];
    final media = (userData['avaliacaoMedia'] as num?)?.toDouble() ?? 0;
    final total = (userData['totalJobs'] as num?)?.toInt() ?? 0;
    final photoUrl = userData['photoUrl'] as String?;

    return SingleChildScrollView(
      child: Column(
        children: [
          // ── Hero do perfil ────────────────────────────────────────────────
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.freelancerPrimary.withOpacity(isDark ? 0.25 : 0.12),
                  Colors.transparent,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            child: Column(
              children: [
                // Avatar
                IFreeAvatar(
                  name: name,
                  size: 88,
                  photoUrl: photoUrl,
                ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),

                const SizedBox(height: 12),
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Sora',
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                  ),
                ),
                Text(
                  email,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                    fontFamily: 'Sora',
                  ),
                ),

                if (media > 0) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      StarRating(rating: media, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        '${media.toStringAsFixed(1)} ($total job${total != 1 ? "s" : ""})',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                          fontFamily: 'Sora',
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 14),
                ElevatedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Editar perfil'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(160, 42),
                    textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, fontFamily: 'Sora'),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms),

          // ── Stats cards ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                _MiniStat(label: 'Jobs', value: '$total', icon: Icons.check_circle_outline_rounded, color: AppColors.success),
                const SizedBox(width: 10),
                _MiniStat(label: 'Avaliação', value: media > 0 ? media.toStringAsFixed(1) : '—', icon: Icons.star_outline_rounded, color: AppColors.gold),
                const SizedBox(width: 10),
                _MiniStat(
                  label: 'Perfil',
                  value: (userData['profileComplete'] as bool? ?? false) ? '✓' : '⚠',
                  icon: Icons.person_outline_rounded,
                  color: (userData['profileComplete'] as bool? ?? false) ? AppColors.success : AppColors.analise,
                ),
              ],
            ),
          ).animate().fadeIn(delay: 150.ms),

          // ── Sobre mim ─────────────────────────────────────────────────────
          if (bio.isNotEmpty) ...[
            _Section(
              title: 'Sobre mim',
              icon: Icons.info_outline_rounded,
              child: Text(
                bio,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                  fontFamily: 'Sora',
                  height: 1.6,
                ),
              ),
            ),
          ],

          // ── Skills ────────────────────────────────────────────────────────
          if (skills.isNotEmpty) ...[
            _Section(
              title: 'Habilidades',
              icon: Icons.construction_outlined,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: skills.map((s) => Chip(label: Text(s))).toList(),
              ),
            ),
          ],

          // ── Avaliações dos restaurantes ───────────────────────────────────
          _Section(
            title: 'Avaliações',
            icon: Icons.star_outline_rounded,
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .collection('avaliacoes')
                  .orderBy('data', descending: true)
                  .snapshots(),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snap.data!.docs;
                if (docs.isEmpty) {
                  return Text(
                    'Nenhuma avaliação ainda. Complete jobs para receber avaliações!',
                    style: TextStyle(
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                      fontSize: 13,
                      fontFamily: 'Sora',
                    ),
                  );
                }
                return Column(
                  children: docs.map((doc) {
                    final d = doc.data() as Map<String, dynamic>;
                    return _AvaliacaoCard(data: d);
                  }).toList(),
                );
              },
            ),
          ),

          // ── Configurações ─────────────────────────────────────────────────
          _Section(
            title: 'Configurações',
            icon: Icons.settings_outlined,
            child: Column(
              children: [
                // ── Dark mode aqui, não na AppBar ──────────────────────────
                _SettingsTile(
                  icon: Icons.dark_mode_outlined,
                  title: 'Modo noturno',
                  subtitle: themeMode == ThemeMode.dark ? 'Ativado' : 'Desativado',
                  trailing: Switch(
                    value: themeMode == ThemeMode.dark,
                    activeColor: AppColors.freelancerPrimary,
                    onChanged: (v) => ref.read(themeModeProvider.notifier).toggle(),
                  ),
                ),
                _SettingsTile(
                  icon: Icons.notifications_outlined,
                  title: 'Notificações',
                  subtitle: 'Gerenciar alertas de vagas',
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {},
                ),
                _SettingsTile(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Privacidade',
                  subtitle: 'Visibilidade do perfil',
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {},
                ),
                const Divider(height: 20),
                _SettingsTile(
                  icon: Icons.logout_rounded,
                  title: 'Sair da conta',
                  subtitle: FirebaseAuth.instance.currentUser?.email ?? '',
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: onSignOut,
                  titleColor: AppColors.error,
                  iconColor: AppColors.error,
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ── Edit Mode ─────────────────────────────────────────────────────────────────
class _EditView extends StatelessWidget {
  final TextEditingController nameCtrl;
  final TextEditingController bioCtrl;
  final GlobalKey<FormState> formKey;
  final bool saving;
  final bool saved;
  final VoidCallback onSave;
  final Map<String, dynamic>? userData;

  const _EditView({
    required this.nameCtrl,
    required this.bioCtrl,
    required this.formKey,
    required this.saving,
    required this.saved,
    required this.onSave,
    required this.userData,
  });

  @override
  Widget build(BuildContext context) {
    final name = nameCtrl.text;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: IFreeAvatar(
                name: name.isNotEmpty ? name : 'U',
                size: 80,
                photoUrl: userData?['photoUrl'] as String?,
              ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
            ),
            const SizedBox(height: 28),
            TextFormField(
              controller: nameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nome completo *',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
              validator: (v) => v != null && v.trim().length >= 2 ? null : 'Nome muito curto',
            ).animate().fadeIn(delay: 100.ms),
            const SizedBox(height: 14),
            TextFormField(
              controller: bioCtrl,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Sobre mim / Experiência',
                prefixIcon: Padding(
                  padding: EdgeInsets.only(bottom: 72),
                  child: Icon(Icons.info_outline_rounded),
                ),
                alignLabelWithHint: true,
                hintText: 'Descreva sua experiência, habilidades e disponibilidade...',
              ),
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 28),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: saved
                  ? Container(
                      key: const ValueKey('saved'),
                      width: double.infinity,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_rounded, color: Colors.white),
                          SizedBox(width: 8),
                          Text('Perfil salvo!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16, fontFamily: 'Sora')),
                        ],
                      ),
                    ).animate().scale(duration: 400.ms, curve: Curves.elasticOut)
                  : ElevatedButton(
                      key: const ValueKey('save'),
                      onPressed: saving ? null : onSave,
                      child: saving
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Salvar perfil'),
                    ),
            ).animate().fadeIn(delay: 300.ms),
          ],
        ),
      ),
    );
  }
}

// ── Widgets auxiliares ────────────────────────────────────────────────────────
class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MiniStat({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.bgCardDark : AppColors.bgCardLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight, width: 0.8),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color, fontFamily: 'Sora')),
            Text(label, style: TextStyle(fontSize: 10, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary, fontFamily: 'Sora')),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _Section({required this.title, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDark ? AppColors.bgCardDark : AppColors.bgCardLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight, width: 0.8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: AppColors.freelancerPrimary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Sora',
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms);
  }
}

class _AvaliacaoCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _AvaliacaoCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final nota = (data['nota'] as num?)?.toDouble() ?? 0;
    final autor = data['autorNome'] as String? ?? 'Restaurante';
    final comentario = data['comentario'] as String? ?? '';
    final tipo = data['tipo'] as String? ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.bgCard2Dark : AppColors.bgCard2Light,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight, width: 0.6),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IFreeAvatar(name: autor, size: 36),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(autor, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, fontFamily: 'Sora', color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary)),
                      if (tipo.isNotEmpty)
                        Text(tipo, style: TextStyle(fontSize: 11, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary, fontFamily: 'Sora')),
                    ],
                  ),
                ),
                StarRating(rating: nota, size: 15),
              ],
            ),
            if (comentario.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '"$comentario"',
                style: TextStyle(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                  fontFamily: 'Sora',
                  height: 1.5,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback? onTap;
  final Color? titleColor;
  final Color? iconColor;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.onTap,
    this.titleColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: (iconColor ?? AppColors.freelancerPrimary).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: iconColor ?? AppColors.freelancerPrimary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, fontFamily: 'Sora', color: titleColor ?? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary))),
                  Text(subtitle, style: TextStyle(fontSize: 11, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary, fontFamily: 'Sora')),
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}
