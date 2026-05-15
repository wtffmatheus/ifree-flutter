import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

class CreateVacancyScreen extends StatefulWidget {
  const CreateVacancyScreen({super.key});

  @override
  State<CreateVacancyScreen> createState() => _CreateVacancyScreenState();
}

class _CreateVacancyScreenState extends State<CreateVacancyScreen> {
  final _formKey     = GlobalKey<FormState>();
  final _tituloCtrl  = TextEditingController();
  final _localCtrl   = TextEditingController();
  final _valorCtrl   = TextEditingController();
  final _descCtrl    = TextEditingController();
  bool _loading      = false;
  bool _success      = false;

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _localCtrl.dispose();
    _valorCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _publish() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      await FirebaseFirestore.instance.collection('vagas').add({
        'titulo': _tituloCtrl.text.trim(),
        'local': _localCtrl.text.trim(),
        'valor': _valorCtrl.text.trim(),
        'descricao': _descCtrl.text.trim(),
        'companyId': uid,
        'createdAt': FieldValue.serverTimestamp(),
      });
      setState(() => _success = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Erro ao publicar vaga. Tente novamente.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Postar Vaga'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.go('/company'),
        ),
      ),
      body: SafeArea(
        child: _success ? _buildSuccess() : _buildForm(),
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nova oportunidade',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ).animate().fadeIn(),

            const SizedBox(height: 4),
            Text(
              'Preencha os dados para atrair os melhores freelancers.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.textSecondary),
            ).animate().fadeIn(delay: const Duration(milliseconds: 100)),

            const SizedBox(height: 28),

            TextFormField(
              controller: _tituloCtrl,
              decoration: const InputDecoration(
                labelText: 'Título da vaga *',
                prefixIcon: Icon(Icons.work_outline_rounded),
                hintText: 'Ex: Garçom para evento, Chef de Cozinha...',
              ),
              validator: (v) =>
                  v != null && v.trim().length >= 3 ? null : 'Título muito curto',
            ).animate().fadeIn(delay: const Duration(milliseconds: 150)),

            const SizedBox(height: 16),

            TextFormField(
              controller: _localCtrl,
              decoration: const InputDecoration(
                labelText: 'Local *',
                prefixIcon: Icon(Icons.location_on_outlined),
                hintText: 'Ex: Sorocaba - SP, Bairro Jardins...',
              ),
              validator: (v) =>
                  v != null && v.trim().isNotEmpty ? null : 'Informe o local',
            ).animate().fadeIn(delay: const Duration(milliseconds: 200)),

            const SizedBox(height: 16),

            TextFormField(
              controller: _valorCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Valor (R\$)',
                prefixIcon: Icon(Icons.attach_money_rounded),
                hintText: 'Ex: 150,00',
              ),
            ).animate().fadeIn(delay: const Duration(milliseconds: 250)),

            const SizedBox(height: 16),

            TextFormField(
              controller: _descCtrl,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Descrição *',
                prefixIcon: Padding(
                  padding: EdgeInsets.only(bottom: 80),
                  child: Icon(Icons.description_outlined),
                ),
                alignLabelWithHint: true,
                hintText:
                    'Descreva o serviço, horários, requisitos e benefícios...',
              ),
              validator: (v) =>
                  v != null && v.trim().length >= 10
                      ? null
                      : 'Descrição muito curta',
            ).animate().fadeIn(delay: const Duration(milliseconds: 300)),

            const SizedBox(height: 32),

            ElevatedButton.icon(
              onPressed: _loading ? null : _publish,
              icon: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.publish_rounded),
              label: Text(_loading ? 'Publicando...' : 'Publicar vaga'),
            ).animate().fadeIn(delay: const Duration(milliseconds: 400)),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccess() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: const BoxDecoration(
                  color: AppColors.success, shape: BoxShape.circle),
              child: const Icon(Icons.check_rounded,
                  color: Colors.white, size: 56),
            )
                .animate()
                .scale(
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.elasticOut)
                .then()
                .shake(duration: const Duration(milliseconds: 200)),

            const SizedBox(height: 28),

            Text(
              'Vaga publicada!',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: const Duration(milliseconds: 500)),

            const SizedBox(height: 12),

            Text(
              'Sua vaga já está disponível para os freelancers.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: const Duration(milliseconds: 700)),

            const SizedBox(height: 36),

            ElevatedButton(
              onPressed: () => context.go('/company'),
              child: const Text('Ver minhas vagas'),
            ).animate().fadeIn(delay: const Duration(milliseconds: 800)),

            const SizedBox(height: 12),

            OutlinedButton(
              onPressed: () => setState(() => _success = false),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Postar outra vaga'),
            ).animate().fadeIn(delay: const Duration(milliseconds: 900)),
          ],
        ),
      ),
    );
  }
}
