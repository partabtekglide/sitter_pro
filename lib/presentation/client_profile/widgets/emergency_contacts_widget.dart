import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class EmergencyContactsWidget extends StatelessWidget {
  final List<Map<String, dynamic>> emergencyContacts;
  final Function(Map<String, dynamic>)? onContactTap;

  const EmergencyContactsWidget({
    super.key,
    required this.emergencyContacts,
    this.onContactTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (emergencyContacts.isEmpty) {
      return Container(
        padding: EdgeInsets.all(4.w),
        child: Column(
          children: [
            CustomIconWidget(
              iconName: 'contact_emergency',
              size: 48,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            SizedBox(height: 2.h),
            Text(
              'No emergency contacts added',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Add emergency contacts for quick access during appointments',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
          child: Row(
            children: [
              CustomIconWidget(
                iconName: 'emergency',
                size: 20,
                color: theme.colorScheme.error,
              ),
              SizedBox(width: 2.w),
              Text(
                'Emergency Contacts',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.error,
                ),
              ),
            ],
          ),
        ),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          itemCount: emergencyContacts.length,
          separatorBuilder: (context, index) => SizedBox(height: 1.h),
          itemBuilder: (context, index) {
            final contact = emergencyContacts[index];
            return _buildEmergencyContactCard(context, contact);
          },
        ),
      ],
    );
  }

  Widget _buildEmergencyContactCard(
      BuildContext context, Map<String, dynamic> contact) {
    final theme = Theme.of(context);

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.error.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () => _showCallConfirmationDialog(context, contact),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(3.w),
          child: Row(
            children: [
              Container(
                width: 12.w,
                height: 12.w,
                decoration: BoxDecoration(
                  color: theme.colorScheme.error.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: CustomIconWidget(
                  iconName: 'person',
                  size: 20,
                  color: theme.colorScheme.error,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contact["name"] as String? ?? "Unknown Contact",
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (contact["relationship"] != null) ...[
                      SizedBox(height: 0.5.h),
                      Text(
                        contact["relationship"] as String,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.7),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (contact["phone"] != null) ...[
                      SizedBox(height: 0.5.h),
                      Row(
                        children: [
                          CustomIconWidget(
                            iconName: 'phone',
                            size: 14,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.6),
                          ),
                          SizedBox(width: 1.w),
                          Expanded(
                            child: Text(
                              contact["phone"] as String,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.6),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  onPressed: () =>
                      _showCallConfirmationDialog(context, contact),
                  icon: CustomIconWidget(
                    iconName: 'phone',
                    size: 18,
                    color: theme.colorScheme.error,
                  ),
                  tooltip: 'Call Emergency Contact',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCallConfirmationDialog(
      BuildContext context, Map<String, dynamic> contact) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              CustomIconWidget(
                iconName: 'emergency',
                size: 24,
                color: theme.colorScheme.error,
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  'Emergency Call',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Call ${contact["name"] as String? ?? "Unknown Contact"}?',
                style: theme.textTheme.bodyLarge,
              ),
              if (contact["phone"] != null) ...[
                SizedBox(height: 1.h),
                Text(
                  contact["phone"] as String,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
              if (contact["relationship"] != null) ...[
                SizedBox(height: 1.h),
                Text(
                  'Relationship: ${contact["relationship"] as String}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                onContactTap?.call(contact);
              },
              icon: CustomIconWidget(
                iconName: 'phone',
                size: 18,
                color: theme.colorScheme.onError,
              ),
              label: Text(
                'Call Now',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onError,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
