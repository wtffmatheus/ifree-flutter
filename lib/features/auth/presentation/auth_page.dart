import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/app_providers.dart';
import '../data/auth_repository.dart';

class AuthPage extends ConsumerStatefulWidget {
  const AuthPage({super.key});

  @override
  ConsumerState<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends ConsumerState<AuthPage> {
  final _repo = AuthRepository();

  final _loginFormKey = GlobalKey<FormState>();
  final _signupFormKey = GlobalKey<FormState>();

  final _loginEmailCtrl = TextEditingController();
  final _loginPasswordCtrl = TextEditingController();

  final _signupNameCtrl = TextEditingController();
  final _signupEmailCtrl = TextEditingController();
  final _signupPasswordCtrl = TextEditingController();

  bool _isLogin = true;
  bool _isLoading = false;
  bool _loginObscure = true;
  bool _signupObscure = true;
  String _selectedRole = 'freelancer';

  @override
  void dispose() {
    _loginEmailCtrl.dispose();
    _loginPasswordCtrl.dispose();
    _signupNameCtrl.dispose();
    _signupEmailCtrl.dispose();
    _signupPasswordCtrl.dispose();
    super.dispose();
  }

  String? _emailValidator(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Informe seu e-mail.';
    if (!email.contains('@') || !email.contains('.')) return 'Digite um e-mail válido.';
    return null;
  }

  String? _passwordValidator(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return 'Informe sua senha.';
    if (password.length < 6) return 'Use pelo menos 6 caracteres.';
    return null;
  }

  String _translateError(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'email-already-in-use':
          return 'Este e-mail já está cadastrado.';
        case 'invalid-email':
          return 'O e-mail informado é inválido.';
        case 'weak-password':
          return 'A senha precisa ser mais forte.';
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          return 'E-mail ou senha incorretos.';
        case 'network-request-failed':
          return 'Sem conexão. Verifique sua internet.';
        case 'too-many-requests':
          return 'Muitas tentativas. Tente novamente em instantes.';
        case 'user-disabled':
          return 'Esta conta está desativada.';
        default:
          return error.message ?? 'Não foi possível continuar.';
      }
    }

    return 'Não foi possível concluir a operação.';
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  Future<void> _afterLogin(String uid) async {
    final role = await _repo.getUserRole(uid);
    if (!mounted) return;

    ref.read(userRoleProvider.notifier).set(role ?? 'freelancer');
    context.go(role == 'company' ? '/company' : '/freelancer');
  }

  Future<void> _login() async {
    if (!_loginFormKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final credential = await _repo.signInWithEmail(
        _loginEmailCtrl.text,
        _loginPasswordCtrl.text,
      );
      await _afterLogin(credential.user!.uid);
    } catch (error) {
      _showError(_translateError(error));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signup() async {
    if (!_signupFormKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final credential = await _repo.signUp(
        name: _signupNameCtrl.text,
        email: _signupEmailCtrl.text,
        password: _signupPasswordCtrl.text,
        role: _selectedRole,
      );
      await _afterLogin(credential.user!.uid);
    } catch (error) {
      _showError(_translateError(error));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() => _isLoading = true);

    try {
      final credential = await _repo.signInWithGoogle(
        defaultRole: _selectedRole,
      );
      await _afterLogin(credential.user!.uid);
    } catch (error) {
      _showError(_translateError(error));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 960;

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [
                        const Color(0xFF0B0D12),
                        const Color(0xFF11141B),
                      ]
                    : [
                        const Color(0xFFF5F7FB),
                        const Color(0xFFEEF2F7),
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              child: isDesktop
                  ? Row(
                      children: [
                        Expanded(
                          flex: 11,
                          child: _BrandPanel(colorScheme: colorScheme),
                        ),
                        Expanded(
                          flex: 10,
                          child: Center(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(42),
                              child: _AuthCard(
                                isLogin: _isLogin,
                                isLoading: _isLoading,
                                selectedRole: _selectedRole,
                                loginEmailCtrl: _loginEmailCtrl,
                                loginPasswordCtrl: _loginPasswordCtrl,
                                signupNameCtrl: _signupNameCtrl,
                                signupEmailCtrl: _signupEmailCtrl,
                                signupPasswordCtrl: _signupPasswordCtrl,
                                loginFormKey: _loginFormKey,
                                signupFormKey: _signupFormKey,
                                loginObscure: _loginObscure,
                                signupObscure: _signupObscure,
                                onModeChanged: (value) =>
                                    setState(() => _isLogin = value),
                                onRoleChanged: (value) =>
                                    setState(() => _selectedRole = value),
                                onLoginObscureChanged: () => setState(
                                  () => _loginObscure = !_loginObscure,
                                ),
                                onSignupObscureChanged: () => setState(
                                  () => _signupObscure = !_signupObscure,
                                ),
                                onLogin: _login,
                                onSignup: _signup,
                                onGoogle: _loginWithGoogle,
                                emailValidator: _emailValidator,
                                passwordValidator: _passwordValidator,
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                      child: Column(
                        children: [
                          const _MobileBrand(),
                          const SizedBox(height: 28),
                          _AuthCard(
                            isLogin: _isLogin,
                            isLoading: _isLoading,
                            selectedRole: _selectedRole,
                            loginEmailCtrl: _loginEmailCtrl,
                            loginPasswordCtrl: _loginPasswordCtrl,
                            signupNameCtrl: _signupNameCtrl,
                            signupEmailCtrl: _signupEmailCtrl,
                            signupPasswordCtrl: _signupPasswordCtrl,
                            loginFormKey: _loginFormKey,
                            signupFormKey: _signupFormKey,
                            loginObscure: _loginObscure,
                            signupObscure: _signupObscure,
                            onModeChanged: (value) =>
                                setState(() => _isLogin = value),
                            onRoleChanged: (value) =>
                                setState(() => _selectedRole = value),
                            onLoginObscureChanged: () => setState(
                              () => _loginObscure = !_loginObscure,
                            ),
                            onSignupObscureChanged: () => setState(
                              () => _signupObscure = !_signupObscure,
                            ),
                            onLogin: _login,
                            onSignup: _signup,
                            onGoogle: _loginWithGoogle,
                            emailValidator: _emailValidator,
                            passwordValidator: _passwordValidator,
                          ),
                        ],
                      ),
                    ),
            ),
          );
        },
      ),
    );
  }
}

class _BrandPanel extends StatelessWidget {
  final ColorScheme colorScheme;

  const _BrandPanel({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(34),
        child: Container(
          padding: const EdgeInsets.all(48),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colorScheme.primary,
                colorScheme.primary.withValues(alpha: 0.72),
                const Color(0xFF7C3AED),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -90,
                top: -100,
                child: _GlowCircle(size: 280),
              ),
              Positioned(
                left: -80,
                bottom: -110,
                child: _GlowCircle(size: 240),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _BrandMark(light: true),
                  const Spacer(),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: const Text(
                      'Trabalho flexível. Contratações sem complicação.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 44,
                        height: 1.08,
                        letterSpacing: -1.8,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Text(
                      'O iFree aproxima profissionais e estabelecimentos para preencher oportunidades com mais rapidez, clareza e confiança.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.78),
                        fontSize: 16,
                        height: 1.6,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 34),
                  const Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _BenefitPill(
                        icon: Icons.bolt_rounded,
                        label: 'Oportunidades em tempo real',
                      ),
                      _BenefitPill(
                        icon: Icons.location_on_rounded,
                        label: 'Vagas perto de você',
                      ),
                      _BenefitPill(
                        icon: Icons.verified_user_rounded,
                        label: 'Perfis organizados',
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    'Feito para quem precisa contratar e para quem quer trabalhar.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.62),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
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

class _GlowCircle extends StatelessWidget {
  final double size;

  const _GlowCircle({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.08),
      ),
    );
  }
}

class _MobileBrand extends StatelessWidget {
  const _MobileBrand();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _BrandMark(),
        const SizedBox(height: 14),
        Text(
          'Conectando oportunidades a quem faz acontecer.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

class _BrandMark extends StatelessWidget {
  final bool light;

  const _BrandMark({this.light = false});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: light ? Colors.white.withValues(alpha: 0.14) : primary,
            borderRadius: BorderRadius.circular(16),
            border: light
                ? Border.all(color: Colors.white.withValues(alpha: 0.16))
                : null,
          ),
          alignment: Alignment.center,
          child: const Text(
            'iF',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.8,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'iFree',
          style: TextStyle(
            color: light ? Colors.white : null,
            fontSize: 24,
            fontWeight: FontWeight.w900,
            letterSpacing: -1,
          ),
        ),
      ],
    );
  }
}

class _BenefitPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _BenefitPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.13)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 17),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthCard extends StatelessWidget {
  final bool isLogin;
  final bool isLoading;
  final String selectedRole;

  final TextEditingController loginEmailCtrl;
  final TextEditingController loginPasswordCtrl;
  final TextEditingController signupNameCtrl;
  final TextEditingController signupEmailCtrl;
  final TextEditingController signupPasswordCtrl;

  final GlobalKey<FormState> loginFormKey;
  final GlobalKey<FormState> signupFormKey;

  final bool loginObscure;
  final bool signupObscure;

  final ValueChanged<bool> onModeChanged;
  final ValueChanged<String> onRoleChanged;
  final VoidCallback onLoginObscureChanged;
  final VoidCallback onSignupObscureChanged;
  final VoidCallback onLogin;
  final VoidCallback onSignup;
  final VoidCallback onGoogle;
  final String? Function(String?) emailValidator;
  final String? Function(String?) passwordValidator;

  const _AuthCard({
    required this.isLogin,
    required this.isLoading,
    required this.selectedRole,
    required this.loginEmailCtrl,
    required this.loginPasswordCtrl,
    required this.signupNameCtrl,
    required this.signupEmailCtrl,
    required this.signupPasswordCtrl,
    required this.loginFormKey,
    required this.signupFormKey,
    required this.loginObscure,
    required this.signupObscure,
    required this.onModeChanged,
    required this.onRoleChanged,
    required this.onLoginObscureChanged,
    required this.onSignupObscureChanged,
    required this.onLogin,
    required this.onSignup,
    required this.onGoogle,
    required this.emailValidator,
    required this.passwordValidator,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 500),
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.6),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 34,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: Column(
            key: ValueKey(isLogin),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isLogin ? 'Bem-vindo de volta' : 'Crie sua conta',
                style: const TextStyle(
                  fontSize: 28,
                  height: 1.15,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isLogin
                    ? 'Entre para acompanhar suas oportunidades e atividades.'
                    : 'Escolha como você vai usar o iFree e comece agora.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              _ModeSelector(
                isLogin: isLogin,
                onChanged: onModeChanged,
              ),
              const SizedBox(height: 24),
              if (isLogin)
                Form(
                  key: loginFormKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: loginEmailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        validator: emailValidator,
                        decoration: const InputDecoration(
                          labelText: 'E-mail',
                          hintText: 'voce@email.com',
                          prefixIcon: Icon(Icons.alternate_email_rounded),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: loginPasswordCtrl,
                        obscureText: loginObscure,
                        textInputAction: TextInputAction.done,
                        validator: passwordValidator,
                        onFieldSubmitted: (_) => onLogin(),
                        decoration: InputDecoration(
                          labelText: 'Senha',
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          suffixIcon: IconButton(
                            onPressed: onLoginObscureChanged,
                            icon: Icon(
                              loginObscure
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: isLoading
                              ? null
                              : () => context.go('/forgot-password'),
                          child: const Text('Esqueci minha senha'),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Form(
                  key: signupFormKey,
                  child: Column(
                    children: [
                      _RoleSelector(
                        selectedRole: selectedRole,
                        onChanged: onRoleChanged,
                      ),
                      const SizedBox(height: 18),
                      TextFormField(
                        controller: signupNameCtrl,
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          if ((value?.trim().length ?? 0) < 2) {
                            return 'Informe seu nome.';
                          }
                          return null;
                        },
                        decoration: const InputDecoration(
                          labelText: 'Nome',
                          prefixIcon: Icon(Icons.person_outline_rounded),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: signupEmailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        validator: emailValidator,
                        decoration: const InputDecoration(
                          labelText: 'E-mail',
                          prefixIcon: Icon(Icons.alternate_email_rounded),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: signupPasswordCtrl,
                        obscureText: signupObscure,
                        textInputAction: TextInputAction.done,
                        validator: passwordValidator,
                        onFieldSubmitted: (_) => onSignup(),
                        decoration: InputDecoration(
                          labelText: 'Senha',
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          suffixIcon: IconButton(
                            onPressed: onSignupObscureChanged,
                            icon: Icon(
                              signupObscure
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: isLoading ? null : (isLogin ? onLogin : onSignup),
                  icon: isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          isLogin
                              ? Icons.arrow_forward_rounded
                              : Icons.person_add_alt_1_rounded,
                        ),
                  label: Text(isLogin ? 'Entrar no iFree' : 'Criar minha conta'),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: Divider(color: colorScheme.outlineVariant)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'ou continue com',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  Expanded(child: Divider(color: colorScheme.outlineVariant)),
                ],
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: isLoading ? null : onGoogle,
                  icon: Container(
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      shape: BoxShape.circle,
                    ),
                    child: const Text(
                      'G',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  label: const Text('Google'),
                ),
              ),
              const SizedBox(height: 18),
              Center(
                child: Text(
                  'Ao continuar, você concorda com os termos de uso e política de privacidade.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeSelector extends StatelessWidget {
  final bool isLogin;
  final ValueChanged<bool> onChanged;

  const _ModeSelector({required this.isLogin, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ModeButton(
              label: 'Entrar',
              selected: isLogin,
              onTap: () => onChanged(true),
            ),
          ),
          Expanded(
            child: _ModeButton(
              label: 'Cadastrar',
              selected: !isLogin,
              onTap: () => onChanged(false),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ModeButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: selected ? colorScheme.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: selected ? colorScheme.primary : colorScheme.onSurfaceVariant,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _RoleSelector extends StatelessWidget {
  final String selectedRole;
  final ValueChanged<String> onChanged;

  const _RoleSelector({
    required this.selectedRole,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _RoleCard(
            selected: selectedRole == 'freelancer',
            icon: Icons.badge_outlined,
            title: 'Quero trabalhar',
            subtitle: 'Encontrar vagas e diárias',
            onTap: () => onChanged('freelancer'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _RoleCard(
            selected: selectedRole == 'company',
            icon: Icons.storefront_outlined,
            title: 'Quero contratar',
            subtitle: 'Publicar vagas e escolher pessoas',
            onTap: () => onChanged('company'),
          ),
        ),
      ],
    );
  }
}

class _RoleCard extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _RoleCard({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? colorScheme.primary.withValues(alpha: 0.08)
              : colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? colorScheme.primary
                : colorScheme.outlineVariant.withValues(alpha: 0.65),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: selected ? colorScheme.primary : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 10),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              maxLines: 2,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
