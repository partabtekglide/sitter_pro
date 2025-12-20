import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_export.dart';
import './widgets/bookings_timeline_widget.dart';
import './widgets/client_info_card.dart';
import './widgets/emergency_contacts_widget.dart';
import './widgets/notes_widget.dart';
import './widgets/pets_kids_widget.dart';
import './edit_client_screen.dart';
import '../../services/supabase_service.dart';

class ClientProfile extends StatefulWidget {
  const ClientProfile({super.key});

  @override
  State<ClientProfile> createState() => _ClientProfileState();
}

class _ClientProfileState extends State<ClientProfile>
    with TickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic> _clientData = {};
  bool _isDataLoaded = false;

  // Mock data for other sections (keep these for now or fetch if available)
  List<Map<String, dynamic>> _emergencyContacts = [
    {
      "id": 1,
      "name": "Michael Johnson",
      "relationship": "Husband",
      "phone": "(555) 123-4568",
    },
  ];

  List<Map<String, dynamic>> _petsKids = [];

  List<Map<String, dynamic>> _bookings = [];
  bool _isLoadingBookings = false;

  List<Map<String, dynamic>> _notes = [];
  bool _isLoadingNotes = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  Future<void> _loadBookings() async {
    if (_clientData['id'] == null) return;

    setState(() {
      _isLoadingBookings = true;
    });

    try {
      final rawBookings = await SupabaseService.instance.getBookings(
        clientId: _clientData['id'].toString(),
      );

      final formatted = rawBookings.map((b) {
        return {
          "id": b['id'],
          "service": _formatServiceType(b['service_type']),
          "date": b['start_date'],
          "time": "${_formatTime(b['start_time'])} - ${_formatTime(b['end_time'] ?? '')}",
          "duration": b['duration_hours']?.toString() ?? "0",
          "amount": "\$${b['total_amount']?.toString() ?? '0'}",
          "status": _capitalize(b['status'] ?? 'pending'),
          "paymentStatus": "Pending", // TODO: Add payment status to DB
          "notes": b['special_instructions'] ?? "",
        };
      }).toList();
      print("formatted: $formatted"); 
      if (mounted) {
        setState(() {
          _bookings = formatted;
          _isLoadingBookings = false;
        });
      }
    } catch (e) {
      print('Error loading client bookings: $e');
      if (mounted) {
        setState(() {
          _isLoadingBookings = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load bookings: $e')),
        );
      }
    }
  }

  String _formatServiceType(String? type) {
    if (type == null) return 'Service';
    return type.split('_').map((word) => _capitalize(word)).join(' ');
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  String _formatTime(String time) {
    if (time.isEmpty) return '';
    try {
      final parts = time.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      final dt = DateTime(2022, 1, 1, hour, minute);
      return TimeOfDay.fromDateTime(dt).format(context);
    } catch (e) {
      return time;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isDataLoaded) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args != null && args is Map<String, dynamic>) {
        _initializeData(args);
        // Load bookings immediately after initializing data
        _loadBookings();
        _loadNotes();
      }
      _isDataLoaded = true;
    }
  }

  void _initializeData(Map<String, dynamic> args) {
    setState(() {
      _clientData = {
        "id": args['id'],
        "name": args['name'] ?? 'Unknown Client',
        "phone": args['phone'] ?? '',
        "email": args['email'] ?? '',
        "address": args['address'] ?? '',
        "avatar": args['avatar'],
        "avatarSemanticLabel": args['semanticLabel'],
        "joinDate": args['joinDate'] ?? "2024-01-01",
        "totalBookings": 0, // Placeholder
        "preferredServices": args['serviceTypes'] ?? [],
        "specialInstructions": args['specialInstructions'] ??
            "No special instructions provided.",
        "emergency_contact_name": args['emergency_contact_name'],
        "emergency_contact_phone": args['emergency_contact_phone'],
      };

      // Handle emergency contacts
      if (args['emergency_contact_name'] != null) {
        _emergencyContacts = [
          {
            "id": 1,
            "name": args['emergency_contact_name'],
            "relationship": "Emergency Contact",
            "phone": args['emergency_contact_phone'] ?? '',
          }
        ];
      } else {
        _emergencyContacts = [];
      }

      // Handle pets
      if (args['rawPets'] != null && args['rawPets'] is List) {
        final petsList = args['rawPets'] as List;
        _petsKids = petsList.map((pet) {
          return {
            "id": pet['id'],
            "name": pet['name'] ?? 'Unknown',
            "type": pet['type'] ?? 'Pet',
            "breed": "Unknown", // Not in DB yet
            "age": 0, // Not in DB yet
            "image": "https://images.unsplash.com/photo-1583337130417-3346a1be7dee",
            "imageSemanticLabel": "${pet['name']} the ${pet['type']}",
            "specialNotes": "",
            "medicalInfo": "",
            "vetInfo": "",
          };
        }).toList();
      } else if (args['pets'] != null && args['pets'] is List) {
        // Fallback to parsing strings if rawPets not available
        final petsList = args['pets'] as List;
        _petsKids = petsList.asMap().entries.map((entry) {
          final petString = entry.value.toString();
          String name = petString;
          String type = 'Pet';
          
          if (petString.contains('(')) {
            final parts = petString.split('(');
            name = parts[0].trim();
            type = parts[1].replaceAll(')', '').trim();
          }

          return {
            "id": entry.key,
            "name": name,
            "type": type,
            "breed": "Unknown",
            "age": 0,
            "image": "https://images.unsplash.com/photo-1583337130417-3346a1be7dee",
            "imageSemanticLabel": "$name the $type",
            "specialNotes": "",
            "medicalInfo": "",
            "vetInfo": "",
          };
        }).toList();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          _clientData["name"] as String? ?? "Client Profile",
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: CustomIconWidget(
            iconName: 'arrow_back',
            size: 24,
            color: theme.colorScheme.onSurface,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _editClient,
            icon: CustomIconWidget(
              iconName: 'edit',
              size: 24,
              color: theme.colorScheme.primary,
            ),
            tooltip: 'Edit Client',
          ),
        ],
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: theme.brightness == Brightness.light
              ? Brightness.dark
              : Brightness.light,
        ),
      ),
      body: Column(
        children: [
          // Client Info Card
          ClientInfoCard(
            clientData: _clientData,
            onCall: _callClient,
            onMessage: _messageClient,
            onNavigate: _navigateToClient,
          ),

          // Tab Bar
          Container(
            margin: EdgeInsets.symmetric(horizontal: 4.w),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Overview'),
                // Tab(text: 'Pets/Kids'),
                Tab(text: 'Bookings'),
                Tab(text: 'Notes'),
              ],
              labelStyle: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w400,
              ),
              indicator: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              indicatorPadding: EdgeInsets.all(1.w),
              labelColor: theme.colorScheme.onPrimary,
              unselectedLabelColor:
                  theme.colorScheme.onSurface.withValues(alpha: 0.7),
              dividerColor: Colors.transparent,
            ),
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Overview Tab
                SingleChildScrollView(
                  padding: EdgeInsets.only(top: 2.h, bottom: 10.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildOverviewSection(context),
                      SizedBox(height: 2.h),
                      EmergencyContactsWidget(
                        emergencyContacts: _emergencyContacts,
                        onContactTap: _callEmergencyContact,
                      ),
                    ],
                  ),
                ),

                // Pets/Kids Tab
                // SingleChildScrollView(
                //   padding: EdgeInsets.only(top: 2.h, bottom: 10.h),
                //   child: PetsKidsWidget(
                //     petsKids: _petsKids,
                //     onPetKidTap: _viewPetKidProfile,
                //     onLongPress: _showPetKidOptions,
                //   ),
                // ),

                // Bookings Tab
                _isLoadingBookings
                    ? const Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(
                        padding: EdgeInsets.only(top: 2.h, bottom: 10.h),
                        child: BookingsTimelineWidget(
                          bookings: _bookings,
                          onBookingTap: _viewBookingDetails,
                          onDuplicate: _duplicateBooking,
                          onInvoice: _generateInvoice,
                          onMarkPaid: _markBookingPaid,
                        ),
                      ),

                // Notes Tab
                _isLoadingNotes
                    ? const Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(
                        padding: EdgeInsets.only(top: 2.h, bottom: 10.h),
                        child: NotesWidget(
                          notes: _notes,
                          onAddNote: _addNote,
                          onEditNote: _editNote,
                          onDeleteNote: _deleteNote,
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createNewBooking,
        icon: CustomIconWidget(
          iconName: 'add',
          size: 24,
          color: theme.colorScheme.onPrimary,
        ),
        label: Text(
          'New Booking',
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: theme.colorScheme.primary,
        elevation: 3,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildOverviewSection(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Client Overview',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 2.h),

          // Stats Cards
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  context,
                  'Total Bookings',
                  '${_clientData["totalBookings"]}',
                  Icons.event_note,
                  theme.colorScheme.primary,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: _buildStatCard(
                  context,
                  'Client Since',
                  _formatJoinDate(_clientData["joinDate"] as String? ?? ""),
                  Icons.calendar_today,
                  theme.colorScheme.secondary,
                ),
              ),
            ],
          ),

          SizedBox(height: 3.h),

          // Preferred Services
          if (_clientData["preferredServices"] != null) ...[
            Text(
              'Preferred Services',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 1.h),
            Wrap(
              spacing: 2.w,
              runSpacing: 1.h,
              children:
                  (_clientData["preferredServices"] as List).map((service) {
                return Container(
                  padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    service as String,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 3.h),
          ],

          // Special Instructions
          if (_clientData["specialInstructions"] != null) ...[
            Text(
              'Special Instructions',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 1.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomIconWidget(
                    iconName: 'info',
                    size: 20,
                    color: theme.colorScheme.secondary,
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      _clientData["specialInstructions"] as String,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value,
      IconData icon, Color color) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: CustomIconWidget(
              iconName: icon.toString().split('.').last,
              size: 24,
              color: color,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _formatJoinDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
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
        'Dec'
      ];
      return '${months[date.month - 1]} ${date.year}';
    } catch (e) {
      return 'Unknown';
    }
  }

  // Action Methods
  Future<void> _editClient() async {
    final updatedData = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditClientScreen(clientData: _clientData),
      ),
    );

    if (updatedData != null && updatedData is Map<String, dynamic>) {
      setState(() {
        _clientData = updatedData;
        
        // Update emergency contacts list
        if (updatedData['emergency_contact_name'] != null) {
          _emergencyContacts = [
            {
              "id": 1,
              "name": updatedData['emergency_contact_name'],
              "relationship": "Emergency Contact",
              "phone": updatedData['emergency_contact_phone'] ?? '',
            }
          ];
        } else {
          _emergencyContacts = [];
        }
      });
    }
  }

  void _callClient() async {
    final phone = _clientData["phone"] as String?;
    if (phone == null || phone.isEmpty) return;

    final url = Uri.parse('tel:${phone.replaceAll(RegExp(r'[^\d+]'), '')}');
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch dialer: $e')),
        );
      }
    }
  }

  void _messageClient() {
    Navigator.pushNamed(
      context,
      AppRoutes.communicationHub,
      arguments: {'clientId': _clientData["id"]},
    );
  }

  void _navigateToClient() {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening navigation...'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _callEmergencyContact(Map<String, dynamic> contact) async {
    final phone = contact["phone"] as String?;
    if (phone == null || phone.isEmpty) return;

    final url = Uri.parse('tel:${phone.replaceAll(RegExp(r'[^\d+]'), '')}');
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch dialer: $e')),
        );
      }
    }
  }

  void _viewPetKidProfile(Map<String, dynamic> petKid) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening ${petKid["name"]} profile...'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showPetKidOptions(Map<String, dynamic> petKid) {
    // This is handled by the widget itself
  }

  void _viewBookingDetails(Map<String, dynamic> booking) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening booking details...'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _duplicateBooking(Map<String, dynamic> booking) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Duplicating ${booking["service"]} booking...'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _generateInvoice(Map<String, dynamic> booking) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Generating invoice for ${booking["service"]}...'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _markBookingPaid(Map<String, dynamic> booking) {
    HapticFeedback.lightImpact();
    setState(() {
      final index = _bookings.indexWhere((b) => b["id"] == booking["id"]);
      if (index != -1) {
        _bookings[index]["paymentStatus"] = "Paid";
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Marked booking as paid'),
        duration: const Duration(seconds: 2),
        backgroundColor: AppTheme.successLight,
      ),
    );
  }

  Future<void> _loadNotes() async {
    if (_clientData['id'] == null) return;

    setState(() {
      _isLoadingNotes = true;
    });

    try {
      final rawNotes = await SupabaseService.instance.getClientNotes(
        _clientData['id'].toString(),
      );

      if (mounted) {
        setState(() {
          _notes = rawNotes.map((n) {
            return {
              "id": n['id'],
              "content": n['content'],
              "timestamp": n['created_at'],
              "isRichText": false,
            };
          }).toList();
          _isLoadingNotes = false;
        });
      }
    } catch (e) {
      print('Error loading client notes: $e');
      if (mounted) {
        setState(() {
          _isLoadingNotes = false;
        });
      }
    }
  }

  Future<void> _addNote(String content) async {
    if (_clientData['id'] == null) return;

    try {
      final newNote = await SupabaseService.instance.addClientNote(
        clientId: _clientData['id'].toString(),
        content: content,
      );

      setState(() {
        _notes.insert(0, {
          "id": newNote['id'],
          "content": newNote['content'],
          "timestamp": newNote['created_at'],
          "isRichText": false,
        });
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Note added successfully'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add note: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _editNote(Map<String, dynamic> note) async {
    try {
      final updatedNote = await SupabaseService.instance.updateClientNote(
        noteId: note['id'].toString(),
        content: note['content'],
      );

      setState(() {
        final index = _notes.indexWhere((n) => n["id"] == note["id"]);
        if (index != -1) {
          _notes[index] = {
            "id": updatedNote['id'],
            "content": updatedNote['content'],
            "timestamp": updatedNote['created_at'],
            "isRichText": false,
          };
        }
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Note updated successfully'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update note: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteNote(Map<String, dynamic> note) async {
    try {
      await SupabaseService.instance.deleteClientNote(note['id'].toString());

      setState(() {
        _notes.removeWhere((n) => n["id"] == note["id"]);
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Note deleted'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete note: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _createNewBooking() {
    Navigator.pushNamed(
      context,
      AppRoutes.newBooking,
      arguments: {'clientId': _clientData["id"]},
    );
  }
}
