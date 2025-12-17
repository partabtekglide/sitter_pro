import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class ConfirmationStep extends StatelessWidget {
  final Map<String, dynamic> bookingData;
  final Function(int) onEditStep;

  const ConfirmationStep({
    super.key,
    required this.bookingData,
    required this.onEditStep,
  });

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
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

  double get _totalAmount {
    final duration = bookingData['duration'] as int;
    final rate = bookingData['rate'] as double;
    return duration * rate;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final client = bookingData['client'] as Map<String, dynamic>?;
    final selectedDate = bookingData['selectedDate'] as DateTime?;
    final startTime = bookingData['startTime'] as TimeOfDay?;
    final endTime = bookingData['endTime'] as TimeOfDay?;

    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Booking Summary',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),

          SizedBox(height: 1.h),

          Text(
            'Review the details before creating the booking',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),

          SizedBox(height: 4.h),

          // Client Information
          _buildSectionCard(
            context,
            title: 'Client Information',
            stepIndex: 0,
            child:
                client != null
                    ? Row(
                      children: [
                        // Profile Image
                        Container(
                          width: 15.w,
                          height: 15.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: theme.colorScheme.outline.withValues(
                                alpha: 0.3,
                              ),
                              width: 1,
                            ),
                          ),
                          child: ClipOval(
                            child: CustomImageWidget(
                              imagePath: client['profileImage'],
                              semanticLabel:
                                  'Profile photo of ${client['name']}',
                              width: 15.w,
                              height: 15.w,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),

                        SizedBox(width: 4.w),

                        // Client Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                client['name'],
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              SizedBox(height: 0.5.h),
                              Text(
                                client['email'],
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.6,
                                  ),
                                ),
                              ),
                              SizedBox(height: 0.5.h),
                              Row(
                                children: [
                                  CustomIconWidget(
                                    iconName: 'phone',
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.6),
                                    size: 3.w,
                                  ),
                                  SizedBox(width: 1.w),
                                  Text(
                                    client['phone'],
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                    : const SizedBox.shrink(),
          ),

          SizedBox(height: 3.h),

          // Service Details
          _buildSectionCard(
            context,
            title: 'Service Details',
            stepIndex: 1,
            child: Column(
              children: [
                // Service Type
                Row(
                  children: [
                    Container(
                      width: 12.w,
                      height: 12.w,
                      decoration: BoxDecoration(
                        color: _getServiceColor(
                          bookingData['serviceType'],
                        ).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: CustomIconWidget(
                          iconName: _getServiceIcon(bookingData['serviceType']),
                          color: _getServiceColor(bookingData['serviceType']),
                          size: 6.w,
                        ),
                      ),
                    ),
                    SizedBox(width: 3.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getServiceName(bookingData['serviceType']),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            '${bookingData['duration']} hours at \$${bookingData['rate'].toStringAsFixed(2)}/hour',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.6,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                if (bookingData['specialInstructions'].isNotEmpty) ...[
                  SizedBox(height: 2.h),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(3.w),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: theme.colorScheme.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Special Instructions',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 1.h),
                        Text(
                          bookingData['specialInstructions'],
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.8,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          SizedBox(height: 3.h),

          // Schedule Information
          _buildSectionCard(
            context,
            title: 'Schedule',
            stepIndex: 2,
            child: Column(
              children: [
                // Date and Time
                Row(
                  children: [
                    Expanded(
                      child: _buildScheduleDetail(
                        context,
                        'Date',
                        selectedDate != null
                            ? _formatDate(selectedDate)
                            : 'Not selected',
                        'calendar_today',
                        theme,
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Expanded(
                      child: _buildScheduleDetail(
                        context,
                        'Time',
                        startTime != null && endTime != null
                            ? '${_formatTimeOfDay(startTime)} - ${_formatTimeOfDay(endTime)}'
                            : 'Not selected',
                        'access_time',
                        theme,
                      ),
                    ),
                  ],
                ),

                if (bookingData['isRecurring'] == true) ...[
                  SizedBox(height: 2.h),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(3.w),
                    decoration: BoxDecoration(
                      color: AppTheme.accentLight.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.accentLight.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        CustomIconWidget(
                          iconName: 'repeat',
                          color: AppTheme.accentLight,
                          size: 5.w,
                        ),
                        SizedBox(width: 3.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Recurring Booking',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.accentLight,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '${bookingData['recurringFrequency'].toString().toUpperCase()}${bookingData['recurringEndDate'] != null ? ' until ${_formatDate(bookingData['recurringEndDate'])}' : ''}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.6,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          SizedBox(height: 4.h),

          // Payment Summary
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: AppTheme.successLight.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.successLight.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CustomIconWidget(
                      iconName: 'attach_money',
                      color: AppTheme.successLight,
                      size: 6.w,
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      'Payment Summary',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppTheme.successLight,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 2.h),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Service Duration:',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.8,
                        ),
                      ),
                    ),
                    Text(
                      '${bookingData['duration']} hours',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 1.h),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Hourly Rate:',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.8,
                        ),
                      ),
                    ),
                    Text(
                      '\$${bookingData['rate'].toStringAsFixed(2)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 1.h),

                const Divider(),

                SizedBox(height: 1.h),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Amount:',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppTheme.successLight,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '\$${_totalAmount.toStringAsFixed(2)}',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: AppTheme.successLight,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(height: 10.h), // Extra space for bottom navigation
        ],
      ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required String title,
    required int stepIndex,
    required Widget child,
  }) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => onEditStep(stepIndex),
                  icon: CustomIconWidget(
                    iconName: 'edit',
                    color: theme.colorScheme.primary,
                    size: 4.w,
                  ),
                  label: const Text('Edit'),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      horizontal: 2.w,
                      vertical: 1.h,
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 2.h),

            // Section Content
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleDetail(
    BuildContext context,
    String label,
    String value,
    String iconName,
    ThemeData theme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CustomIconWidget(
              iconName: iconName,
              color: theme.colorScheme.primary,
              size: 4.w,
            ),
            SizedBox(width: 2.w),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        SizedBox(height: 0.5.h),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
