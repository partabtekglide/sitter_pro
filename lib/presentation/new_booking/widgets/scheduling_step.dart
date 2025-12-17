import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class SchedulingStep extends StatefulWidget {
  final DateTime? selectedDate;
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;
  final bool isRecurring;
  final String recurringFrequency;
  final DateTime? recurringEndDate;
  final Function(DateTime) onDateSelected;
  final Function(TimeOfDay) onStartTimeSelected;
  final Function(TimeOfDay) onEndTimeSelected;
  final Function(bool) onRecurringToggled;
  final Function(String) onRecurringFrequencyChanged;
  final Function(DateTime) onRecurringEndDateSelected;

  const SchedulingStep({
    super.key,
    required this.selectedDate,
    required this.startTime,
    required this.endTime,
    required this.isRecurring,
    required this.recurringFrequency,
    required this.recurringEndDate,
    required this.onDateSelected,
    required this.onStartTimeSelected,
    required this.onEndTimeSelected,
    required this.onRecurringToggled,
    required this.onRecurringFrequencyChanged,
    required this.onRecurringEndDateSelected,
  });

  @override
  State<SchedulingStep> createState() => _SchedulingStepState();
}

class _SchedulingStepState extends State<SchedulingStep> {
  final List<Map<String, dynamic>> _existingBookings = [
    {
      'date': DateTime.now().add(const Duration(days: 1)),
      'startTime': const TimeOfDay(hour: 14, minute: 0),
      'endTime': const TimeOfDay(hour: 18, minute: 0),
      'clientName': 'Sarah Johnson',
    },
    {
      'date': DateTime.now().add(const Duration(days: 3)),
      'startTime': const TimeOfDay(hour: 9, minute: 0),
      'endTime': const TimeOfDay(hour: 12, minute: 0),
      'clientName': 'Mike Chen',
    },
  ];

  final List<String> _recurringOptions = ['daily', 'weekly', 'monthly'];

  bool _hasConflict() {
    if (widget.selectedDate == null ||
        widget.startTime == null ||
        widget.endTime == null) {
      return false;
    }

    final selectedDateTime = DateTime(
      widget.selectedDate!.year,
      widget.selectedDate!.month,
      widget.selectedDate!.day,
    );

    for (final booking in _existingBookings) {
      final bookingDate = DateTime(
        booking['date'].year,
        booking['date'].month,
        booking['date'].day,
      );

      if (selectedDateTime.isAtSameMomentAs(bookingDate)) {
        final bookingStart = booking['startTime'] as TimeOfDay;
        final bookingEnd = booking['endTime'] as TimeOfDay;

        final selectedStart = widget.startTime!;
        final selectedEnd = widget.endTime!;

        // Convert to minutes for easier comparison
        final bookingStartMinutes =
            bookingStart.hour * 60 + bookingStart.minute;
        final bookingEndMinutes = bookingEnd.hour * 60 + bookingEnd.minute;
        final selectedStartMinutes =
            selectedStart.hour * 60 + selectedStart.minute;
        final selectedEndMinutes = selectedEnd.hour * 60 + selectedEnd.minute;

        // Check for overlap
        if (selectedStartMinutes < bookingEndMinutes &&
            selectedEndMinutes > bookingStartMinutes) {
          return true;
        }
      }
    }
    return false;
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasConflict = _hasConflict();

    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Schedule Booking',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),

          SizedBox(height: 1.h),

          Text(
            'Select date and time for the appointment',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),

          SizedBox(height: 4.h),

          // Date Selection
          Text(
            'Date',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),

          SizedBox(height: 2.h),

          InkWell(
            onTap: () async {
              final selectedDate = await showDatePicker(
                context: context,
                initialDate:
                    widget.selectedDate ??
                    DateTime.now().add(const Duration(days: 1)),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
                builder: (context, child) {
                  return Theme(
                    data: theme.copyWith(
                      colorScheme: theme.colorScheme.copyWith(
                        primary: theme.colorScheme.primary,
                        onPrimary: theme.colorScheme.onPrimary,
                      ),
                    ),
                    child: child!,
                  );
                },
              );

              if (selectedDate != null) {
                widget.onDateSelected(selectedDate);
                HapticFeedback.lightImpact();
              }
            },
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                border: Border.all(
                  color:
                      widget.selectedDate != null
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline.withValues(alpha: 0.5),
                  width: widget.selectedDate != null ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(12),
                color:
                    widget.selectedDate != null
                        ? theme.colorScheme.primary.withValues(alpha: 0.05)
                        : null,
              ),
              child: Row(
                children: [
                  Container(
                    width: 12.w,
                    height: 12.w,
                    decoration: BoxDecoration(
                      color:
                          widget.selectedDate != null
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outline.withValues(
                                alpha: 0.3,
                              ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: CustomIconWidget(
                        iconName: 'calendar_today',
                        color:
                            widget.selectedDate != null
                                ? Colors.white
                                : theme.colorScheme.outline,
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
                          widget.selectedDate != null
                              ? 'Selected Date'
                              : 'Select Date',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.6,
                            ),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (widget.selectedDate != null) ...[
                          SizedBox(height: 0.5.h),
                          Text(
                            '${widget.selectedDate!.day}/${widget.selectedDate!.month}/${widget.selectedDate!.year}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  CustomIconWidget(
                    iconName: 'arrow_forward_ios',
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    size: 4.w,
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 4.h),

          // Time Selection
          Text(
            'Time',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),

          SizedBox(height: 2.h),

          Row(
            children: [
              // Start Time
              Expanded(
                child: _buildTimeSelector(
                  context,
                  'Start Time',
                  widget.startTime,
                  (time) {
                    widget.onStartTimeSelected(time);
                    HapticFeedback.lightImpact();
                  },
                  theme,
                ),
              ),

              SizedBox(width: 4.w),

              // End Time
              Expanded(
                child: _buildTimeSelector(context, 'End Time', widget.endTime, (
                  time,
                ) {
                  widget.onEndTimeSelected(time);
                  HapticFeedback.lightImpact();
                }, theme),
              ),
            ],
          ),

          SizedBox(height: 3.h),

          // Conflict Warning
          if (hasConflict)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: AppTheme.errorLight.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.errorLight.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  CustomIconWidget(
                    iconName: 'warning',
                    color: AppTheme.errorLight,
                    size: 6.w,
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Scheduling Conflict',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: AppTheme.errorLight,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 0.5.h),
                        Text(
                          'This time slot conflicts with an existing booking',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.errorLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          SizedBox(height: 4.h),

          // Recurring Booking Toggle
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recurring Booking',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      'Set up a repeating schedule',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: widget.isRecurring,
                onChanged: (value) {
                  widget.onRecurringToggled(value);
                  HapticFeedback.lightImpact();
                },
              ),
            ],
          ),

          // Recurring Options
          if (widget.isRecurring) ...[
            SizedBox(height: 3.h),

            // Frequency Selection
            Text(
              'Frequency',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),

            SizedBox(height: 2.h),

            Row(
              children:
                  _recurringOptions.map((option) {
                    final isSelected = widget.recurringFrequency == option;
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: option != _recurringOptions.last ? 2.w : 0,
                        ),
                        child: InkWell(
                          onTap: () {
                            widget.onRecurringFrequencyChanged(option);
                            HapticFeedback.lightImpact();
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 3.h),
                            decoration: BoxDecoration(
                              color:
                                  isSelected
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.outline.withValues(
                                        alpha: 0.1,
                                      ),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color:
                                    isSelected
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.outline.withValues(
                                          alpha: 0.3,
                                        ),
                              ),
                            ),
                            child: Text(
                              option.toUpperCase(),
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color:
                                    isSelected
                                        ? Colors.white
                                        : theme.colorScheme.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
            ),

            SizedBox(height: 3.h),

            // End Date for Recurring
            InkWell(
              onTap: () async {
                final endDate = await showDatePicker(
                  context: context,
                  initialDate:
                      widget.recurringEndDate ??
                      DateTime.now().add(const Duration(days: 30)),
                  firstDate: widget.selectedDate ?? DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );

                if (endDate != null) {
                  widget.onRecurringEndDateSelected(endDate);
                  HapticFeedback.lightImpact();
                }
              },
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.5),
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    CustomIconWidget(
                      iconName: 'event',
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      size: 6.w,
                    ),
                    SizedBox(width: 3.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'End Date',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.6,
                              ),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (widget.recurringEndDate != null) ...[
                            SizedBox(height: 0.5.h),
                            Text(
                              '${widget.recurringEndDate!.day}/${widget.recurringEndDate!.month}/${widget.recurringEndDate!.year}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    CustomIconWidget(
                      iconName: 'arrow_forward_ios',
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      size: 4.w,
                    ),
                  ],
                ),
              ),
            ),
          ],

          SizedBox(height: 10.h), // Extra space for bottom navigation
        ],
      ),
    );
  }

  Widget _buildTimeSelector(
    BuildContext context,
    String label,
    TimeOfDay? selectedTime,
    Function(TimeOfDay) onTimeSelected,
    ThemeData theme,
  ) {
    return InkWell(
      onTap: () async {
        final time = await showTimePicker(
          context: context,
          initialTime: selectedTime ?? const TimeOfDay(hour: 9, minute: 0),
          builder: (context, child) {
            return Theme(
              data: theme.copyWith(
                colorScheme: theme.colorScheme.copyWith(
                  primary: theme.colorScheme.primary,
                  onPrimary: theme.colorScheme.onPrimary,
                ),
              ),
              child: child!,
            );
          },
        );

        if (time != null) {
          onTimeSelected(time);
        }
      },
      child: Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          border: Border.all(
            color:
                selectedTime != null
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline.withValues(alpha: 0.5),
            width: selectedTime != null ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color:
              selectedTime != null
                  ? theme.colorScheme.primary.withValues(alpha: 0.05)
                  : null,
        ),
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
            SizedBox(height: 1.h),
            Row(
              children: [
                CustomIconWidget(
                  iconName: 'access_time',
                  color:
                      selectedTime != null
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline,
                  size: 5.w,
                ),
                SizedBox(width: 2.w),
                Text(
                  selectedTime != null
                      ? _formatTimeOfDay(selectedTime)
                      : 'Select',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color:
                        selectedTime != null
                            ? theme.colorScheme.onSurface
                            : theme.colorScheme.onSurface.withValues(
                              alpha: 0.6,
                            ),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
