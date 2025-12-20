import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';
import '../../../services/supabase_service.dart';

class DateTimePickerWidget extends StatefulWidget {
  final DateTime? startDate;
  final DateTime? endDate;
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;
  final Function(Map<String, dynamic>) onDateTimeSelected;

  const DateTimePickerWidget({
    super.key,
    this.startDate,
    this.endDate,
    this.startTime,
    this.endTime,
    required this.onDateTimeSelected,
  });

  @override
  State<DateTimePickerWidget> createState() => _DateTimePickerWidgetState();
}

class _DateTimePickerWidgetState extends State<DateTimePickerWidget> {
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;
  TimeOfDay? _selectedStartTime;
  TimeOfDay? _selectedEndTime;
  bool _isRecurring = false;
  String _recurringPattern = 'weekly';
  DateTime? _recurrenceEndDate;
  
  List<Map<String, dynamic>> _existingBookings = [];
  bool _isLoadingBookings = false;
  String? _conflictMessage;

  @override
  void initState() {
    super.initState();
    _selectedStartDate = widget.startDate;
    _selectedEndDate = widget.endDate;
    _selectedStartTime = widget.startTime;
    _selectedEndTime = widget.endTime;
    // Default recurrence end date to 1 month from now if not set
    _recurrenceEndDate = DateTime.now().add(const Duration(days: 30));
    _fetchBookings();
  }

  Future<void> _fetchBookings() async {
    setState(() {
      _isLoadingBookings = true;
    });
    try {
      final user = SupabaseService.instance.currentUser;
      if (user != null) {
        // Fetch all bookings for this sitter to check for conflicts
        final bookings = await SupabaseService.instance.getBookings(
          sitterId: user.id,
          // We can optionally filter by date range if we want to optimize, 
          // e.g. from today onwards.
          startDate: DateTime.now().subtract(const Duration(days: 1)),
        );
        if (mounted) {
          setState(() {
            _existingBookings = bookings;
            _isLoadingBookings = false;
          });
          // Re-validate in case we already have a selection that conflicts
          _updateDateTime(); 
        }
      }
    } catch (e) {
      debugPrint('Error fetching bookings: $e');
      if (mounted) {
        setState(() {
          _isLoadingBookings = false;
        });
      }
    }
  }

  bool _checkConflict() {
    if (_selectedStartDate == null ||
        _selectedStartTime == null ||
        _selectedEndTime == null) return false;

    // 1. Generate slots needed for the NEW booking
    List<DateTimeRange> proposedSlots = [];
    
    final startDateTime = DateTime(
      _selectedStartDate!.year,
      _selectedStartDate!.month,
      _selectedStartDate!.day,
      _selectedStartTime!.hour,
      _selectedStartTime!.minute,
    );
    
    final endDateTimeBase = DateTime(
       _selectedEndDate?.year ?? _selectedStartDate!.year,
       _selectedEndDate?.month ?? _selectedStartDate!.month,
       _selectedEndDate?.day ?? _selectedStartDate!.day,
       _selectedEndTime!.hour,
       _selectedEndTime!.minute,
    );
    
    final duration = endDateTimeBase.difference(startDateTime);

    // If new booking is recurring, look ahead a bit (e.g., 6 months or 50 occurrences)
    // to warn about conflicts in the series.
    if (_isRecurring && _recurrenceEndDate != null) {
      DateTime current = startDateTime;
      int limit = 50; 
      while (current.isBefore(_recurrenceEndDate!.add(const Duration(days: 1))) && limit > 0) {
        proposedSlots.add(DateTimeRange(start: current, end: current.add(duration)));
        
        if (_recurringPattern == 'daily') {
          current = current.add(const Duration(days: 1));
        } else if (_recurringPattern == 'weekly') {
           current = current.add(const Duration(days: 7));
        } else if (_recurringPattern == 'monthly') {
           var newMonth = current.month + 1;
           var newYear = current.year;
           if (newMonth > 12) { newMonth = 1; newYear++; }
           // Handle end of month edge cases simply for now
           var daysInNewMonth = DateUtils.getDaysInMonth(newYear, newMonth);
           var newDay = current.day > daysInNewMonth ? daysInNewMonth : current.day;
           current = DateTime(newYear, newMonth, newDay, current.hour, current.minute);
        }
        limit--;
      }
    } else {
       proposedSlots.add(DateTimeRange(start: startDateTime, end: endDateTimeBase));
    }

    // 2. Check against existing bookings
    for (var booking in _existingBookings) {
      if (booking['status'] == 'cancelled' || booking['status'] == 'declined') continue;

      final isExistingRecurring = booking['is_recurring'] == true;
      
      try {
        final bDateStr = booking['start_date'] as String;
        final bDate = DateTime.parse(bDateStr);
        final bStartTimeStr = (booking['start_time'] as String);
        final bTimeParts = bStartTimeStr.split(':');
        
        // Base start time on the booking's original date
        final bStartDateTime = DateTime(
            bDate.year, bDate.month, bDate.day, 
            int.parse(bTimeParts[0]), int.parse(bTimeParts[1])
        );
        
        // Calculate duration of the existing booking
        final bEndDateStr = (booking['end_date'] ?? booking['start_date']) as String;
        final bEndDate = DateTime.parse(bEndDateStr);
        final bEndTimeStr = (booking['end_time'] ?? booking['start_time']) as String;
        final bEndTimeParts = bEndTimeStr.split(':');
        final bEndDateTime = DateTime(
            bEndDate.year, bEndDate.month, bEndDate.day, 
            int.parse(bEndTimeParts[0]), int.parse(bEndTimeParts[1])
        );
        final bDuration = bEndDateTime.difference(bStartDateTime);
        
        final bRecurEndStr = booking['recurrence_end_date'] as String?;
        final bRecurEnd = bRecurEndStr != null 
            ? DateTime.parse(bRecurEndStr) 
            : bStartDateTime.add(const Duration(days: 365)); // Fallback
        
        final bRule = booking['recurrence_rule'] ?? 'weekly';

        for (var slot in proposedSlots) {
           if (!isExistingRecurring) {
              // Simple overlap check
              if (slot.start.isBefore(bEndDateTime) && slot.end.isAfter(bStartDateTime)) {
                 return true;
              }
           } else {
              // Existing booking is recurring.
              // We check if the 'slot' (which spans slot.start to slot.end) overlaps with ANY instance of 'booking'.
              // We generate instances of 'booking' for the dates involved in 'slot'.
              
              // Days to check: slot.start date and slot.end date
              final checkDates = {
                DateTime(slot.start.year, slot.start.month, slot.start.day),
                DateTime(slot.end.year, slot.end.month, slot.end.day)
              };

              for (var date in checkDates) {
                  // 1. Is date within recurrence range?
                  if (date.isBefore(DateTime(bDate.year, bDate.month, bDate.day))) continue;
                  if (date.isAfter(bRecurEnd.add(const Duration(days: 1)).subtract(const Duration(milliseconds: 1)))) continue;
                  
                  // 2. Does date match the pattern?
                  bool matches = false;
                  if (bRule == 'daily') {
                    matches = true;
                  } else if (bRule == 'weekly') {
                    matches = date.weekday == bDate.weekday;
                  } else if (bRule == 'monthly') {
                    matches = date.day == bDate.day;
                  }
                  
                  if (matches) {
                    // Reconstruct the booking instance on this specific date
                    // Note: This logic assumes "Time of Day" applies to the recurrence date.
                    final instanceStart = DateTime(
                      date.year, date.month, date.day,
                      bStartDateTime.hour, bStartDateTime.minute
                    );
                    final instanceEnd = instanceStart.add(bDuration);
                    
                    if (slot.start.isBefore(instanceEnd) && slot.end.isAfter(instanceStart)) {
                       return true; 
                    }
                  }
              }
           }
        }
      } catch (e) {
        // Skip malformed booking data
        continue;
      }
    }
    return false;
  }

  Future<void> _selectRecurrenceEndDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _recurrenceEndDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: _selectedStartDate ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );

    if (picked != null) {
      setState(() {
        _recurrenceEndDate = picked;
      });
      _updateDateTime();
    }
  }

    void _updateDateTime() {
    int duration = 0;
    _conflictMessage = null;

    if (_selectedStartDate != null &&
        _selectedStartTime != null &&
        _selectedEndTime != null) {
      final startDateTime = DateTime(
        _selectedStartDate!.year,
        _selectedStartDate!.month,
        _selectedStartDate!.day,
        _selectedStartTime!.hour,
        _selectedStartTime!.minute,
      );

      final endDateTime = DateTime(
        _selectedEndDate?.year ?? _selectedStartDate!.year,
        _selectedEndDate?.month ?? _selectedStartDate!.month,
        _selectedEndDate?.day ?? _selectedStartDate!.day,
        _selectedEndTime!.hour,
        _selectedEndTime!.minute,
      );

      duration = endDateTime.difference(startDateTime).inHours;
      if (duration < 0) duration = 0;

      // Check for conflicts
      if (_checkConflict()) {
        setState(() {
          _conflictMessage = "This slot is already occupied please use set other time";
        });
      } else {
        setState(() {
          _conflictMessage = null;
        });
      }
    }

    // If there is a conflict, we send null for startTime to prevent "Next"
    // but we allow the UI to show the selected (conflicted) time.
    final hasConflict = _conflictMessage != null;

    widget.onDateTimeSelected({
      'startDate': _selectedStartDate,
      'endDate': _selectedEndDate,
      'startTime': hasConflict ? null : _selectedStartTime, 
      'endTime': _selectedEndTime,
      'duration': duration,
      'isRecurring': _isRecurring,
      'recurringPattern': _recurringPattern,
      'recurrenceEndDate': _recurrenceEndDate,
    });
  }

  Future<void> _selectStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedStartDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        _selectedStartDate = picked;
        // If end date is before start date, update it
        if (_selectedEndDate != null && _selectedEndDate!.isBefore(picked)) {
          _selectedEndDate = picked;
        }
      });
      _updateDateTime();
    }
  }

  Future<void> _selectEndDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedEndDate ?? _selectedStartDate ?? DateTime.now(),
      firstDate: _selectedStartDate ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        _selectedEndDate = picked;
      });
      _updateDateTime();
    }
  }

  Future<void> _selectStartTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedStartTime ?? TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() {
        _selectedStartTime = picked;
        // Auto-set end time to 2 hours later if not set
        if (_selectedEndTime == null) {
          final endHour = (picked.hour + 2) % 24;
          _selectedEndTime = TimeOfDay(hour: endHour, minute: picked.minute);
        }
      });
      _updateDateTime();
    }
  }

  Future<void> _selectEndTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime:
          _selectedEndTime ??
          (_selectedStartTime != null
              ? TimeOfDay(
                hour: (_selectedStartTime!.hour + 2) % 24,
                minute: _selectedStartTime!.minute,
              )
              : TimeOfDay.now()),
    );

    if (picked != null) {
      setState(() {
        _selectedEndTime = picked;
      });
      _updateDateTime();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
            'Set the date and time for your service',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),

          SizedBox(height: 4.h),

          // Quick date selection
          _buildQuickDateSelection(context),

          SizedBox(height: 4.h),

          // Start date
          _buildDateTimeCard(
            context,
            'Start Date',
            _selectedStartDate != null
                ? _formatDate(_selectedStartDate!)
                : 'Select start date',
            'calendar_today',
            _selectStartDate,
            _selectedStartDate != null,
          ),

          SizedBox(height: 3.h),

          // End date (optional)
          _buildDateTimeCard(
            context,
            'End Date (Optional)',
            _selectedEndDate != null
                ? _formatDate(_selectedEndDate!)
                : 'Same as start date',
            'event',
            _selectEndDate,
            _selectedEndDate != null,
          ),

          SizedBox(height: 4.h),

          // Time selection
          Row(
            children: [
              Expanded(
                child: _buildDateTimeCard(
                  context,
                  'Start Time',
                  _selectedStartTime != null
                      ? _selectedStartTime!.format(context)
                      : 'Select time',
                  'schedule',
                  _selectStartTime,
                  _selectedStartTime != null,
                ),
              ),
              SizedBox(width: 4.w),
              Expanded(
                child: _buildDateTimeCard(
                  context,
                  'End Time',
                  _selectedEndTime != null
                      ? _selectedEndTime!.format(context)
                      : 'Select time',
                  'schedule',
                  _selectEndTime,
                  _selectedEndTime != null,
                ),
              ),
            ],
          ),

          SizedBox(height: 4.h),

          // Duration display
            if (_selectedStartTime != null && _selectedEndTime != null)
            Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  CustomIconWidget(
                    iconName: 'hourglass_empty',
                    color: theme.colorScheme.primary,
                    size: 5.w,
                  ),
                  SizedBox(width: 3.w),
                  Text(
                    'Duration: ${_calculateDuration()} hours',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

          if (_conflictMessage != null) ...[
            SizedBox(height: 2.h),
            Container(
              padding: EdgeInsets.all(3.w),
              width: double.infinity,
              decoration: BoxDecoration(
                color: theme.colorScheme.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.error.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  CustomIconWidget(
                    iconName: 'error_outline',
                    color: theme.colorScheme.error,
                    size: 5.w,
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Text(
                      _conflictMessage!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.error,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          SizedBox(height: 4.h),

          // Recurring booking option
          _buildRecurringSection(context),
        ],
      ),
    );
  }

  Widget _buildQuickDateSelection(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();

    final List<Map<String, dynamic>> quickOptions = [
      {'label': 'Today', 'date': now, 'icon': 'today'},
      {
        'label': 'Tomorrow',
        'date': now.add(const Duration(days: 1)),
        'icon': 'tomorrow',
      },
      {
        'label': 'This Weekend',
        'date': now.add(Duration(days: 6 - now.weekday)),
        'icon': 'weekend',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Selection',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 2.h),
        Row(
          children:
              quickOptions.map((option) {
                final isSelected =
                    _selectedStartDate != null &&
                    _isSameDay(_selectedStartDate!, option['date'] as DateTime);

                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedStartDate = option['date'] as DateTime;
                      });
                      _updateDateTime();
                      HapticFeedback.selectionClick();
                    },
                    child: Container(
                      margin: EdgeInsets.only(right: 2.w),
                      padding: EdgeInsets.symmetric(
                        vertical: 2.h,
                        horizontal: 2.w,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color:
                              isSelected
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.outline.withValues(
                                    alpha: 0.3,
                                  ),
                        ),
                      ),
                      child: Column(
                        children: [
                          CustomIconWidget(
                            iconName: option['icon'] as String,
                            color:
                                isSelected
                                    ? theme.colorScheme.onPrimary
                                    : theme.colorScheme.onSurface.withValues(
                                      alpha: 0.6,
                                    ),
                            size: 5.w,
                          ),
                          SizedBox(height: 1.h),
                          Text(
                            option['label'] as String,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color:
                                  isSelected
                                      ? theme.colorScheme.onPrimary
                                      : theme.colorScheme.onSurface.withValues(
                                        alpha: 0.8,
                                      ),
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }

  Widget _buildDateTimeCard(
    BuildContext context,
    String title,
    String value,
    String iconName,
    VoidCallback onTap,
    bool isSelected,
  ) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CustomIconWidget(
                  iconName: iconName,
                  color:
                      isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  size: 5.w,
                ),
                SizedBox(width: 3.w),
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            SizedBox(height: 1.h),
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                color:
                    isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecurringSection(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recurring Booking',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 2.h),

        SwitchListTile(
          title: const Text('Make this a recurring booking'),
          subtitle: const Text('Schedule regular appointments'),
          value: _isRecurring,
          onChanged: (value) {
            setState(() {
              _isRecurring = value;
            });
            _updateDateTime();
          },
          secondary: CustomIconWidget(
            iconName: 'repeat',
            color: theme.colorScheme.primary,
            size: 5.w,
          ),
        ),

        if (_isRecurring) ...[
          SizedBox(height: 2.h),
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Text(
                      'Repeat every:',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 2.h),
                Row(
                  children: [
                    _buildRecurringOption('daily', 'Daily'),
                    SizedBox(width: 3.w),
                    _buildRecurringOption('weekly', 'Weekly'),
                    SizedBox(width: 3.w),
                    _buildRecurringOption('monthly', 'Monthly'),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 2.h),
          _buildDateTimeCard(
            context,
            'Repeat Until',
            _recurrenceEndDate != null
                ? _formatDate(_recurrenceEndDate!)
                : 'Select end date',
            'event_repeat',
            _selectRecurrenceEndDate,
            _recurrenceEndDate != null,
          ),
        ],
      ],
    );
  }

  Widget _buildRecurringOption(String value, String label) {
    final theme = Theme.of(context);
    final isSelected = _recurringPattern == value;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _recurringPattern = value;
          });
          _updateDateTime();
        },
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 2.h),
          decoration: BoxDecoration(
            color:
                isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color:
                  isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline.withValues(alpha: 0.3),
            ),
          ),
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color:
                  isSelected
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
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
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  String _calculateDuration() {
    if (_selectedStartTime == null || _selectedEndTime == null) return '0';

    final startMinutes =
        _selectedStartTime!.hour * 60 + _selectedStartTime!.minute;
    final endMinutes = _selectedEndTime!.hour * 60 + _selectedEndTime!.minute;
    final diffMinutes = endMinutes - startMinutes;

    if (diffMinutes <= 0) return '0';

    final hours = diffMinutes / 60;
    return hours.toStringAsFixed(1);
  }
}
