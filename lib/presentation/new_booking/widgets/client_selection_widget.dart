import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../services/supabase_service.dart';
import '../../../widgets/custom_icon_widget.dart';

class ClientSelectionWidget extends StatefulWidget {
  final List<Map<String, dynamic>> clients;
  final String selectedClientId;
  final Function(Map<String, dynamic>) onClientSelected;
  final VoidCallback? onAddClient;

  const ClientSelectionWidget({
    super.key,
    required this.clients,
    required this.selectedClientId,
    required this.onClientSelected,
    this.onAddClient,
  });

  @override
  State<ClientSelectionWidget> createState() => _ClientSelectionWidgetState();
}

class _ClientSelectionWidgetState extends State<ClientSelectionWidget> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredClients {
    if (_searchQuery.isEmpty) return widget.clients;
    return widget.clients.where((client) {
      return client['name'].toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          client['address'].toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
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
            'Select Client',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Choose which client this booking is for',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),

          SizedBox(height: 3.h),

          // Search bar
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.3),
              ),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search clients...',
                prefixIcon: Padding(
                  padding: EdgeInsets.all(3.w),
                  child: CustomIconWidget(
                    iconName: 'search',
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    size: 5.w,
                  ),
                ),
                suffixIcon:
                    _searchQuery.isNotEmpty
                        ? IconButton(
                          icon: CustomIconWidget(
                            iconName: 'clear',
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.6,
                            ),
                            size: 5.w,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                        : null,
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 4.w,
                  vertical: 3.h,
                ),
              ),
            ),
          ),

          SizedBox(height: 3.h),

          // Add new client button
          Container(
            width: double.infinity,
            margin: EdgeInsets.only(bottom: 3.h),
            child: OutlinedButton.icon(
              onPressed: _showAddClientDialog,
              icon: CustomIconWidget(
                iconName: 'person_add',
                color: theme.colorScheme.primary,
                size: 5.w,
              ),
              label: const Text('Add New Client'),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 3.h),
                side: BorderSide(
                  color: theme.colorScheme.primary.withValues(alpha: 0.3),
                ),
              ),
            ),
          ),

          // Client list
          if (_filteredClients.isEmpty) ...[
            _buildEmptyState(context),
          ] else ...[
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _filteredClients.length,
              itemBuilder: (context, index) {
                final client = _filteredClients[index];
                return _buildClientCard(context, client);
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(8.w),
      child: Column(
        children: [
          CustomIconWidget(
            iconName: 'people_outline',
            color: theme.colorScheme.outline,
            size: 20.w,
          ),
          SizedBox(height: 3.h),
          Text(
            _searchQuery.isNotEmpty ? 'No clients found' : 'No clients yet',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            _searchQuery.isNotEmpty
                ? 'Try adjusting your search terms'
                : 'Add your first client to get started',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildClientCard(BuildContext context, Map<String, dynamic> client) {
    final theme = Theme.of(context);
    final bool isSelected = widget.selectedClientId == client['id'];
    final List<String> pets = List<String>.from(client['pets'] ?? []);

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        widget.onClientSelected(client);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: EdgeInsets.only(bottom: 3.h),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color:
                  isSelected
                      ? theme.colorScheme.primary.withValues(alpha: 0.1)
                      : theme.colorScheme.shadow.withValues(alpha: 0.05),
              blurRadius: isSelected ? 12 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(4.w),
          child: Row(
            children: [
              // Client photo
              Stack(
                children: [
                  CircleAvatar(
                    radius: 8.w,
                    backgroundImage: CachedNetworkImageProvider(
                      client['photo'] as String,
                    ),
                    child: CachedNetworkImage(
                      imageUrl: client['photo'] as String,
                      imageBuilder:
                          (context, imageProvider) => Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              image: DecorationImage(
                                image: imageProvider,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                      placeholder:
                          (context, url) => Container(
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(
                                alpha: 0.1,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: CustomIconWidget(
                                iconName: 'person',
                                color: theme.colorScheme.primary,
                                size: 7.w,
                              ),
                            ),
                          ),
                      errorWidget:
                          (context, url, error) => Container(
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(
                                alpha: 0.1,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: CustomIconWidget(
                                iconName: 'person',
                                color: theme.colorScheme.primary,
                                size: 7.w,
                              ),
                            ),
                          ),
                    ),
                  ),
                  if (isSelected)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: EdgeInsets.all(1.w),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.colorScheme.surface,
                            width: 2,
                          ),
                        ),
                        child: CustomIconWidget(
                          iconName: 'check',
                          color: Colors.white,
                          size: 3.w,
                        ),
                      ),
                    ),
                ],
              ),

              SizedBox(width: 4.w),

              // Client info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      client['name'] as String,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color:
                            isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    Row(
                      children: [
                        CustomIconWidget(
                          iconName: 'phone',
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                          size: 3.w,
                        ),
                        SizedBox(width: 2.w),
                        Text(
                          client['phone'] as String,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.7,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 0.5.h),
                    Row(
                      children: [
                        CustomIconWidget(
                          iconName: 'location_on',
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                          size: 3.w,
                        ),
                        SizedBox(width: 2.w),
                        Expanded(
                          child: Text(
                            client['address'] as String,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.7,
                              ),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (pets.isNotEmpty) ...[
                      SizedBox(height: 1.h),
                      Row(
                        children: [
                          CustomIconWidget(
                            iconName: 'pets',
                            color: theme.colorScheme.tertiary,
                            size: 3.w,
                          ),
                          SizedBox(width: 2.w),
                          Expanded(
                            child: Text(
                              pets.join(', '),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.tertiary,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    SizedBox(height: 1.h),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 2.w,
                        vertical: 0.5.h,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Preferred rate: \$${client['preferredRate']}/hour',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddClientDialog() {
    if (widget.onAddClient != null) {
      widget.onAddClient!();
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => _buildAddClientSheet(),
      );
    }
  }

  Widget _buildAddClientSheet() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    final addressController = TextEditingController();
    final emergencyContactController = TextEditingController();
    final emergencyPhoneController = TextEditingController();
    final notesController = TextEditingController();

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
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
                      color: Theme.of(
                        context,
                      ).colorScheme.outline.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                SizedBox(height: 3.h),

                // Header
                Text(
                  'Add New Client',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),

                SizedBox(height: 3.h),

                // Form fields
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name *',
                    border: OutlineInputBorder(),
                  ),
                ),

                SizedBox(height: 2.h),

                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number *',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                ),

                SizedBox(height: 2.h),

                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email Address *',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),

                SizedBox(height: 2.h),

                TextField(
                  controller: addressController,
                  decoration: const InputDecoration(
                    labelText: 'Address *',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),

                SizedBox(height: 2.h),

                TextField(
                  controller: emergencyContactController,
                  decoration: const InputDecoration(
                    labelText: 'Emergency Contact Name',
                    border: OutlineInputBorder(),
                  ),
                ),

                SizedBox(height: 2.h),

                TextField(
                  controller: emergencyPhoneController,
                  decoration: const InputDecoration(
                    labelText: 'Emergency Contact Phone',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                ),

                SizedBox(height: 2.h),

                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: 'Special Notes',
                    border: OutlineInputBorder(),
                    hintText: 'Any special instructions or notes...',
                  ),
                  maxLines: 3,
                ),

                SizedBox(height: 4.h),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                    ),
                    SizedBox(width: 3.w),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          if (nameController.text.isNotEmpty &&
                              phoneController.text.isNotEmpty &&
                              emailController.text.isNotEmpty &&
                              addressController.text.isNotEmpty) {
                            try {
                              // Show loading
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder:
                                    (context) => const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                              );

                              // Create user profile first
                              final userId =
                                  SupabaseService.instance.client
                                      .from('user_profiles')
                                      .insert({
                                        'full_name': nameController.text,
                                        'email': emailController.text,
                                        'phone': phoneController.text,
                                        'address': addressController.text,
                                        'role': 'client',
                                      })
                                      .select('id')
                                      .single();

                              final userResult = await userId;

                              // Then create client record
                              final clientResponse =
                                  await SupabaseService.instance.client
                                      .from('clients')
                                      .insert({
                                        'user_id': userResult['id'],
                                        'emergency_contact_name':
                                            emergencyContactController.text,
                                        'emergency_contact_phone':
                                            emergencyPhoneController.text,
                                        'special_instructions':
                                            notesController.text,
                                      })
                                      .select('''
                                id,
                                user_profiles!inner (
                                  full_name,
                                  phone,
                                  address,
                                  avatar_url
                                ),
                                emergency_contact_name,
                                emergency_contact_phone,
                                special_instructions
                              ''')
                                      .single();

                              // Close loading dialog
                              Navigator.pop(context);

                              // Close bottom sheet with new client data
                              Navigator.of(context).pop({
                                'id': clientResponse['id'],
                                'name':
                                    clientResponse['user_profiles']['full_name'],
                                'phone':
                                    clientResponse['user_profiles']['phone'],
                                'address':
                                    clientResponse['user_profiles']['address'],
                                'photo':
                                    clientResponse['user_profiles']['avatar_url'] ??
                                    'https://images.unsplash.com/photo-1494790108755-2616b612b47c',
                                'pets': [],
                                'preferredRate': 25.0,
                                'emergency_contact_name':
                                    clientResponse['emergency_contact_name'],
                                'emergency_contact_phone':
                                    clientResponse['emergency_contact_phone'],
                                'special_instructions':
                                    clientResponse['special_instructions'],
                              });
                            } catch (error) {
                              // Close loading dialog
                              Navigator.pop(context);

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to add client: $error'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Please fill all required fields',
                                ),
                                backgroundColor: Colors.orange,
                              ),
                            );
                          }
                        },
                        child: const Text('Add Client'),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 2.h),
              ],
            ),
          );
        },
      ),
    );
  }
}
