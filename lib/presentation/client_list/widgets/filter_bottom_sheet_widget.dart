import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class FilterBottomSheetWidget extends StatefulWidget {
  final Map<String, dynamic> currentFilters;
  final ValueChanged<Map<String, dynamic>>? onFiltersChanged;

  const FilterBottomSheetWidget({
    super.key,
    required this.currentFilters,
    this.onFiltersChanged,
  });

  @override
  State<FilterBottomSheetWidget> createState() =>
      _FilterBottomSheetWidgetState();
}

class _FilterBottomSheetWidgetState extends State<FilterBottomSheetWidget> {
  late Map<String, dynamic> _filters;

  @override
  void initState() {
    super.initState();
    _filters = Map<String, dynamic>.from(widget.currentFilters);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(context),
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildServiceTypeFilter(context),
                    SizedBox(height: 3.h),
                    _buildStatusFilter(context),
                    SizedBox(height: 3.h),
                    _buildLocationFilter(context),
                    SizedBox(height: 3.h),
                    _buildBookingFrequencyFilter(context),
                    SizedBox(height: 4.h),
                  ],
                ),
              ),
            ),
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.onSurface.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Spacer(),
          Text(
            'Filter Clients',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          InkWell(
            onTap: () => Navigator.pop(context),
            child: CustomIconWidget(
              iconName: 'close',
              size: 24,
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceTypeFilter(BuildContext context) {
    final theme = Theme.of(context);
    final serviceTypes = ['Babysitting', 'Pet Sitting', 'House Sitting'];
    final selectedTypes = (_filters['serviceTypes'] as List<String>?) ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Service Type',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 2.h),
        Wrap(
          spacing: 2.w,
          runSpacing: 1.h,
          children: serviceTypes.map((type) {
            final isSelected = selectedTypes.contains(type);
            return FilterChip(
              label: Text(type),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  final newTypes = List<String>.from(selectedTypes);
                  if (selected) {
                    newTypes.add(type);
                  } else {
                    newTypes.remove(type);
                  }
                  _filters['serviceTypes'] = newTypes;
                });
              },
              selectedColor:
                  AppTheme.lightTheme.primaryColor.withValues(alpha: 0.2),
              checkmarkColor: AppTheme.lightTheme.primaryColor,
              labelStyle: TextStyle(
                color: isSelected
                    ? AppTheme.lightTheme.primaryColor
                    : theme.colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStatusFilter(BuildContext context) {
    final theme = Theme.of(context);
    final statuses = [
      'Active',
      'Inactive',
      'Upcoming Bookings',
      'Overdue Payments'
    ];
    final selectedStatus = _filters['status'] as String?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Client Status',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 2.h),
        ...statuses.map((status) {
          return RadioListTile<String>(
            title: Text(status),
            value: status,
            groupValue: selectedStatus,
            onChanged: (value) {
              setState(() {
                _filters['status'] = value;
              });
            },
            contentPadding: EdgeInsets.zero,
            activeColor: AppTheme.lightTheme.primaryColor,
          );
        }),
      ],
    );
  }

  Widget _buildLocationFilter(BuildContext context) {
    final theme = Theme.of(context);
    final proximityValue = (_filters['locationProximity'] as double?) ?? 10.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Location Proximity',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 1.h),
        Text(
          'Within ${proximityValue.round()} miles',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppTheme.lightTheme.primaryColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        Slider(
          value: proximityValue,
          min: 1.0,
          max: 50.0,
          divisions: 49,
          onChanged: (value) {
            setState(() {
              _filters['locationProximity'] = value;
            });
          },
          activeColor: AppTheme.lightTheme.primaryColor,
        ),
      ],
    );
  }

  Widget _buildBookingFrequencyFilter(BuildContext context) {
    final theme = Theme.of(context);
    final frequencies = ['Weekly', 'Bi-weekly', 'Monthly', 'Occasional'];
    final selectedFrequencies =
        (_filters['bookingFrequency'] as List<String>?) ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Booking Frequency',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 2.h),
        Wrap(
          spacing: 2.w,
          runSpacing: 1.h,
          children: frequencies.map((frequency) {
            final isSelected = selectedFrequencies.contains(frequency);
            return FilterChip(
              label: Text(frequency),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  final newFrequencies = List<String>.from(selectedFrequencies);
                  if (selected) {
                    newFrequencies.add(frequency);
                  } else {
                    newFrequencies.remove(frequency);
                  }
                  _filters['bookingFrequency'] = newFrequencies;
                });
              },
              selectedColor:
                  AppTheme.lightTheme.primaryColor.withValues(alpha: 0.2),
              checkmarkColor: AppTheme.lightTheme.primaryColor,
              labelStyle: TextStyle(
                color: isSelected
                    ? AppTheme.lightTheme.primaryColor
                    : theme.colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                setState(() {
                  _filters.clear();
                });
                widget.onFiltersChanged?.call(_filters);
                Navigator.pop(context);
              },
              child: const Text('Clear All'),
            ),
          ),
          SizedBox(width: 4.w),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: () {
                widget.onFiltersChanged?.call(_filters);
                Navigator.pop(context);
              },
              child: Text('Apply Filters (${_getActiveFilterCount()})'),
            ),
          ),
        ],
      ),
    );
  }

  int _getActiveFilterCount() {
    int count = 0;

    final serviceTypes = _filters['serviceTypes'] as List<String>?;
    if (serviceTypes != null && serviceTypes.isNotEmpty) count++;

    if (_filters['status'] != null) count++;

    final bookingFrequency = _filters['bookingFrequency'] as List<String>?;
    if (bookingFrequency != null && bookingFrequency.isNotEmpty) count++;

    final proximity = _filters['locationProximity'] as double?;
    if (proximity != null && proximity != 10.0) count++;

    return count;
  }
}
