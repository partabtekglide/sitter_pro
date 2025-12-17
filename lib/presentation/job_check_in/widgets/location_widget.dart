import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';

class LocationWidget extends StatefulWidget {
  final String address;
  final Function(Map<String, dynamic>) onLocationUpdated;

  const LocationWidget({
    super.key,
    required this.address,
    required this.onLocationUpdated,
  });

  @override
  State<LocationWidget> createState() => _LocationWidgetState();
}

class _LocationWidgetState extends State<LocationWidget> {
  bool _isLocationEnabled = false;
  bool _isLoadingLocation = false;
  Map<String, dynamic>? _currentLocation;

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
  }

  Future<void> _checkLocationPermission() async {
    // Mock permission check
    setState(() {
      _isLocationEnabled = true; // Mock enabled
      _currentLocation = {
        'latitude': 39.7817,
        'longitude': -89.6501,
        'accuracy': 5.0,
        'timestamp': DateTime.now().toIso8601String(),
      };
    });
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);

    try {
      // Mock getting current location
      await Future.delayed(const Duration(seconds: 2));

      final mockLocation = {
        'latitude': 39.7817 + (0.001 * (DateTime.now().millisecond / 1000)),
        'longitude': -89.6501 + (0.001 * (DateTime.now().millisecond / 1000)),
        'accuracy': 3.0 + (DateTime.now().millisecond % 5),
        'timestamp': DateTime.now().toIso8601String(),
      };

      setState(() {
        _currentLocation = mockLocation;
        _isLoadingLocation = false;
      });

      widget.onLocationUpdated(mockLocation);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location updated successfully!'),
          backgroundColor: Color(0xFF4CAF50),
        ),
      );
    } catch (e) {
      setState(() => _isLoadingLocation = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to get location. Please try again.'),
          backgroundColor: Color(0xFFF44336),
        ),
      );
    }
  }

  void _requestLocationPermission() async {
    // Mock permission request
    setState(() => _isLoadingLocation = true);

    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _isLocationEnabled = true;
      _isLoadingLocation = false;
    });

    _getCurrentLocation();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: _isLocationEnabled
                      ? const Color(0xFF4CAF50)
                      : const Color(0xFFFF9800),
                  size: 24.sp,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Location Verification',
                        style: GoogleFonts.inter(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                      Text(
                        _isLocationEnabled
                            ? 'GPS tracking active'
                            : 'Location services disabled',
                        style: GoogleFonts.inter(
                          fontSize: 14.sp,
                          color: _isLocationEnabled
                              ? const Color(0xFF4CAF50)
                              : const Color(0xFFFF9800),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: (_isLocationEnabled
                            ? const Color(0xFF4CAF50)
                            : const Color(0xFFFF9800))
                        .withAlpha(26),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6.w,
                        height: 6.h,
                        decoration: BoxDecoration(
                          color: _isLocationEnabled
                              ? const Color(0xFF4CAF50)
                              : const Color(0xFFFF9800),
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        _isLocationEnabled ? 'ACTIVE' : 'INACTIVE',
                        style: GoogleFonts.inter(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w600,
                          color: _isLocationEnabled
                              ? const Color(0xFF4CAF50)
                              : const Color(0xFFFF9800),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: 20.h),

            // Service Address
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Service Address',
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    children: [
                      Icon(
                        Icons.home,
                        color: const Color(0xFF1976D2),
                        size: 18.sp,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          widget.address,
                          style: GoogleFonts.inter(
                            fontSize: 14.sp,
                            color: Colors.grey[800],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            if (_isLocationEnabled && _currentLocation != null) ...[
              SizedBox(height: 16.h),

              // Current Location Info
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withAlpha(13),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF4CAF50).withAlpha(51),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Location',
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF4CAF50),
                      ),
                    ),
                    SizedBox(height: 12.h),

                    _buildLocationDetail(
                      'Coordinates',
                      '${_currentLocation!['latitude']!.toStringAsFixed(4)}, '
                          '${_currentLocation!['longitude']!.toStringAsFixed(4)}',
                      Icons.gps_fixed,
                    ),

                    SizedBox(height: 8.h),

                    _buildLocationDetail(
                      'Accuracy',
                      '±${_currentLocation!['accuracy']!.toStringAsFixed(1)}m',
                      Icons.my_location,
                    ),

                    SizedBox(height: 8.h),

                    _buildLocationDetail(
                      'Last Updated',
                      _formatTimestamp(_currentLocation!['timestamp']),
                      Icons.schedule,
                    ),

                    SizedBox(height: 16.h),

                    // Distance Verification
                    Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50).withAlpha(26),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: const Color(0xFF4CAF50),
                            size: 20.sp,
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Location Verified',
                                  style: GoogleFonts.inter(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF4CAF50),
                                  ),
                                ),
                                Text(
                                  'You are within 50m of the service address',
                                  style: GoogleFonts.inter(
                                    fontSize: 12.sp,
                                    color: const Color(0xFF2E7D32),
                                  ),
                                ),
                              ],
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

            // Action Buttons
            if (!_isLocationEnabled)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed:
                      _isLoadingLocation ? null : _requestLocationPermission,
                  icon: _isLoadingLocation
                      ? SizedBox(
                          width: 16.w,
                          height: 16.h,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Icon(Icons.location_on),
                  label: Text(
                    _isLoadingLocation ? 'Enabling...' : 'Enable Location',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1976D2),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                  ),
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed:
                          _isLoadingLocation ? null : _getCurrentLocation,
                      icon: _isLoadingLocation
                          ? SizedBox(
                              width: 16.w,
                              height: 16.h,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  const Color(0xFF4CAF50),
                                ),
                              ),
                            )
                          : const Icon(Icons.refresh),
                      label: Text(
                        _isLoadingLocation ? 'Updating...' : 'Update Location',
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF4CAF50),
                        side: const BorderSide(color: Color(0xFF4CAF50)),
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _openMaps(),
                      icon: const Icon(Icons.map),
                      label: const Text('Open Maps'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF1976D2),
                        side: const BorderSide(color: Color(0xFF1976D2)),
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationDetail(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16.sp, color: Colors.grey[600]),
        SizedBox(width: 8.w),
        Text(
          '$label: ',
          style: GoogleFonts.inter(fontSize: 12.sp, color: Colors.grey[600]),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
              color: Colors.grey[800],
            ),
          ),
        ),
      ],
    );
  }

  String _formatTimestamp(String timestamp) {
    final time = DateTime.tryParse(timestamp);
    if (time == null) return 'Unknown';

    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else {
      final hour = time.hour > 12
          ? time.hour - 12
          : time.hour == 0
              ? 12
              : time.hour;
      final minute = time.minute.toString().padLeft(2, '0');
      final period = time.hour >= 12 ? 'PM' : 'AM';
      return '$hour:$minute $period';
    }
  }

  void _openMaps() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening Maps with service address...'),
        backgroundColor: Color(0xFF1976D2),
      ),
    );

    // In real implementation, this would open maps with the address
  }
}
