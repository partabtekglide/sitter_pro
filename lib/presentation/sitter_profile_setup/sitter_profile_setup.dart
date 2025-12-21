import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import './widgets/bio_section.dart';
import './widgets/emergency_contact_section.dart';
import './widgets/profile_photo_section.dart';
import './widgets/rate_settings_section.dart';
import './widgets/service_type_selector.dart';
import '../../services/supabase_service.dart';

class SitterProfileSetup extends StatefulWidget {
  const SitterProfileSetup({super.key});

  @override
  State<SitterProfileSetup> createState() => _SitterProfileSetupState();
}

class _SitterProfileSetupState extends State<SitterProfileSetup>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();

  // Controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _rateController = TextEditingController();
  final _bioController = TextEditingController();

  // State variables
  int _currentStep = 0;
  XFile? _selectedPhoto;
  String? _existingAvatarUrl;
  List<ServiceType> _selectedServices = [];
  List<EmergencyContact> _emergencyContacts = [];
  bool _isLoading = false;

  // Progress tracking
  static const int totalSteps = 3;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    setState(() => _isLoading = true);
    try {
      final user = SupabaseService.instance.currentUser;
      if (user != null) {
        final profile = await SupabaseService.instance.getUserProfile(user.id);
        if (profile != null) {
          setState(() {
            _nameController.text = profile['full_name'] ?? '';
            _emailController.text = profile['email'] ?? '';
            _phoneController.text = profile['phone'] ?? '';
            _addressController.text = profile['address'] ?? '';
            _bioController.text = profile['bio'] ?? '';
            _rateController.text = (profile['hourly_rate'] ?? '').toString();
            _existingAvatarUrl = profile['avatar_url'];
            // Note: services and emergency contacts are not in user_profiles table
            // so they are not populated here unless added to the schema
          });
        }
      }
    } catch (e) {
      print('Error fetching profile: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _rateController.dispose();
    _bioController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  bool _isStepValid(int step) {
    switch (step) {
      case 0:
        return _nameController.text.trim().isNotEmpty &&
            _phoneController.text.trim().isNotEmpty &&
            _emailController.text.trim().isNotEmpty;
      case 1:
        return _rateController.text.trim().isNotEmpty &&
            (double.tryParse(_rateController.text) ?? 0) >= 5;
      case 2:
        return true; // Bio and emergency contacts are optional
      default:
        return false;
    }
  }

  void _nextStep() {
    if (_currentStep < totalSteps - 1) {
      if (_isStepValid(_currentStep)) {
        setState(() {
          _currentStep++;
        });
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        _showValidationError();
      }
    } else {
      _completeSetup();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _showValidationError() {
    String message = '';
    switch (_currentStep) {
      case 0:
        message = 'Please fill in all required personal information';
        break;
      case 1:
        message = 'Please select at least one service and set your hourly rate';
        break;
      default:
        message = 'Please complete all required fields';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.lightTheme.colorScheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Future<void> _completeSetup() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = SupabaseService.instance.currentUser;
      if (user == null) throw Exception('User not logged in');

      String? avatarUrl = _existingAvatarUrl;
      if (_selectedPhoto != null) {
        avatarUrl = await SupabaseService.instance.uploadAvatar(
          user.id,
          _selectedPhoto!.path,
        );
      }

      final updates = {
        'full_name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'bio': _bioController.text.trim(),
        'hourly_rate': double.tryParse(_rateController.text.trim()) ?? 0.0,
        'avatar_url': avatarUrl,
      };

      await SupabaseService.instance.updateUserProfile(user.id, updates);

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profile setup completed successfully!'),
            backgroundColor: AppTheme.lightTheme.colorScheme.tertiary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );

        // Navigate to dashboard
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/dashboard',
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save profile: ${e.toString()}'),
            backgroundColor: AppTheme.lightTheme.colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<bool> _onWillPop() async {
    if (_currentStep > 0) {
      _previousStep();
      return false;
    }

    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Exit Setup?'),
            content: const Text(
                'Your progress will be lost. Are you sure you want to exit?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(
                  'Exit',
                  style: TextStyle(
                    color: AppTheme.lightTheme.colorScheme.error,
                  ),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(
            'Profile Setup',
            style: AppTheme.lightTheme.textTheme.titleLarge,
          ),
          backgroundColor: AppTheme.lightTheme.appBarTheme.backgroundColor,
          elevation: 0,
          leading: IconButton(
            onPressed:
                _currentStep > 0 ? _previousStep : () => Navigator.pop(context),
            icon: CustomIconWidget(
              iconName: 'arrow_back',
              color: AppTheme.lightTheme.colorScheme.onSurface,
              size: 24,
            ),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              _buildProgressIndicator(),
              Expanded(
                child: Form(
                  key: _formKey,
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildPersonalInfoStep(),
                      _buildServicePreferencesStep(),
                      _buildAdditionalInfoStep(),
                    ],
                  ),
                ),
              ),
              _buildBottomNavigation(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: EdgeInsets.all(4.w),
      child: Column(
        children: [
          Row(
            children: List.generate(totalSteps, (index) {
              final isCompleted = index < _currentStep;
              final isCurrent = index == _currentStep;

              return Expanded(
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 1.w),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: isCompleted || isCurrent
                                ? AppTheme.lightTheme.colorScheme.primary
                                : AppTheme.lightTheme.colorScheme.outline
                                    .withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      if (index < totalSteps - 1) SizedBox(width: 1.w),
                    ],
                  ),
                ),
              );
            }),
          ),
          SizedBox(height: 2.h),
          Text(
            'Step ${_currentStep + 1} of $totalSteps',
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurface
                  .withValues(alpha: 0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoStep() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Personal Information',
            style: AppTheme.lightTheme.textTheme.headlineSmall,
          ),
          SizedBox(height: 1.h),
          Text(
            'Let\'s start with your basic information',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurface
                  .withValues(alpha: 0.7),
            ),
          ),
          SizedBox(height: 4.h),
          ProfilePhotoSection(
            onPhotoSelected: (photo) {
              setState(() {
                _selectedPhoto = photo;
              });
            },
            selectedPhoto: _selectedPhoto,
            existingAvatarUrl: _existingAvatarUrl,
          ),
          SizedBox(height: 4.h),
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Full Name *',
              hintText: 'Enter your full name',
            ),
            textCapitalization: TextCapitalization.words,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your full name';
              }
              return null;
            },
          ),
          SizedBox(height: 3.h),
          TextFormField(
            controller: _phoneController,
            decoration: const InputDecoration(
              labelText: 'Phone Number *',
              hintText: '(555) 123-4567',
            ),
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your phone number';
              }
              if (value.length < 10) {
                return 'Please enter a valid phone number';
              }
              return null;
            },
          ),
          SizedBox(height: 3.h),
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email Address *',
              hintText: 'your.email@example.com',
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your email address';
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                  .hasMatch(value)) {
                return 'Please enter a valid email address';
              }
              return null;
            },
          ),
          SizedBox(height: 3.h),
          TextFormField(
            controller: _addressController,
            decoration: const InputDecoration(
              labelText: 'Address',
              hintText: 'Enter your address',
            ),
            textCapitalization: TextCapitalization.words,
            maxLines: 2,
          ),
          SizedBox(height: 6.h),
        ],
      ),
    );
  }

  Widget _buildServicePreferencesStep() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Service Preferences',
            style: AppTheme.lightTheme.textTheme.headlineSmall,
          ),
          SizedBox(height: 1.h),
          Text(
            'Tell us about the services you offer',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurface
                  .withValues(alpha: 0.7),
            ),
          ),
          SizedBox(height: 4.h),
          /*
          ServiceTypeSelector(
            selectedServices: _selectedServices,
            onServicesChanged: (services) {
              setState(() {
                _selectedServices = services;
              });
            },
          ),
          SizedBox(height: 4.h),
          */
          RateSettingsSection(
            rateController: _rateController,
            onRateChanged: (rate) {
              // Rate is automatically updated through controller
            },
          ),
          SizedBox(height: 6.h),
        ],
      ),
    );
  }

  Widget _buildAdditionalInfoStep() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Additional Information',
            style: AppTheme.lightTheme.textTheme.headlineSmall,
          ),
          SizedBox(height: 1.h),
          Text(
            'Help clients get to know you better',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurface
                  .withValues(alpha: 0.7),
            ),
          ),
          SizedBox(height: 4.h),
          BioSection(
            bioController: _bioController,
            onBioChanged: (bio) {
              // Bio is automatically updated through controller
            },
          ),
          SizedBox(height: 4.h),
          /*
          EmergencyContactSection(
            contacts: _emergencyContacts,
            onContactsChanged: (contacts) {
              setState(() {
                _emergencyContacts = contacts;
              });
            },
          ),
          */
          SizedBox(height: 6.h),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color:
                AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (_currentStep > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: _previousStep,
                  child: const Text('Back'),
                ),
              ),
            if (_currentStep > 0) SizedBox(width: 4.w),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _nextStep,
                child: _isLoading
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppTheme.lightTheme.colorScheme.onPrimary,
                          ),
                        ),
                      )
                    : Text(
                        _currentStep == totalSteps - 1
                            ? 'Complete Setup'
                            : 'Continue',
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
