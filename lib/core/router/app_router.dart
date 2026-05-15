import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../features/auth/presentation/auth_page.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/freelancer/presentation/freelancer_dashboard.dart';
import '../../features/freelancer/presentation/job_search_screen.dart';
import '../../features/freelancer/presentation/my_jobs_page.dart';
import '../../features/freelancer/presentation/profile_freelancer_page.dart';
import '../../features/restaurant/presentation/company_dashboard.dart';
import '../../features/restaurant/presentation/create_vacancy_screen.dart';
import '../../features/restaurant/presentation/candidates_screen.dart';
import '../../features/restaurant/presentation/profile_restaurant_page.dart';

final appRouter = GoRouter(
  initialLocation: '/auth',
  redirect: (context, state) async {
    final user = FirebaseAuth.instance.currentUser;
    final goingToAuth = state.matchedLocation == '/auth' ||
        state.matchedLocation == '/forgot-password';
    if (user == null && !goingToAuth) return '/auth';
    if (user != null && state.matchedLocation == '/auth') return '/freelancer';
    return null;
  },
  routes: [
    GoRoute(path: '/auth',           builder: (_, __) => const AuthPage()),
    GoRoute(path: '/forgot-password', builder: (_, __) => const ForgotPasswordScreen()),

    // ── Freelancer Shell ────────────────────────────────────────────────────
    ShellRoute(
      builder: (context, state, child) => _FreelancerShell(child: child),
      routes: [
        GoRoute(path: '/freelancer',            builder: (_, __) => const FreelancerDashboard()),
        GoRoute(path: '/freelancer/search',     builder: (_, __) => const JobSearchScreen()),
        GoRoute(path: '/freelancer/my-jobs',    builder: (_, __) => const MyJobsPage()),
        GoRoute(path: '/freelancer/profile',    builder: (_, __) => const ProfileFreelancerPage()),
      ],
    ),

    // ── Company Shell ───────────────────────────────────────────────────────
    ShellRoute(
      builder: (context, state, child) => _CompanyShell(child: child),
      routes: [
        GoRoute(path: '/company',                     builder: (_, __) => const CompanyDashboard()),
        GoRoute(path: '/company/create-vacancy',      builder: (_, __) => const CreateVacancyScreen()),
        GoRoute(path: '/company/candidates/:vagaId',  builder: (_, state) => CandidatesScreen(vagaId: state.pathParameters['vagaId']!)),
        GoRoute(path: '/company/profile',             builder: (_, __) => const ProfileRestaurantPage()),
      ],
    ),
  ],
);

// ── Freelancer Bottom Nav ────────────────────────────────────────────────────
class _FreelancerShell extends StatelessWidget {
  final Widget child;
  const _FreelancerShell({required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    int index = 0;
    if (location.contains('search'))  index = 1;
    if (location.contains('my-jobs')) index = 2;
    if (location.contains('profile')) index = 3;

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) {
          const routes = [
            '/freelancer',
            '/freelancer/search',
            '/freelancer/my-jobs',
            '/freelancer/profile',
          ];
          context.go(routes[i]);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Início',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search_rounded),
            label: 'Buscar',
          ),
          NavigationDestination(
            icon: Icon(Icons.work_outline_rounded),
            selectedIcon: Icon(Icons.work_rounded),
            label: 'Meus Jobs',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}

// ── Company Bottom Nav ───────────────────────────────────────────────────────
class _CompanyShell extends StatelessWidget {
  final Widget child;
  const _CompanyShell({required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    int index = 0;
    if (location.contains('create-vacancy')) index = 1;
    if (location.contains('profile'))        index = 2;

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) {
          const routes = [
            '/company',
            '/company/create-vacancy',
            '/company/profile',
          ];
          context.go(routes[i]);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Vagas',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline_rounded),
            selectedIcon: Icon(Icons.add_circle_rounded),
            label: 'Postar',
          ),
          NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront_rounded),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
