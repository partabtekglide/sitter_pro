import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class TodayScheduleWidget extends StatelessWidget {
  final List<Map<String, dynamic>> appointments;
  final Function(Map<String, dynamic>) onAppointmentTap;
  final Function(Map<String, dynamic>) onCheckIn;
  final Function(Map<String, dynamic>) onMessageClient;
  final Function(Map<String, dynamic>) onViewDetails;

  const TodayScheduleWidget({
    super.key,
    required this.appointments,
    required this.onAppointmentTap,
    required this.onCheckIn,
    required this.onMessageClient,
    required this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
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
          Padding(
            padding: EdgeInsets.all(4.w),
            child: Row(
              children: [
                CustomIconWidget(
                  iconName: 'schedule',
                  color: theme.colorScheme.primary,
                  size: 5.w,
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: Text(
                    'Today\'s Schedule',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                Text(
                  '${appointments.length} appointments',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          if (appointments.isEmpty)
            Padding(
              padding: EdgeInsets.all(4.w),
              child: Center(
                child: Column(
                  children: [
                    CustomIconWidget(
                      iconName: 'event_available',
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                      size: 12.w,
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'No appointments today',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      'Enjoy your free day!',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: appointments.length > 3 ? 3 : appointments.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                color: theme.colorScheme.outline.withValues(alpha: 0.2),
              ),
              itemBuilder: (context, index) {
                final appointment = appointments[index];
                return _buildAppointmentCard(context, appointment);
              },
            ),
          if (appointments.length > 3)
            Padding(
              padding: EdgeInsets.all(4.w),
              child: Center(
                child: TextButton(
                  onPressed: () {
                    // Navigate to full schedule
                  },
                  child: Text(
                    'View all ${appointments.length} appointments',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAppointmentCard(
      BuildContext context, Map<String, dynamic> appointment) {
    final theme = Theme.of(context);

    return Slidable(
      key: ValueKey(appointment['id']),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (context) => onCheckIn(appointment),
            backgroundColor: theme.colorScheme.tertiary,
            foregroundColor: theme.colorScheme.onTertiary,
            icon: Icons.login,
            label: 'Check-in',
          ),
          SlidableAction(
            onPressed: (context) => onMessageClient(appointment),
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
            icon: Icons.message,
            label: 'Message',
          ),
          SlidableAction(
            onPressed: (context) => onViewDetails(appointment),
            backgroundColor: theme.colorScheme.secondary,
            foregroundColor: theme.colorScheme.onSecondary,
            icon: Icons.info,
            label: 'Details',
          ),
        ],
      ),
      child: InkWell(
        onTap: () => onAppointmentTap(appointment),
        child: Padding(
          padding: EdgeInsets.all(4.w),
          child: Row(
            children: [
              Container(
                width: 12.w,
                height: 12.w,
                decoration: BoxDecoration(
                  color: _getServiceColor(
                          appointment['serviceType'] as String, theme)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: CustomIconWidget(
                    iconName:
                        _getServiceIcon(appointment['serviceType'] as String),
                    color: _getServiceColor(
                        appointment['serviceType'] as String, theme),
                    size: 6.w,
                  ),
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appointment['clientName'] as String,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      appointment['serviceType'] as String,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    Row(
                      children: [
                        CustomIconWidget(
                          iconName: 'access_time',
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.5),
                          size: 3.w,
                        ),
                        SizedBox(width: 1.w),
                        Text(
                          '${appointment['startTime']} - ${appointment['endTime']}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                    decoration: BoxDecoration(
                      color: _getStatusColor(
                              appointment['status'] as String, theme)
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      appointment['status'] as String,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: _getStatusColor(
                            appointment['status'] as String, theme),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    '\$${appointment['amount']}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getServiceIcon(String serviceType) {
    switch (serviceType.toLowerCase()) {
      case 'babysitting':
        return 'child_care';
      case 'pet sitting':
        return 'pets';
      case 'house sitting':
        return 'home';
      default:
        return 'work';
    }
  }

  Color _getServiceColor(String serviceType, ThemeData theme) {
    switch (serviceType.toLowerCase()) {
      case 'babysitting':
        return theme.colorScheme.tertiary;
      case 'pet sitting':
        return theme.colorScheme.primary;
      case 'house sitting':
        return theme.colorScheme.secondary;
      default:
        return theme.colorScheme.onSurface;
    }
  }

  Color _getStatusColor(String status, ThemeData theme) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'completed':
        return theme.colorScheme.primary;
      default:
        return theme.colorScheme.onSurface;
    }
  }
}
