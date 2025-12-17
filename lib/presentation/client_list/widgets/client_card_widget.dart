import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class ClientCardWidget extends StatelessWidget {
  final Map<String, dynamic> client;
  final VoidCallback? onTap;
  final VoidCallback? onCall;
  final VoidCallback? onMessage;
  final VoidCallback? onNewBooking;
  final VoidCallback? onArchive;
  final VoidCallback? onEdit;
  final VoidCallback? onDuplicate;
  final VoidCallback? onShare;

  const ClientCardWidget({
    super.key,
    required this.client,
    this.onTap,
    this.onCall,
    this.onMessage,
    this.onNewBooking,
    this.onArchive,
    this.onEdit,
    this.onDuplicate,
    this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      child: Slidable(
        key: ValueKey(client['id']),
        startActionPane: ActionPane(
          motion: const ScrollMotion(),
          children: [
            SlidableAction(
              onPressed: (_) => onCall?.call(),
              backgroundColor: AppTheme.lightTheme.colorScheme.tertiary,
              foregroundColor: Colors.white,
              icon: Icons.phone,
              label: 'Call',
              borderRadius: BorderRadius.circular(12),
            ),
            SlidableAction(
              onPressed: (_) => onMessage?.call(),
              backgroundColor: AppTheme.lightTheme.primaryColor,
              foregroundColor: Colors.white,
              icon: Icons.message,
              label: 'Message',
              borderRadius: BorderRadius.circular(12),
            ),
            SlidableAction(
              onPressed: (_) => onNewBooking?.call(),
              backgroundColor: AppTheme.successLight,
              foregroundColor: Colors.white,
              icon: Icons.add_circle,
              label: 'Book',
              borderRadius: BorderRadius.circular(12),
            ),
          ],
        ),
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          children: [
            SlidableAction(
              onPressed: (_) => _showArchiveConfirmation(context),
              backgroundColor: AppTheme.warningLight,
              foregroundColor: Colors.white,
              icon: Icons.archive,
              label: 'Archive',
              borderRadius: BorderRadius.circular(12),
            ),
          ],
        ),
        child: GestureDetector(
          onTap: onTap,
          onLongPress: () => _showContextMenu(context),
          child: Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(4.w),
              child: Row(
                children: [
                  _buildProfileImage(),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                client['name'] as String? ?? 'Unknown Client',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            _buildStatusIndicator(colorScheme),
                          ],
                        ),
                        SizedBox(height: 0.5.h),
                        Text(
                          _getServiceTypesText(),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 0.5.h),
                        Row(
                          children: [
                            CustomIconWidget(
                              iconName: 'schedule',
                              size: 14,
                              color:
                                  colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                            SizedBox(width: 1.w),
                            Expanded(
                              child: Text(
                                _getLastBookingText(),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurface
                                      .withValues(alpha: 0.6),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        if (_hasUpcomingBooking()) ...[
                          SizedBox(height: 0.5.h),
                          Row(
                            children: [
                              CustomIconWidget(
                                iconName: 'event',
                                size: 14,
                                color: AppTheme.successLight,
                              ),
                              SizedBox(width: 1.w),
                              Expanded(
                                child: Text(
                                  _getUpcomingBookingText(),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: AppTheme.successLight,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  CustomIconWidget(
                    iconName: 'chevron_right',
                    size: 20,
                    color: colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileImage() {
    return Container(
      width: 15.w,
      height: 15.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15.w / 2),
        child: client['avatar'] != null
            ? CustomImageWidget(
                imageUrl: client['avatar'] as String,
                width: 15.w,
                height: 15.w,
                fit: BoxFit.cover,
                semanticLabel: client['semanticLabel'] as String? ??
                    'Client profile photo',
              )
            : Container(
                color: AppTheme.lightTheme.colorScheme.primary
                    .withValues(alpha: 0.1),
                child: Center(
                  child: Text(
                    _getInitials(),
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.lightTheme.colorScheme.primary,
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildStatusIndicator(ColorScheme colorScheme) {
    final status = _getClientStatus();
    Color statusColor;

    switch (status) {
      case 'upcoming':
        statusColor = AppTheme.successLight;
        break;
      case 'overdue':
        statusColor = AppTheme.warningLight;
        break;
      case 'inactive':
        statusColor = colorScheme.onSurface.withValues(alpha: 0.4);
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: statusColor,
        shape: BoxShape.circle,
      ),
    );
  }

  String _getInitials() {
    final name = client['name'] as String? ?? 'U';
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  String _getServiceTypesText() {
    final services = client['serviceTypes'] as List<dynamic>? ?? [];
    if (services.isEmpty) return 'No services';
    if (services.length == 1) return services[0] as String;
    if (services.length == 2) return '${services[0]} & ${services[1]}';
    return '${services[0]} & ${services.length - 1} more';
  }

  String _getLastBookingText() {
    final lastBooking = client['lastBookingDate'] as String?;
    if (lastBooking == null) return 'No bookings yet';

    final date = DateTime.tryParse(lastBooking);
    if (date == null) return 'No bookings yet';

    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';
    if (difference < 7) return '$difference days ago';
    if (difference < 30) return '${(difference / 7).floor()} weeks ago';
    return '${(difference / 30).floor()} months ago';
  }

  bool _hasUpcomingBooking() {
    final upcomingBooking = client['upcomingBookingDate'] as String?;
    if (upcomingBooking == null) return false;

    final date = DateTime.tryParse(upcomingBooking);
    if (date == null) return false;

    return date.isAfter(DateTime.now());
  }

  String _getUpcomingBookingText() {
    final upcomingBooking = client['upcomingBookingDate'] as String?;
    if (upcomingBooking == null) return '';

    final date = DateTime.tryParse(upcomingBooking);
    if (date == null) return '';

    final now = DateTime.now();
    final difference = date.difference(now).inDays;

    if (difference == 0) return 'Today';
    if (difference == 1) return 'Tomorrow';
    if (difference < 7) return 'In $difference days';
    return 'In ${(difference / 7).floor()} weeks';
  }

  String _getClientStatus() {
    if (_hasUpcomingBooking()) return 'upcoming';

    final overduePayment = client['hasOverduePayment'] as bool? ?? false;
    if (overduePayment) return 'overdue';

    final lastBooking = client['lastBookingDate'] as String?;
    if (lastBooking == null) return 'inactive';

    final date = DateTime.tryParse(lastBooking);
    if (date == null) return 'inactive';

    final daysSinceLastBooking = DateTime.now().difference(date).inDays;
    if (daysSinceLastBooking > 90) return 'inactive';

    return 'active';
  }

  void _showArchiveConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Archive Client'),
          content: Text(
              'Are you sure you want to archive ${client['name']}? This will hide them from your active client list.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                onArchive?.call();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.warningLight,
              ),
              child: const Text('Archive'),
            ),
          ],
        );
      },
    );
  }

  void _showContextMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: CustomIconWidget(
                  iconName: 'edit',
                  size: 24,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                title: const Text('Edit Client'),
                onTap: () {
                  Navigator.pop(context);
                  onEdit?.call();
                },
              ),
              ListTile(
                leading: CustomIconWidget(
                  iconName: 'content_copy',
                  size: 24,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                title: const Text('Duplicate Client'),
                onTap: () {
                  Navigator.pop(context);
                  onDuplicate?.call();
                },
              ),
              ListTile(
                leading: CustomIconWidget(
                  iconName: 'share',
                  size: 24,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                title: const Text('Share Contact'),
                onTap: () {
                  Navigator.pop(context);
                  onShare?.call();
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}
