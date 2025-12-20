import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_bottom_bar.dart';
import '../../widgets/custom_icon_widget.dart';
import './widgets/client_card_widget.dart';
import './widgets/empty_state_widget.dart';
import './widgets/filter_bottom_sheet_widget.dart';
import './widgets/search_bar_widget.dart';
import './widgets/section_header_widget.dart';
import './widgets/add_client_sheet.dart';
import '../../services/supabase_service.dart';

class ClientList extends StatefulWidget {
  const ClientList({super.key});

  @override
  State<ClientList> createState() => _ClientListState();
}

class _ClientListState extends State<ClientList> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> _allClients = [];
  List<Map<String, dynamic>> _filteredClients = [];
  Map<String, dynamic> _activeFilters = {};
  List<String> _recentSearches = ['Sarah Johnson', 'Pet Care', 'Downtown'];
  bool _isLoading = false;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadClients();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadClients() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final clients = await SupabaseService.instance.getClients();
      print(  'Loaded ${clients} clients from Supabase');

      if (!mounted) return;

      _allClients = clients.map<Map<String, dynamic>>((client) {
        final pets = client['pets_kids'] as List<dynamic>? ?? [];

        return {
          "id": client['id'].toString(),
          "name": (client['full_name'] ?? '') as String,
          "avatar": (client['avatar_url'] ??
                  "https://images.unsplash.com/photo-1494790108755-2616b612b47c")
              as String,
          "semanticLabel":
              "Client profile for ${(client['full_name'] ?? 'Client')}",
          "serviceTypes": <String>[
            // Placeholder until you have real service types in DB
            "Babysitting"
          ],
          "lastBookingDate": null, // later: client['last_booking_date']
          "upcomingBookingDate": null, // later: client['upcoming_booking_date']
          "hasOverduePayment":
              (client['has_overdue_payment'] as bool?) ?? false,
          "phone": (client['phone'] ?? '') as String,
          "email": (client['email'] ?? '') as String,
          "address": (client['address'] ?? '') as String,
          "bookingFrequency": "Occasional",
          "pets": pets
              .map((pet) =>
                  "${pet['name'] ?? 'Pet'} (${pet['type'] ?? 'Unknown'})")
              .toList(),
          "rawPets": pets,
          "emergency_contact_name": client['emergency_contact_name'],
          "emergency_contact_phone": client['emergency_contact_phone'],
          "specialInstructions": client['special_instructions'],
        };
      }).toList();

      _filteredClients = _applyFilters(_allClients);

      setState(() {
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load clients: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase().trim();

    setState(() {
      _isSearching = query.isNotEmpty;

      if (query.isEmpty) {
        _filteredClients = _applyFilters(_allClients);
      } else {
        final searchResults = _allClients.where((client) {
          final name = (client['name'] as String).toLowerCase();
          final serviceTypes = (client['serviceTypes'] as List<dynamic>)
              .map((type) => type.toString().toLowerCase())
              .join(' ');
          final address = (client['address'] as String).toLowerCase();

          return name.contains(query) ||
              serviceTypes.contains(query) ||
              address.contains(query);
        }).toList();

        _filteredClients = _applyFilters(searchResults);

        // Add to recent searches if not already present
        if (query.length > 2 &&
            !_recentSearches.contains(_searchController.text)) {
          _recentSearches.insert(0, _searchController.text);
          if (_recentSearches.length > 5) {
            _recentSearches.removeLast();
          }
        }
      }
    });
  }

  List<Map<String, dynamic>> _applyFilters(List<Map<String, dynamic>> clients) {
    List<Map<String, dynamic>> filtered = List.from(clients);

    // Service type filter
    final serviceTypes = _activeFilters['serviceTypes'] as List<String>?;
    if (serviceTypes != null && serviceTypes.isNotEmpty) {
      filtered = filtered.where((client) {
        final clientServices = client['serviceTypes'] as List<dynamic>;
        return serviceTypes.any((type) => clientServices.contains(type));
      }).toList();
    }

    // Status filter
    final status = _activeFilters['status'] as String?;
    if (status != null) {
      filtered = filtered.where((client) {
        switch (status) {
          case 'Active':
            return _getClientStatus(client) == 'active' ||
                _getClientStatus(client) == 'upcoming';
          case 'Inactive':
            return _getClientStatus(client) == 'inactive';
          case 'Upcoming Bookings':
            return _getClientStatus(client) == 'upcoming';
          case 'Overdue Payments':
            return _getClientStatus(client) == 'overdue';
          default:
            return true;
        }
      }).toList();
    }

    // Booking frequency filter
    final frequencies = _activeFilters['bookingFrequency'] as List<String>?;
    if (frequencies != null && frequencies.isNotEmpty) {
      filtered = filtered.where((client) {
        final clientFrequency =
            (client['bookingFrequency'] ?? '') as String;
        return frequencies.contains(clientFrequency);
      }).toList();
    }

    return filtered;
  }

  String _getClientStatus(Map<String, dynamic> client) {
    final upcomingBooking = client['upcomingBookingDate'] as String?;
    if (upcomingBooking != null) {
      final date = DateTime.tryParse(upcomingBooking);
      if (date != null && date.isAfter(DateTime.now())) {
        return 'upcoming';
      }
    }

    final overduePayment = client['hasOverduePayment'] as bool? ?? false;
    if (overduePayment) return 'overdue';

    final lastBooking = client['lastBookingDate'] as String?;
    if (lastBooking == null) return 'inactive';

    final date = DateTime.tryParse(lastBooking);
    if (date == null) return 'inactive';

    final daysSinceLastBooking = DateTime.now().difference(date).inDays;
    if (daysSinceLastBooking > 90) return 'inactive';

    return 'active';
  }

  Map<String, List<Map<String, dynamic>>> _groupClientsByLetter() {
    final Map<String, List<Map<String, dynamic>>> grouped = {};

    for (final client in _filteredClients) {
      final name = client['name'] as String;
      final firstLetter = name.isNotEmpty ? name[0].toUpperCase() : '#';

      if (!grouped.containsKey(firstLetter)) {
        grouped[firstLetter] = [];
      }
      grouped[firstLetter]!.add(client);
    }

    // Sort each group by name
    grouped.forEach((key, value) {
      value.sort(
        (a, b) => (a['name'] as String).compareTo(b['name'] as String),
      );
    });

    return grouped;
  }

  Future<void> _onRefresh() async {
    await _loadClients();
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterBottomSheetWidget(
        currentFilters: _activeFilters,
        onFiltersChanged: (filters) {
          setState(() {
            _activeFilters = filters;
            _filteredClients = _applyFilters(_allClients);
          });
        },
      ),
    );
  }

  void _navigateToClientProfile(Map<String, dynamic> client) {
    Navigator.pushNamed(
      context,
      '/client-profile',
      arguments: client,
    );
  }

  Future<void> _navigateToAddClient() async {
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
        preferredRate: 25.0, // Default rate
      );

      // 2) List refresh karo
      await _loadClients();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Client ${result['name']} added successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create client: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _handleClientAction(String action, Map<String, dynamic> client) {
    switch (action) {
      case 'call':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Calling ${client['name']}...'),
            duration: const Duration(seconds: 2),
          ),
        );
        break;
      case 'message':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Opening message to ${client['name']}...'),
            duration: const Duration(seconds: 2),
          ),
        );
        break;
      case 'new_booking':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Creating new booking for ${client['name']}...'),
            duration: const Duration(seconds: 2),
          ),
        );
        break;
      case 'archive':
        setState(() {
          _allClients.removeWhere((c) => c['id'] == client['id']);
          _filteredClients.removeWhere((c) => c['id'] == client['id']);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${client['name']} archived'),
            duration: const Duration(seconds: 2),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () {
                setState(() {
                  _allClients.add(client);
                  _filteredClients = _applyFilters(_allClients);
                });
              },
            ),
          ),
        );
        break;
      case 'edit':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Edit ${client['name']} feature coming soon'),
            duration: const Duration(seconds: 2),
          ),
        );
        break;
      case 'duplicate':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Duplicate ${client['name']} feature coming soon'),
            duration: const Duration(seconds: 2),
          ),
        );
        break;
      case 'share':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Share ${client['name']} contact feature coming soon'),
            duration: const Duration(seconds: 2),
          ),
        );
        break;
    }
  }

  void _importContacts() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Import contacts feature coming soon'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final groupedClients = _groupClientsByLetter();

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: CustomAppBar(
        title: 'Clients',
        variant: CustomAppBarVariant.search,
        actions: [
          IconButton(
            icon: CustomIconWidget(
              iconName: 'person_add',
              size: 24,
              color: colorScheme.primary,
            ),
            onPressed: _navigateToAddClient,
            tooltip: 'Add Client',
          ),
        ],
      ),
      body: Column(
        children: [
          SearchBarWidget(
            controller: _searchController,
            onChanged: (value) {}, // Handled by listener
            onFilterTap: _showFilterBottomSheet,
            recentSearches: _recentSearches,
            onRecentSearchTap: (search) {
              _searchController.text = search;
            },
            onClearRecentSearches: () {
              setState(() {
                _recentSearches.clear();
              });
            },
          ),
          if (_activeFilters.isNotEmpty) _buildActiveFiltersChips(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredClients.isEmpty
                    ? _isSearching
                        ? _buildNoSearchResults()
                        : EmptyStateWidget(
                            onAddClient: _navigateToAddClient,
                            onImportContacts: _importContacts,
                          )
                    : RefreshIndicator(
                        onRefresh: _onRefresh,
                        child: _buildClientList(groupedClients),
                      ),
          ),
        ],
      ),
      bottomNavigationBar: const CustomBottomBar(
        currentIndex: 1,
        variant: CustomBottomBarVariant.standard,
      ),
    );
  }

  Widget _buildActiveFiltersChips() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      height: 6.h,
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          if (_activeFilters['serviceTypes'] != null) ...[
            ...((_activeFilters['serviceTypes'] as List<String>)
                .map((type) => _buildFilterChip(type, () {
                      setState(() {
                        final types =
                            _activeFilters['serviceTypes'] as List<String>;
                        types.remove(type);
                        if (types.isEmpty) {
                          _activeFilters.remove('serviceTypes');
                        }
                        _filteredClients = _applyFilters(_allClients);
                      });
                    }))),
          ],
          if (_activeFilters['status'] != null)
            _buildFilterChip(_activeFilters['status'] as String, () {
              setState(() {
                _activeFilters.remove('status');
                _filteredClients = _applyFilters(_allClients);
              });
            }),
          if (_activeFilters['bookingFrequency'] != null) ...[
            ...((_activeFilters['bookingFrequency'] as List<String>)
                .map((freq) => _buildFilterChip(freq, () {
                      setState(() {
                        final frequencies =
                            _activeFilters['bookingFrequency'] as List<String>;
                        frequencies.remove(freq);
                        if (frequencies.isEmpty) {
                          _activeFilters.remove('bookingFrequency');
                        }
                        _filteredClients = _applyFilters(_allClients);
                      });
                    }))),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onRemove) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: EdgeInsets.only(right: 2.w),
      child: Chip(
        label: Text(label),
        onDeleted: onRemove,
        deleteIcon: CustomIconWidget(
          iconName: 'close',
          size: 16,
          color: colorScheme.primary,
        ),
        backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
        labelStyle: TextStyle(
          color: colorScheme.primary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildNoSearchResults() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(6.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: 'search_off',
              size: 20.w,
              color: colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            SizedBox(height: 3.h),
            Text(
              'No Results Found',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 2.h),
            Text(
              'Try adjusting your search or filters to find what you\'re looking for.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.7),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClientList(
      Map<String, List<Map<String, dynamic>>> groupedClients) {
    final sortedKeys = groupedClients.keys.toList()..sort();

    return ListView.builder(
      controller: _scrollController,
      itemCount: sortedKeys.length * 2, // Headers + clients
      itemBuilder: (context, index) {
        if (index.isEven) {
          // Section header
          final keyIndex = index ~/ 2;
          final letter = sortedKeys[keyIndex];
          return SectionHeaderWidget(letter: letter);
        } else {
          // Client cards
          final keyIndex = (index - 1) ~/ 2;
          final letter = sortedKeys[keyIndex];
          final clients = groupedClients[letter]!;

          return Column(
            children: clients
                .map((client) => ClientCardWidget(
                      client: client,
                      onTap: () => _navigateToClientProfile(client),
                      onCall: () => _handleClientAction('call', client),
                      onMessage: () =>
                          _handleClientAction('message', client),
                      onNewBooking: () =>
                          _handleClientAction('new_booking', client),
                      onArchive: () =>
                          _handleClientAction('archive', client),
                      onEdit: () => _handleClientAction('edit', client),
                      onDuplicate: () =>
                          _handleClientAction('duplicate', client),
                      onShare: () =>
                          _handleClientAction('share', client),
                    ))
                .toList(),
          );
        }
      },
    );
  }
}
