import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class ServiceSelectionWidget extends StatelessWidget {
  final String selectedService;
  final Function(String) onServiceSelected;

  const ServiceSelectionWidget({
    super.key,
    required this.selectedService,
    required this.onServiceSelected,
  });

  final List<Map<String, dynamic>> _services = const [
    {
      'id': 'babysitting',
      'name': 'Babysitting',
      'description': 'Professional childcare services for your little ones',
      'icon': 'child_care',
      'color': Color(0xFF7C3AED),
      'features': [
        'Age-appropriate activities',
        'Meal preparation',
        'Homework assistance',
        'Bedtime routines',
      ],
      'hourlyRate': 18.0,
    },
    {
      'id': 'pet_sitting',
      'name': 'Pet Sitting',
      'description': 'Loving care for your furry family members',
      'icon': 'pets',
      'color': Color(0xFF059669),
      'features': [
        'Feeding & watering',
        'Exercise & walks',
        'Medication administration',
        'Companionship',
      ],
      'hourlyRate': 15.0,
    },
    {
      'id': 'house_sitting',
      'name': 'House Sitting',
      'description': 'Keep your home secure and maintained while you\'re away',
      'icon': 'home',
      'color': Color(0xFF2563EB),
      'features': [
        'Security monitoring',
        'Mail collection',
        'Plant watering',
        'Light maintenance',
      ],
      'hourlyRate': 22.0,
    },
    {
      'id': 'elder_care',
      'name': 'Elderly Care',
      'description': 'Compassionate companionship and assistance for seniors',
      'icon': 'elderly',
      'color': Color(0xFFD97706),
      'features': [
        'Companion services',
        'Medication reminders',
        'Light housekeeping',
        'Transportation',
      ],
      'hourlyRate': 25.0,
    },
  ];

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
            'Select Service Type',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Choose the type of service you\'d like to offer',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),

          SizedBox(height: 4.h),

          // Service cards
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _services.length,
            itemBuilder: (context, index) {
              final service = _services[index];
              return _buildServiceCard(context, service);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(BuildContext context, Map<String, dynamic> service) {
    final theme = Theme.of(context);
    final bool isSelected = selectedService == service['id'];
    final Color serviceColor = service['color'] as Color;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onServiceSelected(service['id'] as String);
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
                    ? serviceColor
                    : theme.colorScheme.outline.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color:
                  isSelected
                      ? serviceColor.withValues(alpha: 0.2)
                      : theme.colorScheme.shadow.withValues(alpha: 0.05),
              blurRadius: isSelected ? 12 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(4.w),
              child: Row(
                children: [
                  // Service icon
                  Container(
                    width: 15.w,
                    height: 15.w,
                    decoration: BoxDecoration(
                      color: serviceColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: CustomIconWidget(
                        iconName: service['icon'] as String,
                        color: serviceColor,
                        size: 7.w,
                      ),
                    ),
                  ),

                  SizedBox(width: 4.w),

                  // Service info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                service['name'] as String,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color:
                                      isSelected
                                          ? serviceColor
                                          : theme.colorScheme.onSurface,
                                ),
                              ),
                            ),
                            if (isSelected)
                              Container(
                                padding: EdgeInsets.all(1.w),
                                decoration: BoxDecoration(
                                  color: serviceColor,
                                  shape: BoxShape.circle,
                                ),
                                child: CustomIconWidget(
                                  iconName: 'check',
                                  color: Colors.white,
                                  size: 4.w,
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: 1.h),
                        Text(
                          service['description'] as String,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.7,
                            ),
                          ),
                        ),
                        SizedBox(height: 1.h),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 3.w,
                            vertical: 1.h,
                          ),
                          decoration: BoxDecoration(
                            color: serviceColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Starting at \$${service['hourlyRate']}/hour',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: serviceColor,
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

            // Features section
            if (isSelected) ...[
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  color: serviceColor.withValues(alpha: 0.05),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'What\'s included:',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: serviceColor,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    ...((service['features'] as List<String>).map((feature) {
                      return Padding(
                        padding: EdgeInsets.only(bottom: 1.h),
                        child: Row(
                          children: [
                            CustomIconWidget(
                              iconName: 'check_circle',
                              color: serviceColor,
                              size: 4.w,
                            ),
                            SizedBox(width: 3.w),
                            Expanded(
                              child: Text(
                                feature,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.8,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList()),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
