import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/supabase_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_bottom_bar.dart';
import './widgets/greeting_header_widget.dart';
import './widgets/quick_stats_widget.dart';
import './widgets/recent_activity_widget.dart';
import './widgets/today_schedule_widget.dart';
import './widgets/weather_widget.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> with TickerProviderStateMixin {
  bool _isRefreshing = false;
  bool _isLocationEnabled = false;
  Map<String, dynamic>? _weatherData;
  late TabController _tabController;

  // Real data from Supabase
  List<Map<String, dynamic>> _todayAppointments = [];
  List<Map<String, dynamic>> _recentActivities = [];
  Map<String, dynamic> _dashboardStats = {
    'weeklyEarnings': 0.0,
    'pendingPayments': 0.0,
    'activeClients': 0,
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadDashboardData();
    _loadWeatherData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    try {
      // Load dashboard statistics
      final stats = await SupabaseService.instance.getDashboardStats();
      print(  'Loaded dashboard stats: $stats');
      // Load today's appointments
      final today = DateTime.now();
      final appointments = await SupabaseService.instance.getBookings(
        startDate: today,
        endDate: today,
      );

      // Load notifications as recent activities
      final notifications = await SupabaseService.instance.getNotifications();
      print('Loaded ${appointments.length} appointments and ${notifications.length} notifications');

      if (mounted) {
        setState(() {
          _dashboardStats = stats;
          _todayAppointments =
              appointments
                  .map(
                    (booking) => {
                      'id': booking['id'],
                      'clientName':
                          booking['clients']?['user_profiles']?['full_name'] ??
                          'Unknown Client',
                      'serviceType': _formatServiceType(
                        booking['service_type'],
                      ),
                      'startTime': _formatTime(booking['start_time']),
                      'endTime': _formatTime(booking['end_time']),
                      'status': _formatStatus(booking['status']),
                      'amount': booking['total_amount']?.toDouble() ?? 0.0,
                      'clientPhone':
                          booking['clients']?['user_profiles']?['phone'] ?? '',
                      'address': booking['address'] ?? '',
                    },
                  )
                  .toList();

          _recentActivities =
              notifications
                  .take(5)
                  .map(
                    (notification) => {
                      'id': notification['id'],
                      'type': _getActivityType(notification['type']),
                      'title': notification['title'],
                      'description': notification['message'],
                      'timestamp': DateTime.parse(notification['created_at']),
                      'hasAction': notification['actionable'] ?? false,
                    },
                  )
                  .toList();
        });
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load dashboard data: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadWeatherData() async {
    if (_isLocationEnabled) {
      // Simulate weather API call
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        setState(() {
          _weatherData = {
            "temperature": 72,
            "condition": "Partly Cloudy",
            "location": "Springfield, IL",
            "windSpeed": 8,
            "humidity": 65,
          };
        });
      }
    }
  }

  Future<void> _refreshDashboard() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    HapticFeedback.lightImpact();

    try {
      await _loadDashboardData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dashboard updated'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to refresh: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  void _onAppointmentTap(Map<String, dynamic> appointment) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildAppointmentDetailsSheet(appointment),
    );
  }

  void _onCheckIn(Map<String, dynamic> appointment) async {
    try {
      await SupabaseService.instance.updateBookingStatus(
        appointment['id'],
        'in_progress',
      );

      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Checked in for ${appointment['clientName']}'),
          duration: const Duration(seconds: 2),
        ),
      );

      // Refresh data
      _loadDashboardData();
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Check-in failed: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _onMessageClient(Map<String, dynamic> appointment) {
    Navigator.pushNamed(
      context,
      AppRoutes.communicationHub,
      arguments: {'clientName': appointment['clientName']},
    );
  }

  void _onViewDetails(Map<String, dynamic> appointment) {
    _onAppointmentTap(appointment);
  }

  void _onActivityAction(Map<String, dynamic> activity) async {
    if (activity['hasAction'] == true) {
      try {
        await SupabaseService.instance.markNotificationAsRead(activity['id']);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Action completed: ${activity['title']}'),
            duration: const Duration(seconds: 2),
          ),
        );
        _loadDashboardData();
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Action failed: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onEnableLocation() {
    setState(() {
      _isLocationEnabled = true;
      _weatherData = null;
    });
    _loadWeatherData();
  }

  void _onNewBooking() {
    HapticFeedback.lightImpact();
    Navigator.pushNamed(context, AppRoutes.newBooking);
  }

  String _formatServiceType(String serviceType) {
    switch (serviceType) {
      case 'babysitting':
        return 'Babysitting';
      case 'pet_sitting':
        return 'Pet Sitting';
      case 'house_sitting':
        return 'House Sitting';
      case 'elder_care':
        return 'Elder Care';
      default:
        return serviceType;
    }
  }

  String _formatTime(String? time) {
    if (time == null) return '';
    try {
      final parts = time.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
    } catch (e) {
      return time;
    }
  }

  String _formatStatus(String status) {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'confirmed':
        return 'Confirmed';
      case 'in_progress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  String _getActivityType(String notificationType) {
    switch (notificationType) {
      case 'booking_request':
        return 'booking';
      case 'booking_confirmed':
        return 'booking';
      case 'payment_received':
        return 'payment';
      case 'reminder':
        return 'reminder';
      case 'message':
        return 'message';
      case 'review':
        return 'review';
      default:
        return 'notification';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: const CustomAppBar(
        title: 'Sitter Pro Manager',
        variant: CustomAppBarVariant.standard,
        showNotificationBadge: true,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshDashboard,
          color: theme.colorScheme.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(4.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Greeting Header
                GreetingHeaderWidget(
                  sitterName: 'Alex Thompson',
                  currentDate: DateTime.now(),
                ),

                SizedBox(height: 3.h),

                // Weather Widget
                WeatherWidget(
                  weatherData: _weatherData,
                  isLocationEnabled: _isLocationEnabled,
                  onEnableLocation: _onEnableLocation,
                ),

                SizedBox(height: 3.h),

                // Today's Schedule
                TodayScheduleWidget(
                  appointments: _todayAppointments,
                  onAppointmentTap: _onAppointmentTap,
                  onCheckIn: _onCheckIn,
                  onMessageClient: _onMessageClient,
                  onViewDetails: _onViewDetails,
                ),

                SizedBox(height: 3.h),

                // Quick Stats - Now with real data
                QuickStatsWidget(
                  weeklyEarnings:
                      _dashboardStats['weeklyEarnings']?.toDouble() ?? 0.0,
                  pendingPayments:
                      _dashboardStats['pendingPayments']?.toDouble() ?? 0.0,
                  activeClients: _dashboardStats['activeClients'] ?? 0,
                ),

                SizedBox(height: 3.h),

                // Recent Activity
                RecentActivityWidget(
                  activities: _recentActivities,
                  onActivityAction: _onActivityAction,
                ),

                SizedBox(height: 10.h), // Extra space for FAB
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _onNewBooking,
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
        currentIndex: 0,
        variant: CustomBottomBarVariant.standard,
      ),
    );
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

                // Header
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        appointment['clientName'] as String,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 3.w,
                        vertical: 1.h,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        appointment['status'] as String,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 2.h),

                // Service details
                _buildDetailRow(
                  context,
                  'Service Type',
                  appointment['serviceType'] as String,
                  'work',
                ),

                _buildDetailRow(
                  context,
                  'Time',
                  '${appointment['startTime']} - ${appointment['endTime']}',
                  'schedule',
                ),

                _buildDetailRow(
                  context,
                  'Amount',
                  '\$${appointment['amount']}',
                  'attach_money',
                ),

                _buildDetailRow(
                  context,
                  'Phone',
                  appointment['clientPhone'] as String,
                  'phone',
                ),

                _buildDetailRow(
                  context,
                  'Address',
                  appointment['address'] as String,
                  'location_on',
                ),

                SizedBox(height: 3.h),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _onMessageClient(appointment);
                        },
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
                        onPressed: () {
                          Navigator.pop(context);
                          _onCheckIn(appointment);
                        },
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
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value,
    String iconName,
  ) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: 2.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 10.w,
            height: 10.w,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: CustomIconWidget(
                iconName: iconName,
                color: theme.colorScheme.primary,
                size: 5.w,
              ),
            ),
          ),
          SizedBox(width: 3.w),
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
}
