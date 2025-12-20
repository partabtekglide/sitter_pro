import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class BookingDetailsWidget extends StatefulWidget {
  final String address;
  final String serviceType;
  final String specialInstructions;
  final String petDetails;
  final Function(Map<String, dynamic>) onDetailsUpdated;

  const BookingDetailsWidget({
    super.key,
    required this.address,
    required this.serviceType,
    required this.specialInstructions,
    required this.petDetails,
    required this.onDetailsUpdated,
  });

  @override
  State<BookingDetailsWidget> createState() => _BookingDetailsWidgetState();
}

class _BookingDetailsWidgetState extends State<BookingDetailsWidget> {
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _instructionsController = TextEditingController();
  final TextEditingController _petDetailsController = TextEditingController();
  
  final FocusNode _addressFocus = FocusNode();
  final FocusNode _instructionsFocus = FocusNode();
  final FocusNode _petDetailsFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _addressController.text = widget.address;
    _instructionsController.text = widget.specialInstructions;
    _petDetailsController.text = widget.petDetails;

    _addressController.addListener(_updateDetails);
    _instructionsController.addListener(_updateDetails);
    _petDetailsController.addListener(_updateDetails);
  }

  @override
  void dispose() {
    _addressController.dispose();
    _instructionsController.dispose();
    _petDetailsController.dispose();
    
    _addressFocus.dispose();
    _instructionsFocus.dispose();
    _petDetailsFocus.dispose();
    super.dispose();
  }

  void _updateDetails() {
    widget.onDetailsUpdated({
      'address': _addressController.text,
      'specialInstructions': _instructionsController.text,
      'petDetails': _petDetailsController.text,
    });
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
            'Booking Details',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Add specific instructions and important details',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),

          SizedBox(height: 4.h),

          // Service-specific templates
          _buildTemplateSection(context),

          SizedBox(height: 4.h),

          // Special Instructions
          _buildTextField(
            context,
            'Special Instructions',
            'Any specific instructions or preferences?',
            _instructionsController,
            _instructionsFocus,
            'edit_note',
            maxLines: 4,
            isRequired: false,
          ),

          SizedBox(height: 3.h),

          // Address
          _buildTextField(
            context,
            'Service Address',
            'Where will the service take place?',
            _addressController,
            _addressFocus,
            'location_on',
            maxLines: 2,
            isRequired: true,
          ),

          SizedBox(height: 3.h),

          // Pet details (if pet sitting)
          if (widget.serviceType.toLowerCase().contains('pet'))
            _buildTextField(
              context,
              'Pet Details',
              'Pet names, breeds, feeding schedules, medications, etc.',
              _petDetailsController,
              _petDetailsFocus,
              'pets',
              maxLines: 3,
              isRequired: false,
            ),

          SizedBox(height: 4.h),

          // Important notes
          _buildImportantNotes(context),
        ],
      ),
    );
  }

  Widget _buildTemplateSection(BuildContext context) {
    final theme = Theme.of(context);

    List<String> templates = [];

    switch (widget.serviceType.toLowerCase()) {
      case 'babysitting':
        templates = [
          'Please prepare lunch for the children',
          'Bedtime routine at 8:00 PM',
          'No screen time after 7:00 PM',
          'Emergency contact: Dr. Smith (555) 123-4567',
        ];
        break;
      case 'pet_sitting':
        templates = [
          'Feed at 6 AM and 6 PM',
          'Walk twice daily - morning and evening',
          'Medication with morning meal',
          'Loves belly rubs and fetch',
        ];
        break;
      case 'house_sitting':
        templates = [
          'Water plants daily',
          'Collect mail and packages',
          'Turn lights on/off to simulate presence',
          'Check security system regularly',
        ];
        break;
      case 'elder_care':
        templates = [
          'Medication reminder at 10 AM and 6 PM',
          'Prefers light conversation and company',
          'Mobility assistance may be needed',
          'Doctor appointment on Tuesday',
        ];
        break;
    }

    if (templates.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Templates',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          'Tap to add common instructions for ${widget.serviceType.toLowerCase().replaceAll('_', ' ')}:',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        SizedBox(height: 2.h),
        Wrap(
          spacing: 2.w,
          runSpacing: 1.h,
          children:
              templates.map((template) {
                return GestureDetector(
                  onTap: () => _addTemplate(template),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 3.w,
                      vertical: 1.h,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CustomIconWidget(
                          iconName: 'add',
                          color: theme.colorScheme.primary,
                          size: 3.w,
                        ),
                        SizedBox(width: 2.w),
                        Flexible(
                          child: Text(
                            template,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }

  Widget _buildTextField(
    BuildContext context,
    String label,
    String hint,
    TextEditingController controller,
    FocusNode focusNode,
    String iconName, {
    int maxLines = 1,
    bool isRequired = false,
  }) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CustomIconWidget(
              iconName: iconName,
              color: theme.colorScheme.primary,
              size: 5.w,
            ),
            SizedBox(width: 3.w),
            Text(
              label,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            if (isRequired) ...[
              SizedBox(width: 1.w),
              Text(
                '*',
                style: TextStyle(
                  color: theme.colorScheme.error,
                  fontSize: 16.sp,
                ),
              ),
            ],
          ],
        ),
        SizedBox(height: 2.h),
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
                  focusNode.hasFocus
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline.withValues(alpha: 0.3),
            ),
          ),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            maxLines: maxLines,
            decoration: InputDecoration(
              hintText: hint,
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(4.w),
              hintStyle: TextStyle(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImportantNotes(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.tertiary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CustomIconWidget(
                iconName: 'info',
                color: theme.colorScheme.tertiary,
                size: 5.w,
              ),
              SizedBox(width: 3.w),
              Text(
                'Important Notes',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.tertiary,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Text(
            '• All details are optional but help provide better service\n'
            '• You can edit these details later if needed\n'
            '• Emergency contacts will only be used in case of emergencies\n'
            '• Clear instructions help avoid misunderstandings',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  void _addTemplate(String template) {
    final currentText = _instructionsController.text;
    final newText =
        currentText.isEmpty ? template : '$currentText\n• $template';

    _instructionsController.text = newText;
    _instructionsController.selection = TextSelection.fromPosition(
      TextPosition(offset: newText.length),
    );
  }
}
