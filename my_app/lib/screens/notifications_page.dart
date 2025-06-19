import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_spacing.dart';
import '../core/theme/app_colors.dart';
import '../core/widgets/animated_widgets.dart';
import '../features/notifications/presentation/notification_controller.dart';
import 'login_page.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: Consumer<NotificationController>(
        builder: (context, controller, child) {
          if (controller.state == NotificationLoadState.unauthorized) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (r) => false,
              );
            });
          }

          if (controller.state == NotificationLoadState.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.state == NotificationLoadState.empty || controller.notifications.isEmpty) {
            return const Center(child: Text('No notifications right now.'));
          }

          if (controller.state == NotificationLoadState.error) {
            return Center(
              child: Text(
                controller.error ?? 'An error occurred',
                style: const TextStyle(color: AppColors.error),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: controller.load,
            child: ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: controller.notifications.length,
              itemBuilder: (context, index) {
                final notification = controller.notifications[index];
                final isUnread = !notification.isRead;
                
                return AnimatedFadeIn(
                  delay: Duration(milliseconds: 50 * index),
                  child: AnimatedSlideIn(
                    begin: const Offset(0.0, 0.5),
                    delay: Duration(milliseconds: 50 * index),
                    child: Card(
                      color: isUnread ? AppColors.primaryContainer.withValues(alpha: 0.3) : AppColors.surface,
                      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isUnread ? AppColors.primary : Colors.grey,
                          child: Icon(
                            isUnread ? Icons.notifications_active : Icons.notifications,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(
                          notification.title,
                          style: TextStyle(
                            fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        subtitle: Text(notification.body),
                        trailing: isUnread
                            ? IconButton(
                                icon: const Icon(Icons.check),
                                tooltip: 'Mark as read',
                                onPressed: () => controller.markAsRead(notification.id),
                              )
                            : null,
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
