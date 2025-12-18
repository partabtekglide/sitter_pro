import 'package:supabase_flutter/supabase_flutter.dart';

import '../presentation/dashboard/dashboard.dart';

class SupabaseService {
  static SupabaseService? _instance;
  static SupabaseService get instance {
    _instance ??= SupabaseService._internal();
    return _instance!;
  }

  SupabaseService._internal();

  // Initialize method for backwards compatibility
  static Future<void> initialize() async {
    // Supabase is already initialized in main.dart
    // This method exists for compatibility with existing code
  }

  // Supabase client getter
  SupabaseClient get client => Supabase.instance.client;

  // Add SignUp method
  // Future<void> signUp({
  //   required String email,
  //   required String password,
  //   required String fullName,
  //   String? phone,
  //   String? address,
  //   String role = 'client',
  // }) async {
  //   try {
  //     // Sign up user with Supabase Auth
  //     final authResponse = await client.auth.signUp(
  //       email: email,
  //       password: password,
  //     );

  //     if (authResponse.user != null) {
  //       // Create user profile
  //       await client.from('user_profiles').insert({
  //         'id': authResponse.user!.id,
  //         'email': email,
  //         'full_name': fullName,
  //         'phone': phone,
  //         'address': address,
  //         'role': role,
  //         'is_active': true,
  //       });

  //       // If role is client, also create client record
  //       if (role == 'client') {
  //         await client.from('clients').insert({
  //           'user_id': authResponse.user!.id,
  //         });
  //       }
  //     } else {
  //       throw Exception('Failed to create user account');
  //     }
  //   } catch (error) {
  //     rethrow;
  //   }
  // }
Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phone,
    String? address,
    String role = 'client',
  }) async {
    try {
      // 1. Sign up user (PASS DATA HERE for the Trigger)
      final authResponse = await client.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'role': role.toLowerCase(),
          'phone': phone,
          'address': address,
        },
      );

      // Check if user creation failed
      if (authResponse.user == null) {
        throw 'Sign up failed. Please check your email/password.';
      }
      
      final userId = authResponse.user!.id;

      // Note: Hum 'user_profiles' mein insert nahi kar rahe, 
      // kyunki Step 1 wala SQL Trigger wo kaam khud kar lega.

      // 2. Client Table (Optional: Add a small delay to ensure profile is ready)
      if (role == 'client') {
        // Thoda wait karte hain taaki Session set ho jaye
        await Future.delayed(const Duration(milliseconds: 500)); 
        
        await client.from('clients').insert({
          'user_id': userId,
          'full_name': fullName,
          'email': email,
          'phone': phone,
          'address': address,
        });
      }
    } on AuthException catch (e) {
      throw e.message;
    } catch (e) {
      // Agar 'users_profile' pehle se ban gaya (trigger se) aur hum duplicate try karein
      if (e.toString().contains('duplicate key')) {
        return; // Ignore duplicate error, matlab kaam ho gaya
      }
      throw 'Error: $e';
    }
  }
  // Authentication Methods
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } catch (error) {
      throw Exception('Sign in failed: $error');
    }
  }

  Future<void> signOut() async {
    try {
      await client.auth.signOut();
    } catch (error) {
      throw Exception('Sign out failed: $error');
    }
  }

  User? get currentUser => client.auth.currentUser;
  Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;

  // User Profile Methods
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final response =
          await client.from('user_profiles').select().eq('id', userId).single();
      return response;
    } catch (error) {
      throw Exception('Get user profile failed: $error');
    }
  }

  Future<Map<String, dynamic>> updateUserProfile(
    String userId,
    Map<String, dynamic> updates,
  ) async {
    try {
      updates['updated_at'] = DateTime.now().toIso8601String();
      final response = await client
          .from('user_profiles')
          .update(updates)
          .eq('id', userId)
          .select()
          .single();
      return response;
    } catch (error) {
      throw Exception('Update user profile failed: $error');
    }
  }

  // Booking Methods
  Future<List<Map<String, dynamic>>> getBookings({
    String? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      var query = client.from('bookings').select('''
            *,
            clients!inner (
              *,
              user_profiles!inner (full_name, phone, avatar_url)
            ),
            sitter:user_profiles!bookings_sitter_id_fkey (full_name, phone, avatar_url)
          ''');

      if (status != null) {
        query = query.eq('status', status);
      }

      if (startDate != null) {
        query = query.gte(
          'start_date',
          startDate.toIso8601String().split('T')[0],
        );
      }

      if (endDate != null) {
        query = query.lte(
          'start_date',
          endDate.toIso8601String().split('T')[0],
        );
      }

      final response = await query.order('start_date', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      throw Exception('Get bookings failed: $error');
    }
  }

  Future<Map<String, dynamic>> createBooking({
    required String clientId,
    required String sitterId,
    required String serviceType,
    required DateTime startDate,
    DateTime? endDate,
    required String startTime,
    String? endTime,
    required double hourlyRate,
    required String address,
    String? specialInstructions,
  }) async {
    try {
      final duration = _calculateDuration(startTime, endTime ?? startTime);
      final totalAmount = hourlyRate * duration;

      final response = await client
          .from('bookings')
          .insert({
            'client_id': clientId,
            'sitter_id': sitterId,
            'service_type': serviceType,
            'start_date': startDate.toIso8601String().split('T')[0],
            'end_date': endDate?.toIso8601String().split('T')[0],
            'start_time': startTime,
            'end_time': endTime,
            'hourly_rate': hourlyRate,
            'total_amount': totalAmount,
            'duration_hours': duration,
            'address': address,
            'special_instructions': specialInstructions,
            'status': 'pending',
          })
          .select()
          .single();
      return response;
    } catch (error) {
      throw Exception('Create booking failed: $error');
    }
  }

  Future<Map<String, dynamic>> updateBookingStatus(
    String bookingId,
    String status,
  ) async {
    try {
      final response = await client
          .from('bookings')
          .update({
            'status': status,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', bookingId)
          .select()
          .single();
      return response;
    } catch (error) {
      throw Exception('Update booking status failed: $error');
    }
  }

// Client Methods
  Future<List<Map<String, dynamic>>> getClients() async {
    final response = await client.from('clients').select('''
        id,
        full_name,
        phone,
        email,
        address,
        avatar_url,
        preferred_rate,
        emergency_contact_name,
        emergency_contact_phone,
        special_instructions,
        created_at,
        pets_kids (
          id,
          name,
          type
        )
      ''').order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>> createInlineClient({
    required String fullName,
    required String phone,
    required String email,
    required String address,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? notes,
    double? preferredRate,
  }) async {
    final user = currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    final response = await client.from('clients').insert({
      'user_id': user.id,
      'full_name': fullName,
      'phone': phone,
      'email': email,
      'address': address,
      'emergency_contact_name': emergencyContactName,
      'emergency_contact_phone': emergencyContactPhone,
      'special_instructions': notes,
      'preferred_rate': preferredRate ?? 25.0,
    }).select('''
        id,
        user_id,
        emergency_contact_name,
        emergency_contact_phone,
        special_instructions,
        created_at,
        preferred_rate,
        user_profiles (
          full_name,
          phone,
          address,
          avatar_url
        ),
        pets_kids (
          id,
          name,
          type
        )
      ''').single();

    return response;
  }

  Future<Map<String, dynamic>?> getClientById(String clientId) async {
    try {
      final response = await client.from('clients').select('''
            *,
            user_profiles!inner (full_name, phone, email, avatar_url, address),
            pets_kids (*),
            bookings (*, user_profiles!bookings_sitter_id_fkey (full_name))
          ''').eq('id', clientId).single();
      return response;
    } catch (error) {
      throw Exception('Get client failed: $error');
    }
  }

  // Communication Methods
  Future<List<Map<String, dynamic>>> getConversations() async {
    try {
      final userId = currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await client
          .from('communications')
          .select('''
            *,
            sender:user_profiles!communications_sender_id_fkey (full_name, avatar_url),
            receiver:user_profiles!communications_receiver_id_fkey (full_name, avatar_url)
          ''')
          .or('sender_id.eq.$userId,receiver_id.eq.$userId')
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      throw Exception('Get conversations failed: $error');
    }
  }

  Future<Map<String, dynamic>> sendMessage({
    required String receiverId,
    required String content,
    String? subject,
    String? bookingId,
  }) async {
    try {
      final userId = currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await client
          .from('communications')
          .insert({
            'sender_id': userId,
            'receiver_id': receiverId,
            'booking_id': bookingId,
            'type': 'message',
            'subject': subject,
            'content': content,
          })
          .select()
          .single();
      return response;
    } catch (error) {
      throw Exception('Send message failed: $error');
    }
  }

  Future<void> markMessageAsRead(String messageId) async {
    try {
      await client
          .from('communications')
          .update({'is_read': true}).eq('id', messageId);
    } catch (error) {
      throw Exception('Mark message as read failed: $error');
    }
  }

  // Notifications Methods
  Future<List<Map<String, dynamic>>> getNotifications() async {
    try {
      final userId = currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await client
          .from('notifications')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      throw Exception('Get notifications failed: $error');
    }
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await client
          .from('notifications')
          .update({'is_read': true}).eq('id', notificationId);
    } catch (error) {
      throw Exception('Mark notification as read failed: $error');
    }
  }

  Future<Map<String, dynamic>> createNotification({
    required String userId,
    required String type,
    required String title,
    required String message,
    String? bookingId,
    bool actionable = false,
  }) async {
    try {
      final response = await client
          .from('notifications')
          .insert({
            'user_id': userId,
            'booking_id': bookingId,
            'type': type,
            'title': title,
            'message': message,
            'actionable': actionable,
          })
          .select()
          .single();
      return response;
    } catch (error) {
      throw Exception('Create notification failed: $error');
    }
  }

  // Dashboard Statistics
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final userId = currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final today = DateTime.now();
      final weekStart = today.subtract(Duration(days: today.weekday - 1));
      final weekEnd = weekStart.add(const Duration(days: 6));

      // Get today's appointments
      final todayBookings = await client
          .from('bookings')
          .select('*')
          .eq('sitter_id', userId)
          .eq('start_date', today.toIso8601String().split('T')[0]);

      // Get weekly earnings
      final weeklyBookings = await client
          .from('bookings')
          .select('total_amount')
          .eq('sitter_id', userId)
          .eq('status', 'completed')
          .gte('start_date', weekStart.toIso8601String().split('T')[0])
          .lte('start_date', weekEnd.toIso8601String().split('T')[0]);

      double weeklyEarnings = 0;
      for (var booking in weeklyBookings) {
        weeklyEarnings += (booking['total_amount'] as num?)?.toDouble() ?? 0;
      }

      // Get pending payments
      final pendingBookings = await client
          .from('bookings')
          .select('total_amount')
          .eq('sitter_id', userId)
          .eq('status', 'completed'); // Assuming completed but not paid

      double pendingPayments = 0;
      for (var booking in pendingBookings) {
        pendingPayments += (booking['total_amount'] as num?)?.toDouble() ?? 0;
      }

      // Get active clients count
      final clientsData = await client
          .from('bookings')
          .select('client_id')
          .eq('sitter_id', userId);

      final uniqueClients = <String>{};
      for (var booking in clientsData) {
        uniqueClients.add(booking['client_id']);
      }

      return {
        'todayAppointments': todayBookings.length,
        'weeklyEarnings': weeklyEarnings,
        'pendingPayments': pendingPayments,
        'activeClients': uniqueClients.length,
      };
    } catch (error) {
      throw Exception('Get dashboard stats failed: $error');
    }
  }

  // Communication Templates Methods
  Future<List<Map<String, dynamic>>> getMessageTemplates() async {
    try {
      final response = await client
          .from('communications')
          .select('subject, content, type')
          .eq('type', 'notification')
          .not('subject', 'is', null)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      throw Exception('Get templates failed: $error');
    }
  }

  Future<Map<String, dynamic>> saveMessageTemplate({
    required String subject,
    required String content,
    required String type,
  }) async {
    try {
      final userId = currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await client
          .from('communications')
          .insert({
            'sender_id': userId,
            'receiver_id': userId, // Template stored with same sender/receiver
            'type': 'notification',
            'subject': subject,
            'content': content,
          })
          .select()
          .single();
      return response;
    } catch (error) {
      throw Exception('Save template failed: $error');
    }
  }

  // Invoice and Financial Methods
  Future<List<Map<String, dynamic>>> getInvoices({
    String? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final userId = currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      var query = client.from('invoices').select('''
            *,
            client:user_profiles!invoices_client_id_fkey (full_name, email),
            sitter:user_profiles!invoices_sitter_id_fkey (full_name, email),
            booking:bookings!invoices_booking_id_fkey (service_type, start_date)
          ''').eq('sitter_id', userId);

      if (status != null) {
        query = query.eq('status', status);
      }

      if (startDate != null) {
        query = query.gte(
          'issued_date',
          startDate.toIso8601String().split('T')[0],
        );
      }

      if (endDate != null) {
        query = query.lte(
          'issued_date',
          endDate.toIso8601String().split('T')[0],
        );
      }

      final response = await query.order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      throw Exception('Get invoices failed: $error');
    }
  }

  Future<Map<String, dynamic>> getFinancialStats() async {
    try {
      final userId = currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final monthStart = DateTime(now.year, now.month, 1);
      final yearStart = DateTime(now.year, 1, 1);

      // Weekly pending
      final weeklyInvoices = await client
          .from('invoices')
          .select('total_amount, status')
          .eq('sitter_id', userId)
          .gte('issued_date', weekStart.toIso8601String().split('T')[0]);

      // Monthly pending
      final monthlyInvoices = await client
          .from('invoices')
          .select('total_amount, status')
          .eq('sitter_id', userId)
          .gte('issued_date', monthStart.toIso8601String().split('T')[0]);

      // YTD earnings
      final ytdInvoices = await client
          .from('invoices')
          .select('total_amount')
          .eq('sitter_id', userId)
          .eq('status', 'paid')
          .gte('paid_date', yearStart.toIso8601String().split('T')[0]);

      double weeklyPending = 0;
      double monthlyPending = 0;
      double ytdEarnings = 0;

      for (var invoice in weeklyInvoices) {
        if (invoice['status'] != 'paid') {
          weeklyPending += (invoice['total_amount'] as num?)?.toDouble() ?? 0;
        }
      }

      for (var invoice in monthlyInvoices) {
        if (invoice['status'] != 'paid') {
          monthlyPending += (invoice['total_amount'] as num?)?.toDouble() ?? 0;
        }
      }

      for (var invoice in ytdInvoices) {
        ytdEarnings += (invoice['total_amount'] as num?)?.toDouble() ?? 0;
      }

      return {
        'weeklyPending': weeklyPending,
        'monthlyPending': monthlyPending,
        'ytdEarnings': ytdEarnings,
      };
    } catch (error) {
      throw Exception('Get financial stats failed: $error');
    }
  }

  // Job Check-in Methods
  Future<List<Map<String, dynamic>>> getJobCheckIns({
    String? status,
    DateTime? date,
  }) async {
    try {
      final userId = currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      var query = client.from('job_checkins').select('''
            *,
            booking:bookings!job_checkins_booking_id_fkey (
              *,
              client:clients!bookings_client_id_fkey (
                user_profiles!clients_user_id_fkey (full_name, phone)
              )
            ),
            checkin_tasks (*)
          ''').eq('sitter_id', userId);

      if (status != null) {
        query = query.eq('status', status);
      }

      if (date != null) {
        query = query.gte('checkin_time', date.toIso8601String().split('T')[0]);
        query = query.lt(
          'checkin_time',
          date.add(Duration(days: 1)).toIso8601String().split('T')[0],
        );
      }

      final response = await query.order('checkin_time', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      throw Exception('Get job check-ins failed: $error');
    }
  }

  Future<Map<String, dynamic>> createJobCheckIn({
    required String bookingId,
    required double? lat,
    required double? lng,
    String? address,
    String? notes,
  }) async {
    try {
      final userId = currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await client
          .from('job_checkins')
          .insert({
            'sitter_id': userId,
            'booking_id': bookingId,
            'checkin_time': DateTime.now().toIso8601String(),
            'location_lat': lat,
            'location_lng': lng,
            'location_address': address,
            'notes': notes,
            'status': 'checked_in',
          })
          .select()
          .single();
      return response;
    } catch (error) {
      throw Exception('Create check-in failed: $error');
    }
  }

  Future<Map<String, dynamic>> updateJobCheckOut(String checkinId) async {
    try {
      final response = await client
          .from('job_checkins')
          .update({
            'checkout_time': DateTime.now().toIso8601String(),
            'status': 'checked_out',
          })
          .eq('id', checkinId)
          .select()
          .single();
      return response;
    } catch (error) {
      throw Exception('Update checkout failed: $error');
    }
  }

  // CSV Export Method
  String generateInvoicesCSV(List<Map<String, dynamic>> invoices) {
    final csvData = <List<String>>[];

    // Header
    csvData.add([
      'Invoice Number',
      'Client Name',
      'Service Type',
      'Amount',
      'Status',
      'Issue Date',
      'Due Date',
      'Paid Date',
    ]);

    // Data rows
    for (var invoice in invoices) {
      csvData.add([
        invoice['invoice_number']?.toString() ?? '',
        invoice['client']?['full_name']?.toString() ?? '',
        invoice['booking']?['service_type']?.toString() ?? '',
        '\$${invoice['total_amount']?.toString() ?? '0'}',
        invoice['status']?.toString() ?? '',
        invoice['issued_date']?.toString() ?? '',
        invoice['due_date']?.toString() ?? '',
        invoice['paid_date']?.toString() ?? '',
      ]);
    }

    return csvData.map((row) => row.join(',')).join('\n');
  }

  // Service Rates Management
  Future<List<Map<String, dynamic>>> getServiceRates() async {
    try {
      final userId = currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await client
          .from('service_rates')
          .select('*')
          .eq('sitter_id', userId)
          .eq('is_active', true)
          .order('service_type');
      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      throw Exception('Get service rates failed: $error');
    }
  }

  Future<Map<String, dynamic>> createServiceRate({
    required String serviceType,
    required double baseRate,
    bool isFlat = false,
    double? weekendMultiplier,
    double? holidayMultiplier,
  }) async {
    try {
      final userId = currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await client
          .from('service_rates')
          .insert({
            'sitter_id': userId,
            'service_type': serviceType,
            'base_rate': baseRate,
            'is_flat_rate': isFlat,
            'weekend_multiplier': weekendMultiplier ?? 1.2,
            'holiday_multiplier': holidayMultiplier ?? 1.5,
            'is_active': true,
          })
          .select()
          .single();
      return response;
    } catch (error) {
      throw Exception('Create service rate failed: $error');
    }
  }

  // Helper Methods
  int _calculateDuration(String startTime, String endTime) {
    final start = _parseTime(startTime);
    final end = _parseTime(endTime);

    if (end.isBefore(start)) {
      // Handle overnight bookings
      return (24 - start.hour + end.hour);
    }

    return end.difference(start).inHours;
  }

  DateTime _parseTime(String timeString) {
    final parts = timeString.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, hour, minute);
  }
}
