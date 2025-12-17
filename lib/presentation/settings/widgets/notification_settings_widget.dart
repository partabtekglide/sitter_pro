import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationSettingsWidget extends StatefulWidget {
  final Function(Map<String, dynamic>) onSave;

  const NotificationSettingsWidget({Key? key, required this.onSave})
    : super(key: key);

  @override
  State<NotificationSettingsWidget> createState() =>
      _NotificationSettingsWidgetState();
}

class _NotificationSettingsWidgetState
    extends State<NotificationSettingsWidget> {
  final Map<String, bool> _settings = {
    'booking_requests': true,
    'booking_confirmations': true,
    'payment_reminders': true,
    'client_messages': true,
    'calendar_reminders': false,
    'marketing_updates': false,
  };

  final Map<String, String> _reminderTiming = {
    'booking_reminders': '1_hour',
    'payment_reminders': '1_day',
  };

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      setState(() {
        _settings.forEach((key, defaultValue) {
          _settings[key] = prefs.getBool('notification_$key') ?? defaultValue;
        });

        _reminderTiming.forEach((key, defaultValue) {
          _reminderTiming[key] = prefs.getString('timing_$key') ?? defaultValue;
        });

        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSetting(String key, bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notification_$key', value);

      setState(() {
        _settings[key] = value;
      });

      widget.onSave({key: value});
    } catch (e) {
      // Handle error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save notification setting: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveTimingSetting(String key, String value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('timing_$key', value);

      setState(() {
        _reminderTiming[key] = value;
      });

      widget.onSave({key: value});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save timing setting: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(13),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'Notifications',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Booking Notifications
                _buildSectionTitle('Booking Notifications'),
                const SizedBox(height: 12),

                _buildNotificationTile(
                  'booking_requests',
                  'Booking Requests',
                  'Get notified when clients request your services',
                  Icons.calendar_today_outlined,
                ),

                _buildNotificationTile(
                  'booking_confirmations',
                  'Booking Confirmations',
                  'Receive confirmations when bookings are accepted',
                  Icons.check_circle_outline,
                ),

                // Reminders Section
                if (_settings['booking_confirmations'] == true) ...[
                  const SizedBox(height: 12),
                  _buildTimingSelector(
                    'booking_reminders',
                    'Booking Reminders',
                    'Remind me before appointments',
                    [
                      {'value': '15_min', 'label': '15 minutes'},
                      {'value': '30_min', 'label': '30 minutes'},
                      {'value': '1_hour', 'label': '1 hour'},
                      {'value': '2_hours', 'label': '2 hours'},
                    ],
                  ),
                ],

                const SizedBox(height: 20),

                // Payment Notifications
                _buildSectionTitle('Payment Notifications'),
                const SizedBox(height: 12),

                _buildNotificationTile(
                  'payment_reminders',
                  'Payment Reminders',
                  'Notifications about pending payments',
                  Icons.payment_outlined,
                ),

                if (_settings['payment_reminders'] == true) ...[
                  const SizedBox(height: 12),
                  _buildTimingSelector(
                    'payment_reminders',
                    'Payment Reminder Timing',
                    'Send payment reminders after completion',
                    [
                      {'value': '1_day', 'label': '1 day'},
                      {'value': '3_days', 'label': '3 days'},
                      {'value': '1_week', 'label': '1 week'},
                    ],
                  ),
                ],

                const SizedBox(height: 20),

                // Communication Notifications
                _buildSectionTitle('Communication'),
                const SizedBox(height: 12),

                _buildNotificationTile(
                  'client_messages',
                  'Client Messages',
                  'New messages from clients',
                  Icons.message_outlined,
                ),

                _buildNotificationTile(
                  'calendar_reminders',
                  'Calendar Reminders',
                  'Daily schedule summaries',
                  Icons.event_note_outlined,
                ),

                const SizedBox(height: 20),

                // Marketing Notifications
                _buildSectionTitle('App Updates'),
                const SizedBox(height: 12),

                _buildNotificationTile(
                  'marketing_updates',
                  'Marketing & Tips',
                  'Business tips and feature updates',
                  Icons.lightbulb_outline,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildNotificationTile(
    String key,
    String title,
    String description,
    IconData icon,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color:
                _settings[key]!
                    ? const Color(0xFF6C5CE7).withAlpha(26)
                    : Colors.grey[100],
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            color: _settings[key]! ? const Color(0xFF6C5CE7) : Colors.grey[400],
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        subtitle: Text(
          description,
          style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600]),
        ),
        trailing: Switch.adaptive(
          value: _settings[key]!,
          onChanged: (value) => _saveSetting(key, value),
          activeColor: const Color(0xFF6C5CE7),
        ),
      ),
    );
  }

  Widget _buildTimingSelector(
    String key,
    String title,
    String description,
    List<Map<String, String>> options,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children:
                options.map((option) {
                  final isSelected = _reminderTiming[key] == option['value'];
                  return GestureDetector(
                    onTap: () => _saveTimingSetting(key, option['value']!),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isSelected ? const Color(0xFF6C5CE7) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color:
                              isSelected
                                  ? const Color(0xFF6C5CE7)
                                  : Colors.grey[300]!,
                        ),
                      ),
                      child: Text(
                        option['label']!,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isSelected ? Colors.white : Colors.grey[700],
                        ),
                      ),
                    ),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }
}
