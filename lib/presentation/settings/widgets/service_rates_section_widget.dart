import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class ServiceRatesSectionWidget extends StatefulWidget {
  final Map<String, dynamic> userProfile;
  final Function(Map<String, dynamic>) onSave;

  const ServiceRatesSectionWidget({
    Key? key,
    required this.userProfile,
    required this.onSave,
  }) : super(key: key);

  @override
  State<ServiceRatesSectionWidget> createState() => _ServiceRatesSectionWidgetState();
}

class _ServiceRatesSectionWidgetState extends State<ServiceRatesSectionWidget> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _hourlyRateController;
  
  bool _isEditing = false;
  bool _hasChanges = false;
  
  // Service types from the database enum
  final List<Map<String, dynamic>> _serviceTypes = [
{ 'type': 'babysitting',
'title': 'Babysitting',
'icon': Icons.child_care,
'description': 'Professional childcare services',
'enabled': true,
},
{ 'type': 'pet_sitting',
'title': 'Pet Sitting',
'icon': Icons.pets,
'description': 'Pet care and companionship',
'enabled': true,
},
{ 'type': 'house_sitting',
'title': 'House Sitting',
'icon': Icons.home,
'description': 'Home security and maintenance',
'enabled': false,
},
{ 'type': 'elder_care',
'title': 'Elder Care',
'icon': Icons.elderly,
'description': 'Senior companion services',
'enabled': false,
},
];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    final hourlyRate = widget.userProfile['hourly_rate'];
    _hourlyRateController = TextEditingController(
      text: hourlyRate != null ? hourlyRate.toString() : '',
    );
    
    _hourlyRateController.addListener(_trackChanges);
  }

  void _trackChanges() {
    final currentRate = widget.userProfile['hourly_rate']?.toString() ?? '';
    final hasChanges = _hourlyRateController.text != currentRate;
        
    if (_hasChanges != hasChanges) {
      setState(() {
        _hasChanges = hasChanges;
      });
    }
  }

  @override
  void dispose() {
    _hourlyRateController.dispose();
    super.dispose();
  }

  void _toggleEdit() {
    if (_isEditing && _hasChanges) {
      _showSaveDialog();
    } else {
      setState(() {
        _isEditing = !_isEditing;
        if (!_isEditing) {
          _initializeControllers();
          _hasChanges = false;
        }
      });
    }
  }

  void _showSaveDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Save Changes?',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'You have unsaved changes to your service rates. Do you want to save them?',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _isEditing = false;
                _initializeControllers();
                _hasChanges = false;
              });
            },
            child: Text(
              'Discard',
              style: GoogleFonts.inter(color: Colors.grey[600]),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _saveServiceRates();
            },
            child: Text(
              'Save',
              style: GoogleFonts.inter(
                color: const Color(0xFF6C5CE7),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _saveServiceRates() {
    if (_formKey.currentState?.validate() ?? false) {
      final rate = double.tryParse(_hourlyRateController.text);
      final updates = {
        'hourly_rate': rate,
      };
      
      widget.onSave(updates);
      setState(() {
        _isEditing = false;
        _hasChanges = false;
      });
    }
  }

  void _toggleService(String serviceType, bool enabled) {
    setState(() {
      final index = _serviceTypes.indexWhere((s) => s['type'] == serviceType);
      if (index != -1) {
        _serviceTypes[index]['enabled'] = enabled;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Services & Rates',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                Row(
                  children: [
                    if (_isEditing && _hasChanges)
                      TextButton(
                        onPressed: _saveServiceRates,
                        style: TextButton.styleFrom(
                          backgroundColor: const Color(0xFF6C5CE7),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        child: Text(
                          'Save',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _toggleEdit,
                      icon: Icon(
                        _isEditing ? Icons.close : Icons.edit,
                        color: _isEditing ? Colors.grey[600] : const Color(0xFF6C5CE7),
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Default Hourly Rate
                  Text(
                    'Default Hourly Rate',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  Row(
                    children: [
                      const Icon(
                        Icons.attach_money,
                        color: Color(0xFF6C5CE7),
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _hourlyRateController,
                          enabled: _isEditing,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                          ],
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Hourly rate is required';
                            }
                            final rate = double.tryParse(value);
                            if (rate == null || rate < 0) {
                              return 'Enter a valid rate';
                            }
                            if (rate > 1000) {
                              return 'Rate seems too high';
                            }
                            return null;
                          },
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _isEditing ? Colors.black87 : Colors.grey[600],
                          ),
                          decoration: InputDecoration(
                            hintText: '25.00',
                            suffix: Text(
                              'per hour',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Color(0xFF6C5CE7)),
                            ),
                            disabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey[200]!),
                            ),
                            filled: !_isEditing,
                            fillColor: _isEditing ? null : Colors.grey[50],
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Service Types
                  Text(
                    'Available Services',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  ..._serviceTypes.map((service) => _buildServiceTile(
                    service['type'],
                    service['title'],
                    service['icon'],
                    service['description'],
                    service['enabled'],
                  )),
                  
                  const SizedBox(height: 16),
                  
                  // Rate Calculator Info
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6C5CE7).withAlpha(26),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: Color(0xFF6C5CE7),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Rate Information',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF6C5CE7),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '• This is your default hourly rate for all services\n'
                          '• You can adjust rates for individual bookings\n'
                          '• Rates are displayed to clients during booking',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.grey[600],
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceTile(String type, String title, IconData icon, String description, bool enabled) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: enabled ? const Color(0xFF6C5CE7).withAlpha(26) : Colors.grey[100],
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            color: enabled ? const Color(0xFF6C5CE7) : Colors.grey[400],
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: enabled ? Colors.black87 : Colors.grey[500],
          ),
        ),
        subtitle: Text(
          description,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        trailing: _isEditing 
            ? Switch.adaptive(
                value: enabled,
                onChanged: (value) => _toggleService(type, value),
                activeColor: const Color(0xFF6C5CE7),
              )
            : enabled 
                ? const Icon(Icons.check_circle, color: Color(0xFF6C5CE7), size: 20)
                : Icon(Icons.radio_button_unchecked, color: Colors.grey[400], size: 20),
      ),
    );
  }
}