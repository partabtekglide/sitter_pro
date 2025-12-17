import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';

class InvoiceListWidget extends StatelessWidget {
  final List<Map<String, dynamic>> invoices;
  final VoidCallback onRefresh;

  const InvoiceListWidget({
    super.key,
    required this.invoices,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: Column(
        children: [
          // Header with filters
          Container(
            padding: EdgeInsets.all(16.w),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Invoices (${invoices.length})',
                    style: GoogleFonts.inter(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => _showFilterDialog(context),
                  icon: const Icon(Icons.filter_list),
                  tooltip: 'Filter invoices',
                ),
                IconButton(
                  onPressed: () => _createNewInvoice(context),
                  icon: const Icon(Icons.add),
                  tooltip: 'Create invoice',
                ),
              ],
            ),
          ),

          // Invoice List
          Expanded(
            child:
                invoices.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      itemCount: invoices.length,
                      itemBuilder: (context, index) {
                        final invoice = invoices[index];
                        return _buildInvoiceCard(context, invoice);
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 64.sp,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16.h),
          Text(
            'No invoices yet',
            style: GoogleFonts.inter(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Create your first invoice to track payments',
            style: GoogleFonts.inter(fontSize: 14.sp, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24.h),
          ElevatedButton.icon(
            onPressed: () => _createNewInvoice(null),
            icon: const Icon(Icons.add),
            label: const Text('Create Invoice'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1976D2),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceCard(BuildContext context, Map<String, dynamic> invoice) {
    final status = invoice['status'] as String? ?? 'draft';
    final statusColor = _getStatusColor(status);
    final amount = (invoice['total_amount'] as num?)?.toDouble() ?? 0;
    final clientName =
        invoice['user_profiles']?['full_name'] ?? 'Unknown Client';
    final invoiceNumber = invoice['invoice_number'] ?? '';
    final dueDate = invoice['due_date'] ?? '';
    final isOverdue = _isOverdue(dueDate, status);

    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side:
            isOverdue
                ? BorderSide(color: Colors.red.withAlpha(77), width: 1)
                : BorderSide.none,
      ),
      child: InkWell(
        onTap: () => _showInvoiceDetails(context, invoice),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          invoiceNumber,
                          style: GoogleFonts.inter(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          clientName,
                          style: GoogleFonts.inter(
                            fontSize: 14.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '\$${amount.toStringAsFixed(2)}',
                        style: GoogleFonts.inter(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withAlpha(26),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          status.toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              SizedBox(height: 12.h),

              // Details Row
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 14.sp,
                    color: Colors.grey[500],
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    'Due: ${_formatDate(dueDate)}',
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      color: isOverdue ? Colors.red : Colors.grey[600],
                      fontWeight:
                          isOverdue ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  if (isOverdue) ...[
                    SizedBox(width: 8.w),
                    Icon(Icons.warning, size: 14.sp, color: Colors.red),
                    SizedBox(width: 4.w),
                    Text(
                      'OVERDUE',
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.red,
                      ),
                    ),
                  ],
                  const Spacer(),
                  // Service Type
                  if (invoice['bookings']?['service_type'] != null) ...[
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 6.w,
                        vertical: 2.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _formatServiceType(invoice['bookings']['service_type']),
                        style: GoogleFonts.inter(
                          fontSize: 10.sp,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                ],
              ),

              SizedBox(height: 12.h),

              // Action Buttons
              Row(
                children: [
                  if (status == 'draft') ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _sendInvoice(context, invoice),
                        child: const Text('Send Invoice'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF1976D2),
                          side: const BorderSide(color: Color(0xFF1976D2)),
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                  ],
                  if (status == 'sent' || status == 'overdue') ...[
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _markAsPaid(context, invoice),
                        child: const Text('Mark as Paid'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4CAF50),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                  ],
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _shareInvoice(context, invoice),
                      child: const Text('Share'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return const Color(0xFF4CAF50);
      case 'sent':
        return const Color(0xFF2196F3);
      case 'overdue':
        return const Color(0xFFF44336);
      case 'draft':
        return const Color(0xFF9E9E9E);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  bool _isOverdue(String? dueDate, String status) {
    if (dueDate == null || status == 'paid') return false;

    final due = DateTime.tryParse(dueDate);
    if (due == null) return false;

    return DateTime.now().isAfter(due) && status != 'paid';
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'No date';

    final date = DateTime.tryParse(dateStr);
    if (date == null) return dateStr;

    return '${date.month}/${date.day}/${date.year}';
  }

  String _formatServiceType(String serviceType) {
    return serviceType
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Filter Invoices'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Status filter
                CheckboxListTile(
                  title: const Text('Show Paid'),
                  value: true,
                  onChanged: (value) {},
                ),
                CheckboxListTile(
                  title: const Text('Show Pending'),
                  value: true,
                  onChanged: (value) {},
                ),
                CheckboxListTile(
                  title: const Text('Show Overdue'),
                  value: true,
                  onChanged: (value) {},
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Apply'),
              ),
            ],
          ),
    );
  }

  void _createNewInvoice(BuildContext? context) {
    // Mock create invoice functionality
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Create invoice functionality coming soon!'),
          backgroundColor: Color(0xFF1976D2),
        ),
      );
    }
  }

  void _showInvoiceDetails(BuildContext context, Map<String, dynamic> invoice) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.7,
            maxChildSize: 0.9,
            minChildSize: 0.5,
            builder:
                (context, scrollController) => Container(
                  padding: EdgeInsets.all(20.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Handle
                      Center(
                        child: Container(
                          width: 40.w,
                          height: 4.h,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),

                      SizedBox(height: 20.h),

                      // Invoice Details
                      Text(
                        'Invoice Details',
                        style: GoogleFonts.inter(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      SizedBox(height: 16.h),

                      Expanded(
                        child: ListView(
                          controller: scrollController,
                          children: [
                            _buildDetailRow(
                              'Invoice Number',
                              invoice['invoice_number'],
                            ),
                            _buildDetailRow(
                              'Client',
                              invoice['user_profiles']?['full_name'],
                            ),
                            _buildDetailRow(
                              'Amount',
                              '\$${invoice['total_amount']}',
                            ),
                            _buildDetailRow('Status', invoice['status']),
                            _buildDetailRow(
                              'Issue Date',
                              _formatDate(invoice['issued_date']),
                            ),
                            _buildDetailRow(
                              'Due Date',
                              _formatDate(invoice['due_date']),
                            ),
                            if (invoice['description'] != null)
                              _buildDetailRow(
                                'Description',
                                invoice['description'],
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
          ),
    );
  }

  Widget _buildDetailRow(String label, String? value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100.w,
            child: Text(
              '$label:',
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value ?? 'N/A',
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                color: Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _sendInvoice(BuildContext context, Map<String, dynamic> invoice) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Invoice ${invoice['invoice_number']} sent successfully!',
        ),
        backgroundColor: const Color(0xFF4CAF50),
      ),
    );
  }

  void _markAsPaid(BuildContext context, Map<String, dynamic> invoice) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Invoice ${invoice['invoice_number']} marked as paid!'),
        backgroundColor: const Color(0xFF4CAF50),
      ),
    );
  }

  void _shareInvoice(BuildContext context, Map<String, dynamic> invoice) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Invoice shared successfully!'),
        backgroundColor: Color(0xFF2196F3),
      ),
    );
  }
}