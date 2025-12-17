import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class ClientSelectionStep extends StatefulWidget {
  final List<Map<String, dynamic>> clients;
  final Map<String, dynamic>? selectedClient;
  final Function(Map<String, dynamic>) onClientSelected;
  final VoidCallback onAddNewClient;

  const ClientSelectionStep({
    super.key,
    required this.clients,
    required this.selectedClient,
    required this.onClientSelected,
    required this.onAddNewClient,
  });

  @override
  State<ClientSelectionStep> createState() => _ClientSelectionStepState();
}

class _ClientSelectionStepState extends State<ClientSelectionStep> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _filteredClients = [];

  @override
  void initState() {
    super.initState();
    _filteredClients = widget.clients;
    _searchController.addListener(_filterClients);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterClients);
    _searchController.dispose();
    super.dispose();
  }

  void _filterClients() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredClients =
          widget.clients.where((client) {
            final name = client['name'].toString().toLowerCase();
            final email = client['email'].toString().toLowerCase();
            final phone = client['phone'].toString().toLowerCase();
            return name.contains(query) ||
                email.contains(query) ||
                phone.contains(query);
          }).toList();
    });
  }

  List<Map<String, dynamic>> get _recentClients {
    return _filteredClients
        .where((client) => client['isRecent'] == true)
        .toList();
  }

  List<Map<String, dynamic>> get _allClients {
    return _filteredClients;
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
            'Choose a client for this booking or add a new one',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),

          SizedBox(height: 3.h),

          // Search Bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search clients........',
              prefixIcon: Padding(
                padding: EdgeInsets.all(3.w),
                child: CustomIconWidget(
                  iconName: 'search',
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  size: 5.w,
                ),
              ),
              suffixIcon:
                  _searchController.text.isNotEmpty
                      ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                        },
                        icon: CustomIconWidget(
                          iconName: 'close',
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                          size: 4.w,
                        ),
                      )
                      : null,
            ),
          ),

          SizedBox(height: 3.h),

          // Add New Client Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: widget.onAddNewClient,
              icon: CustomIconWidget(
                iconName: 'person_add',
                color: theme.colorScheme.primary,
                size: 5.w,
              ),
              label: const Text('Add New Client'),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 3.h),
              ),
            ),
          ),

          SizedBox(height: 4.h),

          // Recent Clients Section
          if (_recentClients.isNotEmpty) ...[
            Row(
              children: [
                CustomIconWidget(
                  iconName: 'history',
                  color: theme.colorScheme.primary,
                  size: 5.w,
                ),
                SizedBox(width: 2.w),
                Text(
                  'Recent Clients',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),

            SizedBox(height: 2.h),

            ...(_recentClients.map(
              (client) => _buildClientCard(client, theme),
            )),

            SizedBox(height: 4.h),
          ],

          // All Clients Section
          Row(
            children: [
              CustomIconWidget(
                iconName: 'people',
                color: theme.colorScheme.primary,
                size: 5.w,
              ),
              SizedBox(width: 2.w),
              Text(
                'All Clients',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),

          SizedBox(height: 2.h),

          // Clients List
          if (_allClients.isEmpty)
            _buildEmptyState(theme)
          else
            ...(_allClients.map((client) => _buildClientCard(client, theme))),

          SizedBox(height: 10.h), // Extra space for bottom navigation
        ],
      ),
    );
  }

  Widget _buildClientCard(Map<String, dynamic> client, ThemeData theme) {
    final isSelected = widget.selectedClient?['id'] == client['id'];

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      child: InkWell(
        onTap: () => widget.onClientSelected(client),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border:
                isSelected
                    ? Border.all(color: theme.colorScheme.primary, width: 2)
                    : null,
            color:
                isSelected
                    ? theme.colorScheme.primary.withValues(alpha: 0.05)
                    : null,
          ),
          child: Row(
            children: [
              // Profile Image
              Container(
                width: 15.w,
                height: 15.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: ClipOval(
                  child: CustomImageWidget(
                    imagePath: client['profileImage'],
                    semanticLabel: 'Profile photo of ${client['name']}',
                    width: 15.w,
                    height: 15.w,
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              SizedBox(width: 4.w),

              // Client Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            client['name'],
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                        if (client['isRecent'] == true)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 2.w,
                              vertical: 0.5.h,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.successLight.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Recent',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppTheme.successLight,
                                fontWeight: FontWeight.w500,
                                fontSize: 10.sp,
                              ),
                            ),
                          ),
                      ],
                    ),

                    SizedBox(height: 0.5.h),

                    Text(
                      client['email'],
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
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
                        SizedBox(width: 1.w),
                        Text(
                          client['phone'],
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Selection Indicator
              if (isSelected)
                Container(
                  width: 6.w,
                  height: 6.w,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: CustomIconWidget(
                      iconName: 'check',
                      color: Colors.white,
                      size: 3.w,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(8.w),
      child: Column(
        children: [
          CustomIconWidget(
            iconName: 'person_search',
            color: theme.colorScheme.outline,
            size: 20.w,
          ),
          SizedBox(height: 2.h),
          Text(
            'No clients found',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Try adjusting your search or add a new client',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
