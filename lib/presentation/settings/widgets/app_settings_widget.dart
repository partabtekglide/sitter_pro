import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

class AppSettingsWidget extends StatefulWidget {
  const AppSettingsWidget({Key? key}) : super(key: key);

  @override
  State<AppSettingsWidget> createState() => _AppSettingsWidgetState();
}

class _AppSettingsWidgetState extends State<AppSettingsWidget> {
  String _selectedTheme = 'system';
  String _selectedLanguage = 'en';
  String _selectedCurrency = 'USD';
  String _selectedTimeZone = 'America/New_York';
  bool _isPWAInstallable = false;
  bool _isLoading = true;

  final List<Map<String, String>> _themes = [
    {'value': 'light', 'label': 'Light'},
    {'value': 'dark', 'label': 'Dark'},
    {'value': 'system', 'label': 'System Default'},
  ];

  final List<Map<String, String>> _languages = [
    {'value': 'en', 'label': 'English'},
    {'value': 'es', 'label': 'Español'},
    {'value': 'fr', 'label': 'Français'},
    {'value': 'de', 'label': 'Deutsch'},
  ];

  final List<Map<String, String>> _currencies = [
    {'value': 'USD', 'label': '\$ USD'},
    {'value': 'EUR', 'label': '€ EUR'},
    {'value': 'GBP', 'label': '£ GBP'},
    {'value': 'CAD', 'label': '\$ CAD'},
  ];

  final List<Map<String, String>> _timeZones = [
    {'value': 'America/New_York', 'label': 'Eastern Time (ET)'},
    {'value': 'America/Chicago', 'label': 'Central Time (CT)'},
    {'value': 'America/Denver', 'label': 'Mountain Time (MT)'},
    {'value': 'America/Los_Angeles', 'label': 'Pacific Time (PT)'},
    {'value': 'UTC', 'label': 'UTC'},
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _checkPWAInstallable();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      setState(() {
        _selectedTheme = prefs.getString('app_theme') ?? 'system';
        _selectedLanguage = prefs.getString('app_language') ?? 'en';
        _selectedCurrency = prefs.getString('app_currency') ?? 'USD';
        _selectedTimeZone =
            prefs.getString('app_timezone') ?? 'America/New_York';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSetting(String key, String value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);

      // Provide user feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Setting saved: ${_getSettingLabel(key, value)}'),
          duration: const Duration(seconds: 1),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save setting: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _checkPWAInstallable() {
    // This is a simplified check - in a real app, you'd check if the app
    // is running in a browser that supports PWA installation
    setState(() {
      _isPWAInstallable = true; // Simulate PWA support
    });
  }

  String _getSettingLabel(String key, String value) {
    switch (key) {
      case 'app_theme':
        return _themes.firstWhere((t) => t['value'] == value)['label'] ?? value;
      case 'app_language':
        return _languages.firstWhere((l) => l['value'] == value)['label'] ??
            value;
      case 'app_currency':
        return _currencies.firstWhere((c) => c['value'] == value)['label'] ??
            value;
      case 'app_timezone':
        return _timeZones.firstWhere((tz) => tz['value'] == value)['label'] ??
            value;
      default:
        return value;
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
              'App Preferences',
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
                // Theme Selection
                _buildSectionTitle('Appearance'),
                const SizedBox(height: 12),
                _buildSettingSelector(
                  'Theme',
                  _selectedTheme,
                  _themes,
                  Icons.palette_outlined,
                  (value) {
                    setState(() {
                      _selectedTheme = value;
                    });
                    _saveSetting('app_theme', value);
                  },
                ),

                const SizedBox(height: 20),

                // Language & Region
                _buildSectionTitle('Language & Region'),
                const SizedBox(height: 12),

                _buildSettingSelector(
                  'Language',
                  _selectedLanguage,
                  _languages,
                  Icons.language_outlined,
                  (value) {
                    setState(() {
                      _selectedLanguage = value;
                    });
                    _saveSetting('app_language', value);
                  },
                ),

                const SizedBox(height: 16),

                _buildSettingSelector(
                  'Currency',
                  _selectedCurrency,
                  _currencies,
                  Icons.attach_money_outlined,
                  (value) {
                    setState(() {
                      _selectedCurrency = value;
                    });
                    _saveSetting('app_currency', value);
                  },
                ),

                const SizedBox(height: 16),

                _buildSettingSelector(
                  'Time Zone',
                  _selectedTimeZone,
                  _timeZones,
                  Icons.schedule_outlined,
                  (value) {
                    setState(() {
                      _selectedTimeZone = value;
                    });
                    _saveSetting('app_timezone', value);
                  },
                ),

                const SizedBox(height: 20),

                // PWA Installation
                if (_isPWAInstallable) ...[
                  _buildSectionTitle('Installation'),
                  const SizedBox(height: 12),
                  _buildPWAInstallCard(),
                  const SizedBox(height: 20),
                ],

                // About Section
                _buildSectionTitle('About'),
                const SizedBox(height: 12),

                _buildInfoRow('App Version', '1.0.0'),
                const SizedBox(height: 8),
                _buildInfoRow('Build', '1.0.0+1'),
                const SizedBox(height: 8),
                _buildInfoRow('Last Updated', 'Nov 13, 2024'),

                const SizedBox(height: 16),

                // Support Links
                _buildActionRow(
                  'Privacy Policy',
                  Icons.privacy_tip_outlined,
                  () => _openPrivacyPolicy(),
                ),
                const SizedBox(height: 8),
                _buildActionRow(
                  'Terms of Service',
                  Icons.description_outlined,
                  () => _openTermsOfService(),
                ),
                const SizedBox(height: 8),
                _buildActionRow(
                  'Contact Support',
                  Icons.support_agent_outlined,
                  () => _contactSupport(),
                ),
                const SizedBox(height: 8),
                _buildActionRow(
                  'Rate App',
                  Icons.star_outline,
                  () => _rateApp(),
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

  Widget _buildSettingSelector(
    String title,
    String currentValue,
    List<Map<String, String>> options,
    IconData icon,
    Function(String) onChanged,
  ) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF6C5CE7).withAlpha(26),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, color: const Color(0xFF6C5CE7), size: 20),
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
          options.firstWhere(
                (option) => option['value'] == currentValue,
              )['label'] ??
              currentValue,
          style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600]),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap:
            () => _showSelectionDialog(title, currentValue, options, onChanged),
      ),
    );
  }

  Widget _buildPWAInstallCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF6C5CE7).withAlpha(26),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF6C5CE7).withAlpha(51)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6C5CE7),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.get_app, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Install App',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF6C5CE7),
                      ),
                    ),
                    Text(
                      'Install Sitter Pro for quick access',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _installPWA,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C5CE7),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: Text(
                'Install Now',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600]),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildActionRow(String title, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF6C5CE7), size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF6C5CE7),
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
          ],
        ),
      ),
    );
  }

  void _showSelectionDialog(
    String title,
    String currentValue,
    List<Map<String, String>> options,
    Function(String) onChanged,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              'Select $title',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children:
                  options.map((option) {
                    final isSelected = option['value'] == currentValue;
                    return ListTile(
                      title: Text(
                        option['label']!,
                        style: GoogleFonts.inter(
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                          color:
                              isSelected
                                  ? const Color(0xFF6C5CE7)
                                  : Colors.black87,
                        ),
                      ),
                      leading: Radio<String>(
                        value: option['value']!,
                        groupValue: currentValue,
                        onChanged: (value) {
                          if (value != null) {
                            Navigator.pop(context);
                            onChanged(value);
                          }
                        },
                        activeColor: const Color(0xFF6C5CE7),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        onChanged(option['value']!);
                      },
                    );
                  }).toList(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.inter(color: Colors.grey[600]),
                ),
              ),
            ],
          ),
    );
  }

  void _installPWA() {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('PWA installation triggered'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _openPrivacyPolicy() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Opening Privacy Policy...')));
  }

  void _openTermsOfService() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening Terms of Service...')),
    );
  }

  void _contactSupport() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Opening support contact...')));
  }

  void _rateApp() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening app store for rating...')),
    );
  }
}
