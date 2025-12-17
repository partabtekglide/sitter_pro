import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

enum ServiceType {
  babysitting,
  petSitting,
  houseSitting,
}

class ServiceTypeSelector extends StatelessWidget {
  final List<ServiceType> selectedServices;
  final Function(List<ServiceType>) onServicesChanged;

  const ServiceTypeSelector({
    super.key,
    required this.selectedServices,
    required this.onServicesChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Service Types',
          style: AppTheme.lightTheme.textTheme.titleMedium,
        ),
        SizedBox(height: 1.h),
        Text(
          'Select the services you offer (you can choose multiple)',
          style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
            color: AppTheme.lightTheme.colorScheme.onSurface
                .withValues(alpha: 0.7),
          ),
        ),
        SizedBox(height: 2.h),
        Wrap(
          spacing: 3.w,
          runSpacing: 1.h,
          children: ServiceType.values.map((service) {
            final isSelected = selectedServices.contains(service);
            return _buildServiceChip(service, isSelected);
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildServiceChip(ServiceType service, bool isSelected) {
    return GestureDetector(
      onTap: () {
        List<ServiceType> updatedServices = List.from(selectedServices);
        if (isSelected) {
          updatedServices.remove(service);
        } else {
          updatedServices.add(service);
        }
        onServicesChanged(updatedServices);
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.lightTheme.colorScheme.primary
              : AppTheme.lightTheme.colorScheme.surface,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected
                ? AppTheme.lightTheme.colorScheme.primary
                : AppTheme.lightTheme.colorScheme.outline
                    .withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomIconWidget(
              iconName: _getServiceIcon(service),
              color: isSelected
                  ? AppTheme.lightTheme.colorScheme.onPrimary
                  : AppTheme.lightTheme.colorScheme.onSurface
                      .withValues(alpha: 0.7),
              size: 20,
            ),
            SizedBox(width: 2.w),
            Text(
              _getServiceLabel(service),
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: isSelected
                    ? AppTheme.lightTheme.colorScheme.onPrimary
                    : AppTheme.lightTheme.colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getServiceIcon(ServiceType service) {
    switch (service) {
      case ServiceType.babysitting:
        return 'child_care';
      case ServiceType.petSitting:
        return 'pets';
      case ServiceType.houseSitting:
        return 'home';
    }
  }

  String _getServiceLabel(ServiceType service) {
    switch (service) {
      case ServiceType.babysitting:
        return 'Babysitting';
      case ServiceType.petSitting:
        return 'Pet Sitting';
      case ServiceType.houseSitting:
        return 'House Sitting';
    }
  }
}
