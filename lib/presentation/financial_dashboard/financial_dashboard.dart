import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_bottom_bar.dart';
import './widgets/financial_stats_widget.dart';
import './widgets/earnings_chart_widget.dart';
import './widgets/invoice_list_widget.dart';
import './widgets/export_controls_widget.dart';
import '../../services/supabase_service.dart';

class FinancialDashboard extends StatefulWidget {
  const FinancialDashboard({super.key});

  @override
  State<FinancialDashboard> createState() => _FinancialDashboardState();
}

class _FinancialDashboardState extends State<FinancialDashboard>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String _selectedPeriod = 'This Month';
  bool _isLoading = true;

  // Financial data
  Map<String, dynamic> _financialData = {};
  List<Map<String, dynamic>> _invoices = [];
  List<Map<String, dynamic>> _earnings = [];

  final List<String> _periods = [
    'This Week',
    'This Month',
    'This Quarter',
    'This Year',
  ];

  bool _showPaid = true;
  bool _showPending = true;
  bool _showOverdue = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadFinancialData();
  }

  Future<void> _loadFinancialData() async {
    setState(() => _isLoading = true);

    try {
      final supabase = SupabaseService.instance.client;
      final userId = supabase.auth.currentUser?.id;

      if (userId == null) {
        setState(() => _isLoading = false);
        return;
      }

      // Calculate start and end dates based on selected period
      DateTime now = DateTime.now();
      DateTime startDate;
      DateTime endDate;
      
      switch (_selectedPeriod) {
        case 'This Week':
          // Assuming Monday is the start of the week
          startDate = now.subtract(Duration(days: now.weekday - 1));
          endDate = startDate.add(const Duration(days: 6));
          break;
        case 'This Month':
          startDate = DateTime(now.year, now.month, 1);
          endDate = DateTime(now.year, now.month + 1, 0);
          break;
        case 'This Quarter':
          int quarter = (now.month - 1) ~/ 3 + 1;
          startDate = DateTime(now.year, (quarter - 1) * 3 + 1, 1);
          endDate = DateTime(now.year, quarter * 3 + 1, 0);
          break;
        case 'This Year':
          startDate = DateTime(now.year, 1, 1);
          endDate = DateTime(now.year, 12, 31);
          break;
        default:
          startDate = DateTime(now.year, now.month, 1);
          endDate = DateTime(now.year, now.month + 1, 0);
      }
      
      String startDateStr = startDate.toIso8601String().split('T')[0];
      String endDateStr = endDate.toIso8601String().split('T')[0];

      // Load invoices (Filter by booking start_date)
      final invoicesResponse = await supabase
          .from('invoices')
          .select(
            '*, bookings!inner(service_type, start_date, clients!inner(user_profiles!inner(full_name)))',
          )
          .eq('sitter_id', userId)
          .gte('bookings.start_date', startDateStr)
          .lte('bookings.start_date', endDateStr)
          .order('issued_date', ascending: false);

      // Load earnings from completed bookings (Filter by start_date)
      final earningsResponse = await supabase
          .from('bookings')
          .select('total_amount, start_date, service_type, status')
          .eq('sitter_id', userId)
          .eq('status', 'completed')
          .gte('start_date', startDateStr)
          .lte('start_date', endDateStr)
          .order('start_date', ascending: false);

      // Load financial stats from API
      final stats = await SupabaseService.instance.getFinancialStats();

      setState(() {
        // Filter invoices based on status checkboxes
        final allInvoices = List<Map<String, dynamic>>.from(invoicesResponse);
        _invoices = allInvoices.where((inv) {
          final status = (inv['status'] as String? ?? 'draft').toLowerCase();
          
          // Check for overdue logic if needed, or rely on status field
          // Assuming 'overdue' is a status, or we check due_date
          bool isOverdue = status == 'overdue';
          if (!isOverdue && status != 'paid' && inv['due_date'] != null) {
             final dueDate = DateTime.tryParse(inv['due_date']);
             if (dueDate != null && DateTime.now().isAfter(dueDate)) {
               isOverdue = true;
             }
          }

          if (status == 'paid') return _showPaid;
          if (isOverdue) return _showOverdue;
          // Pending includes 'sent', 'draft', 'pending' that are not overdue
          return _showPending;
        }).toList();

        _earnings = List<Map<String, dynamic>>.from(earningsResponse);
        _financialData = stats;

        // Calculate Average Hourly Rate from bookings (heuristic)
        double totalBookingEarnings = 0;
        for (final earning in _earnings) {
          totalBookingEarnings +=
              (earning['total_amount'] as num?)?.toDouble() ?? 0;
        }
        _financialData['averageHourlyRate'] =
            totalBookingEarnings > 0
                ? (totalBookingEarnings / _earnings.length * 0.8)
                : 25.0;
        
        // Update total earnings in stats to reflect the filtered period
        _financialData['totalEarnings'] = totalBookingEarnings;

        _isLoading = false;
      });
    } catch (e) {
      print('Error loading financial data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load financial data: $e')),
        );
      }
    }
  }

  void _calculateFinancialStats() {
    final now = DateTime.now();
    double totalEarnings = 0;
    double pendingPayments = 0;
    double weeklyEarnings = 0;
    double monthlyEarnings = 0;

    // Calculate from earnings
    for (final earning in _earnings) {
      final amount = (earning['total_amount'] as num?)?.toDouble() ?? 0;
      totalEarnings += amount;

      final date = DateTime.tryParse(earning['start_date'] ?? '');
      if (date != null) {
        final daysDiff = now.difference(date).inDays;
        if (daysDiff <= 7) weeklyEarnings += amount;
        if (daysDiff <= 30) monthlyEarnings += amount;
      }
    }

    // Calculate pending from invoices
    for (final invoice in _invoices) {
      if (invoice['status'] == 'sent' || invoice['status'] == 'overdue') {
        pendingPayments += (invoice['total_amount'] as num?)?.toDouble() ?? 0;
      }
    }

    _financialData = {
      'totalEarnings': totalEarnings,
      'pendingPayments': pendingPayments,
      'weeklyEarnings': weeklyEarnings,
      'monthlyEarnings': monthlyEarnings,
      'averageHourlyRate':
          totalEarnings > 0 ? (totalEarnings / _earnings.length * 0.8) : 25.0,
    };
  }

  void _exportData(String format) async {
    // Mock export functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Exporting financial data as $format...'),
        backgroundColor: Colors.green,
      ),
    );

    // In real implementation, generate and download CSV/PDF
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Financial report exported successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: 'Financial Dashboard',
        variant: CustomAppBarVariant.standard,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: theme.colorScheme.onSurface),
            onPressed: _loadFinancialData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Tab Bar
                    Container(
                      color: theme.colorScheme.surface,
                      child: TabBar(
                        controller: _tabController,
                        labelColor: theme.colorScheme.primary,
                        unselectedLabelColor: theme.colorScheme.onSurface
                            .withValues(alpha: 0.6),
                        indicatorColor: theme.colorScheme.primary,
                        tabs: const [
                          Tab(text: 'Overview'),
                          Tab(text: 'Invoices'),
                          Tab(text: 'Analytics'),
                        ],
                      ),
                    ),

                    // Tab Content
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          // Overview Tab
                          RefreshIndicator(
                            onRefresh: _loadFinancialData,
                            child: SingleChildScrollView(
                              padding: EdgeInsets.all(4.w),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Financial Stats Cards
                                  FinancialStatsWidget(
                                    totalEarnings:
                                        _financialData['totalEarnings'] ?? 0,
                                    pendingPayments:
                                        _financialData['pendingPayments'] ?? 0,
                                    weeklyEarnings:
                                        _financialData['weeklyEarnings'] ?? 0,
                                    monthlyEarnings:
                                        _financialData['monthlyEarnings'] ?? 0,
                                    averageRate:
                                        _financialData['averageHourlyRate'] ?? 0,
                                  ),

                                  SizedBox(height: 4.h),

                                  // Quick Actions
                                  Card(
                                    child: Padding(
                                      padding: EdgeInsets.all(4.w),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        // children: [
                                        //   Text(
                                        //     'Quick Actions',
                                        //     style: theme.textTheme.titleMedium
                                        //         ?.copyWith(
                                        //           fontWeight: FontWeight.w600,
                                        //         ),
                                        //   ),
                                        //   SizedBox(height: 2.h),
                                        //   Row(
                                        //     children: [
                                        //       Expanded(
                                        //         child: ElevatedButton.icon(
                                        //           onPressed:
                                        //               () => _exportData('CSV'),
                                        //           icon: const Icon(
                                        //             Icons.file_download,
                                        //           ),
                                        //           label: const Text('Export CSV'),
                                        //           style: ElevatedButton.styleFrom(
                                        //             backgroundColor:
                                        //                 theme.colorScheme.primary,
                                        //             foregroundColor:
                                        //                 theme
                                        //                     .colorScheme
                                        //                     .onPrimary,
                                        //             padding: EdgeInsets.symmetric(
                                        //               vertical: 2.h,
                                        //             ),
                                        //           ),
                                        //         ),
                                        //       ),
                                        //       SizedBox(width: 3.w),
                                        //       Expanded(
                                        //         child: OutlinedButton.icon(
                                        //           onPressed:
                                        //               () => _exportData('PDF'),
                                        //           icon: const Icon(
                                        //             Icons.picture_as_pdf,
                                        //           ),
                                        //           label: const Text('Export PDF'),
                                        //           style: OutlinedButton.styleFrom(
                                        //             padding: EdgeInsets.symmetric(
                                        //               vertical: 2.h,
                                        //             ),
                                        //           ),
                                        //         ),
                                        //       ),
                                        //     ],
                                        //   ),
                                        // ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Invoices Tab
                          Column(
                            children: [
                              Padding(
                                padding: EdgeInsets.all(4.w),
                                child: _buildPeriodSelector(theme),
                              ),
                              Expanded(
                                child: InvoiceListWidget(
                                  invoices: _invoices,
                                  onRefresh: _loadFinancialData,
                                  showPaid: _showPaid,
                                  showPending: _showPending,
                                  showOverdue: _showOverdue,
                                  onFilterChanged: (paid, pending, overdue) {
                                    setState(() {
                                      _showPaid = paid;
                                      _showPending = pending;
                                      _showOverdue = overdue;
                                    });
                                    _loadFinancialData();
                                  },
                                ),
                              ),
                            ],
                          ),

                          // Analytics Tab
                          RefreshIndicator(
                            onRefresh: _loadFinancialData,
                            child: SingleChildScrollView(
                              padding: EdgeInsets.all(4.w),
                              child: Column(
                                children: [
                                  _buildPeriodSelector(theme),
                                  SizedBox(height: 2.h),
                                  EarningsChartWidget(earnings: _earnings),
                                  SizedBox(height: 4.h),
                                  ExportControlsWidget(
                                    invoices: _invoices,
                                    onDateRangeChanged: (start, end) {
                                      // Handle date range change if needed
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
      bottomNavigationBar: const CustomBottomBar(currentIndex: 3),
    );
  }

  Widget _buildPeriodSelector(ThemeData theme) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 4.w,
        vertical: 2.h,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(
            alpha: 0.2,
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            'Period: ',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          Expanded(
            child: DropdownButton<String>(
              value: _selectedPeriod,
              isExpanded: true,
              underline: Container(),
              items:
                  _periods.map((period) {
                    return DropdownMenuItem(
                      value: period,
                      child: Text(period),
                    );
                  }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedPeriod = value!;
                });
                _loadFinancialData();
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
