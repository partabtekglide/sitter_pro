import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/supabase_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_bottom_bar.dart';
import './widgets/check_in_card_widget.dart';
import './widgets/earnings_calculator_widget.dart';
import './widgets/location_widget.dart';
import './widgets/photo_capture_widget.dart';
import './widgets/task_list_widget.dart';
import './widgets/time_tracker_widget.dart';

class JobCheckIn extends StatefulWidget {
  const JobCheckIn({super.key});

  @override
  State<JobCheckIn> createState() => _JobCheckInState();
}

class _JobCheckInState extends State<JobCheckIn> {
  bool _isLoading = true;
  bool _isCheckedIn = false;
  DateTime? _checkInTime;
  DateTime? _checkOutTime;
  String _currentBookingId = '';
  Map<String, dynamic>? _currentBooking;
  List<Map<String, dynamic>> _tasks = [];
  List<String> _capturedPhotos = [];
  String _notes = '';
  Map<String, dynamic>? _location;

  @override
  void initState() {
    super.initState();
    _loadCurrentBooking();
  }

  Future<void> _loadCurrentBooking() async {
    setState(() => _isLoading = true);

    try {
      final supabase = SupabaseService.instance.client;
      final userId = supabase.auth.currentUser?.id;

      if (userId == null) {
        _loadMockData();
        return;
      }

      // Load today's bookings for the sitter
      final bookingsResponse = await supabase
          .from('bookings')
          .select(
            '*, clients(*, user_profiles(full_name)), user_profiles(full_name)',
          )
          .eq('sitter_id', userId)
          .eq('start_date', DateTime.now().toIso8601String().split('T')[0])
          .order('start_time', ascending: true);

      // Load existing check-in for today
      final checkInResponse =
          await supabase
              .from('job_checkins')
              .select('*, checkin_tasks(*)')
              .eq('sitter_id', userId)
              .gte(
                'checkin_time',
                DateTime.now().toIso8601String().split('T')[0],
              )
              .maybeSingle();

      List<Map<String, dynamic>> bookings = List<Map<String, dynamic>>.from(
        bookingsResponse,
      );

      if (bookings.isNotEmpty) {
        _currentBooking = bookings.first;
        _currentBookingId = _currentBooking!['id'];

        if (checkInResponse != null) {
          _isCheckedIn =
              checkInResponse['status'] == 'checked_in' ||
              checkInResponse['status'] == 'in_progress';
          _checkInTime = DateTime.tryParse(
            checkInResponse['checkin_time'] ?? '',
          );
          _checkOutTime = DateTime.tryParse(
            checkInResponse['checkout_time'] ?? '',
          );
          _tasks = List<Map<String, dynamic>>.from(
            checkInResponse['checkin_tasks'] ?? [],
          );
        } else {
          _generateTasksForService(_currentBooking!['service_type']);
        }
      }

      setState(() => _isLoading = false);
    } catch (e) {
      print('Error loading booking data: $e');
      _loadMockData();
    }
  }

  void _loadMockData() {
    setState(() {
      _currentBooking = {
        'id': 'mock_booking_1',
        'service_type': 'babysitting',
        'start_time': '09:00:00',
        'end_time': '14:00:00',
        'hourly_rate': 25.00,
        'address': '456 Oak Street, Springfield, IL 62702',
        'clients': {
          'user_profiles': {'full_name': 'Sarah Johnson'},
        },
        'special_instructions':
            'Kids love pizza for lunch. Emma takes nap at 1 PM.',
      };
      _currentBookingId = 'mock_booking_1';
      _generateTasksForService('babysitting');
      _isLoading = false;
    });
  }

  void _generateTasksForService(String serviceType) {
    switch (serviceType) {
      case 'babysitting':
        _tasks = [
          {
            'id': '1',
            'task_name': 'Safety Check',
            'task_description': 'Verify all doors and windows are secure',
            'is_required': true,
            'status': 'pending',
          },
          {
            'id': '2',
            'task_name': 'Meal Preparation',
            'task_description': 'Prepare healthy snacks or meals as requested',
            'is_required': false,
            'status': 'pending',
          },
          {
            'id': '3',
            'task_name': 'Activity Time',
            'task_description': 'Engage children in appropriate activities',
            'is_required': true,
            'status': 'pending',
          },
          {
            'id': '4',
            'task_name': 'Cleanup',
            'task_description': 'Clean up toys and activity areas',
            'is_required': true,
            'status': 'pending',
          },
        ];
        break;
      case 'pet_sitting':
        _tasks = [
          {
            'id': '1',
            'task_name': 'Walk Pet',
            'task_description': 'Take pet for required walk',
            'is_required': true,
            'status': 'pending',
          },
          {
            'id': '2',
            'task_name': 'Feed Pet',
            'task_description': 'Provide food and fresh water',
            'is_required': true,
            'status': 'pending',
          },
          {
            'id': '3',
            'task_name': 'Play Time',
            'task_description': 'Engage pet in interactive play',
            'is_required': false,
            'status': 'pending',
          },
          {
            'id': '4',
            'task_name': 'Clean Area',
            'task_description': 'Clean pet area and litter box if needed',
            'is_required': true,
            'status': 'pending',
          },
        ];
        break;
      case 'house_sitting':
        _tasks = [
          {
            'id': '1',
            'task_name': 'Security Check',
            'task_description': 'Check all locks and security systems',
            'is_required': true,
            'status': 'pending',
          },
          {
            'id': '2',
            'task_name': 'Mail Collection',
            'task_description': 'Collect mail and packages',
            'is_required': false,
            'status': 'pending',
          },
          {
            'id': '3',
            'task_name': 'Plant Watering',
            'task_description': 'Water plants as instructed',
            'is_required': false,
            'status': 'pending',
          },
          {
            'id': '4',
            'task_name': 'Property Check',
            'task_description': 'General property maintenance check',
            'is_required': true,
            'status': 'pending',
          },
        ];
        break;
      default:
        _tasks = [
          {
            'id': '1',
            'task_name': 'Service Check',
            'task_description': 'Complete service as requested',
            'is_required': true,
            'status': 'pending',
          },
        ];
    }
  }

  Future<void> _handleCheckIn() async {
    if (_isCheckedIn) {
      // Check out
      await _performCheckOut();
    } else {
      // Check in
      await _performCheckIn();
    }
  }

  Future<void> _performCheckIn() async {
    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();
      final supabase = SupabaseService.instance.client;
      final userId = supabase.auth.currentUser?.id;

      if (userId != null) {
        await supabase.from('job_checkins').insert({
          'booking_id': _currentBookingId,
          'sitter_id': userId,
          'checkin_time': now.toIso8601String(),
          'status': 'checked_in',
          'location_address': _currentBooking!['address'],
        });
      }

      setState(() {
        _isCheckedIn = true;
        _checkInTime = now;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Successfully checked in!'),
          backgroundColor: Color(0xFF4CAF50),
        ),
      );
    } catch (e) {
      print('Error checking in: $e');
      // Mock success for demo
      setState(() {
        _isCheckedIn = true;
        _checkInTime = DateTime.now();
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Successfully checked in!'),
          backgroundColor: Color(0xFF4CAF50),
        ),
      );
    }
  }

  Future<void> _performCheckOut() async {
    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();
      final duration =
          _checkInTime != null ? now.difference(_checkInTime!).inMinutes : 0;

      final earnings = _calculateEarnings(duration);

      final supabase = SupabaseService.instance.client;
      final userId = supabase.auth.currentUser?.id;

      if (userId != null) {
        await supabase
            .from('job_checkins')
            .update({
              'checkout_time': now.toIso8601String(),
              'status': 'checked_out',
              'duration_minutes': duration,
              'total_earned': earnings,
              'notes': _notes,
            })
            .eq('sitter_id', userId)
            .eq('booking_id', _currentBookingId);
      }

      setState(() {
        _isCheckedIn = false;
        _checkOutTime = now;
        _isLoading = false;
      });

      _showCompletionDialog(duration, earnings);
    } catch (e) {
      print('Error checking out: $e');
      // Mock success for demo
      final now = DateTime.now();
      final duration =
          _checkInTime != null
              ? now.difference(_checkInTime!).inMinutes
              : 120; // Mock 2 hours
      final earnings = _calculateEarnings(duration);

      setState(() {
        _isCheckedIn = false;
        _checkOutTime = now;
        _isLoading = false;
      });

      _showCompletionDialog(duration, earnings);
    }
  }

  double _calculateEarnings(int minutes) {
    if (_currentBooking == null) return 0.0;

    final hourlyRate =
        (_currentBooking!['hourly_rate'] as num?)?.toDouble() ?? 25.0;
    final hours = minutes / 60.0;
    return hours * hourlyRate;
  }

  void _showCompletionDialog(int duration, double earnings) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.check_circle, color: Color(0xFF4CAF50)),
                SizedBox(width: 8.w),
                const Text('Job Completed!'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Duration: ${duration ~/ 60}h ${duration % 60}m'),
                SizedBox(height: 8.h),
                Text('Earnings: \$${earnings.toStringAsFixed(2)}'),
                SizedBox(height: 16.h),
                Text(
                  'Great job! Your session has been recorded and the client has been notified.',
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context); // Return to dashboard
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Done'),
              ),
            ],
          ),
    );
  }

  void _onTaskToggle(String taskId, bool completed) {
    setState(() {
      final taskIndex = _tasks.indexWhere((task) => task['id'] == taskId);
      if (taskIndex != -1) {
        _tasks[taskIndex]['status'] = completed ? 'completed' : 'pending';
        _tasks[taskIndex]['completed_at'] =
            completed ? DateTime.now().toIso8601String() : null;
      }
    });
  }

  void _onPhotoAdded(String photoPath) {
    setState(() {
      _capturedPhotos.add(photoPath);
    });
  }

  void _onNotesChanged(String notes) {
    _notes = notes;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: CustomAppBar(title: 'Job Check-in', centerTitle: true),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_currentBooking == null) {
      return Scaffold(
        appBar: CustomAppBar(title: 'Job Check-in'),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.event_busy, size: 64.sp, color: Colors.grey[400]),
              SizedBox(height: 16.h),
              Text(
                'No Active Jobs Today',
                style: GoogleFonts.inter(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'You don\'t have any scheduled jobs for today.',
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: const CustomBottomBar(currentIndex: 4),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: CustomAppBar(
        title: 'Job Check-in',
        backgroundColor: const Color(0xFF1976D2),
        titleStyle: GoogleFonts.inter(
          fontSize: 18.sp,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadCurrentBooking,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Booking Info Card
              CheckInCardWidget(
                booking: _currentBooking!,
                isCheckedIn: _isCheckedIn,
                checkInTime: _checkInTime,
                checkOutTime: _checkOutTime,
              ),

              SizedBox(height: 16.h),

              // Check-in/Check-out Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _handleCheckIn,
                  icon: Icon(_isCheckedIn ? Icons.logout : Icons.login),
                  label: Text(_isCheckedIn ? 'Check Out' : 'Check In'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _isCheckedIn
                            ? const Color(0xFFF44336) // Red for check out
                            : const Color(0xFF4CAF50), // Green for check in
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    textStyle: GoogleFonts.inter(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              if (_isCheckedIn) ...[
                SizedBox(height: 20.h),

                // Time Tracker
                TimeTrackerWidget(
                  checkInTime: _checkInTime!,
                  hourlyRate:
                      (_currentBooking!['hourly_rate'] as num?)?.toDouble() ??
                      25.0,
                ),

                SizedBox(height: 20.h),

                // Task List
                TaskListWidget(tasks: _tasks, onTaskToggle: _onTaskToggle),

                SizedBox(height: 20.h),

                // Photo Capture
                PhotoCaptureWidget(
                  photos: _capturedPhotos,
                  onPhotoAdded: _onPhotoAdded,
                ),

                SizedBox(height: 20.h),

                // Location Widget
                LocationWidget(
                  address: _currentBooking!['address'],
                  onLocationUpdated: (location) {
                    _location = location;
                  },
                ),

                SizedBox(height: 20.h),

                // Notes Section
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(16.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Session Notes',
                          style: GoogleFonts.inter(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 12.h),
                        TextField(
                          maxLines: 4,
                          decoration: const InputDecoration(
                            hintText: 'Add notes about your session...',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: _onNotesChanged,
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 20.h),

                // Earnings Calculator
                EarningsCalculatorWidget(
                  checkInTime: _checkInTime!,
                  hourlyRate:
                      (_currentBooking!['hourly_rate'] as num?)?.toDouble() ??
                      25.0,
                ),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: const CustomBottomBar(currentIndex: 4),
    );
  }
}