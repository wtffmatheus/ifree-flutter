import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/auth_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/app_providers.dart';
import 'package:ifree_app/core/providers/app_providers.dart';

class AuthPage extends ConsumerStatefulWidget {
  const AuthPage({super.key});

  @override
  ConsumerState<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends ConsumerState<AuthPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _repo = AuthRepository();

  // Controllers
  final _loginEmailCtrl    = TextEditingController();
  final _loginPasswordCtrl = TextEditingController();
  final _loginFormKey      = GlobalKey<FormState>();

  final _signupNameCtrl     = TextEditingController();
  final _signupEmailCtrl    = TextEditingController();
  final _signupPasswordCtrl = TextEditingController();
  final _signupFormKey      = GlobalKey<FormState>();
  String _selectedRole      = 'freelancer';

  bool _isLoading      = false;
  bool _loginObscure   = true;
  bool _signupObscure  = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginEmailCtrl.dispose();
    _loginPasswordCtrl.dispose();
    _signupNameCtrl.dispose();
    _signupEmailCtrl.dispose();
    _signupPasswordCtrl.dispose();
    super.dispose();
  }

  // ── Tradução de erros Firebase ────────────────────────────────────────────
  String _translateError(dynamic e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'email-already-in-use':
          return 'Este e-mail já está cadastrado. Tente fazer login.';
        case 'invalid-email':
          return 'Formato de e-mail inválido.';
        case 'weak-password':
          return 'Senha muito fraca. Use mínimo 6 caracteres.';
        case 'user-not-found':
          return 'E-mail não encontrado. Crie uma conta.';
        case 'wrong-password':
        case 'invalid-credential':
          return 'E-mail ou senha incorretos.';
        case 'operation-not-allowed':
          return 'Login com e-mail desabilitado no Firebase Console.';
        case 'network-request-failed':
          return 'Sem conexão. Verifique sua internet.';
        case 'too-many-requests':
          return 'Muitas tentativas. Aguarde e tente novamente.';
        case 'user-disabled':
          return 'Conta desativada. Entre em contato.';
        case 'popup-closed-by-user':
        case 'cancelled-popup-request':
          return 'Login cancelado. Tente novamente.';
        default:
          return 'Erro [${e.code}]: ${e.message ?? "Erro desconhecido"}';
      }
    }
    final msg = e.toString();
    if (msg.contains('cancelled')) return 'Login cancelado.';
    return 'Erro inesperado. Tente novamente.';
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.error_outline_rounded, color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(msg)),
      ]),
      backgroundColor: AppColors.error,
    ));
  }

  Future<void> _afterLogin(String uid) async {
    final role = await _repo.getUserRole(uid);
    if (!mounted) return;
    ref.read(userRoleProvider.notifier).set(role ?? 'freelancer');
    if (role == 'company') {
      context.go('/company');
    } else {
      context.go('/freelancer');
    }
  }

  Future<void> _login() async {
    if (!_loginFormKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final cred = await _repo.signInWithEmail(
        _loginEmailCtrl.text,
        _loginPasswordCtrl.text,
      );
      await _afterLogin(cred.user!.uid);
    } catch (e) {
      _showError(_translateError(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final cred = await _repo.signInWithGoogle();
      await _afterLogin(cred.user!.uid);
    } catch (e) {
      _showError(_translateError(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signup() async {
    if (!_signupFormKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final cred = await _repo.signUp(
        name: _signupNameCtrl.text,
        email: _signupEmailCtrl.text,
        password: _signupPasswordCtrl.text,
        role: _selectedRole,
      );
      await _afterLogin(cred.user!.uid);
    } catch (e) {
      _showError(_translateError(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // ── Fundo decorativo ──────────────────────────────────────────────
          Positioned(
            top: -80,
            left: -60,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.freelancerPrimary.withOpacity(0.08),
              ),
            ),
          ),
          Positioned(
            bottom: 60,
            right: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.gold.withOpacity(0.06),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: size.height - MediaQuery.of(context).padding.top),
                child: Column(
                  children: [
                    const SizedBox(height: 40),

                    // ── Logo ──────────────────────────────────────────────
                    Column(
                      children: [
                        ShaderMask(
                          shaderCallback: (b) => const LinearGradient(
                            colors: [AppColors.freelancerPrimary, AppColors.freelancerSecondary],
                          ).createShader(b),
                          child: const Text(
                            'iFree',
                            style: TextStyle(
                              fontSize: 52,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              height: 1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Conectando freelancers a restaurantes',
                          style: TextStyle(
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.2),

                    const SizedBox(height: 36),

                    // ── Card principal ────────────────────────────────────
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.bgCardDark : AppColors.bgCardLight,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: isDark ? AppColors.borderDark : AppColors.borderLight,
                          width: 0.8,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(isDark ? 0.4 : 0.08),
                            blurRadius: 40,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // ── Tabs ────────────────────────────────────────
                          ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(28),
                              topRight: Radius.circular(28),
                            ),
                            child: TabBar(
                              controller: _tabController,
                              dividerColor: Colors.transparent,
                              indicator: BoxDecoration(
                                color: AppColors.freelancerPrimary.withOpacity(0.1),
                                border: const Border(
                                  bottom: BorderSide(
                                    color: AppColors.freelancerPrimary,
                                    width: 2,
                                  ),
                                ),
                              ),
                              tabs: const [
                                Tab(text: 'Entrar'),
                                Tab(text: 'Cadastrar'),
                              ],
                            ),
                          ),

                          Padding(
                            padding: const EdgeInsets.all(24),
                            child: SizedBox(
                              height: _tabController.index == 0 ? 320 : 480,
                              child: TabBarView(
                                controller: _tabController,
                                children: [
                                  _LoginForm(
                                    emailCtrl: _loginEmailCtrl,
                                    passCtrl: _loginPasswordCtrl,
                                    formKey: _loginFormKey,
                                    obscure: _loginObscure,
                                    onToggleObscure: () => setState(() => _loginObscure = !_loginObscure),
                                    onLogin: _login,
                                    isLoading: _isLoading,
                                  ),
                                  _SignupForm(
                                    nameCtrl: _signupNameCtrl,
                                    emailCtrl: _signupEmailCtrl,
                                    passCtrl: _signupPasswordCtrl,
                                    formKey: _signupFormKey,
                                    obscure: _signupObscure,
                                    onToggleObscure: () => setState(() => _signupObscure = !_signupObscure),
                                    selectedRole: _selectedRole,
                                    onRoleChanged: (r) => setState(() => _selectedRole = r),
                                    onSignup: _signup,
                                    isLoading: _isLoading,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),

                    const SizedBox(height: 20),

                    // ── Divider ───────────────────────────────────────────
                    Row(
                      children: [
                        Expanded(child: Divider(color: isDark ? AppColors.borderDark : AppColors.borderLight)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text('ou', style: TextStyle(color: isDark ? AppColors.textDimDark : AppColors.textDim, fontSize: 12)),
                        ),
                        Expanded(child: Divider(color: isDark ? AppColors.borderDark : AppColors.borderLight)),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // ── Google Button ─────────────────────────────────────
                    // CORREÇÃO: botão Google usa signInWithGoogle() do repo
                    // O erro "clientId != null" acontecia no Flutter Web por falta
                    // do <meta name="google-signin-client_id"> no index.html.
                    // SOLUÇÃO: adicionar no web/index.html:
                    // <meta name="google-signin-client_id" content="SEU_CLIENT_ID.apps.googleusercontent.com">
                    OutlinedButton.icon(
                      onPressed: _isLoading ? null : _loginWithGoogle,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: isDark ? AppColors.borderDark : AppColors.borderLight,
                        ),
                        foregroundColor: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                        minimumSize: const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: _GoogleIcon(),
                      label: const Text('Continuar com Google', style: TextStyle(fontFamily: 'Sora', fontWeight: FontWeight.w500)),
                    ).animate().fadeIn(delay: 400.ms),

                    const SizedBox(height: 12),

                    // ── Esqueci senha ─────────────────────────────────────
                    TextButton(
                      onPressed: () => context.go('/forgot-password'),
                      child: const Text('Esqueci minha senha'),
                    ).animate().fadeIn(delay: 500.ms),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Google Icon (SVG inline sem dependência) ──────────────────────────────────
class _GoogleIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(painter: _GooglePainter()),
    );
  }
}

class _GooglePainter extends CustomPainter {
  const _GooglePainter();
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final scale = size.width / 20;
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(Rect.fromLTWH(0, 0, size.width, size.height), -1.5, 3.0, true, paint);
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(Rect.fromLTWH(0, 0, size.width, size.height), 1.5, 1.5, true, paint);
    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(Rect.fromLTWH(0, 0, size.width, size.height), 3.0, 1.6, true, paint);
    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(Rect.fromLTWH(0, 0, size.width, size.height), -3.14, 1.7, true, paint);
    paint.color = Colors.white;
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), size.width * 0.32, paint);
    paint.color = const Color(0xFF4285F4);
    canvas.drawRect(Rect.fromLTWH(size.width * 0.5, size.height * 0.42, size.width * 0.48 * scale, size.height * 0.16), paint);
  }
  @override
  bool shouldRepaint(_) => false;
}

// ── Login Form ────────────────────────────────────────────────────────────────
class _LoginForm extends StatelessWidget {
  final TextEditingController emailCtrl;
  final TextEditingController passCtrl;
  final GlobalKey<FormState> formKey;
  final bool obscure;
  final VoidCallback onToggleObscure;
  final VoidCallback onLogin;
  final bool isLoading;

  const _LoginForm({
    required this.emailCtrl,
    required this.passCtrl,
    required this.formKey,
    required this.obscure,
    required this.onToggleObscure,
    required this.onLogin,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        children: [
          TextFormField(
            controller: emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'E-mail',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            validator: (v) =>
                v != null && v.contains('@') ? null : 'E-mail inválido',
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: passCtrl,
            obscureText: obscure,
            decoration: InputDecoration(
              labelText: 'Senha',
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                onPressed: onToggleObscure,
              ),
            ),
            validator: (v) =>
                v != null && v.length >= 6 ? null : 'Mínimo 6 caracteres',
            onFieldSubmitted: (_) => onLogin(),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: isLoading ? null : onLogin,
            child: isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Entrar'),
          ),
        ],
      ),
    );
  }
}

// ── Signup Form ───────────────────────────────────────────────────────────────
class _SignupForm extends StatelessWidget {
  final TextEditingController nameCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController passCtrl;
  final GlobalKey<FormState> formKey;
  final bool obscure;
  final VoidCallback onToggleObscure;
  final String selectedRole;
  final ValueChanged<String> onRoleChanged;
  final VoidCallback onSignup;
  final bool isLoading;

  const _SignupForm({
    required this.nameCtrl,
    required this.emailCtrl,
    required this.passCtrl,
    required this.formKey,
    required this.obscure,
    required this.onToggleObscure,
    required this.selectedRole,
    required this.onRoleChanged,
    required this.onSignup,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Form(
      key: formKey,
      child: Column(
        children: [
          TextFormField(
            controller: nameCtrl,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Nome completo',
              prefixIcon: Icon(Icons.person_outline_rounded),
            ),
            validator: (v) =>
                v != null && v.trim().length >= 2 ? null : 'Nome muito curto',
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'E-mail',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            validator: (v) =>
                v != null && v.contains('@') ? null : 'E-mail inválido',
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: passCtrl,
            obscureText: obscure,
            decoration: InputDecoration(
              labelText: 'Senha',
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                onPressed: onToggleObscure,
              ),
            ),
            validator: (v) =>
                v != null && v.length >= 6 ? null : 'Mínimo 6 caracteres',
          ),
          const SizedBox(height: 14),
          // ── Seleção de papel ──────────────────────────────────────────────
          Row(
            children: [
              _RoleTile(
                label: '🧑‍🍳  Freelancer',
                subtitle: 'Busco trabalho',
                value: 'freelancer',
                group: selectedRole,
                primary: primary,
                onTap: () => onRoleChanged('freelancer'),
              ),
              const SizedBox(width: 10),
              _RoleTile(
                label: '🏪  Restaurante',
                subtitle: 'Contrato talentos',
                value: 'company',
                group: selectedRole,
                primary: primary,
                onTap: () => onRoleChanged('company'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: isLoading ? null : onSignup,
            child: isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Criar conta'),
          ),
        ],
      ),
    );
  }
}

class _RoleTile extends StatelessWidget {
  final String label;
  final String subtitle;
  final String value;
  final String group;
  final Color primary;
  final VoidCallback onTap;

  const _RoleTile({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.group,
    required this.primary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final selected = value == group;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: selected ? primary.withOpacity(0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? primary : Colors.grey.withOpacity(0.2),
              width: selected ? 1.5 : 0.8,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: selected ? primary : null,
                    fontFamily: 'Sora',
                  )),
              Text(subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: selected ? primary.withOpacity(0.7) : Colors.grey,
                    fontFamily: 'Sora',
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
