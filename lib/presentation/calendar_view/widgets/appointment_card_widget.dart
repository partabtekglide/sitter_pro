import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class AppointmentCardWidget extends StatelessWidget {
  final Map<String, dynamic> appointment;
  final ScrollController scrollController;
  final Function(Map<String, dynamic>, String) onAction;
  final bool showFullDetails;

  const AppointmentCardWidget({
    super.key,
    required this.appointment,
    required this.scrollController,
    required this.onAction,
    this.showFullDetails = false,
  });

  Color _getServiceColor(String serviceType) {
    switch (serviceType) {
      case 'babysitting':
        return AppTheme.primaryLight;
      case 'pet_sitting':
        return AppTheme.successLight;
      case 'house_sitting':
        return AppTheme.warningLight;
      default:
        return AppTheme.primaryLight;
    }
  }

  String _getServiceIcon(String serviceType) {
    switch (serviceType) {
      case 'babysitting':
        return 'child_care';
      case 'pet_sitting':
        return 'pets';
      case 'house_sitting':
        return 'home';
      default:
        return 'work';
    }
  }

  String _getServiceName(String serviceType) {
    switch (serviceType) {
      case 'babysitting':
        return 'Babysitting';
      case 'pet_sitting':
        return 'Pet Sitting';
      case 'house_sitting':
        return 'House Sitting';
      default:
        return serviceType;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return AppTheme.successLight;
      case 'pending':
        return AppTheme.warningLight;
      case 'cancelled':
        return AppTheme.errorLight;
      case 'completed':
        return AppTheme.primaryLight;
      default:
        return AppTheme.secondaryLight;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final serviceColor = _getServiceColor(appointment['serviceType']);
    final statusColor = _getStatusColor(appointment['status']);
    final startTime = appointment['startTime'] as TimeOfDay;
    final endTime = appointment['endTime'] as TimeOfDay;

    return SingleChildScrollView(
      controller: scrollController,
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 12.w,
              height: 0.5.h,
              decoration: BoxDecoration(
                color: theme.colorScheme.outline.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          SizedBox(height: 3.h),

          // Header Section
          Row(
            children: [
              // Profile Image
              Container(
                width: 20.w,
                height: 20.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: serviceColor.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: ClipOval(
                  child: CustomImageWidget(
                    imageUrl: appointment['profileImage'] ?? '',
                    semanticLabel:
                        'Profile photo of ${appointment['clientName']}',
                    width: 20.w,
                    height: 20.w,
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              SizedBox(width: 4.w),

              // Client Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appointment['clientName'],
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(height: 1.h),
                    Row(
                      children: [
                        CustomIconWidget(
                          iconName: _getServiceIcon(appointment['serviceType']),
                          color: serviceColor,
                          size: 5.w,
                        ),
                        SizedBox(width: 2.w),
                        Text(
                          _getServiceName(appointment['serviceType']),
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: serviceColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Status Badge
              Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  appointment['status'].toString().toUpperCase(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 4.h),

          // Details Section
          Column(
            children: [
              _buildDetailRow(
                context,
                'Date & Time',
                '${_formatDate(appointment['date'])} • ${_formatTimeOfDay(startTime)} - ${_formatTimeOfDay(endTime)}',
                'schedule',
                theme,
              ),

              _buildDetailRow(
                context,
                'Amount',
                '\$${appointment['amount'].toStringAsFixed(2)}',
                'attach_money',
                theme,
              ),

              _buildDetailRow(
                context,
                'Phone',
                appointment['clientPhone'] as String,
                'phone',
                theme,
              ),

              _buildDetailRow(
                context,
                'Address',
                appointment['address'] as String,
                'location_on',
                theme,
              ),
            ],
          ),

          // Notes Section
          if (appointment['notes'] != null &&
              appointment['notes'].isNotEmpty) ...[
            SizedBox(height: 3.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CustomIconWidget(
                        iconName: 'note',
                        color: theme.colorScheme.primary,
                        size: 5.w,
                      ),
                      SizedBox(width: 2.w),
                      Text(
                        'Special Notes',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    appointment['notes'],
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],

          SizedBox(height: 4.h),

          // Quick Actions Section
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quick Actions',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 2.h),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 3,
                  childAspectRatio: 1.2,
                  crossAxisSpacing: 2.w,
                  mainAxisSpacing: 2.w,
                  children: [
                    if (appointment['status'] == 'in_progress')
                      _buildQuickActionButton(
                        context,
                        'Check Out',
                        'logout',
                        AppTheme.warningLight,
                        () => onAction(appointment, 'check_out'),
                        theme,
                      )
                    else
                      _buildQuickActionButton(
                        context,
                        'Check In',
                        'login',
                        AppTheme.successLight,
                        () => onAction(appointment, 'check_in'),
                        theme,
                      ),
                    // _buildQuickActionButton(
                    //   context,
                    //   'Reschedule',
                    //   'event',
                    //   AppTheme.warningLight,
                    //   () => onAction(appointment, 'reschedule'),
                    //   theme,
                    // ),
                    // _buildQuickActionButton(
                    //   context,
                    //   'Message',
                    //   'message',
                    //   AppTheme.primaryLight,
                    //   () => onAction(appointment, 'message'),
                    //   theme,
                    // ),
                    _buildQuickActionButton(
                      context,
                      'Edit',
                      'edit',
                      AppTheme.accentLight,
                      () => onAction(appointment, 'edit'),
                      theme,
                    ),
                    // _buildQuickActionButton(
                    //   context,
                    //   'Duplicate',
                    //   'content_copy',
                    //   AppTheme.secondaryLight,
                    //   () => onAction(appointment, 'duplicate'),
                    //   theme,
                    // ),
                    _buildQuickActionButton(
                      context,
                      'Cancel',
                      'cancel',
                      AppTheme.errorLight,
                      () => onAction(appointment, 'cancel'),
                      theme,
                    ),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(height: 4.h),

          // Primary Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => onAction(appointment, 'message'),
                  icon: CustomIconWidget(
                    iconName: 'message',
                    color: theme.colorScheme.primary,
                    size: 4.w,
                  ),
                  label: const Text('Message Client'),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 3.h),
                  ),
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: appointment['status'] == 'in_progress'
                    ? ElevatedButton.icon(
                        onPressed: () => onAction(appointment, 'check_out'),
                        icon: CustomIconWidget(
                          iconName: 'logout',
                          color: theme.colorScheme.onPrimary,
                          size: 4.w,
                        ),
                        label: const Text('Check Out'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.warningLight,
                          padding: EdgeInsets.symmetric(vertical: 3.h),
                        ),
                      )
                    : ElevatedButton.icon(
                        onPressed: () => onAction(appointment, 'check_in'),
                        icon: CustomIconWidget(
                          iconName: 'login',
                          color: theme.colorScheme.onPrimary,
                          size: 4.w,
                        ),
                        label: const Text('Check In'),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 3.h),
                        ),
                      ),
              ),
            ],
          ),

          SizedBox(height: 2.h),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value,
    String iconName,
    ThemeData theme,
  ) {
    return Padding(
      padding: EdgeInsets.only(bottom: 3.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 12.w,
            height: 12.w,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: CustomIconWidget(
                iconName: iconName,
                color: theme.colorScheme.primary,
                size: 6.w,
              ),
            ),
          ),
          SizedBox(width: 4.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(
    BuildContext context,
    String label,
    String iconName,
    Color color,
    VoidCallback onPressed,
    ThemeData theme,
  ) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(iconName: iconName, color: color, size: 6.w),
            SizedBox(height: 1.h),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }
}