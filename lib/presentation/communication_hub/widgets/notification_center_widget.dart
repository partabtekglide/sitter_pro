import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class NotificationCenterWidget extends StatelessWidget {
  final List<Map<String, dynamic>> notifications;
  final Function(Map<String, dynamic>) onNotificationTap;

  const NotificationCenterWidget({
    super.key,
    required this.notifications,
    required this.onNotificationTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (notifications.isEmpty) {
      return _buildEmptyState(context);
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(vertical: 2.h),
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        final notification = notifications[index];
        return _buildNotificationItem(context, notification);
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomIconWidget(
            iconName: 'notifications_none',
            color: theme.colorScheme.outline,
            size: 20.w,
          ),
          SizedBox(height: 3.h),
          Text(
            'No notifications',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'You\'re all caught up!',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(
    BuildContext context,
    Map<String, dynamic> notification,
  ) {
    final theme = Theme.of(context);
    final String notificationType = notification['type'] as String;
    final bool isRead = notification['isRead'] as bool;
    final bool actionRequired = notification['actionRequired'] as bool;
    final DateTime timestamp = notification['timestamp'] as DateTime;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      decoration: BoxDecoration(
        color:
            isRead
                ? theme.colorScheme.surface
                : theme.colorScheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              isRead
                  ? theme.colorScheme.outline.withValues(alpha: 0.1)
                  : theme.colorScheme.primary.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.all(3.w),
        leading: _buildNotificationIcon(context, notificationType, isRead),
        title: Row(
          children: [
            Expanded(
              child: Text(
                notification['title'] as String,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: isRead ? FontWeight.w500 : FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            if (!isRead)
              Container(
                width: 2.w,
                height: 2.w,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 1.h),
            Text(
              notification['message'] as String,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 1.h),
            Row(
              children: [
                Text(
                  _formatTimestamp(timestamp),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
                if (actionRequired) ...[
                  SizedBox(width: 2.w),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 2.w,
                      vertical: 0.5.h,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.tertiary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Action Required',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.tertiary,
                        fontWeight: FontWeight.w600,
                        fontSize: 9.sp,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            if (actionRequired)
              Padding(
                padding: EdgeInsets.only(top: 2.h),
                child: Row(
                  children: [
                    TextButton(
                      onPressed: () => onNotificationTap(notification),
                      child: const Text('Take Action'),
                    ),
                    SizedBox(width: 2.w),
                    OutlinedButton(
                      onPressed: () => onNotificationTap(notification),
                      child: const Text('Dismiss'),
                    ),
                  ],
                ),
              ),
          ],
        ),
        onTap: () => onNotificationTap(notification),
      ),
    );
  }

  Widget _buildNotificationIcon(
    BuildContext context,
    String type,
    bool isRead,
  ) {
    final theme = Theme.of(context);

    String iconName;
    Color iconColor;
    Color backgroundColor;

    switch (type) {
      case 'booking':
        iconName = 'event';
        iconColor = theme.colorScheme.primary;
        backgroundColor = theme.colorScheme.primary.withValues(alpha: 0.1);
        break;
      case 'payment':
        iconName = 'payment';
        iconColor = Colors.green;
        backgroundColor = Colors.green.withValues(alpha: 0.1);
        break;
      case 'reminder':
        iconName = 'alarm';
        iconColor = theme.colorScheme.tertiary;
        backgroundColor = theme.colorScheme.tertiary.withValues(alpha: 0.1);
        break;
      case 'message':
        iconName = 'message';
        iconColor = theme.colorScheme.secondary;
        backgroundColor = theme.colorScheme.secondary.withValues(alpha: 0.1);
        break;
      case 'system':
        iconName = 'info';
        iconColor = theme.colorScheme.outline;
        backgroundColor = theme.colorScheme.outline.withValues(alpha: 0.1);
        break;
      default:
        iconName = 'notifications';
        iconColor = theme.colorScheme.primary;
        backgroundColor = theme.colorScheme.primary.withValues(alpha: 0.1);
    }

    return Container(
      width: 12.w,
      height: 12.w,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: CustomIconWidget(
          iconName: iconName,
          color: isRead ? iconColor.withValues(alpha: 0.6) : iconColor,
          size: 5.w,
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}
