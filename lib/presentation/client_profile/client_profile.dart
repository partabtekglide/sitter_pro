import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import './widgets/bookings_timeline_widget.dart';
import './widgets/client_info_card.dart';
import './widgets/emergency_contacts_widget.dart';
import './widgets/notes_widget.dart';
import './widgets/pets_kids_widget.dart';

class ClientProfile extends StatefulWidget {
  const ClientProfile({super.key});

  @override
  State<ClientProfile> createState() => _ClientProfileState();
}

class _ClientProfileState extends State<ClientProfile>
    with TickerProviderStateMixin {
  late TabController _tabController;

  // Mock client data
  final Map<String, dynamic> _clientData = {
    "id": 1,
    "name": "Sarah Johnson",
    "phone": "(555) 123-4567",
    "email": "sarah.johnson@email.com",
    "address": "1234 Maple Street, Springfield, IL 62701",
    "avatar":
        "https://img.rocket.new/generatedImages/rocket_gen_img_126100cab-1762273569433.png",
    "avatarSemanticLabel":
        "Professional headshot of a woman with shoulder-length brown hair wearing a navy blue blazer, smiling at the camera against a neutral background",
    "joinDate": "2024-03-15",
    "totalBookings": 12,
    "preferredServices": ["Pet Sitting", "Dog Walking"],
    "specialInstructions":
        "Please use the side gate entrance. Dogs are very friendly but excited when meeting new people.",
  };

  final List<Map<String, dynamic>> _emergencyContacts = [
    {
      "id": 1,
      "name": "Michael Johnson",
      "relationship": "Husband",
      "phone": "(555) 123-4568",
    },
    {
      "id": 2,
      "name": "Dr. Emily Chen",
      "relationship": "Veterinarian",
      "phone": "(555) 987-6543",
    },
  ];

  final List<Map<String, dynamic>> _petsKids = [
    {
      "id": 1,
      "name": "Max",
      "type": "Pet",
      "breed": "Golden Retriever",
      "age": 3,
      "image":
          "https://images.unsplash.com/photo-1633722714057-aaa9bf7f2383",
      "imageSemanticLabel":
          "Golden retriever dog sitting outdoors on grass with tongue out, looking happy and alert",
      "specialNotes": "Loves treats, needs medication twice daily",
      "medicalInfo":
          "Takes arthritis medication morning and evening. Allergic to chicken-based treats.",
      "vetInfo": "Dr. Emily Chen - Springfield Animal Hospital",
    },
    {
      "id": 2,
      "name": "Luna",
      "type": "Pet",
      "breed": "Persian Cat",
      "age": 2,
      "image":
          "https://images.unsplash.com/photo-1632300218303-069300b05723",
      "imageSemanticLabel":
          "White Persian cat with long fluffy fur sitting elegantly, looking directly at camera with bright blue eyes",
      "specialNotes": "Shy with strangers, hides under bed",
      "medicalInfo": "Regular grooming needed. No known allergies.",
      "vetInfo": "Dr. Emily Chen - Springfield Animal Hospital",
    },
    {
      "id": 3,
      "name": "Emma",
      "type": "Child",
      "age": 8,
      "image":
          "https://images.unsplash.com/photo-1615473137677-d7e7b93e80ec",
      "imageSemanticLabel":
          "Young girl with curly brown hair wearing a pink sweater, smiling brightly while sitting at a desk with books",
      "specialNotes": "Bedtime at 8 PM, loves reading stories",
      "medicalInfo": "No known allergies. Takes vitamins with breakfast.",
    },
  ];

  final List<Map<String, dynamic>> _bookings = [
    {
      "id": 1,
      "service": "Pet Sitting",
      "date": "2024-11-10",
      "time": "9:00 AM - 6:00 PM",
      "duration": "9",
      "amount": "\$180",
      "status": "Completed",
      "paymentStatus": "Paid",
      "notes":
          "Max was great today! Took him for two long walks and he enjoyed playing in the backyard.",
    },
    {
      "id": 2,
      "service": "Dog Walking",
      "date": "2024-11-08",
      "time": "12:00 PM - 1:00 PM",
      "duration": "1",
      "amount": "\$25",
      "status": "Completed",
      "paymentStatus": "Paid",
    },
    {
      "id": 3,
      "service": "Pet Sitting",
      "date": "2024-11-05",
      "time": "8:00 AM - 7:00 PM",
      "duration": "11",
      "amount": "\$220",
      "status": "Completed",
      "paymentStatus": "Pending",
      "notes": "Both pets did well. Luna came out from hiding after an hour.",
    },
    {
      "id": 4,
      "service": "Babysitting",
      "date": "2024-11-15",
      "time": "6:00 PM - 11:00 PM",
      "duration": "5",
      "amount": "\$100",
      "status": "Confirmed",
      "paymentStatus": "Pending",
      "notes":
          "Emma's bedtime routine: story, brush teeth, lights out by 8 PM.",
    },
  ];

  List<Map<String, dynamic>> _notes = [
    {
      "id": 1,
      "content":
          "Sarah is very organized and always leaves detailed instructions. The pets are well-trained and the house is always clean.",
      "timestamp": "2024-11-09T14:30:00Z",
      "isRichText": false,
    },
    {
      "id": 2,
      "content":
          "Remember to check the back door lock - it sometimes doesn't latch properly. Sarah mentioned this during our last conversation.",
      "timestamp": "2024-11-07T10:15:00Z",
      "isRichText": false,
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
                Tab(text: 'Pets/Kids'),
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
                SingleChildScrollView(
                  padding: EdgeInsets.only(top: 2.h, bottom: 10.h),
                  child: PetsKidsWidget(
                    petsKids: _petsKids,
                    onPetKidTap: _viewPetKidProfile,
                    onLongPress: _showPetKidOptions,
                  ),
                ),

                // Bookings Tab
                SingleChildScrollView(
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
                SingleChildScrollView(
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
  void _editClient() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Edit client feature coming soon'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _callClient() {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Calling ${_clientData["name"]}...'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _messageClient() {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening message to ${_clientData["name"]}...'),
        duration: const Duration(seconds: 2),
      ),
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

  void _callEmergencyContact(Map<String, dynamic> contact) {
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Calling ${contact["name"]} - ${contact["phone"]}'),
        duration: const Duration(seconds: 2),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
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

  void _addNote(String content) {
    setState(() {
      _notes.insert(0, {
        "id": _notes.length + 1,
        "content": content,
        "timestamp": DateTime.now().toIso8601String(),
        "isRichText": false,
      });
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Note added successfully'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _editNote(Map<String, dynamic> note) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Edit note feature coming soon'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _deleteNote(Map<String, dynamic> note) {
    setState(() {
      _notes.removeWhere((n) => n["id"] == note["id"]);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Note deleted'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _createNewBooking() {
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Creating new booking for ${_clientData["name"]}...'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
