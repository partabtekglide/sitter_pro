import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';

class CheckInCardWidget extends StatelessWidget {
  final Map<String, dynamic> booking;
  final bool isCheckedIn;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;

  const CheckInCardWidget({
    super.key,
    required this.booking,
    required this.isCheckedIn,
    this.checkInTime,
    this.checkOutTime,
  });

  @override
  Widget build(BuildContext context) {
    final clientName =
        booking['clients']?['user_profiles']?['full_name'] ?? 'Unknown Client';
    final serviceType = booking['service_type'] ?? '';
    final startTime = booking['start_time'] ?? '';
    final endTime = booking['end_time'] ?? '';
    final hourlyRate = (booking['hourly_rate'] as num?)?.toDouble() ?? 0.0;
    final address = booking['address'] ?? '';
    final specialInstructions = booking['special_instructions'];

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1976D2).withAlpha(13),
              const Color(0xFF42A5F5).withAlpha(5),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with status
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        clientName,
                        style: GoogleFonts.inter(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        _formatServiceType(serviceType),
                        style: GoogleFonts.inter(
                          fontSize: 14.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color:
                        isCheckedIn
                            ? const Color(0xFF4CAF50)
                            : const Color(0xFFFF9800),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isCheckedIn ? Icons.check_circle : Icons.schedule,
                        color: Colors.white,
                        size: 16.sp,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        isCheckedIn ? 'Active' : 'Scheduled',
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: 20.h),

            // Time and Rate Info
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    icon: Icons.access_time,
                    label: 'Scheduled Time',
                    value: '$startTime - $endTime',
                    color: const Color(0xFF1976D2),
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: _buildInfoItem(
                    icon: Icons.attach_money,
                    label: 'Hourly Rate',
                    value: '\$${hourlyRate.toStringAsFixed(2)}',
                    color: const Color(0xFF4CAF50),
                  ),
                ),
              ],
            ),

            if (isCheckedIn && checkInTime != null) ...[
              SizedBox(height: 16.h),

              // Check-in/Check-out Times
              Row(
                children: [
                  Expanded(
                    child: _buildTimeInfo(
                      label: 'Checked In',
                      time: checkInTime!,
                      color: const Color(0xFF4CAF50),
                    ),
                  ),
                  if (checkOutTime != null) ...[
                    SizedBox(width: 16.w),
                    Expanded(
                      child: _buildTimeInfo(
                        label: 'Checked Out',
                        time: checkOutTime!,
                        color: const Color(0xFFF44336),
                      ),
                    ),
                  ],
                ],
              ),
            ],

            SizedBox(height: 20.h),

            // Address
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.location_on,
                    color: const Color(0xFF1976D2),
                    size: 20.sp,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      address,
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            if (specialInstructions != null &&
                specialInstructions.isNotEmpty) ...[
              SizedBox(height: 16.h),

              // Special Instructions
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: const Color(0xFFFF9800),
                      size: 20.sp,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Special Instructions',
                            style: GoogleFonts.inter(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFE65100),
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            specialInstructions,
                            style: GoogleFonts.inter(
                              fontSize: 14.sp,
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
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
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
          Icon(icon, color: color, size: 24.sp),
          SizedBox(height: 8.h),
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 12.sp, color: Colors.grey[600]),
          ),
          SizedBox(height: 4.h),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeInfo({
    required String label,
    required DateTime time,
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
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 12.sp, color: Colors.grey[600]),
          ),
          SizedBox(height: 4.h),
          Text(
            _formatTime(time),
            style: GoogleFonts.inter(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            _formatDate(time),
            style: GoogleFonts.inter(fontSize: 11.sp, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  String _formatServiceType(String serviceType) {
    return serviceType
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
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
    return '${months[time.month - 1]} ${time.day}, ${time.year}';
  }
}