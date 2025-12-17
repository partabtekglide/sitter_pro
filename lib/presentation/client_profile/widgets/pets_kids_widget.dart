import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class PetsKidsWidget extends StatelessWidget {
  final List<Map<String, dynamic>> petsKids;
  final Function(Map<String, dynamic>)? onPetKidTap;
  final Function(Map<String, dynamic>)? onLongPress;

  const PetsKidsWidget({
    super.key,
    required this.petsKids,
    this.onPetKidTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (petsKids.isEmpty) {
      return Container(
        padding: EdgeInsets.all(4.w),
        child: Column(
          children: [
            CustomIconWidget(
              iconName: 'pets',
              size: 48,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            SizedBox(height: 2.h),
            Text(
              'No pets or children added',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Add pet or child profiles to track their specific needs and information',
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
          child: Text(
            'Pets & Children (${petsKids.length})',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        SizedBox(
          height: 25.h,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            itemCount: petsKids.length,
            separatorBuilder: (context, index) => SizedBox(width: 3.w),
            itemBuilder: (context, index) {
              final petKid = petsKids[index];
              return _buildPetKidCard(context, petKid);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPetKidCard(BuildContext context, Map<String, dynamic> petKid) {
    final theme = Theme.of(context);
    final type = petKid["type"] as String? ?? "pet";
    final isChild = type.toLowerCase() == "child";

    return GestureDetector(
      onTap: () => onPetKidTap?.call(petKid),
      onLongPress: () => _showContextMenu(context, petKid),
      child: Container(
        width: 40.w,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image section
            Container(
              height: 12.h,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                color: theme.colorScheme.surfaceContainerHighest,
              ),
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: petKid["image"] != null
                    ? CustomImageWidget(
                        imageUrl: petKid["image"] as String,
                        width: double.infinity,
                        height: 12.h,
                        fit: BoxFit.cover,
                        semanticLabel:
                            petKid["imageSemanticLabel"] as String? ??
                                "${isChild ? 'Child' : 'Pet'} photo",
                      )
                    : Container(
                        width: double.infinity,
                        height: 12.h,
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: CustomIconWidget(
                          iconName: isChild ? 'child_care' : 'pets',
                          size: 32,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.4),
                        ),
                      ),
              ),
            ),
            // Content section
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(3.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            petKid["name"] as String? ?? "Unknown",
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 2.w, vertical: 0.5.h),
                          decoration: BoxDecoration(
                            color: isChild
                                ? theme.colorScheme.tertiary
                                    .withValues(alpha: 0.1)
                                : theme.colorScheme.primary
                                    .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            type.toUpperCase(),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: isChild
                                  ? theme.colorScheme.tertiary
                                  : theme.colorScheme.primary,
                              fontWeight: FontWeight.w500,
                              fontSize: 8.sp,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 1.h),
                    if (petKid["age"] != null) ...[
                      Row(
                        children: [
                          CustomIconWidget(
                            iconName: 'cake',
                            size: 14,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.6),
                          ),
                          SizedBox(width: 1.w),
                          Expanded(
                            child: Text(
                              '${petKid["age"]} ${isChild ? 'years old' : 'years'}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.7),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 0.5.h),
                    ],
                    if (petKid["breed"] != null && !isChild) ...[
                      Row(
                        children: [
                          CustomIconWidget(
                            iconName: 'info',
                            size: 14,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.6),
                          ),
                          SizedBox(width: 1.w),
                          Expanded(
                            child: Text(
                              petKid["breed"] as String,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.7),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 0.5.h),
                    ],
                    if (petKid["specialNotes"] != null) ...[
                      Row(
                        children: [
                          CustomIconWidget(
                            iconName: 'note',
                            size: 14,
                            color: theme.colorScheme.secondary,
                          ),
                          SizedBox(width: 1.w),
                          Expanded(
                            child: Text(
                              petKid["specialNotes"] as String,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.secondary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const Spacer(),
                    if (petKid["medicalInfo"] != null ||
                        petKid["vetInfo"] != null) ...[
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(vertical: 0.5.h),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.errorContainer
                              .withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CustomIconWidget(
                              iconName: 'medical_services',
                              size: 12,
                              color: theme.colorScheme.error,
                            ),
                            SizedBox(width: 1.w),
                            Text(
                              'Medical Info',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.error,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showContextMenu(BuildContext context, Map<String, dynamic> petKid) {
    final theme = Theme.of(context);
    final type = petKid["type"] as String? ?? "pet";
    final isChild = type.toLowerCase() == "child";

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(4.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 12.w,
                height: 0.5.h,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outline.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                petKid["name"] as String? ?? "Unknown",
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 3.h),
              ListTile(
                leading: CustomIconWidget(
                  iconName: 'edit',
                  size: 24,
                  color: theme.colorScheme.primary,
                ),
                title: Text(
                  'Edit Profile',
                  style: theme.textTheme.bodyLarge,
                ),
                onTap: () {
                  Navigator.pop(context);
                  onPetKidTap?.call(petKid);
                },
              ),
              ListTile(
                leading: CustomIconWidget(
                  iconName: 'medical_services',
                  size: 24,
                  color: theme.colorScheme.error,
                ),
                title: Text(
                  '${isChild ? 'Medical' : 'Vet'} Information',
                  style: theme.textTheme.bodyLarge,
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showMedicalInfo(context, petKid);
                },
              ),
              ListTile(
                leading: CustomIconWidget(
                  iconName: 'photo_library',
                  size: 24,
                  color: theme.colorScheme.secondary,
                ),
                title: Text(
                  'Photos',
                  style: theme.textTheme.bodyLarge,
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showPhotos(context, petKid);
                },
              ),
              SizedBox(height: 2.h),
            ],
          ),
        );
      },
    );
  }

  void _showMedicalInfo(BuildContext context, Map<String, dynamic> petKid) {
    final theme = Theme.of(context);
    final type = petKid["type"] as String? ?? "pet";
    final isChild = type.toLowerCase() == "child";

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
                iconName: 'medical_services',
                size: 24,
                color: theme.colorScheme.error,
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  '${isChild ? 'Medical' : 'Vet'} Information',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (petKid["medicalInfo"] != null) ...[
                  Text(
                    'Medical Notes:',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    petKid["medicalInfo"] as String,
                    style: theme.textTheme.bodyMedium,
                  ),
                  SizedBox(height: 2.h),
                ],
                if (petKid["vetInfo"] != null && !isChild) ...[
                  Text(
                    'Veterinarian:',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    petKid["vetInfo"] as String,
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
                if (petKid["medicalInfo"] == null &&
                    petKid["vetInfo"] == null) ...[
                  Text(
                    'No ${isChild ? 'medical' : 'veterinary'} information available.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Close',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showPhotos(BuildContext context, Map<String, dynamic> petKid) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Photo gallery feature coming soon'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
