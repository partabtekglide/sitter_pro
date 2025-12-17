import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class MonthViewWidget extends StatelessWidget {
  final DateTime focusedDate;
  final DateTime selectedDate;
  final List<Map<String, dynamic>> appointments;
  final Function(DateTime) onDateSelected;
  final Function(Map<String, dynamic>) onAppointmentTap;
  final Function(DateTime?, TimeOfDay?) onQuickBooking;

  const MonthViewWidget({
    super.key,
    required this.focusedDate,
    required this.selectedDate,
    required this.appointments,
    required this.onDateSelected,
    required this.onAppointmentTap,
    required this.onQuickBooking,
  });

  List<Map<String, dynamic>> _getAppointmentsForDate(DateTime date) {
    return appointments.where((appointment) {
      final appointmentDate = appointment['date'] as DateTime;
      return appointmentDate.year == date.year &&
          appointmentDate.month == date.month &&
          appointmentDate.day == date.day;
    }).toList();
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

  List<DateTime> _getDaysInMonth(DateTime month) {
    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0);

    // Get the first day of the calendar grid (might be from previous month)
    final startOfGrid = firstDay.subtract(Duration(days: firstDay.weekday - 1));

    // Get the last day of the calendar grid (might be from next month)
    final endOfGrid = lastDay.add(Duration(days: 7 - lastDay.weekday));

    final days = <DateTime>[];
    var currentDay = startOfGrid;

    while (currentDay.isBefore(endOfGrid) ||
        currentDay.isAtSameMomentAs(endOfGrid)) {
      days.add(currentDay);
      currentDay = currentDay.add(const Duration(days: 1));
    }

    return days;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final daysInMonth = _getDaysInMonth(focusedDate);

    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(height: 2.h),

          // Week Day Headers
          Container(
            padding: EdgeInsets.symmetric(horizontal: 2.w),
            child: Row(
              children:
                  ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                      .map(
                        (day) => Expanded(
                          child: Center(
                            child: Text(
                              day,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.6,
                                ),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
            ),
          ),

          SizedBox(height: 1.h),

          // Calendar Grid
          Container(
            padding: EdgeInsets.symmetric(horizontal: 2.w),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 0.8,
                crossAxisSpacing: 1,
                mainAxisSpacing: 1,
              ),
              itemCount: daysInMonth.length,
              itemBuilder: (context, index) {
                final date = daysInMonth[index];
                return _buildCalendarCell(context, date, theme);
              },
            ),
          ),

          SizedBox(height: 3.h),

          // Selected Date Details
          if (_getAppointmentsForDate(selectedDate).isNotEmpty) ...[
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 2.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Appointments for ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  ..._getAppointmentsForDate(selectedDate).map(
                    (appointment) => _buildAppointmentCard(appointment, theme),
                  ),
                ],
              ),
            ),
          ],

          SizedBox(height: 10.h), // Extra space for FAB
        ],
      ),
    );
  }

  Widget _buildCalendarCell(
    BuildContext context,
    DateTime date,
    ThemeData theme,
  ) {
    final isCurrentMonth = date.month == focusedDate.month;
    final isSelected =
        date.year == selectedDate.year &&
        date.month == selectedDate.month &&
        date.day == selectedDate.day;
    final isToday =
        date.year == DateTime.now().year &&
        date.month == DateTime.now().month &&
        date.day == DateTime.now().day;

    final dayAppointments = _getAppointmentsForDate(date);
    final hasAppointments = dayAppointments.isNotEmpty;

    return InkWell(
      onTap: () {
        onDateSelected(date);
        HapticFeedback.lightImpact();
      },
      onLongPress: hasAppointments ? null : () => onQuickBooking(date, null),
      child: Container(
        margin: EdgeInsets.all(0.5.w),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? theme.colorScheme.primary
                  : isToday
                  ? theme.colorScheme.primary.withValues(alpha: 0.1)
                  : null,
          borderRadius: BorderRadius.circular(8),
          border:
              isToday && !isSelected
                  ? Border.all(color: theme.colorScheme.primary, width: 1)
                  : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Date Number
            Text(
              '${date.day}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color:
                    isSelected
                        ? Colors.white
                        : isCurrentMonth
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.onSurface.withValues(alpha: 0.3),
                fontWeight:
                    isToday || isSelected ? FontWeight.w700 : FontWeight.w400,
              ),
            ),

            SizedBox(height: 0.5.h),

            // Appointment Indicators
            if (hasAppointments)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children:
                    dayAppointments.take(3).map((appointment) {
                      return Container(
                        width: 1.w,
                        height: 1.w,
                        margin: EdgeInsets.symmetric(horizontal: 0.5.w),
                        decoration: BoxDecoration(
                          color:
                              isSelected
                                  ? Colors.white
                                  : _getServiceColor(
                                    appointment['serviceType'],
                                  ),
                          shape: BoxShape.circle,
                        ),
                      );
                    }).toList(),
              ),

            // More Indicator
            if (dayAppointments.length > 3)
              Text(
                '+${dayAppointments.length - 3}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color:
                      isSelected
                          ? Colors.white
                          : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  fontSize: 8.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentCard(
    Map<String, dynamic> appointment,
    ThemeData theme,
  ) {
    final startTime = appointment['startTime'] as TimeOfDay;
    final endTime = appointment['endTime'] as TimeOfDay;
    final serviceColor = _getServiceColor(appointment['serviceType']);

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      child: InkWell(
        onTap: () => onAppointmentTap(appointment),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(4.w),
          child: Row(
            children: [
              // Service Color Indicator
              Container(
                width: 1.w,
                height: 15.w,
                decoration: BoxDecoration(
                  color: serviceColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              SizedBox(width: 4.w),

              // Appointment Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            appointment['clientName'],
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 2.w,
                            vertical: 0.5.h,
                          ),
                          decoration: BoxDecoration(
                            color: serviceColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
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

                    SizedBox(height: 1.h),

                    Row(
                      children: [
                        CustomIconWidget(
                          iconName: 'access_time',
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                          size: 4.w,
                        ),
                        SizedBox(width: 2.w),
                        Text(
                          '${_formatTimeOfDay(startTime)} - ${_formatTimeOfDay(endTime)}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.8,
                            ),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '\$${appointment['amount'].toStringAsFixed(2)}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: serviceColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }
}
