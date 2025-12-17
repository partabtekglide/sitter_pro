import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class DayViewWidget extends StatelessWidget {
  final DateTime selectedDate;
  final List<Map<String, dynamic>> appointments;
  final Function(Map<String, dynamic>) onAppointmentTap;
  final Function(Map<String, dynamic>, String) onAppointmentAction;
  final Function(DateTime?, TimeOfDay?) onQuickBooking;

  const DayViewWidget({
    super.key,
    required this.selectedDate,
    required this.appointments,
    required this.onAppointmentTap,
    required this.onAppointmentAction,
    required this.onQuickBooking,
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

  List<TimeOfDay> _getAvailableTimeSlots() {
    final slots = <TimeOfDay>[];

    for (int hour = 6; hour < 24; hour++) {
      for (int minute in [0, 30]) {
        final timeSlot = TimeOfDay(hour: hour, minute: minute);

        // Check if this time slot is occupied
        final isOccupied = appointments.any((appointment) {
          final startTime = appointment['startTime'] as TimeOfDay;
          final endTime = appointment['endTime'] as TimeOfDay;
          final startMinutes = startTime.hour * 60 + startTime.minute;
          final endMinutes = endTime.hour * 60 + endTime.minute;
          final slotMinutes = timeSlot.hour * 60 + timeSlot.minute;

          return slotMinutes >= startMinutes && slotMinutes < endMinutes;
        });

        if (!isOccupied) {
          slots.add(timeSlot);
        }
      }
    }

    return slots;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sortedAppointments = List<Map<String, dynamic>>.from(appointments);

    // Sort appointments by start time
    sortedAppointments.sort((a, b) {
      final aTime = a['startTime'] as TimeOfDay;
      final bTime = b['startTime'] as TimeOfDay;
      final aMinutes = aTime.hour * 60 + aTime.minute;
      final bMinutes = bTime.hour * 60 + bTime.minute;
      return aMinutes.compareTo(bMinutes);
    });

    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date Header
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 12.w,
                  height: 12.w,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: CustomIconWidget(
                      iconName: 'calendar_today',
                      color: Colors.white,
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
                        _formatDate(selectedDate),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        '${appointments.length} appointment${appointments.length == 1 ? '' : 's'}',
                        style: theme.textTheme.bodyMedium?.copyWith(
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

          SizedBox(height: 3.h),

          // Appointments List
          if (sortedAppointments.isNotEmpty) ...[
            Text(
              'Schedule',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 2.h),
            ...sortedAppointments.map(
              (appointment) =>
                  _buildDetailedAppointmentCard(appointment, theme),
            ),
          ] else ...[
            // No Appointments Message
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(8.w),
              child: Column(
                children: [
                  CustomIconWidget(
                    iconName: 'event_available',
                    color: theme.colorScheme.outline,
                    size: 20.w,
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    'No appointments today',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    'Tap the + button to create a new booking',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],

          SizedBox(height: 4.h),

          // Available Time Slots
          if (_getAvailableTimeSlots().isNotEmpty) ...[
            Text(
              'Available Time Slots',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 2.h),
            Wrap(
              spacing: 2.w,
              runSpacing: 1.h,
              children:
                  _getAvailableTimeSlots().take(12).map((timeSlot) {
                    return InkWell(
                      onTap: () => onQuickBooking(selectedDate, timeSlot),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 4.w,
                          vertical: 2.h,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.1,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.3,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CustomIconWidget(
                              iconName: 'access_time',
                              color: theme.colorScheme.primary,
                              size: 4.w,
                            ),
                            SizedBox(width: 2.w),
                            Text(
                              _formatTimeOfDay(timeSlot),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
            ),
          ],

          SizedBox(height: 10.h), // Extra space for FAB
        ],
      ),
    );
  }

  Widget _buildDetailedAppointmentCard(
    Map<String, dynamic> appointment,
    ThemeData theme,
  ) {
    final serviceColor = _getServiceColor(appointment['serviceType']);
    final startTime = appointment['startTime'] as TimeOfDay;
    final endTime = appointment['endTime'] as TimeOfDay;

    return Card(
      margin: EdgeInsets.only(bottom: 3.h),
      child: InkWell(
        onTap: () => onAppointmentTap(appointment),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: serviceColor.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  // Profile Image
                  Container(
                    width: 15.w,
                    height: 15.w,
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
                        width: 15.w,
                        height: 15.w,
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
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        SizedBox(height: 0.5.h),
                        Row(
                          children: [
                            CustomIconWidget(
                              iconName: _getServiceIcon(
                                appointment['serviceType'],
                              ),
                              color: serviceColor,
                              size: 4.w,
                            ),
                            SizedBox(width: 2.w),
                            Text(
                              _getServiceName(appointment['serviceType']),
                              style: theme.textTheme.bodyMedium?.copyWith(
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
                    padding: EdgeInsets.symmetric(
                      horizontal: 3.w,
                      vertical: 1.h,
                    ),
                    decoration: BoxDecoration(
                      color: serviceColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      appointment['status'].toString().toUpperCase(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: serviceColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 10.sp,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 3.h),

              // Time and Amount Row
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 10.w,
                          height: 10.w,
                          decoration: BoxDecoration(
                            color: serviceColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: CustomIconWidget(
                              iconName: 'access_time',
                              color: serviceColor,
                              size: 5.w,
                            ),
                          ),
                        ),
                        SizedBox(width: 3.w),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Time',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.6,
                                ),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '${_formatTimeOfDay(startTime)} - ${_formatTimeOfDay(endTime)}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Amount
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Amount',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '\$${appointment['amount'].toStringAsFixed(2)}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: serviceColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              if (appointment['notes'] != null &&
                  appointment['notes'].isNotEmpty) ...[
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
                        'Notes',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        appointment['notes'],
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

              SizedBox(height: 3.h),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed:
                          () => onAppointmentAction(appointment, 'message'),
                      icon: CustomIconWidget(
                        iconName: 'message',
                        color: theme.colorScheme.primary,
                        size: 4.w,
                      ),
                      label: const Text('Message'),
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed:
                          () => onAppointmentAction(appointment, 'check_in'),
                      icon: CustomIconWidget(
                        iconName: 'login',
                        color: theme.colorScheme.onPrimary,
                        size: 4.w,
                      ),
                      label: const Text('Check In'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    return '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }
}