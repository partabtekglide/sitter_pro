import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class AddClientSheet extends StatefulWidget {
  const AddClientSheet({super.key});

  @override
  State<AddClientSheet> createState() => _AddClientSheetState();
}

class _AddClientSheetState extends State<AddClientSheet> {
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final addressController = TextEditingController();
  final emergencyContactController = TextEditingController();
  final emergencyPhoneController = TextEditingController();
  final notesController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    addressController.dispose();
    emergencyContactController.dispose();
    emergencyPhoneController.dispose();
    notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: EdgeInsets.all(4.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 12.w,
                    height: 0.5.h,
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .outline
                          .withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                SizedBox(height: 3.h),

                // Header
                Text(
                  'Add New Client',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                SizedBox(height: 3.h),

                // Form fields
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name *',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 2.h),

                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number *',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                SizedBox(height: 2.h),

                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email Address *',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                SizedBox(height: 2.h),

                TextField(
                  controller: addressController,
                  decoration: const InputDecoration(
                    labelText: 'Address *',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                SizedBox(height: 2.h),

                TextField(
                  controller: emergencyContactController,
                  decoration: const InputDecoration(
                    labelText: 'Emergency Contact Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 2.h),

                TextField(
                  controller: emergencyPhoneController,
                  decoration: const InputDecoration(
                    labelText: 'Emergency Contact Phone',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                SizedBox(height: 2.h),

                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: 'Special Notes',
                    border: OutlineInputBorder(),
                    hintText: 'Any special instructions or notes...',
                  ),
                  maxLines: 3,
                ),
                SizedBox(height: 4.h),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                    ),
                    SizedBox(width: 3.w),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (nameController.text.isNotEmpty &&
                              phoneController.text.isNotEmpty &&
                              emailController.text.isNotEmpty &&
                              addressController.text.isNotEmpty) {
                            Navigator.of(context).pop({
                              'name': nameController.text,
                              'phone': phoneController.text,
                              'email': emailController.text,
                              'address': addressController.text,
                              'emergency_contact':
                                  emergencyContactController.text,
                              'emergency_phone': emergencyPhoneController.text,
                              'notes': notesController.text,
                            });
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                    Text('Please fill all required fields'),
                                backgroundColor: Colors.orange,
                              ),
                            );
                          }
                        },
                        child: const Text('Add Client'),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 2.h),
              ],
            ),
          );
        },
      ),
    );
  }
}
