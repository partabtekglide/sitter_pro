import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class MessageComposerWidget extends StatefulWidget {
  final Function(String, String?) onSendMessage;

  const MessageComposerWidget({super.key, required this.onSendMessage});

  @override
  State<MessageComposerWidget> createState() => _MessageComposerWidgetState();
}

class _MessageComposerWidgetState extends State<MessageComposerWidget> {
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _messageFocusNode = FocusNode();
  String? _selectedClientId;
  bool _isRecording = false;

  // Mock client data for selection
  final List<Map<String, dynamic>> _clients = [
    {
      "id": "1",
      "name": "Sarah Johnson",
      "photo":
          "https://images.unsplash.com/photo-1494790108755-2616b612b786?w=150&h=150&fit=crop&crop=face",
    },
    {
      "id": "2",
      "name": "Mike Chen",
      "photo":
          "https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150&h=150&fit=crop&crop=face",
    },
    {
      "id": "3",
      "name": "Emily Rodriguez",
      "photo":
          "https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=150&h=150&fit=crop&crop=face",
    },
  ];

  // Template messages
  final List<String> _templates = [
    "Running 5 minutes late",
    "I've arrived at your location",
    "Pet has been fed and walked",
    "Kids are doing well, all good here",
    "Task completed successfully",
    "Will send photos shortly",
    "Everything went smoothly today",
    "Thank you for your trust",
  ];

  @override
  void dispose() {
    _messageController.dispose();
    _messageFocusNode.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isNotEmpty) {
      widget.onSendMessage(message, _selectedClientId);
      _messageController.clear();
      Navigator.pop(context);
    }
  }

  void _selectTemplate(String template) {
    _messageController.text = template;
    setState(() {});
  }

  void _toggleRecording() {
    setState(() {
      _isRecording = !_isRecording;
    });

    HapticFeedback.mediumImpact();

    if (_isRecording) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Voice recording started'),
          duration: Duration(seconds: 1),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Voice recording stopped'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  void _attachPhoto() {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Photo attachment feature coming soon'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
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
                      color: theme.colorScheme.outline.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                SizedBox(height: 3.h),

                // Header
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Compose Message',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: CustomIconWidget(
                        iconName: 'close',
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                        size: 5.w,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),

                SizedBox(height: 3.h),

                // Client selection
                Text(
                  'Select Client',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),

                SizedBox(height: 2.h),

                Container(
                  height: 12.h,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _clients.length,
                    itemBuilder: (context, index) {
                      final client = _clients[index];
                      final isSelected = _selectedClientId == client['id'];

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedClientId = client['id'] as String;
                          });
                        },
                        child: Container(
                          width: 18.w,
                          margin: EdgeInsets.only(right: 3.w),
                          child: Column(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color:
                                        isSelected
                                            ? theme.colorScheme.primary
                                            : Colors.transparent,
                                    width: 3,
                                  ),
                                ),
                                child: CircleAvatar(
                                  radius: 6.w,
                                  backgroundImage: NetworkImage(
                                    client['photo'] as String,
                                  ),
                                ),
                              ),
                              SizedBox(height: 1.h),
                              Text(
                                client['name'] as String,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight:
                                      isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                  color:
                                      isSelected
                                          ? theme.colorScheme.primary
                                          : theme.colorScheme.onSurface
                                              .withValues(alpha: 0.7),
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                SizedBox(height: 4.h),

                // Message templates
                Text(
                  'Quick Templates',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),

                SizedBox(height: 2.h),

                Wrap(
                  spacing: 2.w,
                  runSpacing: 1.h,
                  children:
                      _templates.map((template) {
                        return GestureDetector(
                          onTap: () => _selectTemplate(template),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 3.w,
                              vertical: 1.h,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: theme.colorScheme.primary.withValues(
                                  alpha: 0.3,
                                ),
                              ),
                            ),
                            child: Text(
                              template,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                ),

                SizedBox(height: 4.h),

                // Message input
                Text(
                  'Message',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),

                SizedBox(height: 2.h),

                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.outline.withValues(alpha: 0.3),
                    ),
                  ),
                  child: TextField(
                    controller: _messageController,
                    focusNode: _messageFocusNode,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Type your message here...',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(4.w),
                    ),
                  ),
                ),

                SizedBox(height: 3.h),

                // Action buttons row
                Row(
                  children: [
                    // Photo attachment
                    IconButton(
                      onPressed: _attachPhoto,
                      icon: CustomIconWidget(
                        iconName: 'photo_camera',
                        color: theme.colorScheme.primary,
                        size: 6.w,
                      ),
                      tooltip: 'Attach photo',
                    ),

                    SizedBox(width: 2.w),

                    // Voice memo
                    IconButton(
                      onPressed: _toggleRecording,
                      icon: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        child: CustomIconWidget(
                          iconName: _isRecording ? 'stop' : 'mic',
                          color:
                              _isRecording
                                  ? theme.colorScheme.error
                                  : theme.colorScheme.primary,
                          size: 6.w,
                        ),
                      ),
                      tooltip:
                          _isRecording ? 'Stop recording' : 'Record voice memo',
                    ),

                    const Spacer(),

                    // Send button
                    ElevatedButton.icon(
                      onPressed:
                          _messageController.text.trim().isNotEmpty &&
                                  _selectedClientId != null
                              ? _sendMessage
                              : null,
                      icon: CustomIconWidget(
                        iconName: 'send',
                        color: theme.colorScheme.onPrimary,
                        size: 4.w,
                      ),
                      label: const Text('Send'),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6.w,
                          vertical: 2.h,
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 2.h),

                // Recording indicator
                if (_isRecording)
                  Container(
                    padding: EdgeInsets.all(3.w),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 3.w,
                          height: 3.w,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.error,
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 3.w),
                        Text(
                          'Recording voice memo...',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.error,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                SizedBox(height: 10.h), // Extra space for keyboard
              ],
            ),
          );
        },
      ),
    );
  }
}
