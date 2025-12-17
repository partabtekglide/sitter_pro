import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class EmergencyContact {
  String name;
  String phone;
  String relationship;

  EmergencyContact({
    required this.name,
    required this.phone,
    required this.relationship,
  });
}

class EmergencyContactSection extends StatefulWidget {
  final List<EmergencyContact> contacts;
  final Function(List<EmergencyContact>) onContactsChanged;

  const EmergencyContactSection({
    super.key,
    required this.contacts,
    required this.onContactsChanged,
  });

  @override
  State<EmergencyContactSection> createState() =>
      _EmergencyContactSectionState();
}

class _EmergencyContactSectionState extends State<EmergencyContactSection> {
  final List<String> _relationshipOptions = [
    'Spouse/Partner',
    'Parent',
    'Sibling',
    'Friend',
    'Colleague',
    'Other Family',
    'Neighbor',
  ];

  void _addContact() {
    final newContact = EmergencyContact(
      name: '',
      phone: '',
      relationship: _relationshipOptions.first,
    );

    final updatedContacts = List<EmergencyContact>.from(widget.contacts)
      ..add(newContact);
    widget.onContactsChanged(updatedContacts);
  }

  void _removeContact(int index) {
    final updatedContacts = List<EmergencyContact>.from(widget.contacts)
      ..removeAt(index);
    widget.onContactsChanged(updatedContacts);
  }

  void _updateContact(int index, EmergencyContact updatedContact) {
    final updatedContacts = List<EmergencyContact>.from(widget.contacts);
    updatedContacts[index] = updatedContact;
    widget.onContactsChanged(updatedContacts);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Emergency Contacts',
              style: AppTheme.lightTheme.textTheme.titleMedium,
            ),
            if (widget.contacts.length < 3)
              TextButton.icon(
                onPressed: _addContact,
                icon: CustomIconWidget(
                  iconName: 'add',
                  color: AppTheme.lightTheme.colorScheme.primary,
                  size: 18,
                ),
                label: Text(
                  'Add Contact',
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: 1.h),
        Text(
          'Add emergency contacts for safety during your sitting jobs',
          style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
            color: AppTheme.lightTheme.colorScheme.onSurface
                .withValues(alpha: 0.7),
          ),
        ),
        SizedBox(height: 2.h),
        if (widget.contacts.isEmpty)
          _buildEmptyState()
        else
          ...widget.contacts.asMap().entries.map((entry) {
            final index = entry.key;
            final contact = entry.value;
            return _buildContactCard(index, contact);
          }).toList(),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          CustomIconWidget(
            iconName: 'contact_emergency',
            color: AppTheme.lightTheme.colorScheme.onSurface
                .withValues(alpha: 0.5),
            size: 32,
          ),
          SizedBox(height: 2.h),
          Text(
            'No emergency contacts added',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurface
                  .withValues(alpha: 0.7),
            ),
          ),
          SizedBox(height: 1.h),
          ElevatedButton.icon(
            onPressed: _addContact,
            icon: CustomIconWidget(
              iconName: 'add',
              color: AppTheme.lightTheme.colorScheme.onPrimary,
              size: 18,
            ),
            label: const Text('Add First Contact'),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard(int index, EmergencyContact contact) {
    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Contact ${index + 1}',
                style: AppTheme.lightTheme.textTheme.titleSmall,
              ),
              IconButton(
                onPressed: () => _removeContact(index),
                icon: CustomIconWidget(
                  iconName: 'delete',
                  color: AppTheme.lightTheme.colorScheme.error,
                  size: 20,
                ),
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
          SizedBox(height: 2.h),
          TextFormField(
            initialValue: contact.name,
            decoration: const InputDecoration(
              labelText: 'Full Name',
              hintText: 'Enter contact name',
            ),
            textCapitalization: TextCapitalization.words,
            onChanged: (value) {
              _updateContact(
                index,
                EmergencyContact(
                  name: value,
                  phone: contact.phone,
                  relationship: contact.relationship,
                ),
              );
            },
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter contact name';
              }
              return null;
            },
          ),
          SizedBox(height: 2.h),
          TextFormField(
            initialValue: contact.phone,
            decoration: const InputDecoration(
              labelText: 'Phone Number',
              hintText: '(555) 123-4567',
            ),
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            onChanged: (value) {
              _updateContact(
                index,
                EmergencyContact(
                  name: contact.name,
                  phone: value,
                  relationship: contact.relationship,
                ),
              );
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter phone number';
              }
              if (value.length < 10) {
                return 'Please enter a valid phone number';
              }
              return null;
            },
          ),
          SizedBox(height: 2.h),
          DropdownButtonFormField<String>(
            value: contact.relationship,
            decoration: const InputDecoration(
              labelText: 'Relationship',
            ),
            items: _relationshipOptions.map((relationship) {
              return DropdownMenuItem(
                value: relationship,
                child: Text(relationship),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                _updateContact(
                  index,
                  EmergencyContact(
                    name: contact.name,
                    phone: contact.phone,
                    relationship: value,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
