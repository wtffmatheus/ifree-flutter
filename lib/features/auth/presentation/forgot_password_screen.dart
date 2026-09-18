import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/auth_repository.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _controller = TextEditingController();
  final _repo = AuthRepository();

  bool _loading = false;
  bool _sent = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final email = _controller.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Digite um e-mail válido.')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      await _repo.sendPasswordResetEmail(email);
      if (mounted) setState(() => _sent = true);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível enviar o link. Tente novamente.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).scaffoldBackgroundColor,
              scheme.primary.withValues(alpha: 0.035),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: scheme.outlineVariant),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 32,
                        offset: const Offset(0, 16),
                      ),
                    ],
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: _sent
                        ? _SuccessState(
                            email: _controller.text.trim(),
                            onBack: () => context.go('/login'),
                          )
                        : _RequestState(
                            controller: _controller,
                            loading: _loading,
                            onSend: _send,
                            onBack: () => context.go('/login'),
                          ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RequestState extends StatelessWidget {
  final TextEditingController controller;
  final bool loading;
  final VoidCallback onSend;
  final VoidCallback onBack;

  const _RequestState({
    required this.controller,
    required this.loading,
    required this.onSend,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      key: const ValueKey('request'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onBack,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.arrow_back_rounded),
          ),
        ),
        const SizedBox(height: 24),
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Icon(
            Icons.lock_reset_rounded,
            color: scheme.primary,
            size: 28,
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Recupere seu acesso',
          style: TextStyle(
            fontSize: 27,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.8,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Informe o e-mail da sua conta e enviaremos um link para criar uma nova senha.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontSize: 14,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 26),
        TextField(
          controller: controller,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => onSend(),
          decoration: const InputDecoration(
            labelText: 'E-mail',
            hintText: 'voce@email.com',
            prefixIcon: Icon(Icons.alternate_email_rounded),
          ),
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: loading ? null : onSend,
            icon: loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.send_rounded),
            label: const Text('Enviar link de recuperação'),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: loading ? null : onBack,
            child: const Text('Voltar para o login'),
          ),
        ),
      ],
    );
  }
}

class _SuccessState extends StatelessWidget {
  final String email;
  final VoidCallback onBack;

  const _SuccessState({
    required this.email,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      key: const ValueKey('success'),
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(22),
          ),
          child: const Icon(
            Icons.mark_email_read_outlined,
            color: Colors.green,
            size: 34,
          ),
        ),
        const SizedBox(height: 22),
        const Text(
          'Confira seu e-mail',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 27,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.8,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Enviamos as instruções de recuperação para',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 6),
        Text(
          email,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: scheme.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: onBack,
            child: const Text('Voltar para o login'),
          ),
        ),
      ],
    );
  }
}
