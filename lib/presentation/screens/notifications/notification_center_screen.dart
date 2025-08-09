import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/providers/notification_provider.dart';
import '../../../domain/entities/notification_model.dart';
import '../../../data/providers/auth_provider.dart';

class NotificationCenterScreen extends ConsumerWidget {
  const NotificationCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(userNotificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Centre de notifications'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.check_done_all),
            onPressed: () {
              final userId = ref.read(currentUserProvider)?.uid;
              if (userId != null) {
                ref.read(notificationServiceProvider).markAllAsRead(userId);
              }
            },
          ),
        ],
      ),
      body: notificationsAsync.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined,
                      size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Aucune notification',
                      style: TextStyle(fontSize: 18, color: Colors.grey)),
                ],
              ),
            );
          }
          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return _NotificationTile(notification: notification);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) =>
            Center(child: Text('Erreur: $error')),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification});

  final NotificationModel notification;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: notification.read
            ? Colors.grey.shade300
            : Theme.of(context).primaryColor.withOpacity(0.2),
        child: Icon(
          _getIconForType(notification.type),
          color: notification.read
              ? Colors.grey.shade600
              : Theme.of(context).primaryColor,
        ),
      ),
      title: Text(
        notification.title,
        style: TextStyle(
          fontWeight: notification.read ? FontWeight.normal : FontWeight.bold,
        ),
      ),
      subtitle: Text(notification.message),
      trailing: Text(
        timeago.format(notification.createdAt.toDate(), locale: 'fr'),
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
      onTap: () {
        // Mark as read
        FirebaseFirestore.instance
            .collection('notifications')
            .doc(notification.id)
            .update({'read': true});

        // Navigate if there's a relevant link
        final data = notification.data;
        if (data.containsKey('tontineId')) {
          context.push('/tontine/${data['tontineId']}');
        } else if (data.containsKey('creditId')) {
          context.push('/credit/${data['creditId']}');
        }
      },
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'transfer_sent':
        return Icons.arrow_upward;
      case 'transfer_received':
        return Icons.arrow_downward;
      case 'tontine_reminder':
        return Icons.group;
      case 'credit_approved':
        return Icons.check_circle;
      default:
        return Icons.notifications;
    }
  }
}
