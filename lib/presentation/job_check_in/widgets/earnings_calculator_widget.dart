import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';

class EarningsCalculatorWidget extends StatefulWidget {
  final DateTime checkInTime;
  final double hourlyRate;

  const EarningsCalculatorWidget({
    super.key,
    required this.checkInTime,
    required this.hourlyRate,
  });

  @override
  State<EarningsCalculatorWidget> createState() =>
      _EarningsCalculatorWidgetState();
}

class _EarningsCalculatorWidgetState extends State<EarningsCalculatorWidget> {
  late Duration _elapsed;
  late double _currentEarnings;
  late double _projectedTotal;
  late int _overtimeMinutes;

  @override
  void initState() {
    super.initState();
    _updateCalculations();

    // Update calculations every minute
    Future.doWhile(() async {
      if (mounted) {
        await Future.delayed(const Duration(minutes: 1));
        if (mounted) {
          _updateCalculations();
        }
        return true;
      }
      return false;
    });
  }

  void _updateCalculations() {
    setState(() {
      _elapsed = DateTime.now().difference(widget.checkInTime);

      final totalMinutes = _elapsed.inMinutes;
      final totalHours = totalMinutes / 60.0;

      // Calculate current earnings
      _currentEarnings = totalHours * widget.hourlyRate;

      // Calculate overtime (assuming 8 hours is standard)
      final standardHours = 8;
      final standardMinutes = standardHours * 60;
      _overtimeMinutes =
          totalMinutes > standardMinutes ? totalMinutes - standardMinutes : 0;

      // Calculate projected total if continuing at current rate
      final projectedHours = totalHours + 1; // Project 1 hour ahead
      _projectedTotal = projectedHours * widget.hourlyRate;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF4CAF50).withAlpha(13),
              const Color(0xFF81C784).withAlpha(5),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.calculate,
                  color: const Color(0xFF4CAF50),
                  size: 24.sp,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    'Earnings Calculator',
                    style: GoogleFonts.inter(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withAlpha(51),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Live',
                    style: GoogleFonts.inter(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF4CAF50),
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 20.h),

            // Current Earnings Display
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withAlpha(26),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF4CAF50).withAlpha(77),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'Current Session Earnings',
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    '\$${_currentEarnings.toStringAsFixed(2)}',
                    style: GoogleFonts.inter(
                      fontSize: 36.sp,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF4CAF50),
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    '${_elapsed.inHours}h ${_elapsed.inMinutes.remainder(60)}m at \$${widget.hourlyRate.toStringAsFixed(2)}/hr',
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20.h),

            // Breakdown Cards
            Row(
              children: [
                Expanded(
                  child: _buildCalculationCard(
                    title: 'Base Rate',
                    value: '\$${widget.hourlyRate.toStringAsFixed(2)}',
                    subtitle: 'Per Hour',
                    icon: Icons.schedule,
                    color: const Color(0xFF2196F3),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _buildCalculationCard(
                    title: 'Duration',
                    value: '${(_elapsed.inMinutes / 60.0).toStringAsFixed(1)}h',
                    subtitle: 'Total Time',
                    icon: Icons.timer,
                    color: const Color(0xFF9C27B0),
                  ),
                ),
              ],
            ),

            SizedBox(height: 12.h),

            Row(
              children: [
                Expanded(
                  child: _buildCalculationCard(
                    title: 'Next Hour',
                    value: '\$${_projectedTotal.toStringAsFixed(2)}',
                    subtitle: 'Projected',
                    icon: Icons.trending_up,
                    color: const Color(0xFF4CAF50),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _buildCalculationCard(
                    title: _overtimeMinutes > 0 ? 'Overtime' : 'Regular',
                    value:
                        _overtimeMinutes > 0
                            ? '${(_overtimeMinutes / 60.0).toStringAsFixed(1)}h'
                            : 'On Time',
                    subtitle: _overtimeMinutes > 0 ? 'Extra Hours' : 'Status',
                    icon:
                        _overtimeMinutes > 0
                            ? Icons.access_time_filled
                            : Icons.check_circle,
                    color:
                        _overtimeMinutes > 0
                            ? const Color(0xFFFF9800)
                            : const Color(0xFF4CAF50),
                  ),
                ),
              ],
            ),

            if (_overtimeMinutes > 0) ...[
              SizedBox(height: 16.h),

              // Overtime Alert
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9800).withAlpha(26),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning,
                      color: const Color(0xFFFF9800),
                      size: 20.sp,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Overtime Alert',
                            style: GoogleFonts.inter(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFFF9800),
                            ),
                          ),
                          Text(
                            'You have worked ${(_overtimeMinutes / 60.0).toStringAsFixed(1)} hours of overtime',
                            style: GoogleFonts.inter(
                              fontSize: 12.sp,
                              color: const Color(0xFFE65100),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            SizedBox(height: 20.h),

            // Calculation Breakdown
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Calculation Breakdown',
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  SizedBox(height: 12.h),

                  _buildCalculationRow(
                    'Time worked:',
                    '${(_elapsed.inMinutes / 60.0).toStringAsFixed(2)} hours',
                  ),

                  _buildCalculationRow(
                    'Hourly rate:',
                    '\$${widget.hourlyRate.toStringAsFixed(2)} / hour',
                  ),

                  Divider(height: 16.h, color: Colors.grey[300]),

                  _buildCalculationRow(
                    'Total earnings:',
                    '\$${_currentEarnings.toStringAsFixed(2)}',
                    isTotal: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalculationCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20.sp),
          SizedBox(height: 6.h),
          Text(
            title,
            style: GoogleFonts.inter(fontSize: 10.sp, color: Colors.grey[600]),
          ),
          SizedBox(height: 2.h),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            subtitle,
            style: GoogleFonts.inter(fontSize: 9.sp, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildCalculationRow(
    String label,
    String value, {
    bool isTotal = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isTotal ? 0 : 6.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              color: Colors.grey[600],
              fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              color: isTotal ? const Color(0xFF4CAF50) : Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }
}