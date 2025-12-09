import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class NotesWidget extends StatefulWidget {
  final List<Map<String, dynamic>> notes;
  final Function(String)? onAddNote;
  final Function(Map<String, dynamic>)? onEditNote;
  final Function(Map<String, dynamic>)? onDeleteNote;

  const NotesWidget({
    super.key,
    required this.notes,
    this.onAddNote,
    this.onEditNote,
    this.onDeleteNote,
  });

  @override
  State<NotesWidget> createState() => _NotesWidgetState();
}

class _NotesWidgetState extends State<NotesWidget> {
  final QuillController _quillController = QuillController.basic();
  final TextEditingController _simpleController = TextEditingController();
  bool _isAddingNote = false;
  bool _useRichText = false;

  @override
  void dispose() {
    _quillController.dispose();
    _simpleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Private Notes (${widget.notes.length})',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => setState(() => _isAddingNote = !_isAddingNote),
                icon: CustomIconWidget(
                  iconName: _isAddingNote ? 'close' : 'add',
                  size: 24,
                  color: theme.colorScheme.primary,
                ),
                tooltip: _isAddingNote ? 'Cancel' : 'Add Note',
              ),
            ],
          ),
        ),
        if (_isAddingNote) ...[
          _buildAddNoteSection(context),
          SizedBox(height: 2.h),
        ],
        if (widget.notes.isEmpty && !_isAddingNote) ...[
          Container(
            padding: EdgeInsets.all(4.w),
            child: Column(
              children: [
                CustomIconWidget(
                  iconName: 'note_add',
                  size: 48,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                ),
                SizedBox(height: 2.h),
                Text(
                  'No notes yet',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                SizedBox(height: 1.h),
                Text(
                  'Add private notes about this client that only you can see',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ] else ...[
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            itemCount: widget.notes.length,
            separatorBuilder: (context, index) => SizedBox(height: 1.h),
            itemBuilder: (context, index) {
              final note = widget.notes[index];
              return _buildNoteCard(context, note);
            },
          ),
        ],
      ],
    );
  }

  Widget _buildAddNoteSection(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Add New Note',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Row(
                children: [
                  Text(
                    'Rich Text',
                    style: theme.textTheme.bodySmall,
                  ),
                  SizedBox(width: 2.w),
                  Switch(
                    value: _useRichText,
                    onChanged: (value) => setState(() => _useRichText = value),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 2.h),
          if (_useRichText) ...[
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.3),
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  QuillSimpleToolbar(
                    controller: _quillController,
                    config: QuillSimpleToolbarConfig(
                      showBoldButton: true,
                      showItalicButton: true,
                      showUnderLineButton: true,
                      showStrikeThrough: false,
                      showInlineCode: false,
                      showColorButton: false,
                      showBackgroundColorButton: false,
                      showClearFormat: true,
                      showAlignmentButtons: false,
                      showLeftAlignment: false,
                      showCenterAlignment: false,
                      showRightAlignment: false,
                      showJustifyAlignment: false,
                      showHeaderStyle: false,
                      showListNumbers: true,
                      showListBullets: true,
                      showListCheck: false,
                      showCodeBlock: false,
                      showQuote: false,
                      showIndent: false,
                      showLink: false,
                      showUndo: true,
                      showRedo: true,
                      showDirection: false,
                      showSearchButton: false,
                      showSubscript: false,
                      showSuperscript: false,
                      showFontFamily: false,
                      showFontSize: false,
                    ),
                  ),
                  Container(
                    height: 20.h,
                    padding: EdgeInsets.all(2.w),
                    child: QuillEditor.basic(
                      controller: _quillController,
                      config: QuillEditorConfig(
                        placeholder: 'Write your note here...',
                        padding: EdgeInsets.all(2.w),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            TextField(
              controller: _simpleController,
              maxLines: 6,
              decoration: InputDecoration(
                hintText: 'Write your note here...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: EdgeInsets.all(3.w),
              ),
            ),
          ],
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _isAddingNote = false;
                      _simpleController.clear();
                      _quillController.clear();
                    });
                  },
                  child: Text('Cancel'),
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: ElevatedButton(
                  onPressed: _saveNote,
                  child: Text('Save Note'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNoteCard(BuildContext context, Map<String, dynamic> note) {
    final theme = Theme.of(context);
    final timestamp =
        DateTime.tryParse(note["timestamp"] as String? ?? "") ?? DateTime.now();
    final isRichText = note["isRichText"] as bool? ?? false;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CustomIconWidget(
                        iconName: isRichText ? 'text_format' : 'note',
                        size: 12,
                        color: theme.colorScheme.primary,
                      ),
                      SizedBox(width: 1.w),
                      Text(
                        isRichText ? 'RICH TEXT' : 'NOTE',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w500,
                          fontSize: 8.sp,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  _formatTimestamp(timestamp),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                SizedBox(width: 2.w),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        widget.onEditNote?.call(note);
                        break;
                      case 'delete':
                        _showDeleteConfirmation(context, note);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          CustomIconWidget(
                            iconName: 'edit',
                            size: 16,
                            color: theme.colorScheme.onSurface,
                          ),
                          SizedBox(width: 2.w),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          CustomIconWidget(
                            iconName: 'delete',
                            size: 16,
                            color: theme.colorScheme.error,
                          ),
                          SizedBox(width: 2.w),
                          Text(
                            'Delete',
                            style: TextStyle(color: theme.colorScheme.error),
                          ),
                        ],
                      ),
                    ),
                  ],
                  child: CustomIconWidget(
                    iconName: 'more_vert',
                    size: 20,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            if (isRichText) ...[
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  note["content"] as String? ?? "",
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ] else ...[
              Text(
                note["content"] as String? ?? "",
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _saveNote() {
    String content = _useRichText
        ? _quillController.document.toPlainText().trim()
        : _simpleController.text.trim();

    if (content.isNotEmpty) {
      widget.onAddNote?.call(content);
      setState(() {
        _isAddingNote = false;
        _simpleController.clear();
        _quillController.clear();
        _useRichText = false;
      });
    }
  }

  void _showDeleteConfirmation(
      BuildContext context, Map<String, dynamic> note) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              CustomIconWidget(
                iconName: 'delete',
                size: 24,
                color: theme.colorScheme.error,
              ),
              SizedBox(width: 2.w),
              Text(
                'Delete Note',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to delete this note? This action cannot be undone.',
            style: theme.textTheme.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                widget.onDeleteNote?.call(note);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
              ),
              child: Text(
                'Delete',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onError,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.month}/${timestamp.day}/${timestamp.year}';
    }
  }
}