import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/ifree_responsive_shell.dart';

import '../../features/admin/presentation/admin_dashboard_page.dart';
import '../../features/auth/presentation/auth_page.dart';
import '../../features/chat/presentation/chat_page.dart';
import '../../features/freelancer/presentation/freelancer_dashboard.dart';
import '../../features/freelancer/presentation/job_search_screen.dart';
import '../../features/freelancer/presentation/my_jobs_page.dart';
import '../../features/freelancer/presentation/profile_freelancer_page.dart';
import '../../features/notifications/presentation/notifications_page.dart';
import '../../features/restaurant/presentation/candidates_screen.dart';
import '../../features/restaurant/presentation/company_dashboard.dart';
import '../../features/restaurant/presentation/create_vacancy_screen.dart';
import '../../features/restaurant/presentation/profile_restaurant_page.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  debugLogDiagnostics: true,
  redirect: (context, state) {
    final user = FirebaseAuth.instance.currentUser;
    final location = state.matchedLocation;

    final isAuthRoute = location == '/login' || location == '/auth';

    if (user == null && !isAuthRoute) {
      return '/login';
    }

    if (user != null && (location == '/' || isAuthRoute)) {
      return '/freelancer';
    }

    return null;
  },
  errorBuilder: (context, state) {
    return _NotFoundPage(
      message: state.error?.toString() ?? 'Rota não encontrada.',
    );
  },
  routes: [
    GoRoute(
      path: '/',
      redirect: (context, state) {
        final user = FirebaseAuth.instance.currentUser;

        if (user == null) {
          return '/login';
        }

        return '/freelancer';
      },
    ),
    GoRoute(path: '/login', builder: (context, state) => const AuthPage()),
    GoRoute(path: '/auth', builder: (context, state) => const AuthPage()),

    GoRoute(
      path: '/freelancer',
      builder: (context, state) => const _FreelancerShell(
        selectedIndex: 0,
        child: FreelancerDashboard(),
      ),
    ),
    GoRoute(
      path: '/freelancer/search',
      builder: (context, state) =>
          const _FreelancerShell(selectedIndex: 1, child: JobSearchScreen()),
    ),
    GoRoute(
      path: '/freelancer/my-jobs',
      builder: (context, state) =>
          const _FreelancerShell(selectedIndex: 2, child: MyJobsPage()),
    ),
    GoRoute(
      path: '/freelancer/profile',
      builder: (context, state) => const _FreelancerShell(
        selectedIndex: 3,
        child: ProfileFreelancerPage(),
      ),
    ),

    GoRoute(
      path: '/company',
      builder: (context, state) =>
          const _CompanyShell(selectedIndex: 0, child: CompanyDashboard()),
    ),
    GoRoute(
      path: '/company/dashboard',
      builder: (context, state) =>
          const _CompanyShell(selectedIndex: 0, child: CompanyDashboard()),
    ),
    GoRoute(
      path: '/company/create-vacancy',
      builder: (context, state) => const CreateVacancyScreen(),
    ),
    GoRoute(
      path: '/company/profile',
      builder: (context, state) =>
          const _CompanyShell(selectedIndex: 1, child: ProfileRestaurantPage()),
    ),
    GoRoute(
      path: '/company/candidates/:vagaId',
      builder: (context, state) {
        final vagaId = state.pathParameters['vagaId'] ?? '';

        return CandidatesScreen(vagaId: vagaId);
      },
    ),

    GoRoute(
      path: '/notifications',
      builder: (context, state) => const NotificationsPage(),
    ),
    GoRoute(
      path: '/admin',
      builder: (context, state) => const AdminDashboardPage(),
    ),
    GoRoute(
      path: '/chat',
      builder: (context, state) {
        final conversationId =
            state.uri.queryParameters['conversationId'] ?? '';
        final title = state.uri.queryParameters['title'] ?? 'Chat';

        return ChatPage(conversationId: conversationId, title: title);
      },
    ),
  ],
);

class _FreelancerShell extends StatelessWidget {
  final int selectedIndex;
  final Widget child;

  const _FreelancerShell({required this.selectedIndex, required this.child});

  void _goToTab(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/freelancer');
        break;
      case 1:
        context.go('/freelancer/search');
        break;
      case 2:
        context.go('/freelancer/my-jobs');
        break;
      case 3:
        context.go('/freelancer/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return IFreeResponsiveShell(
      selectedIndex: selectedIndex,
      onDestinationSelected: (index) => _goToTab(context, index),
      sectionLabel: 'Freelancer',
      sectionSubtitle: 'Seu trabalho, do seu jeito',
      destinations: const [
        IFreeNavItem(
          label: 'Início',
          icon: Icons.home_outlined,
          selectedIcon: Icons.home_rounded,
        ),
        IFreeNavItem(
          label: 'Buscar',
          icon: Icons.search_outlined,
          selectedIcon: Icons.search_rounded,
        ),
        IFreeNavItem(
          label: 'Meus Jobs',
          icon: Icons.work_outline_rounded,
          selectedIcon: Icons.work_rounded,
        ),
        IFreeNavItem(
          label: 'Perfil',
          icon: Icons.person_outline_rounded,
          selectedIcon: Icons.person_rounded,
        ),
      ],
      child: child,
    );
  }
}

class _CompanyShell extends StatelessWidget {
  final int selectedIndex;
  final Widget child;

  const _CompanyShell({required this.selectedIndex, required this.child});

  void _goToTab(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/company');
        break;
      case 1:
        context.go('/company/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return IFreeResponsiveShell(
      selectedIndex: selectedIndex,
      onDestinationSelected: (index) => _goToTab(context, index),
      sectionLabel: 'Empresa',
      sectionSubtitle: 'Contrate com mais agilidade',
      destinations: const [
        IFreeNavItem(
          label: 'Painel',
          icon: Icons.dashboard_outlined,
          selectedIcon: Icons.dashboard_rounded,
        ),
        IFreeNavItem(
          label: 'Perfil',
          icon: Icons.storefront_outlined,
          selectedIcon: Icons.storefront_rounded,
        ),
      ],
      child: child,
    );
  }
}

class _NotFoundPage extends StatelessWidget {
  final String message;

  const _NotFoundPage({required this.message});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Página não encontrada')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 54),
              const SizedBox(height: 14),
              const Text(
                'Page Not Found',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: () {
                  if (user == null) {
                    context.go('/login');
                  } else {
                    context.go('/freelancer');
                  }
                },
                icon: const Icon(Icons.home_rounded),
                label: const Text('Voltar para o início'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
