import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class CallLogWidget extends StatelessWidget {
  final List<Map<String, dynamic>> callLogs;
  final Function(Map<String, dynamic>) onCallBack;

  const CallLogWidget({
    super.key,
    required this.callLogs,
    required this.onCallBack,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (callLogs.isEmpty) {
      return _buildEmptyState(context);
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(vertical: 2.h),
      itemCount: callLogs.length,
      itemBuilder: (context, index) {
        final callLog = callLogs[index];
        return _buildCallLogItem(context, callLog);
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
            iconName: 'phone',
            color: theme.colorScheme.outline,
            size: 20.w,
          ),
          SizedBox(height: 3.h),
          Text(
            'No call history',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Your call history will appear here',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCallLogItem(BuildContext context, Map<String, dynamic> callLog) {
    final theme = Theme.of(context);
    final String callType = callLog['type'] as String;
    final DateTime timestamp = callLog['timestamp'] as DateTime;
    final String duration = callLog['duration'] as String;

    Color callIconColor;
    String callIconName;

    switch (callType) {
      case 'incoming':
        callIconColor = Colors.green;
        callIconName = 'call_received';
        break;
      case 'outgoing':
        callIconColor = theme.colorScheme.primary;
        callIconName = 'call_made';
        break;
      case 'missed':
        callIconColor = theme.colorScheme.error;
        callIconName = 'call_received';
        break;
      default:
        callIconColor = theme.colorScheme.outline;
        callIconName = 'phone';
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
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
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 6.w,
              backgroundImage: CachedNetworkImageProvider(
                callLog['clientPhoto'] as String,
              ),
              child: CachedNetworkImage(
                imageUrl: callLog['clientPhoto'] as String,
                imageBuilder:
                    (context, imageProvider) => Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        image: DecorationImage(
                          image: imageProvider,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                placeholder:
                    (context, url) => Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: CustomIconWidget(
                          iconName: 'person',
                          color: theme.colorScheme.primary,
                          size: 5.w,
                        ),
                      ),
                    ),
                errorWidget:
                    (context, url, error) => Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: CustomIconWidget(
                          iconName: 'person',
                          color: theme.colorScheme.primary,
                          size: 5.w,
                        ),
                      ),
                    ),
              ),
            ),
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                padding: EdgeInsets.all(1.w),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  shape: BoxShape.circle,
                ),
                child: Container(
                  padding: EdgeInsets.all(1.w),
                  decoration: BoxDecoration(
                    color: callIconColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: CustomIconWidget(
                    iconName: callIconName,
                    color: callIconColor,
                    size: 3.w,
                  ),
                ),
              ),
            ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                callLog['clientName'] as String,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            Text(
              _formatTimestamp(timestamp),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
        subtitle: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    callLog['phoneNumber'] as String,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Row(
                    children: [
                      CustomIconWidget(
                        iconName: 'schedule',
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.5,
                        ),
                        size: 3.w,
                      ),
                      SizedBox(width: 1.w),
                      Text(
                        duration == '00:00:00' ? 'Missed call' : duration,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            _buildCallTypeChip(context, callType),
          ],
        ),
        trailing: IconButton(
          icon: CustomIconWidget(
            iconName: 'phone',
            color: theme.colorScheme.primary,
            size: 5.w,
          ),
          onPressed: () => onCallBack(callLog),
          tooltip: 'Call back',
        ),
      ),
    );
  }

  Widget _buildCallTypeChip(BuildContext context, String callType) {
    final theme = Theme.of(context);

    Color chipColor;
    String chipText;

    switch (callType) {
      case 'incoming':
        chipColor = Colors.green;
        chipText = 'Incoming';
        break;
      case 'outgoing':
        chipColor = theme.colorScheme.primary;
        chipText = 'Outgoing';
        break;
      case 'missed':
        chipColor = theme.colorScheme.error;
        chipText = 'Missed';
        break;
      default:
        chipColor = theme.colorScheme.outline;
        chipText = 'Unknown';
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        chipText,
        style: theme.textTheme.bodySmall?.copyWith(
          color: chipColor,
          fontWeight: FontWeight.w600,
          fontSize: 10.sp,
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
