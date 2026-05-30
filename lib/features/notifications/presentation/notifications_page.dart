import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../data/notification_repository.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final NotificationRepository _repository = NotificationRepository();

  User? get _user => FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    final user = _user;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('FaÃƒÂ§a login para ver suas notificações.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificações'),
        centerTitle: false,
        actions: [
          TextButton(
            onPressed: () => _repository.markAllAsRead(user.uid),
            child: const Text('Ler todas'),
          ),
        ],
      ),
      body: StreamBuilder<List<AppNotification>>(
        stream: _repository.watchNotifications(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _LoadingList();
          }

          if (snapshot.hasError) {
            return const _EmptyState(
              icon: Icons.error_outline_rounded,
              title: 'Não foi possível carregar',
              message: 'Tente novamente em alguns instantes.',
            );
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return const _EmptyState(
              icon: Icons.notifications_none_rounded,
              title: 'Nenhuma notificaÃƒÂ§ÃƒÂ£o',
              message: 'AtualizaÃƒÂ§ÃƒÂµes de candidaturas aparecerÃƒÂ£o aqui.',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final notification = notifications[index];

              return _NotificationCard(
                notification: notification,
                onTap: () {
                  _repository.markAsRead(
                    uid: user.uid,
                    notificationId: notification.id,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;

  const _NotificationCard({required this.notification, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final color = switch (notification.type) {
      'aprovado' => Colors.green,
      'recusado' => Colors.red,
      'candidatura' => Colors.orange,
      _ => colorScheme.primary,
    };

    final icon = switch (notification.type) {
      'aprovado' => Icons.check_circle_rounded,
      'recusado' => Icons.cancel_rounded,
      'candidatura' => Icons.person_add_alt_1_rounded,
      _ => Icons.notifications_rounded,
    };

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: notification.read
              ? colorScheme.surface
              : colorScheme.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: notification.read
                ? colorScheme.outline.withValues(alpha: 0.18)
                : colorScheme.primary.withValues(alpha: 0.24),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.12),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.message,
                    style: TextStyle(
                      height: 1.35,
                      color: colorScheme.onSurface.withValues(alpha: 0.72),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _dateText(notification.createdAt),
                    style: TextStyle(
                      color: colorScheme.onSurface.withValues(alpha: 0.52),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (!notification.read)
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _dateText(DateTime? date) {
    if (date == null) return 'Agora';

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$day/$month ÃƒÂ s $hour:$minute';
  }
}

class _LoadingList extends StatelessWidget {
  const _LoadingList();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: List.generate(
        5,
        (index) => Container(
          height: 92,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: colorScheme.primary, size: 54),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              message,
              style: TextStyle(
                color: colorScheme.onSurface.withValues(alpha: 0.64),
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
