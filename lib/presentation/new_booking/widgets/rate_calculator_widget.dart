import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class RateCalculatorWidget extends StatefulWidget {
  final Map<String, dynamic> bookingData;
  final Function(Map<String, dynamic>) onRateCalculated;

  const RateCalculatorWidget({
    super.key,
    required this.bookingData,
    required this.onRateCalculated,
  });

  @override
  State<RateCalculatorWidget> createState() => _RateCalculatorWidgetState();
}

class _RateCalculatorWidgetState extends State<RateCalculatorWidget> {
  final TextEditingController _hourlyRateController = TextEditingController();
  final TextEditingController _additionalChargesController =
      TextEditingController();
  final TextEditingController _totalAmountController = TextEditingController();
  
  final FocusNode _hourlyRateFocus = FocusNode();
  final FocusNode _additionalChargesFocus = FocusNode();
  final FocusNode _totalAmountFocus = FocusNode();

  double _hourlyRate = 0.0;
  double _additionalCharges = 0.0;
  double _baseAmount = 0.0;
  double _totalAmount = 0.0;
  int _duration = 0;
  bool _isUpdatingInternally = false;

  @override
  void initState() {
    super.initState();
    _initializeData();

    _hourlyRateController.addListener(_onHourlyRateChanged);
    _additionalChargesController.addListener(_onAdditionalChargesChanged);
    _totalAmountController.addListener(_onTotalAmountChanged);
  }

  @override
  void dispose() {
    _hourlyRateController.dispose();
    _additionalChargesController.dispose();
    _totalAmountController.dispose();
    _hourlyRateFocus.dispose();
    _additionalChargesFocus.dispose();
    _totalAmountFocus.dispose();
    super.dispose();
  }

  void _initializeData() {
    _hourlyRate = (widget.bookingData['hourlyRate'] as num?)?.toDouble() ?? 20.0;
    _duration = (widget.bookingData['duration'] as int?) ?? 1;
    _additionalCharges = 0.0;
    _baseAmount = _hourlyRate * _duration;
    _totalAmount = _baseAmount + _additionalCharges;

    _isUpdatingInternally = true;
    _hourlyRateController.text = _hourlyRate.toStringAsFixed(2);
    _additionalChargesController.text = _additionalCharges.toStringAsFixed(2);
    _totalAmountController.text = _totalAmount.toStringAsFixed(2);
    _isUpdatingInternally = false;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.onRateCalculated({
        'hourlyRate': _hourlyRate,
        'additionalCharges': _additionalCharges,
        'baseAmount': _baseAmount,
        'totalAmount': _totalAmount,
      });
    });
  }

  void _onHourlyRateChanged() {
    if (_isUpdatingInternally) return;
    final val = double.tryParse(_hourlyRateController.text) ?? 0.0;
    setState(() {
      _hourlyRate = val;
      _baseAmount = _hourlyRate * _duration;
      _totalAmount = _baseAmount + _additionalCharges;
      
      _isUpdatingInternally = true;
      _totalAmountController.text = _totalAmount.toStringAsFixed(2);
      _isUpdatingInternally = false;
    });
    _notifyParent();
  }

  void _onAdditionalChargesChanged() {
    if (_isUpdatingInternally) return;
    final val = double.tryParse(_additionalChargesController.text) ?? 0.0;
    setState(() {
      _additionalCharges = val;
      _totalAmount = _baseAmount + _additionalCharges;
      
      _isUpdatingInternally = true;
      _totalAmountController.text = _totalAmount.toStringAsFixed(2);
      _isUpdatingInternally = false;
    });
    _notifyParent();
  }

  void _onTotalAmountChanged() {
    if (_isUpdatingInternally) return;
    final val = double.tryParse(_totalAmountController.text) ?? 0.0;
    setState(() {
      _totalAmount = val;
      // User's logic: Additional = Total - (Rate * Hours)
      _additionalCharges = _totalAmount - _baseAmount;
      
      _isUpdatingInternally = true;
      _additionalChargesController.text = _additionalCharges.toStringAsFixed(2);
      _isUpdatingInternally = false;
    });
    _notifyParent();
  }

  void _notifyParent() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.onRateCalculated({
        'hourlyRate': _hourlyRate,
        'additionalCharges': _additionalCharges,
        'baseAmount': _baseAmount,
        'totalAmount': _totalAmount,
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Rate & Review',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Set your rates and review the booking details',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),

          SizedBox(height: 4.h),

          // Booking summary
          _buildBookingSummary(context),

          SizedBox(height: 4.h),

          // Rate input
          _buildRateSection(context),

          SizedBox(height: 4.h),

          // Additional charges
          _buildAdditionalChargesSection(context),

          SizedBox(height: 4.h),

          // Total calculation
          _buildTotalSection(context),

          SizedBox(height: 4.h),

          // Payment terms
          _buildPaymentTerms(context),
        ],
      ),
    );
  }

  Widget _buildBookingSummary(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
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
          Row(
            children: [
              CustomIconWidget(
                iconName: 'assignment',
                color: theme.colorScheme.primary,
                size: 5.w,
              ),
              SizedBox(width: 3.w),
              Text(
                'Booking Summary',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 3.h),

          _buildSummaryRow(
            'Service',
            widget.bookingData['serviceType'] ?? 'N/A',
          ),
          _buildSummaryRow('Client', widget.bookingData['clientName'] ?? 'N/A'),
          _buildSummaryRow('Date', _formatDate()),
          _buildSummaryRow('Duration', '$_duration hours'),

          if (widget.bookingData['specialInstructions']
                  ?.toString()
                  .isNotEmpty ==
              true) ...[
            SizedBox(height: 2.h),
            Text(
              'Special Instructions:',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              widget.bookingData['specialInstructions'] ?? '',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: 1.h),
      child: Row(
        children: [
          SizedBox(
            width: 25.w,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRateSection(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CustomIconWidget(
              iconName: 'attach_money',
              color: theme.colorScheme.primary,
              size: 5.w,
            ),
            SizedBox(width: 3.w),
            Text(
              'Hourly Rate',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SizedBox(height: 2.h),

        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _hourlyRateFocus.hasFocus
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
                child: TextField(
                  controller: _hourlyRateController,
                  focusNode: _hourlyRateFocus,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d+\.?\d{0,2}'),
                    ),
                  ],
                  decoration: InputDecoration(
                    prefixText: '\$ ',
                    suffixText: ' /hour',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(4.w),
                  ),
                ),
              ),
            ),
            SizedBox(width: 4.w),
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '× $_duration hrs',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),

        SizedBox(height: 2.h),

        // Rate suggestions
        _buildRateSuggestions(context),
      ],
    );
  }

  Widget _buildRateSuggestions(BuildContext context) {
    final theme = Theme.of(context);

    final Map<String, double> suggestedRates = {
      'Competitive': 15.0,
      'Standard': 20.0,
      'Premium': 25.0,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Rate Options:',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        SizedBox(height: 1.h),
        Row(
          children: suggestedRates.entries.map((entry) {
            final isSelected = _hourlyRate == entry.value;

            return Expanded(
              child: GestureDetector(
                onTap: () {
                  _hourlyRateController.text =
                      entry.value.toStringAsFixed(2);
                  HapticFeedback.selectionClick();
                },
                child: Container(
                  margin: EdgeInsets.only(right: 2.w),
                  padding: EdgeInsets.symmetric(vertical: 1.5.h),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.colorScheme.primary
                            .withValues(alpha: 0.1)
                        : theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline
                              .withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        entry.key,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface
                                  .withValues(alpha: 0.7),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '\$${entry.value.toStringAsFixed(0)}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAdditionalChargesSection(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
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
          Row(
            children: [
              CustomIconWidget(
                iconName: 'add_circle_outline',
                color: theme.colorScheme.secondary,
                size: 5.w,
              ),
              SizedBox(width: 3.w),
              Text(
                'Additional Charges (Optional)',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),

          TextField(
            controller: _additionalChargesController,
            focusNode: _additionalChargesFocus,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
            ],
            decoration: InputDecoration(
              prefixText: '\$ ',
              hintText: '0.00',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: EdgeInsets.all(3.w),
            ),
          ),

          SizedBox(height: 2.h),

          Text(
            'Examples: Travel expenses, supplies, emergency fees, etc.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalSection(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.1),
            theme.colorScheme.primary.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CustomIconWidget(
                iconName: 'calculate',
                color: theme.colorScheme.primary,
                size: 6.w,
              ),
              SizedBox(width: 3.w),
              Text(
                'Total Calculation',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          SizedBox(height: 3.h),

          _buildCalculationRow(
            'Base amount ($_duration hrs × \$${_hourlyRate.toStringAsFixed(2)})',
            _baseAmount,
          ),

          if (_additionalCharges > 0)
            _buildCalculationRow('Additional charges', _additionalCharges),

          Divider(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
            thickness: 1,
          ),

          Row(
            children: [
              Expanded(
                child: Text(
                  'Total Amount',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              SizedBox(
                width: 40.w,
                child: TextField(
                  controller: _totalAmountController,
                  focusNode: _totalAmountFocus,
                  textAlign: TextAlign.right,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d{0,2}')),
                  ],
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.primary,
                  ),
                  decoration: InputDecoration(
                    prefixText: '\$ ',
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCalculationRow(String label, double amount) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: 1.h),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
          ),
          Text(
            '\$${amount.toStringAsFixed(2)}',
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentTerms(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.tertiary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CustomIconWidget(
                iconName: 'payment',
                color: theme.colorScheme.tertiary,
                size: 5.w,
              ),
              SizedBox(width: 3.w),
              Text(
                'Payment Terms',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.tertiary,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Text(
            '• Payment is due upon completion of service\n'
            '• Accepted payment methods: Cash, Venmo, PayPal\n'
            '• Cancellation must be made 24 hours in advance\n'
            '• Additional charges will be discussed beforehand',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate() {
    final startDate = widget.bookingData['startDate'] as DateTime?;
    final startTime = widget.bookingData['startTime'] as TimeOfDay?;

    if (startDate == null || startTime == null) return 'Not set';

    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${months[startDate.month - 1]} ${startDate.day}, '
        '${startDate.year} at ${startTime.format(context)}';
  }
}
