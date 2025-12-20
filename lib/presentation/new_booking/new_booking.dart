import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_icon_widget.dart';
import './widgets/service_selection_widget.dart';
import './widgets/client_selection_widget.dart';
import './widgets/date_time_picker_widget.dart';
import './widgets/booking_details_widget.dart';
import './widgets/rate_calculator_widget.dart';
import '../client_list/widgets/add_client_sheet.dart';
import '../../services/supabase_service.dart';

class NewBooking extends StatefulWidget {
  const NewBooking({super.key});

  @override
  State<NewBooking> createState() => _NewBookingState();
}

class _NewBookingState extends State<NewBooking> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 5;

  // Booking data
  Map<String, dynamic> _bookingData = {
    'serviceType': '',
    'clientId': '',
    'clientName': '',
    'startDate': null,
    'endDate': null,
    'startTime': null,
    'endTime': null,
    'hourlyRate': 0.0,
    'totalAmount': 0.0,
    'specialInstructions': '',
    'petDetails': '',
    'emergencyContact': '',
    'address': '',
    'duration': 0,
    'isRecurring': false,
    'recurringPattern': 'weekly',
    'recurrenceEndDate': null,
  };

  // Real client data from Supabase
  List<Map<String, dynamic>> _clients = [];
  bool _isLoadingClients = true;
  Map<String, dynamic>? _selectedClient;

  @override
  void initState() {
    super.initState();
    _loadClients();
  }

  /// Supabase se clients fetch karo
  Future<void> _loadClients() async {
    setState(() {
      _isLoadingClients = true;
    });

    try {
      final rawClients = await SupabaseService.instance.getClients();
      print('Supabase NewBooking clients: $rawClients');

      final formatted = rawClients.map<Map<String, dynamic>>((row) {
        final pets = (row['pets_kids'] ?? []) as List<dynamic>;

        return {
          "id": row['id']?.toString() ?? '',
          "name": row['full_name'] ?? 'Unknown Client',
          "photo": row['avatar_url'] ??
              "https://images.unsplash.com/photo-1494790108755-2616b612b47c",
          "phone": row['phone'] ?? '',
          "address": row['address'] ?? '',
          "pets": pets,
          "preferredRate": (row['preferred_rate'] as num?)?.toDouble() ?? 25.0,
        };
      }).toList();

      setState(() {
        _clients = formatted;
        _isLoadingClients = false;

        // Auto-select client if ID is provided in arguments
        final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        if (args != null && args.containsKey('clientId')) {
          final initialClientId = args['clientId'].toString();
          final client = _clients.firstWhere(
            (c) => c['id'] == initialClientId,
            orElse: () => {},
          );
          
          if (client.isNotEmpty) {
            _bookingData['clientId'] = client['id'];
            _bookingData['clientName'] = client['name'];
            _bookingData['hourlyRate'] = client['preferredRate'];
          }
        }
      });
    } catch (e) {
      print('Error loading clients for NewBooking: $e');
      setState(() {
        _isLoadingClients = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load clients: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      setState(() {
        _currentStep++;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _updateBookingData(Map<String, dynamic> data) {
    setState(() {
      _bookingData.addAll(data);
    });
  }

  void _submitBooking() async {
    // Pehle validation
    if (!_validateBookingData()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete all required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Safe locals nikaal lo
    final clientId = _bookingData['clientId']?.toString();
    final serviceType = _bookingData['serviceType']?.toString();
    final startDate = _bookingData['startDate'] as DateTime?;
    final endDate = _bookingData['endDate'] as DateTime?;
    final startTime = _bookingData['startTime'] as TimeOfDay?;
    final endTime = _bookingData['endTime'] as TimeOfDay?;
    final hourlyRate = (_bookingData['hourlyRate'] as num?)?.toDouble() ?? 0.0;
    final address = _bookingData['address']?.toString() ?? '';
    final specialInstructions = _bookingData['specialInstructions']?.toString();

    // Extra null checks
    if (clientId == null ||
        clientId.isEmpty ||
        serviceType == null ||
        serviceType.isEmpty ||
        startDate == null ||
        startTime == null ||
        hourlyRate <= 0 ||
        address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Some required booking fields are missing'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    HapticFeedback.mediumImpact();

    try {
      if (!mounted) return;

      // Loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      final currentUser = SupabaseService.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      await SupabaseService.instance.createBooking(
        clientId: clientId,
        sitterId: currentUser.id,
        serviceType: serviceType.toLowerCase().replaceAll(' ', '_'),
        startDate: startDate,
        endDate: endDate,
        startTime: _formatTimeForDatabase(startTime),
        endTime: _formatTimeForDatabase(endTime),
        hourlyRate: hourlyRate,
        address: address,
        specialInstructions: specialInstructions,
        isRecurring: _bookingData['isRecurring'] ?? false,
        recurrenceRule: _bookingData['recurringPattern'],
        recurrenceEndDate: _bookingData['recurrenceEndDate'],
      );

      if (!mounted) return;

      // Loading band karo
      Navigator.of(context).pop();

      // Success dialog
      showDialog(
        context: context,
        builder: (_) => _buildConfirmationDialog(),
      );
    } catch (error) {
      if (!mounted) return;

      // Agar error aaye to loading dialog band karo
      Navigator.of(context).pop();
      print( 'Error creating booking: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create booking: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  bool _validateBookingData() {
    return _bookingData['serviceType'].toString().isNotEmpty &&
        _bookingData['clientId'].toString().isNotEmpty &&
        _bookingData['startDate'] != null &&
        _bookingData['startTime'] != null &&
        _bookingData['totalAmount'] > 0;
  }

  bool _canProceedToNext() {
    switch (_currentStep) {
      case 0: // Service selection
        return _bookingData['serviceType']?.toString().isNotEmpty ?? false;

      case 1: // Client selection
        return _bookingData['clientId']?.toString().isNotEmpty ?? false;

      case 2: // Date/time selection
        return _bookingData['startDate'] != null &&
            _bookingData['startTime'] != null;

      case 3: // Booking details
        return _bookingData['address']?.toString().isNotEmpty ?? false;

      case 4: // Rate calculation
        final total = _bookingData['totalAmount'];
        return (total is num) && total > 0;

      default:
        return false;
    }
  }

  String _formatTimeForDatabase(TimeOfDay? time) {
    if (time == null) return '';
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _onAddClient() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddClientSheet(),
    );

    if (result == null || !mounted) return;

    try {
      // 1) Supabase me client create karo
      final createdClient = await SupabaseService.instance.createInlineClient(
        fullName: result['name'] ?? '',
        phone: result['phone'] ?? '',
        email: result['email'] ?? '',
        address: result['address'] ?? '',
        emergencyContactName: result['emergency_contact'],
        emergencyContactPhone: result['emergency_phone'],
        notes: result['notes'],
        preferredRate: (result['preferredRate'] as num?)?.toDouble(),
      );

      final String clientId = createdClient['id'].toString();

// 2) Local list me nicely formatted client entry
      final formattedClient = {
        "id": clientId,
        "name": createdClient['full_name'] ?? result['name'] ?? '',
        "photo": createdClient['avatar_url'] ??
            "https://plus.unsplash.com/premium_photo-1689568126014-06fea9d5d341?q=80&w=1170&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D",
        "phone": createdClient['phone'] ?? result['phone'] ?? '',
        "address": createdClient['address'] ?? result['address'] ?? '',
        "pets": const [], // abhi koi pets linked nahi
        "preferredRate":
            (createdClient['preferred_rate'] as num?)?.toDouble() ?? 25.0,
      };

      // 3) Booking data update karo (ab clientId proper UUID hai)
      setState(() {
        _clients.add(formattedClient);
        _bookingData['clientId'] = clientId;
        _bookingData['clientName'] = formattedClient['name'];
        _bookingData['address'] = formattedClient['address'];
        _bookingData['hourlyRate'] = formattedClient['preferredRate'];
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Client ${formattedClient['name']} added and selected'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create client: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: 'New Booking',
        variant: CustomAppBarVariant.standard,
        onBackPressed: () {
          if (_currentStep > 0) {
            _previousStep();
          } else {
            Navigator.pop(context);
          }
        },
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            _buildProgressIndicator(),

            // Step content
            Expanded(
              child: _isLoadingClients
                  ? const Center(child: CircularProgressIndicator())
                  : PageView(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        // Step 1: Service Selection
                        ServiceSelectionWidget(
                          selectedService:
                              (_bookingData['serviceType'] ?? '') as String,
                          onServiceSelected: (service) {
                            _updateBookingData({'serviceType': service});
                          },
                        ),

                        // Step 2: Client Selection
                        ClientSelectionWidget(
                          clients: _clients,
                          selectedClientId:
                              (_bookingData['clientId'] ?? '') as String,
                          onClientSelected: (client) {
                            _updateBookingData({
                              'clientId': client['id'],
                              'clientName': client['name'],
                              'hourlyRate': client['preferredRate'],
                            });
                          },
                          onAddClient: _onAddClient,
                        ),

                        // Step 3: Date/Time Selection
                        DateTimePickerWidget(
                          startDate: _bookingData['startDate'] as DateTime?,
                          endDate: _bookingData['endDate'] as DateTime?,
                          startTime: _bookingData['startTime'] as TimeOfDay?,
                          endTime: _bookingData['endTime'] as TimeOfDay?,
                          onDateTimeSelected: (dateTimeData) {
                            _updateBookingData(dateTimeData);
                          },
                        ),

                        // Step 4: Booking Details
                        BookingDetailsWidget(
                          address: (_bookingData['address'] ?? '') as String,
                          serviceType:
                              (_bookingData['serviceType'] ?? '') as String,
                          specialInstructions:
                              (_bookingData['specialInstructions'] ?? '')
                                  as String,
                          petDetails:
                              (_bookingData['petDetails'] ?? '') as String,
                          emergencyContact: (_bookingData['emergencyContact'] ??
                              '') as String,
                          onDetailsUpdated: (details) {
                            _updateBookingData(details);
                          },
                        ),

                        // Step 5: Rate Calculation & Review
                        RateCalculatorWidget(
                          bookingData: _bookingData,
                          onRateCalculated: (rateData) {
                            _updateBookingData(rateData);
                          },
                        ),
                      ],
                    ),
            ),

            // Navigation buttons
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'Step ${_currentStep + 1} of $_totalSteps',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Text(
                '${((_currentStep + 1) / _totalSteps * 100).round()}%',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          LinearProgressIndicator(
            value: (_currentStep + 1) / _totalSteps,
            backgroundColor: theme.colorScheme.outline.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation<Color>(
              theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _previousStep,
                icon: CustomIconWidget(
                  iconName: 'arrow_back',
                  color: theme.colorScheme.primary,
                  size: 4.w,
                ),
                label: const Text('Previous'),
              ),
            ),
          if (_currentStep > 0) SizedBox(width: 4.w),
          Expanded(
            child: _currentStep == _totalSteps - 1
                ? ElevatedButton.icon(
                    onPressed: _canProceedToNext() ? _submitBooking : null,
                    icon: CustomIconWidget(
                      iconName: 'check',
                      color: theme.colorScheme.onPrimary,
                      size: 4.w,
                    ),
                    label: const Text('Create Booking'),
                  )
                : ElevatedButton.icon(
                    onPressed: _canProceedToNext() ? _nextStep : null,
                    icon: CustomIconWidget(
                      iconName: 'arrow_forward',
                      color: theme.colorScheme.onPrimary,
                      size: 4.w,
                    ),
                    label: const Text('Next'),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmationDialog() {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Row(
        children: [
          CustomIconWidget(
            iconName: 'check_circle',
            color: Colors.green,
            size: 6.w,
          ),
          SizedBox(width: 3.w),
          const Text('Booking Created'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your booking has been successfully created and is now pending client confirmation!',
            style: theme.textTheme.bodyLarge,
          ),
          SizedBox(height: 2.h),
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Booking Summary',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 1.h),
                Text('Service: ${_bookingData['serviceType']}'),
                Text('Client: ${_bookingData['clientName']}'),
              if (_bookingData['isRecurring'] == true)
                Text(
                  'Recurring: ${_bookingData['recurringPattern'].toString()[0].toUpperCase()}${_bookingData['recurringPattern'].toString().substring(1)}',
                  style: TextStyle(color: theme.colorScheme.primary),
                ),
              Text(
                'Total: \$${_bookingData['totalAmount'].toStringAsFixed(2)}',
              ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context); // Close dialog
            Navigator.pop(context); // Go back to previous screen
          },
          child: const Text('Done'),
        ),
      ],
    );
  }
}
