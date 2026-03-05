import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import '../../core/app_export.dart';
import '../../widgets/custom_app_bar.dart';
import '../../services/supabase_service.dart';

class EditClientScreen extends StatefulWidget {
  final Map<String, dynamic> clientData;

  const EditClientScreen({super.key, required this.clientData});

  @override
  State<EditClientScreen> createState() => _EditClientScreenState();
}

class _EditClientScreenState extends State<EditClientScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _emergencyNameController;
  late TextEditingController _emergencyPhoneController;
  late TextEditingController _notesController;
  bool _isLoading = false;

  final List<String> _availableServices = [
    'Babysitting',
    'Pet Sitting',
    'House Sitting',
    'ElderlyCare',
  ];
  List<String> _selectedServices = [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.clientData['name']);
    _phoneController = TextEditingController(text: widget.clientData['phone']);
    _emailController = TextEditingController(text: widget.clientData['email']);
    _addressController =
        TextEditingController(text: widget.clientData['address']);

    _emergencyNameController = TextEditingController(
        text: widget.clientData['emergency_contact_name'] ?? '');
    _emergencyPhoneController = TextEditingController(
        text: widget.clientData['emergency_contact_phone'] ?? '');
    _notesController =
        TextEditingController(text: widget.clientData['specialInstructions'] ?? '');

    // Load existing services
    if (widget.clientData['preferredServices'] != null) {
      _selectedServices = List<String>.from(widget.clientData['preferredServices']);
    } else if (widget.clientData['serviceTypes'] != null) {
      _selectedServices = List<String>.from(widget.clientData['serviceTypes']);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveClient() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await SupabaseService.instance.updateClient(
        clientId: widget.clientData['id'].toString(),
        fullName: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        address: _addressController.text.trim(),
        emergencyContactName: _emergencyNameController.text.trim(),
        emergencyContactPhone: _emergencyPhoneController.text.trim(),
        notes: _notesController.text.trim(),
        preferredServices: _selectedServices,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Client updated successfully')),
      );

      // Return the updated data so the profile can update immediately
      Navigator.pop(context, {
        ...widget.clientData,
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'address': _addressController.text.trim(),
        'emergency_contact_name': _emergencyNameController.text.trim(),
        'emergency_contact_phone': _emergencyPhoneController.text.trim(),
        'specialInstructions': _notesController.text.trim(),
        'serviceTypes': _selectedServices,
        'preferredServices': _selectedServices,
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error updating client: $e'),
            backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Edit Client',
        variant: CustomAppBarVariant.standard,
        onBackPressed: () => Navigator.pop(context),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(4.w),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle(context, 'Basic Information'),
                    SizedBox(height: 2.h),
                    _buildTextField(
                      controller: _nameController,
                      label: 'Full Name',
                      icon: Icons.person,
                      validator: (v) =>
                          v?.isEmpty == true ? 'Name is required' : null,
                    ),
                    SizedBox(height: 2.h),
                    _buildTextField(
                      controller: _phoneController,
                      label: 'Phone',
                      icon: Icons.phone,
                      inputType: TextInputType.phone,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Phone is required';
                        if (v.length < 10 || v.length > 11) return 'Enter a valid 10-11 digit number';
                        return null;
                      },
                    ),
                    SizedBox(height: 2.h),
                    _buildTextField(
                      controller: _emailController,
                      label: 'Email',
                      icon: Icons.email,
                      inputType: TextInputType.emailAddress,
                      validator: (v) =>
                          v?.isEmpty == true ? 'Email is required' : null,
                    ),
                    SizedBox(height: 2.h),
                    _buildTextField(
                      controller: _addressController,
                      label: 'Address',
                      icon: Icons.location_on,
                      maxLines: 2,
                      validator: (v) =>
                          v?.isEmpty == true ? 'Address is required' : null,
                    ),

                    SizedBox(height: 4.h),
                    _buildSectionTitle(context, 'Emergency Contact'),
                    SizedBox(height: 2.h),
                    _buildTextField(
                      controller: _emergencyNameController,
                      label: 'Contact Name',
                      icon: Icons.contact_emergency,
                    ),
                    SizedBox(height: 2.h),
                    _buildTextField(
                      controller: _emergencyPhoneController,
                      label: 'Contact Phone',
                      icon: Icons.phone_in_talk,
                      inputType: TextInputType.phone,
                      validator: (v) {
                        if (v != null && v.isNotEmpty) {
                          if (v.length < 10 || v.length > 11) return 'Enter a valid 10-11 digit number';
                        }
                        return null;
                      },
                    ),

                    SizedBox(height: 4.h),
                    _buildSectionTitle(context, 'Preferred Services'),
                    SizedBox(height: 2.h),
                    Wrap(
                      spacing: 2.w,
                      runSpacing: 1.h,
                      children: _availableServices.map((service) {
                        final isSelected = _selectedServices.contains(service);
                        return FilterChip(
                          label: Text(service),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedServices.add(service);
                              } else {
                                _selectedServices.remove(service);
                              }
                            });
                          },
                          selectedColor:
                              theme.colorScheme.primary.withValues(alpha: 0.2),
                          checkmarkColor: theme.colorScheme.primary,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w400,
                          ),
                        );
                      }).toList(),
                    ),

                    SizedBox(height: 4.h),
                    _buildSectionTitle(context, 'Additional Info'),
                    SizedBox(height: 2.h),
                    _buildTextField(
                      controller: _notesController,
                      label: 'Special Instructions / Notes',
                      icon: Icons.note,
                      maxLines: 3,
                    ),

                    SizedBox(height: 5.h),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveClient,
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 2.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Save Changes',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 2.h),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType inputType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: inputType,
      maxLines: maxLines,
      validator: validator,
      inputFormatters: inputType == TextInputType.phone 
          ? [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(11)] 
          : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        hintText: inputType == TextInputType.phone ? 'Enter 10-11 digit number' : null,
      ),
    );
  }
}
