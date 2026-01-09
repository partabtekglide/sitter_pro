import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:universal_html/html.dart' as html;
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/app_export.dart';
import '../../../services/supabase_service.dart';
import '../../../widgets/custom_icon_widget.dart';

class ExportControlsWidget extends StatefulWidget {
  final List<Map<String, dynamic>> invoices;
  final Function(DateTime?, DateTime?) onDateRangeChanged;

  const ExportControlsWidget({
    super.key,
    required this.invoices,
    required this.onDateRangeChanged,
  });

  @override
  State<ExportControlsWidget> createState() => _ExportControlsWidgetState();
}

class _ExportControlsWidgetState extends State<ExportControlsWidget> {
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isExporting = false;

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      widget.onDateRangeChanged(_startDate, _endDate);
    }
  }

  Future<void> _clearDateFilter() async {
    setState(() {
      _startDate = null;
      _endDate = null;
    });
    widget.onDateRangeChanged(null, null);
  }

  Future<void> _exportToCSV() async {
    setState(() => _isExporting = true);

    try {
      final csvContent =
          SupabaseService.instance.generateInvoicesCSV(widget.invoices);

      if (kIsWeb) {
        // Web export
        final bytes = utf8.encode(csvContent);
        final blob = html.Blob([bytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);

        final anchor = html.AnchorElement(href: url)
          ..setAttribute("download",
              "invoices_${DateTime.now().millisecondsSinceEpoch}.csv")
          ..click();

        html.Url.revokeObjectUrl(url);
      } else {
        // Mobile export - Direct Download
        String filePath;
        
        if (Platform.isAndroid) {
          // Request storage permissions
          var status = await Permission.storage.status;
          if (!status.isGranted) {
            status = await Permission.storage.request();
          }
          
          // For Android 11+ (Manage External Storage might be needed for public dirs if not using MediaStore)
          // But often /storage/emulated/0/Download is accessible.
          if (await Permission.manageExternalStorage.status.isDenied) {
             // Try to request if strictly needed, but proceed to try writing first
          }

          // Use the public Download directory
          final downloadDir = Directory('/storage/emulated/0/Download');
          if (await downloadDir.exists()) {
            filePath = '${downloadDir.path}/invoices_${DateTime.now().millisecondsSinceEpoch}.csv';
          } else {
            // Fallback to app-specific external storage
            final dir = await getExternalStorageDirectory();
            filePath = '${dir?.path ?? ''}/invoices_${DateTime.now().millisecondsSinceEpoch}.csv';
          }
        } else {
          // iOS - Save to Documents
          final dir = await getApplicationDocumentsDirectory();
          filePath = '${dir.path}/invoices_${DateTime.now().millisecondsSinceEpoch}.csv';
        }

        final file = File(filePath);
        await file.writeAsString(csvContent);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      Platform.isAndroid 
                          ? 'Saved to Downloads: ${file.uri.pathSegments.last}' 
                          : 'Saved to Documents',
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
            ),
          );
        }
        return; // Exit function, success handled
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.download_done, color: Colors.white),
                SizedBox(width: 2.w),
                const Text('CSV exported successfully'),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                SizedBox(width: 2.w),
                Expanded(child: Text('Export failed: ${error.toString()}')),
              ],
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: EdgeInsets.all(4.w),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              CustomIconWidget(
                iconName: 'file_download',
                color: theme.colorScheme.primary,
                size: 6.w,
              ),
              SizedBox(width: 3.w),
              Text(
                'Download & Filters',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),

          SizedBox(height: 3.h),

          // Date Range Filter
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _selectDateRange,
                  icon: CustomIconWidget(
                    iconName: 'date_range',
                    color: theme.colorScheme.primary,
                    size: 4.w,
                  ),
                  label: Text(
                    _startDate != null && _endDate != null
                        ? '${_formatDate(_startDate!)} - ${_formatDate(_endDate!)}'
                        : 'Select Date Range',
                  ),
                  style: OutlinedButton.styleFrom(
                    padding:
                        EdgeInsets.symmetric(vertical: 1.5.h, horizontal: 3.w),
                  ),
                ),
              ),
              if (_startDate != null && _endDate != null) ...[
                SizedBox(width: 2.w),
                IconButton(
                  onPressed: _clearDateFilter,
                  icon: CustomIconWidget(
                    iconName: 'clear',
                    color: theme.colorScheme.error,
                    size: 5.w,
                  ),
                  tooltip: 'Clear Filter',
                ),
              ],
            ],
          ),

          SizedBox(height: 2.h),

          // Export Controls
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isExporting ? null : _exportToCSV,
                  icon: _isExporting
                      ? SizedBox(
                          width: 4.w,
                          height: 4.w,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              theme.colorScheme.onPrimary,
                            ),
                          ),
                        )
                      : CustomIconWidget(
                          iconName: 'download',
                          color: theme.colorScheme.onPrimary,
                          size: 4.w,
                        ),
                  label: Text(_isExporting ? 'Downloading...' : 'Download CSV'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 1.5.h),
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 2.h),

          // Summary Info
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                CustomIconWidget(
                  iconName: 'info',
                  color: theme.colorScheme.primary,
                  size: 4.w,
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: Text(
                    '${widget.invoices.length} invoice${widget.invoices.length == 1 ? '' : 's'} ready for download',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}
