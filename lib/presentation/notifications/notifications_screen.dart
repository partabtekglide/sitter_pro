import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../core/app_export.dart';
import '../../services/supabase_service.dart';
import '../../widgets/custom_app_bar.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userId = SupabaseService.instance.currentUser?.id;

    if (userId == null) {
      return Scaffold(
        appBar: const CustomAppBar(title: 'Notifications'),
        body: Center(child: Text('Please log in to see notifications.')),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: 'Notifications',
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: 'Mark all as read',
            onPressed: () async {
              try {
                await SupabaseService.instance.markAllNotificationsAsRead(userId);
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('All notifications marked as read')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: SupabaseService.instance.client
            .from('notifications')
            .stream(primaryKey: ['id'])
            .eq('user_id', userId)
            .order('created_at', ascending: false),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final allNotifications = snapshot.data ?? [];
          // Filter to only show unread notifications in the UI
          final notifications = allNotifications.where((n) => n['is_read'] == false).toList();

          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Icon(
                    Icons.notifications_none,
                    size: 80,
                    color: theme.colorScheme.onSurface.withAlpha(50),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    'No notifications yet',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withAlpha(100),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: EdgeInsets.all(4.w),
            itemCount: notifications.length,
            separatorBuilder: (context, index) => SizedBox(height: 1.5.h),
            itemBuilder: (context, index) {
              final notification = notifications[index];
              final bool isRead = notification['is_read'] ?? false;

              return InkWell(
                onTap: () async {
                  if (!isRead) {
                    await SupabaseService.instance.markNotificationAsRead(notification['id']);
                  }
                  // Handle navigation based on type or booking_id here if needed
                },
                child: Container(
                  padding: EdgeInsets.all(4.w),
                  decoration: BoxDecoration(
                    color: isRead 
                        ? theme.colorScheme.surface 
                        : theme.colorScheme.primary.withAlpha(15),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: isRead 
                          ? theme.colorScheme.outline.withAlpha(30)
                          : theme.colorScheme.primary.withAlpha(50),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: EdgeInsets.all(2.w),
                        decoration: BoxDecoration(
                          color: _getIconColor(notification['type']).withAlpha(30),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getIcon(notification['type']),
                          color: _getIconColor(notification['type']),
                          size: 20,
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    notification['title'] ?? 'Notification',
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: isRead ? FontWeight.w600 : FontWeight.w800,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                                Text(
                                  _formatDate(notification['created_at']),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface.withAlpha(150),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 0.5.h),
                            Text(
                              notification['message'] ?? '',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface.withAlpha(200),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  IconData _getIcon(String? type) {
    switch (type) {
      case 'booking_request':
      case 'booking_confirmed':
        return Icons.event;
      case 'payment_received':
        return Icons.account_balance_wallet;
      case 'reminder':
        return Icons.alarm;
      case 'message':
        return Icons.message;
      default:
        return Icons.notifications;
    }
  }

  Color _getIconColor(String? type) {
    switch (type) {
      case 'booking_request':
        return Colors.blue;
      case 'booking_confirmed':
        return Colors.green;
      case 'payment_received':
        return Colors.orange;
      case 'reminder':
        return Colors.red;
      case 'message':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    final date = DateTime.parse(dateStr).toLocal();
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h';
    } else {
      return '${date.day}/${date.month}';
    }
  }
}
