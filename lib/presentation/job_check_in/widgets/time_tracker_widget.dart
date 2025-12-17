import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';

class TimeTrackerWidget extends StatefulWidget {
  final DateTime checkInTime;
  final double hourlyRate;

  const TimeTrackerWidget({
    super.key,
    required this.checkInTime,
    required this.hourlyRate,
  });

  @override
  State<TimeTrackerWidget> createState() => _TimeTrackerWidgetState();
}

class _TimeTrackerWidgetState extends State<TimeTrackerWidget> {
  late Duration _elapsed;
  late double _currentEarnings;

  @override
  void initState() {
    super.initState();
    _updateTime();

    // Update every second
    Future.doWhile(() async {
      if (mounted) {
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          _updateTime();
        }
        return true;
      }
      return false;
    });
  }

  void _updateTime() {
    setState(() {
      _elapsed = DateTime.now().difference(widget.checkInTime);
      _currentEarnings = (_elapsed.inMinutes / 60.0) * widget.hourlyRate;
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
              const Color(0xFF4CAF50).withAlpha(26),
              const Color(0xFF81C784).withAlpha(13),
            ],
          ),
        ),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.timer, color: const Color(0xFF4CAF50), size: 24.sp),
                SizedBox(width: 8.w),
                Text(
                  'Time Tracker',
                  style: GoogleFonts.inter(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                const Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withAlpha(51),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6.w,
                        height: 6.h,
                        decoration: const BoxDecoration(
                          color: Color(0xFF4CAF50),
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        'ACTIVE',
                        style: GoogleFonts.inter(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF4CAF50),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: 24.h),

            // Time Display
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF4CAF50).withAlpha(77),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'Session Duration',
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    _formatDuration(_elapsed),
                    style: GoogleFonts.inter(
                      fontSize: 32.sp,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF4CAF50),
                      letterSpacing: 2,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'Hours : Minutes : Seconds',
                    style: GoogleFonts.inter(
                      fontSize: 10.sp,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20.h),

            // Earnings and Rate Info
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    title: 'Current Earnings',
                    value: '\$${_currentEarnings.toStringAsFixed(2)}',
                    icon: Icons.attach_money,
                    color: const Color(0xFF4CAF50),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _buildStatCard(
                    title: 'Hourly Rate',
                    value: '\$${widget.hourlyRate.toStringAsFixed(2)}',
                    icon: Icons.schedule,
                    color: const Color(0xFF2196F3),
                  ),
                ),
              ],
            ),

            SizedBox(height: 20.h),

            // Session Info
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.login, color: Colors.grey[600], size: 16.sp),
                      SizedBox(width: 8.w),
                      Text(
                        'Started at ${_formatTime(widget.checkInTime)}',
                        style: GoogleFonts.inter(
                          fontSize: 14.sp,
                          color: Colors.grey[700],
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _formatDate(widget.checkInTime),
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),

                  // Progress indicators
                  Row(
                    children: [
                      Expanded(
                        child: _buildProgressItem(
                          label: 'Minutes',
                          value: _elapsed.inMinutes,
                          maxValue: 480, // 8 hours max
                          color: const Color(0xFF4CAF50),
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: _buildProgressItem(
                          label: 'Earnings Rate',
                          value:
                              (_currentEarnings / (widget.hourlyRate * 8) * 100)
                                  .round(),
                          maxValue: 100,
                          color: const Color(0xFF2196F3),
                          isPercentage: true,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24.sp),
          SizedBox(height: 8.h),
          Text(
            title,
            style: GoogleFonts.inter(fontSize: 12.sp, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 4.h),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressItem({
    required String label,
    required int value,
    required int maxValue,
    required Color color,
    bool isPercentage = false,
  }) {
    final progress = (value / maxValue).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                color: Colors.grey[600],
              ),
            ),
            Text(
              isPercentage ? '${value}%' : value.toString(),
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
        SizedBox(height: 4.h),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: color.withAlpha(51),
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }

  String _formatTime(DateTime time) {
    final hour =
        time.hour > 12
            ? time.hour - 12
            : time.hour == 0
            ? 12
            : time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  String _formatDate(DateTime time) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[time.month - 1]} ${time.day}';
  }
}