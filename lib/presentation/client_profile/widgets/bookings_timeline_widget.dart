import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class BookingsTimelineWidget extends StatelessWidget {
  final List<Map<String, dynamic>> bookings;
  final Function(Map<String, dynamic>)? onBookingTap;
  final Function(Map<String, dynamic>)? onDuplicate;
  final Function(Map<String, dynamic>)? onInvoice;
  final Function(Map<String, dynamic>)? onMarkPaid;

  const BookingsTimelineWidget({
    super.key,
    required this.bookings,
    this.onBookingTap,
    this.onDuplicate,
    this.onInvoice,
    this.onMarkPaid,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (bookings.isEmpty) {
      return Container(
        padding: EdgeInsets.all(4.w),
        child: Column(
          children: [
            CustomIconWidget(
              iconName: 'event_note',
              size: 48,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            SizedBox(height: 2.h),
            Text(
              'No bookings yet',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Booking history will appear here once appointments are scheduled',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Sort bookings by date (most recent first)
    final sortedBookings = List<Map<String, dynamic>>.from(bookings);
    sortedBookings.sort((a, b) {
      final dateA = DateTime.parse(a["date"] as String? ?? "2024-01-01");
      final dateB = DateTime.parse(b["date"] as String? ?? "2024-01-01");
      return dateB.compareTo(dateA);
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
          child: Text(
            'Booking History (${bookings.length})',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          itemCount: sortedBookings.length,
          separatorBuilder: (context, index) => SizedBox(height: 1.h),
          itemBuilder: (context, index) {
            final booking = sortedBookings[index];
            return _buildBookingCard(context, booking, index == 0);
          },
        ),
      ],
    );
  }

  Widget _buildBookingCard(
      BuildContext context, Map<String, dynamic> booking, bool isLatest) {
    final theme = Theme.of(context);
    final status = booking["status"] as String? ?? "pending";
    final paymentStatus = booking["paymentStatus"] as String? ?? "pending";

    Color statusColor = theme.colorScheme.secondary;
    Color paymentColor = theme.colorScheme.secondary;

    switch (status.toLowerCase()) {
      case 'completed':
        statusColor = theme.colorScheme.primary;
        break;
      case 'confirmed':
        statusColor = AppTheme.successLight;
        break;
      case 'cancelled':
        statusColor = theme.colorScheme.error;
        break;
      case 'pending':
        statusColor = AppTheme.warningLight;
        break;
    }

    switch (paymentStatus.toLowerCase()) {
      case 'paid':
        paymentColor = AppTheme.successLight;
        break;
      case 'pending':
        paymentColor = AppTheme.warningLight;
        break;
      case 'overdue':
        paymentColor = theme.colorScheme.error;
        break;
    }

    return Slidable(
      key: ValueKey(booking["id"]),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (context) => onDuplicate?.call(booking),
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
            icon: Icons.copy,
            label: 'Duplicate',
            borderRadius:
                const BorderRadius.horizontal(left: Radius.circular(12)),
          ),
          SlidableAction(
            onPressed: (context) => onInvoice?.call(booking),
            backgroundColor: theme.colorScheme.secondary,
            foregroundColor: theme.colorScheme.onSecondary,
            icon: Icons.receipt,
            label: 'Invoice',
          ),
          if (paymentStatus.toLowerCase() != 'paid')
            SlidableAction(
              onPressed: (context) => onMarkPaid?.call(booking),
              backgroundColor: AppTheme.successLight,
              foregroundColor: Colors.white,
              icon: Icons.payment,
              label: 'Mark Paid',
              borderRadius:
                  const BorderRadius.horizontal(right: Radius.circular(12)),
            ),
        ],
      ),
      child: Card(
        elevation: isLatest ? 2 : 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isLatest
              ? BorderSide(
                  color: theme.colorScheme.primary.withValues(alpha: 0.3),
                  width: 1)
              : BorderSide.none,
        ),
        child: InkWell(
          onTap: () => onBookingTap?.call(booking),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.all(3.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 2.w, vertical: 0.5.h),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  status.toUpperCase(),
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: statusColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 8.sp,
                                  ),
                                ),
                              ),
                              SizedBox(width: 2.w),
                              if (isLatest) ...[
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 2.w, vertical: 0.5.h),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'LATEST',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 8.sp,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          SizedBox(height: 1.h),
                          Text(
                            booking["service"] as String? ?? "Unknown Service",
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _formatDate(booking["date"] as String? ?? ""),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.7),
                          ),
                        ),
                        SizedBox(height: 0.5.h),
                        Text(
                          booking["time"] as String? ?? "",
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 2.h),
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          CustomIconWidget(
                            iconName: 'schedule',
                            size: 16,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.6),
                          ),
                          SizedBox(width: 1.w),
                          Text(
                            '${booking["duration"] as String? ?? "0"} hours',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        CustomIconWidget(
                          iconName: 'attach_money',
                          size: 16,
                          color: paymentColor,
                        ),
                        Text(
                          booking["amount"] as String? ?? "\$0",
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: paymentColor,
                          ),
                        ),
                        SizedBox(width: 2.w),
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 2.w, vertical: 0.5.h),
                          decoration: BoxDecoration(
                            color: paymentColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            paymentStatus.toUpperCase(),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: paymentColor,
                              fontWeight: FontWeight.w500,
                              fontSize: 8.sp,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (booking["notes"] != null) ...[
                  SizedBox(height: 1.h),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(2.w),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        CustomIconWidget(
                          iconName: 'note',
                          size: 14,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.6),
                        ),
                        SizedBox(width: 2.w),
                        Expanded(
                          child: Text(
                            booking["notes"] as String,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.7),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                SizedBox(height: 1.h),
                Row(
                  children: [
                    CustomIconWidget(
                      iconName: 'swipe',
                      size: 12,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                    SizedBox(width: 1.w),
                    Text(
                      'Swipe left for actions',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.4),
                        fontSize: 8.sp,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date).inDays;

      if (difference == 0) {
        return 'Today';
      } else if (difference == 1) {
        return 'Yesterday';
      } else if (difference < 7) {
        return '$difference days ago';
      } else {
        return '${date.month}/${date.day}/${date.year}';
      }
    } catch (e) {
      return dateString;
    }
  }
}
