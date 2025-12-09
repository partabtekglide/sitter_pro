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

  // Mock appointment data
  final List<Map<String, dynamic>> _appointments = [
    {
      'id': 1,
      'clientName': 'Sarah Johnson',
      'clientInitials': 'SJ',
      'serviceType': 'babysitting',
      'date': DateTime.now().add(const Duration(days: 1)),
      'startTime': const TimeOfDay(hour: 9, minute: 0),
      'endTime': const TimeOfDay(hour: 14, minute: 0),
      'status': 'confirmed',
      'amount': 75.0,
      'clientPhone': '+1 (555) 123-4567',
      'address': '123 Oak Street, Springfield, IL 62701',
      'notes': 'Two children: Emma (5) and Jake (3). Lunch at 12pm.',
      'profileImage':
          'https://images.unsplash.com/photo-1704541840921-106a1106cbb0',
    },
    {
      'id': 2,
      'clientName': 'Mike Chen',
      'clientInitials': 'MC',
      'serviceType': 'pet_sitting',
      'date': DateTime.now(),
      'startTime': const TimeOfDay(hour: 16, minute: 0),
      'endTime': const TimeOfDay(hour: 18, minute: 0),
      'status': 'pending',
      'amount': 40.0,
      'clientPhone': '+1 (555) 987-6543',
      'address': '456 Pine Avenue, Springfield, IL 62702',
      'notes': 'Golden Retriever named Max. Needs walk and feeding.',
      'profileImage':
          'https://images.unsplash.com/photo-1635068471990-6d294f073f96',
    },
    {
      'id': 3,
      'clientName': 'Emily Rodriguez',
      'clientInitials': 'ER',
      'serviceType': 'house_sitting',
      'date': DateTime.now().add(const Duration(days: 2)),
      'startTime': const TimeOfDay(hour: 19, minute: 0),
      'endTime': const TimeOfDay(hour: 23, minute: 0),
      'status': 'confirmed',
      'amount': 80.0,
      'clientPhone': '+1 (555) 456-7890',
      'address': '789 Maple Drive, Springfield, IL 62703',
      'notes': 'Water plants, collect mail, and feed cats.',
      'profileImage':
          'https://images.unsplash.com/photo-1639123123923-d0d8ec97e5d1',
    },
    {
      'id': 4,
      'clientName': 'David Wilson',
      'clientInitials': 'DW',
      'serviceType': 'babysitting',
      'date': DateTime.now().add(const Duration(days: 3)),
      'startTime': const TimeOfDay(hour: 18, minute: 30),
      'endTime': const TimeOfDay(hour: 23, minute: 0),
      'status': 'confirmed',
      'amount': 67.5,
      'clientPhone': '+1 (555) 234-5678',
      'address': '321 Cedar Lane, Springfield, IL 62704',
      'notes': 'Date night sitting. One child: Sophie (7). Bedtime at 8:30pm.',
      'profileImage':
          'https://images.unsplash.com/photo-1722605896508-ecae644f6345',
    },
    {
      'id': 5,
      'clientName': 'Lisa Thompson',
      'clientInitials': 'LT',
      'serviceType': 'pet_sitting',
      'date': DateTime.now().subtract(const Duration(days: 1)),
      'startTime': const TimeOfDay(hour: 8, minute: 0),
      'endTime': const TimeOfDay(hour: 10, minute: 0),
      'status': 'completed',
      'amount': 30.0,
      'clientPhone': '+1 (555) 345-6789',
      'address': '654 Birch Street, Springfield, IL 62705',
      'notes': 'Two cats: Whiskers and Mittens. Morning feeding.',
      'profileImage':
          'https://images.unsplash.com/photo-1704541840921-106a1106cbb0',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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

  Future<void> _refreshCalendar() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    HapticFeedback.lightImpact();

    // Simulate data refresh
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _isRefreshing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Calendar updated'),
          duration: Duration(seconds: 2),
        ),
      );
    }
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
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Cancel Appointment'),
            content: Text(
              'Are you sure you want to cancel the appointment with ${appointment['clientName']}?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Keep'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Appointment with ${appointment['clientName']} cancelled',
                      ),
                      backgroundColor: AppTheme.errorLight,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.errorLight,
                ),
                child: const Text('Cancel'),
              ),
            ],
          ),
    );
  }

  void _onMessageClient(Map<String, dynamic> appointment) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening message to ${appointment['clientName']}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _onEditAppointment(Map<String, dynamic> appointment) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Edit ${appointment['clientName']} - Feature coming soon',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
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
