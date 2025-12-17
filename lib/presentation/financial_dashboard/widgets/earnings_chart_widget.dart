import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';

class EarningsChartWidget extends StatefulWidget {
  final List<Map<String, dynamic>> earnings;

  const EarningsChartWidget({super.key, required this.earnings});

  @override
  State<EarningsChartWidget> createState() => _EarningsChartWidgetState();
}

class _EarningsChartWidgetState extends State<EarningsChartWidget> {
  String _chartType = 'Line';
  final List<String> _chartTypes = ['Line', 'Bar'];

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Earnings Trend',
                  style: GoogleFonts.inter(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 4.h,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: DropdownButton<String>(
                    value: _chartType,
                    underline: Container(),
                    isDense: true,
                    items:
                        _chartTypes.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(
                              type,
                              style: GoogleFonts.inter(fontSize: 12.sp),
                            ),
                          );
                        }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _chartType = value!;
                      });
                    },
                  ),
                ),
              ],
            ),

            SizedBox(height: 20.h),

            // Chart
            SizedBox(
              height: 200.h,
              child:
                  _chartType == 'Line' ? _buildLineChart() : _buildBarChart(),
            ),

            SizedBox(height: 16.h),

            // Legend
            _buildLegend(),
          ],
        ),
      ),
    );
  }

  Widget _buildLineChart() {
    final chartData = _processEarningsData();

    if (chartData.isEmpty) {
      return Center(
        child: Text(
          'No earnings data available',
          style: GoogleFonts.inter(fontSize: 14.sp, color: Colors.grey[600]),
        ),
      );
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 50,
          getDrawingHorizontalLine: (value) {
            return FlLine(color: Colors.grey[200]!, strokeWidth: 1);
          },
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40.w,
              getTitlesWidget: (value, meta) {
                return Text(
                  '\$${value.toInt()}',
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    color: Colors.grey[600],
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30.h,
              getTitlesWidget: (value, meta) {
                if (value.toInt() < chartData.length) {
                  return Text(
                    chartData[value.toInt()]['label'],
                    style: GoogleFonts.inter(
                      fontSize: 10.sp,
                      color: Colors.grey[600],
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots:
                chartData.asMap().entries.map((entry) {
                  return FlSpot(
                    entry.key.toDouble(),
                    entry.value['amount'].toDouble(),
                  );
                }).toList(),
            isCurved: true,
            gradient: LinearGradient(
              colors: [const Color(0xFF1976D2), const Color(0xFF42A5F5)],
            ),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF1976D2).withAlpha(51),
                  const Color(0xFF42A5F5).withAlpha(26),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart() {
    final chartData = _processEarningsData();

    if (chartData.isEmpty) {
      return Center(
        child: Text(
          'No earnings data available',
          style: GoogleFonts.inter(fontSize: 14.sp, color: Colors.grey[600]),
        ),
      );
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY:
            chartData
                .map((e) => e['amount'] as double)
                .reduce((a, b) => a > b ? a : b) *
            1.2,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 50,
          getDrawingHorizontalLine: (value) {
            return FlLine(color: Colors.grey[200]!, strokeWidth: 1);
          },
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40.w,
              getTitlesWidget: (value, meta) {
                return Text(
                  '\$${value.toInt()}',
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    color: Colors.grey[600],
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30.h,
              getTitlesWidget: (value, meta) {
                if (value.toInt() < chartData.length) {
                  return Text(
                    chartData[value.toInt()]['label'],
                    style: GoogleFonts.inter(
                      fontSize: 10.sp,
                      color: Colors.grey[600],
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups:
            chartData.asMap().entries.map((entry) {
              return BarChartGroupData(
                x: entry.key,
                barRods: [
                  BarChartRodData(
                    toY: entry.value['amount'].toDouble(),
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF1976D2),
                        const Color(0xFF42A5F5),
                      ],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                    width: 20.w,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              );
            }).toList(),
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem('Babysitting', const Color(0xFF1976D2)),
        SizedBox(width: 20.w),
        _buildLegendItem('Pet Sitting', const Color(0xFF4CAF50)),
        SizedBox(width: 20.w),
        _buildLegendItem('House Sitting', const Color(0xFFFF9800)),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12.w,
          height: 12.h,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        SizedBox(width: 6.w),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 11.sp, color: Colors.grey[600]),
        ),
      ],
    );
  }

  List<Map<String, dynamic>> _processEarningsData() {
    if (widget.earnings.isEmpty) return [];

    // Group earnings by date and sum amounts
    final Map<String, double> dailyEarnings = {};

    for (final earning in widget.earnings) {
      final date = earning['start_date'] as String? ?? '';
      final amount = (earning['total_amount'] as num?)?.toDouble() ?? 0;

      if (date.isNotEmpty) {
        final dateKey =
            DateTime.tryParse(date)?.day.toString() ?? date.split('-').last;
        dailyEarnings[dateKey] = (dailyEarnings[dateKey] ?? 0) + amount;
      }
    }

    return dailyEarnings.entries
        .map((entry) => {'label': entry.key, 'amount': entry.value})
        .toList();
  }
}