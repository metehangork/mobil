import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/models/app_notification.dart';
import '../cubit/notifications_cubit.dart';
import '../cubit/notifications_state.dart';
import 'package:go_router/go_router.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  Color _badgeColor(BuildContext context, NotificationPriority p) {
    final cs = Theme.of(context).colorScheme;
    switch (p) {
      case NotificationPriority.critical:
        return cs.error;
      case NotificationPriority.important:
        return cs.tertiary;
      case NotificationPriority.normal:
        return cs.secondary;
    }
  }

  IconData _icon(NotificationPriority p) {
    switch (p) {
      case NotificationPriority.critical:
        return Icons.warning_amber_outlined;
      case NotificationPriority.important:
        return Icons.priority_high_outlined;
      case NotificationPriority.normal:
        return Icons.notifications_none;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => NotificationsCubit()..load(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Bildirimler'),
        ),
        body: BlocBuilder<NotificationsCubit, NotificationsState>(
          builder: (context, state) {
            if (state is NotificationsLoading || state is NotificationsInitial) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is NotificationsError) {
              return Center(child: Text('Hata: ${state.message}'));
            }
            if (state is NotificationsEmpty) {
              return const Center(child: Text('Henüz bildirimin yok.'));
            }
            final items = (state as NotificationsLoaded).items;
            return ListView.separated(
              padding: const EdgeInsets.all(8),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final n = items[index];
                final color = _badgeColor(context, n.priority);
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: color.withOpacity(.15),
                      child: Icon(_icon(n.priority), color: color),
                    ),
                    title: Text(n.title),
                    subtitle: Text(n.message),
                    trailing: n.read
                        ? const Icon(Icons.done, size: 18)
                        : TextButton(
                            onPressed: () => context.read<NotificationsCubit>().markAsRead(n.id),
                            child: const Text('Okundu'),
                          ),
                    onTap: n.route == null
                        ? null
                        : () {
                            // Basit yönlendirme
                            context.pop();
                            context.go(n.route!);
                          },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
