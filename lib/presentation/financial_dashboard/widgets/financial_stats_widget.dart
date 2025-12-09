import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class FinancialStatsWidget extends StatelessWidget {
  final double totalEarnings;
  final double pendingPayments;
  final double weeklyEarnings;
  final double monthlyEarnings;
  final double averageRate;

  const FinancialStatsWidget({
    super.key,
    required this.totalEarnings,
    required this.pendingPayments,
    required this.weeklyEarnings,
    required this.monthlyEarnings,
    required this.averageRate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Top row - Main earnings
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context: context,
                title: 'YTD Total',
                amount: totalEarnings,
                icon: Icons.trending_up,
                color: Colors.green,
                isMainCard: true,
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: _buildStatCard(
                context: context,
                title: 'Pending',
                amount: pendingPayments,
                icon: Icons.hourglass_empty,
                color: Colors.orange,
                isMainCard: true,
              ),
            ),
          ],
        ),

        SizedBox(height: 3.h),

        // Bottom row - Period earnings
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context: context,
                title: 'This Week',
                amount: weeklyEarnings,
                icon: Icons.calendar_today,
                color: theme.colorScheme.primary,
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: _buildStatCard(
                context: context,
                title: 'This Month',
                amount: monthlyEarnings,
                icon: Icons.calendar_month,
                color: theme.colorScheme.secondary,
              ),
            ),
          ],
        ),

        SizedBox(height: 3.h),

        // Average rate card
        _buildStatCard(
          context: context,
          title: 'Average Hourly Rate',
          amount: averageRate,
          icon: Icons.attach_money,
          color: Colors.purple,
          isRate: true,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required BuildContext context,
    required String title,
    required double amount,
    required IconData icon,
    required Color color,
    bool isMainCard = false,
    bool isRate = false,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 5.w),
              ),
              const Spacer(),
              if (isMainCard)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 2.w,
                    vertical: 0.5.h,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'MAIN',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                      fontSize: 8.sp,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 2.h),
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            isRate
                ? '\$${amount.toStringAsFixed(0)}/hr'
                : '\$${amount.toStringAsFixed(2)}',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
