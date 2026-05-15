import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/app_providers.dart';
import '../../auth/data/auth_repository.dart';

class ProfileRestaurantPage extends ConsumerStatefulWidget {
  const ProfileRestaurantPage({super.key});

  @override
  ConsumerState<ProfileRestaurantPage> createState() =>
      _ProfileRestaurantPageState();
}

class _ProfileRestaurantPageState
    extends ConsumerState<ProfileRestaurantPage> {
  final _nameCtrl    = TextEditingController();
  final _endCtrl     = TextEditingController();
  final _telefoneCtrl = TextEditingController();
  final _formKey     = GlobalKey<FormState>();
  final _repo        = AuthRepository();
  bool _loading      = true;
  bool _saving       = false;
  bool _saved        = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _endCtrl.dispose();
    _telefoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final data = await _repo.getUserData(uid);
    setState(() {
      _nameCtrl.text     = data?['name']      ?? '';
      _endCtrl.text      = data?['endereco']  ?? '';
      _telefoneCtrl.text = data?['telefone']  ?? '';
      _loading = false;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final uid = FirebaseAuth.instance.currentUser!.uid;
    await _repo.updateUserData(uid, {
      'name': _nameCtrl.text.trim(),
      'endereco': _endCtrl.text.trim(),
      'telefone': _telefoneCtrl.text.trim(),
      'profileComplete': true,
    });
    setState(() {
      _saving = false;
      _saved  = true;
    });
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _saved = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil do Restaurante'),
        actions: [
          TextButton.icon(
            onPressed: () async {
              await _repo.signOut();
              if (context.mounted) {
                ref.read(userRoleProvider.notifier).set('freelancer');
                context.go('/auth');
              }
            },
            icon: const Icon(Icons.logout_rounded, size: 18),
            label: const Text('Sair'),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Avatar restaurante
                    Center(
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              AppColors.companyPrimary,
                              AppColors.companySecondary
                            ],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.storefront_rounded,
                          color: Colors.white,
                          size: 48,
                        ),
                      ),
                    ).animate().scale(
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.elasticOut),

                    const SizedBox(height: 28),

                    TextFormField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nome do restaurante *',
                        prefixIcon: Icon(Icons.storefront_outlined),
                      ),
                      validator: (v) =>
                          v != null && v.trim().length >= 2
                              ? null
                              : 'Nome muito curto',
                    ).animate()
                        .fadeIn(delay: const Duration(milliseconds: 150)),

                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _endCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Endereço',
                        prefixIcon: Icon(Icons.location_on_outlined),
                        hintText: 'Rua, número, bairro, cidade...',
                      ),
                    ).animate()
                        .fadeIn(delay: const Duration(milliseconds: 250)),

                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _telefoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Telefone / WhatsApp',
                        prefixIcon: Icon(Icons.phone_outlined),
                        hintText: '(11) 99999-9999',
                      ),
                    ).animate()
                        .fadeIn(delay: const Duration(milliseconds: 350)),

                    const SizedBox(height: 32),

                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      child: _saved
                          ? Container(
                              key: const ValueKey('saved'),
                              width: double.infinity,
                              height: 56,
                              decoration: BoxDecoration(
                                color: AppColors.success,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_rounded,
                                      color: Colors.white),
                                  SizedBox(width: 8),
                                  Text(
                                    'Salvo!',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                        ),
                                  ),
                                ],
                              ),
                            ).animate().scale(
                                duration: const Duration(milliseconds: 400),
                                curve: Curves.elasticOut)
                          : ElevatedButton(
                              key: const ValueKey('save'),
                              onPressed: _saving ? null : _save,
                              child: _saving
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white),
                                    )
                                  : const Text('Salvar perfil'),
                            ),
                    ).animate()
                        .fadeIn(delay: const Duration(milliseconds: 450)),
                  ],
                ),
              ),
            ),
    );
  }
}
