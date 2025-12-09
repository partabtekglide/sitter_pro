import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class ServiceDetailsStep extends StatefulWidget {
  final String serviceType;
  final int duration;
  final double rate;
  final String specialInstructions;
  final Function(String) onServiceTypeChanged;
  final Function(int) onDurationChanged;
  final Function(double) onRateChanged;
  final Function(String) onSpecialInstructionsChanged;

  const ServiceDetailsStep({
    super.key,
    required this.serviceType,
    required this.duration,
    required this.rate,
    required this.specialInstructions,
    required this.onServiceTypeChanged,
    required this.onDurationChanged,
    required this.onRateChanged,
    required this.onSpecialInstructionsChanged,
  });

  @override
  State<ServiceDetailsStep> createState() => _ServiceDetailsStepState();
}

class _ServiceDetailsStepState extends State<ServiceDetailsStep> {
  final TextEditingController _rateController = TextEditingController();
  final TextEditingController _instructionsController = TextEditingController();

  final List<Map<String, dynamic>> _serviceTypes = [
    {
      'type': 'babysitting',
      'name': 'Babysitting',
      'icon': 'child_care',
      'color': AppTheme.primaryLight,
      'baseRate': 15.0,
      'description': 'Care for children in their home',
    },
    {
      'type': 'pet_sitting',
      'name': 'Pet Sitting',
      'icon': 'pets',
      'color': AppTheme.successLight,
      'baseRate': 12.0,
      'description': 'Care for pets while owners are away',
    },
    {
      'type': 'house_sitting',
      'name': 'House Sitting',
      'icon': 'home',
      'color': AppTheme.warningLight,
      'baseRate': 20.0,
      'description': 'Watch over property and handle basic tasks',
    },
  ];

  final List<String> _instructionTemplates = [
    'Feeding schedule: 6am, 12pm, 6pm',
    'Bedtime routine: Bath, story, sleep by 8pm',
    'Medication: Give before meals',
    'Emergency contact: Call immediately if needed',
    'No visitors allowed',
    'Keep doors locked at all times',
    'Water plants daily',
    'Walk dog every 3 hours',
    'Feed cats twice daily',
    'Collect mail and packages',
  ];

  @override
  void initState() {
    super.initState();
    _rateController.text =
        widget.rate > 0 ? widget.rate.toStringAsFixed(2) : '';
    _instructionsController.text = widget.specialInstructions;
  }

  @override
  void dispose() {
    _rateController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  void _selectServiceType(String serviceType) {
    widget.onServiceTypeChanged(serviceType);

    // Auto-fill base rate
    final service = _serviceTypes.firstWhere((s) => s['type'] == serviceType);
    final baseRate = service['baseRate'] as double;

    if (widget.rate == 0) {
      _rateController.text = baseRate.toStringAsFixed(2);
      widget.onRateChanged(baseRate);
    }

    HapticFeedback.lightImpact();
  }

  void _updateRate(String value) {
    final rate = double.tryParse(value) ?? 0.0;
    widget.onRateChanged(rate);
  }

  double get _estimatedEarnings {
    return widget.duration * widget.rate;
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
            'Service Details',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),

          SizedBox(height: 1.h),

          Text(
            'Choose service type and set your pricing',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),

          SizedBox(height: 4.h),

          // Service Type Selection
          Text(
            'Service Type',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),

          SizedBox(height: 2.h),

          ...(_serviceTypes.map(
            (service) => _buildServiceTypeCard(service, theme),
          )),

          SizedBox(height: 4.h),

          // Duration and Rate Row
          Row(
            children: [
              // Duration
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Duration (hours)',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(height: 1.h),
                    _buildDurationSelector(theme),
                  ],
                ),
              ),

              SizedBox(width: 4.w),

              // Hourly Rate
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hourly Rate (\$)',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(height: 1.h),
                    TextField(
                      controller: _rateController,
                      keyboardType: TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d{0,2}'),
                        ),
                      ],
                      decoration: InputDecoration(
                        hintText: '15.00',
                        prefixIcon: Padding(
                          padding: EdgeInsets.all(3.w),
                          child: CustomIconWidget(
                            iconName: 'attach_money',
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.6,
                            ),
                            size: 5.w,
                          ),
                        ),
                      ),
                      onChanged: _updateRate,
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 3.h),

          // Earnings Calculator
          if (widget.duration > 0 && widget.rate > 0)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: AppTheme.successLight.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.successLight.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 10.w,
                    height: 10.w,
                    decoration: BoxDecoration(
                      color: AppTheme.successLight,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: CustomIconWidget(
                        iconName: 'calculate',
                        color: Colors.white,
                        size: 5.w,
                      ),
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Estimated Earnings',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.successLight,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '\$${_estimatedEarnings.toStringAsFixed(2)}',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: AppTheme.successLight,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${widget.duration}h × \$${widget.rate.toStringAsFixed(2)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.successLight.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

          SizedBox(height: 4.h),

          // Special Instructions
          Text(
            'Special Instructions',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),

          SizedBox(height: 1.h),

          Text(
            'Add any specific requirements or notes',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),

          SizedBox(height: 2.h),

          // Instruction Templates
          Wrap(
            spacing: 2.w,
            runSpacing: 1.h,
            children:
                _instructionTemplates.map((template) {
                  return InkWell(
                    onTap: () {
                      final currentText = _instructionsController.text;
                      final newText =
                          currentText.isEmpty
                              ? template
                              : '$currentText\n$template';
                      _instructionsController.text = newText;
                      widget.onSpecialInstructionsChanged(newText);
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 3.w,
                        vertical: 1.h,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.3,
                          ),
                        ),
                      ),
                      child: Text(
                        template,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                }).toList(),
          ),

          SizedBox(height: 2.h),

          // Instructions Text Area
          TextField(
            controller: _instructionsController,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText:
                  'Enter specific instructions, schedules, or preferences...',
            ),
            onChanged: widget.onSpecialInstructionsChanged,
          ),

          SizedBox(height: 10.h), // Extra space for bottom navigation
        ],
      ),
    );
  }

  Widget _buildServiceTypeCard(Map<String, dynamic> service, ThemeData theme) {
    final isSelected = widget.serviceType == service['type'];

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      child: InkWell(
        onTap: () => _selectServiceType(service['type']),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border:
                isSelected
                    ? Border.all(color: service['color'], width: 2)
                    : null,
            color: isSelected ? service['color'].withValues(alpha: 0.05) : null,
          ),
          child: Row(
            children: [
              // Service Icon
              Container(
                width: 15.w,
                height: 15.w,
                decoration: BoxDecoration(
                  color: service['color'].withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: CustomIconWidget(
                    iconName: service['icon'],
                    color: service['color'],
                    size: 8.w,
                  ),
                ),
              ),

              SizedBox(width: 4.w),

              // Service Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service['name'],
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      service['description'],
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      'Base rate: \$${service['baseRate']}/hour',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: service['color'],
                        fontWeight: FontWeight.w600,
                      ),
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
                    color: service['color'],
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

  Widget _buildDurationSelector(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.5),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Decrease Button
          InkWell(
            onTap:
                widget.duration > 1
                    ? () {
                      widget.onDurationChanged(widget.duration - 1);
                      HapticFeedback.lightImpact();
                    }
                    : null,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              bottomLeft: Radius.circular(8),
            ),
            child: Container(
              width: 12.w,
              height: 12.w,
              decoration: BoxDecoration(
                color:
                    widget.duration > 1
                        ? theme.colorScheme.primary.withValues(alpha: 0.1)
                        : theme.colorScheme.outline.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  bottomLeft: Radius.circular(8),
                ),
              ),
              child: Center(
                child: CustomIconWidget(
                  iconName: 'remove',
                  color:
                      widget.duration > 1
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline,
                  size: 5.w,
                ),
              ),
            ),
          ),

          // Duration Display
          Expanded(
            child: Container(
              height: 12.w,
              color: theme.colorScheme.surface,
              child: Center(
                child: Text(
                  '${widget.duration}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ),
          ),

          // Increase Button
          InkWell(
            onTap:
                widget.duration < 24
                    ? () {
                      widget.onDurationChanged(widget.duration + 1);
                      HapticFeedback.lightImpact();
                    }
                    : null,
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(8),
              bottomRight: Radius.circular(8),
            ),
            child: Container(
              width: 12.w,
              height: 12.w,
              decoration: BoxDecoration(
                color:
                    widget.duration < 24
                        ? theme.colorScheme.primary.withValues(alpha: 0.1)
                        : theme.colorScheme.outline.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
              ),
              child: Center(
                child: CustomIconWidget(
                  iconName: 'add',
                  color:
                      widget.duration < 24
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline,
                  size: 5.w,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
