import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';
import '../calendar_view.dart';

class CalendarHeaderWidget extends StatelessWidget {
  final CalendarViewMode currentViewMode;
  final DateTime focusedDate;
  final Function(CalendarViewMode) onViewModeChanged;
  final VoidCallback onTodayPressed;
  final VoidCallback onPreviousPeriod;
  final VoidCallback onNextPeriod;

  const CalendarHeaderWidget({
    super.key,
    required this.currentViewMode,
    required this.focusedDate,
    required this.onViewModeChanged,
    required this.onTodayPressed,
    required this.onPreviousPeriod,
    required this.onNextPeriod,
  });

  String _getFormattedPeriod() {
    switch (currentViewMode) {
      case CalendarViewMode.month:
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
        return '${months[focusedDate.month - 1]} ${focusedDate.year}';
      case CalendarViewMode.week:
        final startOfWeek = focusedDate.subtract(
          Duration(days: focusedDate.weekday - 1),
        );
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        if (startOfWeek.month == endOfWeek.month) {
          return '${startOfWeek.day}-${endOfWeek.day} ${_getMonthName(startOfWeek.month)} ${startOfWeek.year}';
        } else {
          return '${startOfWeek.day} ${_getMonthName(startOfWeek.month)} - ${endOfWeek.day} ${_getMonthName(endOfWeek.month)} ${endOfWeek.year}';
        }
      case CalendarViewMode.day:
        return '${focusedDate.day} ${_getMonthName(focusedDate.month)} ${focusedDate.year}';
    }
  }

  String _getMonthName(int month) {
    const months = [
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
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow,
            offset: const Offset(0, 2),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          // Top Row: View Mode Switcher and Today Button
          Row(
            children: [
              // View Mode Switcher
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildViewModeButton(
                      context,
                      CalendarViewMode.month,
                      'Month',
                      theme,
                    ),
                    _buildViewModeButton(
                      context,
                      CalendarViewMode.week,
                      'Week',
                      theme,
                    ),
                    _buildViewModeButton(
                      context,
                      CalendarViewMode.day,
                      'Day',
                      theme,
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Today Button
              TextButton.icon(
                onPressed: onTodayPressed,
                icon: CustomIconWidget(
                  iconName: 'today',
                  color: theme.colorScheme.primary,
                  size: 4.w,
                ),
                label: const Text('Today'),
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.primary,
                  padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                ),
              ),
            ],
          ),

          SizedBox(height: 2.h),

          // Bottom Row: Navigation and Period Display
          Row(
            children: [
              // Previous Button
              IconButton(
                onPressed: onPreviousPeriod,
                icon: CustomIconWidget(
                  iconName: 'chevron_left',
                  color: theme.colorScheme.onSurface,
                  size: 6.w,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary.withValues(
                    alpha: 0.1,
                  ),
                  padding: EdgeInsets.all(2.w),
                ),
              ),

              // Period Display
              Expanded(
                child: Center(
                  child: Text(
                    _getFormattedPeriod(),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ),

              // Next Button
              IconButton(
                onPressed: onNextPeriod,
                icon: CustomIconWidget(
                  iconName: 'chevron_right',
                  color: theme.colorScheme.onSurface,
                  size: 6.w,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary.withValues(
                    alpha: 0.1,
                  ),
                  padding: EdgeInsets.all(2.w),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildViewModeButton(
    BuildContext context,
    CalendarViewMode mode,
    String label,
    ThemeData theme,
  ) {
    final isSelected = currentViewMode == mode;

    return InkWell(
      onTap: () => onViewModeChanged(mode),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isSelected ? Colors.white : theme.colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
