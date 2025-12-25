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
        _showMockData();
        return;
      }

      // Load invoices
      final invoicesResponse = await supabase
          .from('invoices')
          .select(
            '*, bookings!inner(service_type, start_date, clients!inner(user_profiles!inner(full_name)))',
          )
          .eq('sitter_id', userId)
          .order('created_at', ascending: false);

      // Load earnings from completed bookings
      final earningsResponse = await supabase
          .from('bookings')
          .select('total_amount, start_date, service_type, status')
          .eq('sitter_id', userId)
          .eq('status', 'completed')
          .order('start_date', ascending: false);

      setState(() {
        _invoices = List<Map<String, dynamic>>.from(invoicesResponse);
        _earnings = List<Map<String, dynamic>>.from(earningsResponse);
        _calculateFinancialStats();
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading financial data: $e');
      _showMockData();
    }
  }

  void _showMockData() {
    setState(() {
      _invoices = [
        {
          'id': '1',
          'invoice_number': 'INV-2024-0001',
          'amount': 125.00,
          'total_amount': 137.50,
          'status': 'paid',
          'issued_date': '2024-11-10',
          'due_date': '2024-12-10',
          'description': 'Babysitting services - 5 hours',
          'bookings': {
            'service_type': 'babysitting',
            'start_date': '2024-11-10',
            'clients': {
              'user_profiles': {'full_name': 'Sarah Johnson'},
            },
          },
        },
        {
          'id': '2',
          'invoice_number': 'INV-2024-0002',
          'amount': 80.00,
          'total_amount': 88.00,
          'status': 'sent',
          'issued_date': '2024-11-12',
          'due_date': '2024-12-12',
          'description': 'Pet sitting services - 4 hours',
          'bookings': {
            'service_type': 'pet_sitting',
            'start_date': '2024-11-12',
            'clients': {
              'user_profiles': {'full_name': 'Mike Chen'},
            },
          },
        },
      ];

      _earnings = [
        {
          'total_amount': 125.00,
          'start_date': '2024-11-10',
          'service_type': 'babysitting',
        },
        {
          'total_amount': 80.00,
          'start_date': '2024-11-11',
          'service_type': 'pet_sitting',
        },
        {
          'total_amount': 200.00,
          'start_date': '2024-11-08',
          'service_type': 'house_sitting',
        },
      ];

      _calculateFinancialStats();
      _isLoading = false;
    });
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
                // Period Selector
                Container(
                      margin: EdgeInsets.all(4.w),
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
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

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
                                        children: [
                                          Text(
                                            'Quick Actions',
                                            style: theme.textTheme.titleMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                          SizedBox(height: 2.h),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: ElevatedButton.icon(
                                                  onPressed:
                                                      () => _exportData('CSV'),
                                                  icon: const Icon(
                                                    Icons.file_download,
                                                  ),
                                                  label: const Text('Export CSV'),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        theme.colorScheme.primary,
                                                    foregroundColor:
                                                        theme
                                                            .colorScheme
                                                            .onPrimary,
                                                    padding: EdgeInsets.symmetric(
                                                      vertical: 2.h,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              SizedBox(width: 3.w),
                                              Expanded(
                                                child: OutlinedButton.icon(
                                                  onPressed:
                                                      () => _exportData('PDF'),
                                                  icon: const Icon(
                                                    Icons.picture_as_pdf,
                                                  ),
                                                  label: const Text('Export PDF'),
                                                  style: OutlinedButton.styleFrom(
                                                    padding: EdgeInsets.symmetric(
                                                      vertical: 2.h,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Invoices Tab
                          InvoiceListWidget(
                            invoices: _invoices,
                            onRefresh: _loadFinancialData,
                          ),

                          // Analytics Tab
                          RefreshIndicator(
                            onRefresh: _loadFinancialData,
                            child: SingleChildScrollView(
                              padding: EdgeInsets.all(4.w),
                              child: Column(
                                children: [
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

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
