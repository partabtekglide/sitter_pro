import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_bottom_bar.dart';
import './widgets/appointment_card_widget.dart';
import './widgets/calendar_header_widget.dart';
import './widgets/day_view_widget.dart';
import './widgets/month_view_widget.dart';
import './widgets/week_view_widget.dart';

import '../../services/supabase_service.dart';

enum CalendarViewMode { month, week, day }

class CalendarView extends StatefulWidget {
  const CalendarView({super.key});

  @override
  State<CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<CalendarView>
    with TickerProviderStateMixin {
  late TabController _tabController;
  CalendarViewMode _currentViewMode = CalendarViewMode.month;
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedDate = DateTime.now();
  bool _isRefreshing = false;

  // Appointment data
  List<Map<String, dynamic>> _appointments = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _fetchBookings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _getAppointmentsForDate(DateTime date) {
    return _appointments.where((appointment) {
      final appointmentDate = appointment['date'] as DateTime;
      return appointmentDate.year == date.year &&
          appointmentDate.month == date.month &&
          appointmentDate.day == date.day;
    }).toList();
  }

  List<Map<String, dynamic>> _getAppointmentsForWeek(DateTime startOfWeek) {
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    return _appointments.where((appointment) {
      final appointmentDate = appointment['date'] as DateTime;
      return appointmentDate.isAfter(
            startOfWeek.subtract(const Duration(days: 1)),
          ) &&
          appointmentDate.isBefore(endOfWeek.add(const Duration(days: 1)));
    }).toList();
  }

  List<Map<String, dynamic>> _getAppointmentsForMonth(DateTime month) {
    return _appointments.where((appointment) {
      final appointmentDate = appointment['date'] as DateTime;
      return appointmentDate.year == month.year &&
          appointmentDate.month == month.month;
    }).toList();
  }

  Future<void> _fetchBookings() async {
    setState(() {
      _isRefreshing = true;
    });

    try {
      final rawBookings = await SupabaseService.instance.getBookings();
      final List<Map<String, dynamic>> loadedAppointments = [];

      for (var booking in rawBookings) {
        final client = booking['clients'] ?? {};
        final isRecurring = booking['is_recurring'] == true;
        final startDate = DateTime.parse(booking['start_date']);
        final startTime = _parseTime(booking['start_time']);
        final endTime = _parseTime(booking['end_time'] ?? booking['start_time']);

        final baseAppointment = {
          'id': booking['id'],
          'clientName': client['full_name'] ?? 'Unknown Client',
          'clientInitials': _getInitials(client['full_name'] ?? 'Client'),
          'serviceType': booking['service_type'] ?? 'service',
          'startTime': startTime,
          'endTime': endTime,
          'status': booking['status'] ?? 'pending',
          'amount': (booking['total_amount'] as num?)?.toDouble() ?? 0.0,
          'hourlyRate': (booking['hourly_rate'] as num?)?.toDouble() ?? 0.0,
          'clientPhone': client['phone'] ?? '',
          'address': booking['address'] ?? '',
          'notes': booking['special_instructions'] ?? '',
          'is_recurring': isRecurring,
          'profileImage': client['avatar_url'] ??
              'https://images.unsplash.com/photo-1704541840921-106a1106cbb0',
        };

        if (isRecurring) {
          final recurrenceRule = booking['recurrence_rule'] as String?;
          final recurrenceEndDateStr = booking['recurrence_end_date'] as String?;
          final recurrenceEndDate = recurrenceEndDateStr != null
              ? DateTime.parse(recurrenceEndDateStr)
              : startDate.add(const Duration(days: 365)); // Default 1 year

          loadedAppointments.addAll(_generateRecurringAppointments(
            baseAppointment,
            startDate,
            recurrenceRule,
            recurrenceEndDate,
          ));
        } else {
          loadedAppointments.add({
            ...baseAppointment,
            'date': startDate,
          });
        }
      }

      if (mounted) {
        setState(() {
          _appointments = loadedAppointments;
          _isRefreshing = false;
        });
      }
    } catch (e) {
      print('Error fetching bookings: $e');
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load bookings: $e')),
        );
      }
    }
  }

  List<Map<String, dynamic>> _generateRecurringAppointments(
    Map<String, dynamic> baseAppointment,
    DateTime startDate,
    String? rule,
    DateTime endDate,
  ) {
    final List<Map<String, dynamic>> appointments = [];
    DateTime currentDate = startDate;

    while (currentDate.isBefore(endDate) ||
        currentDate.isAtSameMomentAs(endDate)) {
      appointments.add({
        ...baseAppointment,
        'date': currentDate,
        'isRecurringInstance': true,
      });

      switch (rule) {
        case 'daily':
          currentDate = currentDate.add(const Duration(days: 1));
          break;
        case 'weekly':
          currentDate = currentDate.add(const Duration(days: 7));
          break;
        case 'monthly':
          currentDate = DateTime(
            currentDate.year,
            currentDate.month + 1,
            currentDate.day,
          );
          break;
        default:
          // If unknown rule, stop to avoid infinite loop
          return appointments;
      }
    }
    return appointments;
  }

  TimeOfDay _parseTime(String timeStr) {
    try {
      final parts = timeStr.split(':');
      return TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    } catch (e) {
      return const TimeOfDay(hour: 0, minute: 0);
    }
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'C';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  Future<void> _refreshCalendar() async {
    await _fetchBookings();
  }

  void _onViewModeChanged(CalendarViewMode mode) {
    setState(() {
      _currentViewMode = mode;
    });
    HapticFeedback.lightImpact();
  }

  void _onDateChanged(DateTime date) {
    setState(() {
      _selectedDate = date;
      _focusedDate = date;
    });
  }

  void _onTodayPressed() {
    final today = DateTime.now();
    setState(() {
      _selectedDate = today;
      _focusedDate = today;
    });
    HapticFeedback.lightImpact();
  }

  void _onPreviousPeriod() {
    setState(() {
      switch (_currentViewMode) {
        case CalendarViewMode.month:
          _focusedDate = DateTime(_focusedDate.year, _focusedDate.month - 1, 1);
          break;
        case CalendarViewMode.week:
          _focusedDate = _focusedDate.subtract(const Duration(days: 7));
          break;
        case CalendarViewMode.day:
          _focusedDate = _focusedDate.subtract(const Duration(days: 1));
          _selectedDate = _focusedDate;
          break;
      }
    });
    HapticFeedback.lightImpact();
  }

  void _onNextPeriod() {
    setState(() {
      switch (_currentViewMode) {
        case CalendarViewMode.month:
          _focusedDate = DateTime(_focusedDate.year, _focusedDate.month + 1, 1);
          break;
        case CalendarViewMode.week:
          _focusedDate = _focusedDate.add(const Duration(days: 7));
          break;
        case CalendarViewMode.day:
          _focusedDate = _focusedDate.add(const Duration(days: 1));
          _selectedDate = _focusedDate;
          break;
      }
    });
    HapticFeedback.lightImpact();
  }

  void _onAppointmentTap(Map<String, dynamic> appointment) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildAppointmentDetailsSheet(appointment),
    );
  }

  void _onAppointmentAction(Map<String, dynamic> appointment, String action) {
    switch (action) {
      case 'check_in':
        _onCheckIn(appointment);
        break;
      case 'reschedule':
        _onReschedule(appointment);
        break;
      case 'cancel':
        _onCancel(appointment);
        break;
      case 'message':
        _onMessageClient(appointment);
        break;
      case 'edit':
        _onEditAppointment(appointment);
        break;
      case 'duplicate':
        _onDuplicateAppointment(appointment);
        break;
      case 'add_notes':
        _onAddNotes(appointment);
        break;
    }
  }

  void _onCheckIn(Map<String, dynamic> appointment) {
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Checked in for ${appointment['clientName']}'),
        backgroundColor: AppTheme.successLight,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _onReschedule(Map<String, dynamic> appointment) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Reschedule ${appointment['clientName']} - Feature coming soon',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _onCancel(Map<String, dynamic> appointment) {
    debugPrint('Attempting to cancel appointment: ${appointment['id']}, is_recurring: ${appointment['is_recurring']}, isRecurringInstance: ${appointment['isRecurringInstance']}');
    
    final bool isRecurring = appointment['is_recurring'] == true || 
                             appointment['isRecurringInstance'] == true;

    if (isRecurring) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Recurring Booking'),
          content: const Text(
            'This is a recurring booking. For your safety, we do not allow deleting individual instances of recurring bookings yet. Please edit the series to make changes.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Appointment'),
        content: Text(
          'Are you sure you want to cancel and delete the appointment with ${appointment['clientName']}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close sheet if open

              try {
                await SupabaseService.instance.deleteBooking(appointment['id']);
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Appointment with ${appointment['clientName']} deleted',
                      ),
                      backgroundColor: AppTheme.errorLight,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                  _refreshCalendar(); // Refresh the list
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete booking: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorLight,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _onMessageClient(Map<String, dynamic> appointment) {
    Navigator.pushNamed(
      context,
      AppRoutes.communicationHub,
      arguments: {'clientName': appointment['clientName']},
    );
  }

  void _onEditAppointment(Map<String, dynamic> appointment) {
    if (appointment['is_recurring'] == true || appointment['isRecurringInstance'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Editing recurring series is coming soon.')),
      );
      return;
    }
    
    Navigator.pushNamed(
      context,
      AppRoutes.newBooking,
      arguments: {'editBooking': appointment},
    ).then((_) => _fetchBookings());
  }

  void _onDuplicateAppointment(Map<String, dynamic> appointment) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Duplicate ${appointment['clientName']} - Feature coming soon',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _onAddNotes(Map<String, dynamic> appointment) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Add notes for ${appointment['clientName']} - Feature coming soon',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _onQuickBooking(DateTime? date, TimeOfDay? time) {
    Navigator.pushNamed(
      context,
      AppRoutes.newBooking,
      arguments: {'preselectedDate': date, 'preselectedTime': time},
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: const CustomAppBar(
        title: 'Calendar',
        variant: CustomAppBarVariant.standard,
        showNotificationBadge: true,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshCalendar,
          color: theme.colorScheme.primary,
          child: Column(
            children: [
              // Calendar Header
              CalendarHeaderWidget(
                currentViewMode: _currentViewMode,
                focusedDate: _focusedDate,
                onViewModeChanged: _onViewModeChanged,
                onTodayPressed: _onTodayPressed,
                onPreviousPeriod: _onPreviousPeriod,
                onNextPeriod: _onNextPeriod,
              ),

              // Calendar Content
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  child: _buildCalendarView(),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _onQuickBooking(_selectedDate, null),
        icon: CustomIconWidget(
          iconName: 'add',
          color: theme.colorScheme.onPrimary,
          size: 5.w,
        ),
        label: Text(
          'New Booking',
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      bottomNavigationBar: const CustomBottomBar(
        currentIndex: 1,
        variant: CustomBottomBarVariant.standard,
      ),
    );
  }

  Widget _buildCalendarView() {
    switch (_currentViewMode) {
      case CalendarViewMode.month:
        return MonthViewWidget(
          focusedDate: _focusedDate,
          selectedDate: _selectedDate,
          appointments: _getAppointmentsForMonth(_focusedDate),
          onDateSelected: _onDateChanged,
          onAppointmentTap: _onAppointmentTap,
          onQuickBooking: _onQuickBooking,
        );
      case CalendarViewMode.week:
        return WeekViewWidget(
          focusedDate: _focusedDate,
          selectedDate: _selectedDate,
          appointments: _getAppointmentsForWeek(_getStartOfWeek(_focusedDate)),
          onDateSelected: _onDateChanged,
          onAppointmentTap: _onAppointmentTap,
          onAppointmentAction: _onAppointmentAction,
          onQuickBooking: _onQuickBooking,
        );
      case CalendarViewMode.day:
        return DayViewWidget(
          selectedDate: _selectedDate,
          appointments: _getAppointmentsForDate(_selectedDate),
          onAppointmentTap: _onAppointmentTap,
          onAppointmentAction: _onAppointmentAction,
          onQuickBooking: _onQuickBooking,
        );
    }
  }

  DateTime _getStartOfWeek(DateTime date) {
    final weekday = date.weekday;
    return date.subtract(Duration(days: weekday - 1));
  }

  Widget _buildAppointmentDetailsSheet(Map<String, dynamic> appointment) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
          return AppointmentCardWidget(
            appointment: appointment,
            scrollController: scrollController,
            onAction: _onAppointmentAction,
            showFullDetails: true,
          );
        },
      ),
    );
  }
}
