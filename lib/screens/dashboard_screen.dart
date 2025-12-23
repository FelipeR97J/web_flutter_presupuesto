import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/auth_service.dart';
import '../services/dashboard_service.dart';
import '../models/dashboard_model.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _authService = AuthService();
  final _dashboardService = DashboardService();

  DashboardSummary? _summary;
  CategoryDistribution? _distribution;
  DashboardHistory? _history;
  bool _isLoading = true;
  int _touchedIndex = -1;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  void _loadDashboardData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final token = _authService.token ?? '';
      final now = DateTime.now();

      final results = await Future.wait([
        _dashboardService.getSummary(token, year: now.year, month: now.month),
        _dashboardService.getCategoryDistribution(token, year: now.year, month: now.month),
        _dashboardService.getHistory(token),
      ]);

      if (mounted) {
        setState(() {
          _summary = results[0] as DashboardSummary;
          _distribution = results[1] as CategoryDistribution;
          _history = results[2] as DashboardHistory;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      debugPrint('Error al cargar datos del dashboard: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Dashboard Financiero',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.deepPurple[600],
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadDashboardData,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _summary == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      const Text('No hay datos disponibles'),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _loadDashboardData,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSummaryCard(),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _buildPieChartCard()),
                          const SizedBox(width: 16),
                          Expanded(child: _buildBarChartCard()),
                        ],
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildSummaryCard() {
    if (_summary == null) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resumen Mensual - ${_summary!.period.month}/${_summary!.period.year}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    '💰 Ingresos',
                    '\$${NumberFormat('#,##0', 'es_ES').format(_summary!.summary.income.total.toInt())}',
                    _summary!.summary.income.variationPercentage,
                    _summary!.summary.income.trend,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricTile(
                    '💸 Gastos',
                    '\$${NumberFormat('#,##0', 'es_ES').format(_summary!.summary.expense.total.toInt())}',
                    _summary!.summary.expense.variationPercentage,
                    _summary!.summary.expense.trend,
                    Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    '💳 Deudas',
                    '\$${NumberFormat('#,##0', 'es_ES').format(_summary!.summary.debt.totalPayment.toInt())}',
                    null,
                    null,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricTile(
                    '💵 Balance',
                    '\$${NumberFormat('#,##0', 'es_ES').format(_summary!.summary.balance.total.toInt())}',
                    null,
                    null,
                    _summary!.summary.balance.statusColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile(
    String title,
    String value,
    double? variation,
    String? trend,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (variation != null && trend != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  trend == 'up'
                      ? Icons.trending_up
                      : trend == 'down'
                          ? Icons.trending_down
                          : Icons.trending_flat,
                  size: 14,
                  color: trend == 'up'
                      ? Colors.green
                      : trend == 'down'
                          ? Colors.red
                          : Colors.grey,
                ),
                const SizedBox(width: 4),
                Text(
                  '${variation.toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPieChartCard() {
    if (_distribution == null || _distribution!.categories.isEmpty) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(Icons.pie_chart, size: 48, color: Colors.grey[300]),
              const SizedBox(height: 8),
              const Text('Sin datos de categorías'),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Gastos por Categoría',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      pieTouchData: PieTouchData(
                        touchCallback: (FlTouchEvent event, pieTouchResponse) {
                          setState(() {
                            if (!event.isInterestedForInteractions ||
                                pieTouchResponse == null ||
                                pieTouchResponse.touchedSection == null) {
                              _touchedIndex = -1;
                              return;
                            }
                            _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                          });
                        },
                      ),
                      sections: _distribution!.categories.asMap().entries.map((entry) {
                        final index = entry.key;
                        final cat = entry.value;
                        final isTouched = index == _touchedIndex;
                        final fontSize = isTouched ? 16.0 : 12.0;
                        final radius = isTouched ? 60.0 : 50.0;
                        
                        return PieChartSectionData(
                          value: cat.total,
                          title: isTouched ? '' : '${cat.percentage.toStringAsFixed(0)}%',
                          color: cat.colorValue,
                          radius: radius,
                          titleStyle: TextStyle(
                            fontSize: fontSize,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        );
                      }).toList(),
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                    ),
                  ),
                  if (_touchedIndex != -1 && _touchedIndex < _distribution!.categories.length)
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _distribution!.categories[_touchedIndex].name,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '\$${NumberFormat('#,##0', 'es_ES').format(_distribution!.categories[_touchedIndex].total.toInt())}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _distribution!.categories[_touchedIndex].colorValue,
                          ),
                        ),
                        Text(
                          '${_distribution!.categories[_touchedIndex].percentage.toStringAsFixed(1)}%',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    )
                  else
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Total',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          '\$${NumberFormat.compact(locale: 'es_ES').format(_distribution!.total)}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: _distribution!.categories.map((cat) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: cat.colorValue,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      cat.name,
                      style: const TextStyle(fontSize: 11),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChartCard() {
    if (_history == null || _history!.history.isEmpty) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(Icons.bar_chart, size: 48, color: Colors.grey[300]),
              const SizedBox(height: 8),
              const Text('Sin historial'),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Historial (6 meses)',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: _history!.history
                          .map((h) => [h.income, h.expense, h.debt].reduce((a, b) => a > b ? a : b))
                          .reduce((a, b) => a > b ? a : b) *
                      1.2,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= 0 && value.toInt() < _history!.history.length) {
                            return Text(
                              _history!.history[value.toInt()].monthLabel,
                              style: const TextStyle(fontSize: 10),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: _history!.history.asMap().entries.map((entry) {
                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(
                          toY: entry.value.income,
                          color: Colors.green,
                          width: 6,
                        ),
                        BarChartRodData(
                          toY: entry.value.expense,
                          color: Colors.red,
                          width: 6,
                        ),
                        BarChartRodData(
                          toY: entry.value.debt,
                          color: Colors.orange,
                          width: 6,
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem('Ingresos', Colors.green),
                const SizedBox(width: 12),
                _buildLegendItem('Gastos', Colors.red),
                const SizedBox(width: 12),
                _buildLegendItem('Deudas', Colors.orange),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11),
        ),
      ],
    );
  }
}
