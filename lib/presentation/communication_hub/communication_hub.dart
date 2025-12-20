import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/supabase_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_bottom_bar.dart';
import './widgets/conversation_list_widget.dart';
import './widgets/message_composer_widget.dart';
import './widgets/search_header_widget.dart';

class CommunicationHub extends StatefulWidget {
  const CommunicationHub({super.key});

  @override
  State<CommunicationHub> createState() => _CommunicationHubState();
}

class _CommunicationHubState extends State<CommunicationHub>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;

  List<Map<String, dynamic>> _templates = [];
  List<Map<String, dynamic>> _conversations = [];
  List<Map<String, dynamic>> _sentHistory = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      // final templates = await SupabaseService.instance.getMessageTemplates();
      // final conversations = await SupabaseService.instance.getConversations();

      if (mounted) {
        setState(() {
          // _templates = templates;
          // _conversations = conversations;
          // _sentHistory =
          //     conversations.where((c) => c['type'] == 'message').toList();
          _isLoading = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar( 
          SnackBar(
            content: Text('Failed to load data: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  Future<void> _sendViaEmail({
    required String to,
    required String subject,
    required String body,
  }) async {
    try {
      final emailUrl = Uri.parse(
          'mailto:$to?subject=${Uri.encodeFull(subject)}&body=${Uri.encodeFull(body)}');
      if (await canLaunchUrl(emailUrl)) {
        await launchUrl(emailUrl);
        HapticFeedback.lightImpact();
      } else {
        throw Exception('Could not launch email client');
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to open email: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _sendViaSMS({
    required String to,
    required String body,
  }) async {
    try {
      final smsUrl = Uri.parse('sms:$to?body=${Uri.encodeFull(body)}');
      if (await canLaunchUrl(smsUrl)) {
        await launchUrl(smsUrl);
        HapticFeedback.lightImpact();
      } else {
        throw Exception('Could not launch SMS client');
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to open SMS: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _createTemplate(Map<String, String> template) async {
    try {
      await SupabaseService.instance.saveMessageTemplate(
        subject: template['subject']!,
        content: template['content']!,
        type: template['type']!,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Template saved successfully')),
      );

      _loadData(); // Refresh data
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save template: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _mergePlaceholders(String template, Map<String, String> data) {
    String merged = template;
    data.forEach((key, value) {
      merged = merged.replaceAll('{$key}', value);
    });
    return merged;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: const CustomAppBar(
          title: 'Communication Hub',
          variant: CustomAppBarVariant.standard,
        ),
        body: const Center(child: CircularProgressIndicator()),
        bottomNavigationBar: const CustomBottomBar(currentIndex: 2),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: const CustomAppBar(
        title: 'Communication Hub',
        variant: CustomAppBarVariant.standard,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Header
            /*
            SearchHeaderWidget(
              onFilterTap: () {},
              totalUnread: 0,
            ),
            */

            SizedBox(height: 2.h),

            // Tab Bar
            /*
            Container(
              margin: EdgeInsets.symmetric(horizontal: 4.w),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                indicatorPadding: EdgeInsets.all(0.5.h),
                labelColor: theme.colorScheme.onPrimary,
                unselectedLabelColor: theme.colorScheme.onSurface,
                labelStyle: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                tabs: const [
                  Tab(text: 'Templates'),
                  Tab(text: 'Send'),
                  Tab(text: 'History'),
                ],
              ),
            ),
            */

            SizedBox(height: 2.h),

            // Tab Views
            Expanded(
              child: MessageComposerWidget(
                initialClientId: (ModalRoute.of(context)?.settings.arguments as Map?)?['clientId'],
                onSendMessage: (message, client) {
                  // Logic handled internally in MessageComposerWidget
                },
              ),
            ),
            /*
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Templates Tab
                  _buildTemplatesTab(theme),

                  // Send Tab
                  MessageComposerWidget(
                    onSendMessage: (message, clientId) {},
                  ),

                  // History Tab
                  ConversationListWidget(
                    conversations: _sentHistory
                        .where((c) =>
                            _searchQuery.isEmpty ||
                            c['content']
                                    ?.toString()
                                    .toLowerCase()
                                    .contains(_searchQuery.toLowerCase()) ==
                                true)
                        .toList(),
                    onConversationTap: (conversation) {},
                    onCallClient: (conversation) {},
                    onVideoCall: (conversation) {},
                    onMarkAsRead: (conversation) {},
                  ),
                ],
              ),
            ),
            */
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomBar(currentIndex: 2),
      // floatingActionButton: _tabController.index == 0
      //     ? FloatingActionButton(
      //         onPressed: () => _showCreateTemplateDialog(theme),
      //         child: const Icon(Icons.add),
      //       )
      //     : null,
    );
  }

  Widget _buildTemplatesTab(ThemeData theme) {
    final filteredTemplates = _templates
        .where((template) =>
            _searchQuery.isEmpty ||
            template['subject']
                    ?.toString()
                    .toLowerCase()
                    .contains(_searchQuery.toLowerCase()) ==
                true ||
            template['content']
                    ?.toString()
                    .toLowerCase()
                    .contains(_searchQuery.toLowerCase()) ==
                true)
        .toList();

    if (filteredTemplates.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.message_outlined,
              size: 15.w,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
            SizedBox(height: 2.h),
            Text(
              _searchQuery.isEmpty
                  ? 'No Templates Yet'
                  : 'No Matching Templates',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              _searchQuery.isEmpty
                  ? 'Tap the + button to create your first template'
                  : 'Try a different search term',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(4.w),
      itemCount: filteredTemplates.length,
      itemBuilder: (context, index) {
        final template = filteredTemplates[index];
        return Card(
          margin: EdgeInsets.only(bottom: 2.h),
          child: ListTile(
            contentPadding: EdgeInsets.all(3.w),
            leading: CircleAvatar(
              backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
              child: Icon(
                Icons.mail_outline,
                color: theme.colorScheme.primary,
              ),
            ),
            title: Text(
              template['subject'] ?? 'No Subject',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              template['content'] ?? '',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            trailing: PopupMenuButton(
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: ListTile(
                    leading: Icon(Icons.edit),
                    title: Text('Edit'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    leading: Icon(Icons.delete, color: Colors.red),
                    title: Text('Delete', style: TextStyle(color: Colors.red)),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'edit') {
                  _showEditTemplateDialog(theme, template);
                } else if (value == 'delete') {
                  _showDeleteConfirmation(template);
                }
              },
            ),
          ),
        );
      },
    );
  }

  void _showCreateTemplateDialog(ThemeData theme) {
    showDialog(
      context: context,
      builder: (context) => _TemplateDialog(
        title: 'Create Template',
        onSave: _createTemplate,
      ),
    );
  }

  void _showEditTemplateDialog(ThemeData theme, Map<String, dynamic> template) {
    showDialog(
      context: context,
      builder: (context) => _TemplateDialog(
        title: 'Edit Template',
        initialSubject: template['subject'],
        initialContent: template['content'],
        onSave: (updatedTemplate) async {
          // For now, create a new template since we don't have update method
          await _createTemplate(updatedTemplate);
        },
      ),
    );
  }

  void _showDeleteConfirmation(Map<String, dynamic> template) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Template'),
        content:
            Text('Are you sure you want to delete "${template['subject']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Implement delete functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Template deleted')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _TemplateDialog extends StatefulWidget {
  final String title;
  final String? initialSubject;
  final String? initialContent;
  final Function(Map<String, String>) onSave;

  const _TemplateDialog({
    required this.title,
    this.initialSubject,
    this.initialContent,
    required this.onSave,
  });

  @override
  State<_TemplateDialog> createState() => _TemplateDialogState();
}

class _TemplateDialogState extends State<_TemplateDialog> {
  late TextEditingController _subjectController;
  late TextEditingController _contentController;
  String _selectedType = 'confirmation';

  @override
  void initState() {
    super.initState();
    _subjectController =
        TextEditingController(text: widget.initialSubject ?? '');
    _contentController =
        TextEditingController(text: widget.initialContent ?? '');
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Template Type',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                    value: 'confirmation', child: Text('Confirmation')),
                DropdownMenuItem(value: 'reminder', child: Text('Reminder')),
                DropdownMenuItem(value: 'follow_up', child: Text('Follow-up')),
              ],
              onChanged: (value) => setState(() => _selectedType = value!),
            ),
            SizedBox(height: 2.h),
            TextField(
              controller: _subjectController,
              decoration: const InputDecoration(
                labelText: 'Subject',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 2.h),
            TextField(
              controller: _contentController,
              decoration: const InputDecoration(
                labelText: 'Message Content',
                border: OutlineInputBorder(),
                hintText:
                    'Use {client_name}, {service_type}, {date}, {time} for placeholders',
              ),
              maxLines: 4,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_subjectController.text.isNotEmpty &&
                _contentController.text.isNotEmpty) {
              widget.onSave({
                'subject': _subjectController.text,
                'content': _contentController.text,
                'type': _selectedType,
              });
              Navigator.of(context).pop();
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}