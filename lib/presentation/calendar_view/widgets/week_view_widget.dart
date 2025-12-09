import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class WeekViewWidget extends StatelessWidget {
  final DateTime focusedDate;
  final DateTime selectedDate;
  final List<Map<String, dynamic>> appointments;
  final Function(DateTime) onDateSelected;
  final Function(Map<String, dynamic>) onAppointmentTap;
  final Function(Map<String, dynamic>, String) onAppointmentAction;
  final Function(DateTime?, TimeOfDay?) onQuickBooking;

  const WeekViewWidget({
    super.key,
    required this.focusedDate,
    required this.selectedDate,
    required this.appointments,
    required this.onDateSelected,
    required this.onAppointmentTap,
    required this.onAppointmentAction,
    required this.onQuickBooking,
  });

  List<DateTime> _getWeekDays() {
    final startOfWeek = focusedDate.subtract(
      Duration(days: focusedDate.weekday - 1),
    );
    return List.generate(7, (index) => startOfWeek.add(Duration(days: index)));
  }

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

  double _getAppointmentPosition(TimeOfDay time) {
    final totalMinutes = time.hour * 60 + time.minute;
    const startHour = 6; // 6 AM
    const endHour = 24; // 12 AM (midnight)
    const totalHours = endHour - startHour;

    final position = (totalMinutes - (startHour * 60)) / (totalHours * 60);
    return position.clamp(0.0, 1.0);
  }

  double _getAppointmentHeight(TimeOfDay startTime, TimeOfDay endTime) {
    final startMinutes = startTime.hour * 60 + startTime.minute;
    final endMinutes = endTime.hour * 60 + endTime.minute;
    final durationMinutes = endMinutes - startMinutes;

    const totalHours = 18; // 6 AM to 12 AM
    return (durationMinutes / (totalHours * 60)).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final weekDays = _getWeekDays();

    return Column(
      children: [
        SizedBox(height: 2.h),

        // Week Days Header
        Container(
          height: 12.w,
          padding: EdgeInsets.symmetric(horizontal: 2.w),
          child: Row(
            children:
                weekDays.map((date) {
                  final isSelected =
                      date.year == selectedDate.year &&
                      date.month == selectedDate.month &&
                      date.day == selectedDate.day;
                  final isToday =
                      date.year == DateTime.now().year &&
                      date.month == DateTime.now().month &&
                      date.day == DateTime.now().day;

                  final dayAppointments = _getAppointmentsForDate(date);

                  return Expanded(
                    child: InkWell(
                      onTap: () {
                        onDateSelected(date);
                        HapticFeedback.lightImpact();
                      },
                      onLongPress: () => onQuickBooking(date, null),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        margin: EdgeInsets.symmetric(horizontal: 1.w),
                        decoration: BoxDecoration(
                          color:
                              isSelected
                                  ? theme.colorScheme.primary
                                  : isToday
                                  ? theme.colorScheme.primary.withValues(
                                    alpha: 0.1,
                                  )
                                  : null,
                          borderRadius: BorderRadius.circular(8),
                          border:
                              isToday && !isSelected
                                  ? Border.all(
                                    color: theme.colorScheme.primary,
                                    width: 1,
                                  )
                                  : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              [
                                'Mon',
                                'Tue',
                                'Wed',
                                'Thu',
                                'Fri',
                                'Sat',
                                'Sun',
                              ][date.weekday - 1],
                              style: theme.textTheme.bodySmall?.copyWith(
                                color:
                                    isSelected
                                        ? Colors.white
                                        : theme.colorScheme.onSurface
                                            .withValues(alpha: 0.6),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 0.5.h),
                            Text(
                              '${date.day}',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color:
                                    isSelected
                                        ? Colors.white
                                        : theme.colorScheme.onSurface,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (dayAppointments.isNotEmpty) ...[
                              SizedBox(height: 0.5.h),
                              Container(
                                width: 1.5.w,
                                height: 1.5.w,
                                decoration: BoxDecoration(
                                  color:
                                      isSelected
                                          ? Colors.white
                                          : theme.colorScheme.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
          ),
        ),

        SizedBox(height: 2.h),

        // Timeline View
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Time Labels
              Container(
                width: 15.w,
                child: Column(
                  children: List.generate(19, (index) {
                    final hour = index + 6; // Start from 6 AM
                    return Container(
                      height: 8.h,
                      alignment: Alignment.topRight,
                      padding: EdgeInsets.only(right: 2.w, top: 1.h),
                      child: Text(
                        hour == 12
                            ? '12 PM'
                            : hour > 12
                            ? '${hour - 12} PM'
                            : hour == 0
                            ? '12 AM'
                            : '$hour AM',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }),
                ),
              ),

              // Week Timeline
              Expanded(
                child: SingleChildScrollView(
                  child: Container(
                    height: 19 * 8.h, // 19 hours from 6 AM to 1 AM
                    child: Row(
                      children:
                          weekDays.map((date) {
                            final dayAppointments = _getAppointmentsForDate(
                              date,
                            );

                            return Expanded(
                              child: Container(
                                margin: EdgeInsets.symmetric(horizontal: 0.5.w),
                                decoration: BoxDecoration(
                                  border: Border(
                                    left: BorderSide(
                                      color: theme.colorScheme.outline
                                          .withValues(alpha: 0.2),
                                      width: 1,
                                    ),
                                  ),
                                ),
                                child: Stack(
                                  children: [
                                    // Hour Lines
                                    ...List.generate(19, (index) {
                                      return Positioned(
                                        top: index * 8.h,
                                        left: 0,
                                        right: 0,
                                        child: Container(
                                          height: 1,
                                          color: theme.colorScheme.outline
                                              .withValues(alpha: 0.1),
                                        ),
                                      );
                                    }),

                                    // Appointments
                                    ...dayAppointments.map((appointment) {
                                      final startTime =
                                          appointment['startTime'] as TimeOfDay;
                                      final endTime =
                                          appointment['endTime'] as TimeOfDay;
                                      final position = _getAppointmentPosition(
                                        startTime,
                                      );
                                      final height = _getAppointmentHeight(
                                        startTime,
                                        endTime,
                                      );

                                      return Positioned(
                                        top: position * 19 * 8.h,
                                        left: 1.w,
                                        right: 1.w,
                                        height: height * 19 * 8.h,
                                        child: _buildAppointmentBlock(
                                          appointment,
                                          theme,
                                        ),
                                      );
                                    }),

                                    // Quick Book Areas (tap empty space)
                                    ...List.generate(19, (index) {
                                      final hour = index + 6;
                                      final timeSlot = TimeOfDay(
                                        hour: hour,
                                        minute: 0,
                                      );

                                      // Check if this time slot is occupied
                                      final isOccupied = dayAppointments.any((
                                        appointment,
                                      ) {
                                        final startTime =
                                            appointment['startTime']
                                                as TimeOfDay;
                                        final endTime =
                                            appointment['endTime'] as TimeOfDay;
                                        final startMinutes =
                                            startTime.hour * 60 +
                                            startTime.minute;
                                        final endMinutes =
                                            endTime.hour * 60 + endTime.minute;
                                        final slotMinutes =
                                            timeSlot.hour * 60 +
                                            timeSlot.minute;

                                        return slotMinutes >= startMinutes &&
                                            slotMinutes < endMinutes;
                                      });

                                      if (!isOccupied) {
                                        return Positioned(
                                          top: index * 8.h,
                                          left: 0,
                                          right: 0,
                                          height: 8.h,
                                          child: InkWell(
                                            onTap:
                                                () => onQuickBooking(
                                                  date,
                                                  timeSlot,
                                                ),
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: Colors.transparent,
                                              ),
                                            ),
                                          ),
                                        );
                                      }

                                      return const SizedBox.shrink();
                                    }),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAppointmentBlock(
    Map<String, dynamic> appointment,
    ThemeData theme,
  ) {
    final serviceColor = _getServiceColor(appointment['serviceType']);
    final startTime = appointment['startTime'] as TimeOfDay;
    final endTime = appointment['endTime'] as TimeOfDay;

    return InkWell(
      onTap: () => onAppointmentTap(appointment),
      onLongPress: () => _showAppointmentActions(appointment),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        decoration: BoxDecoration(
          color: serviceColor,
          borderRadius: BorderRadius.circular(6),
          boxShadow: [
            BoxShadow(
              color: serviceColor.withValues(alpha: 0.3),
              offset: const Offset(0, 2),
              blurRadius: 4,
            ),
          ],
        ),
        padding: EdgeInsets.all(2.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              appointment['clientName'],
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 0.5.h),
            Text(
              '${_formatTimeOfDay(startTime)} - ${_formatTimeOfDay(endTime)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 10.sp,
              ),
            ),
            SizedBox(height: 0.5.h),
            Text(
              appointment['serviceType']
                  .toString()
                  .replaceAll('_', ' ')
                  .toUpperCase(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 9.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAppointmentActions(Map<String, dynamic> appointment) {
    // This would show a context menu with quick actions
    // For now, we'll just trigger the main appointment action
    onAppointmentAction(appointment, 'edit');
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }
}
