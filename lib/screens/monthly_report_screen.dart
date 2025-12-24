import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/monthly_report_model.dart';
import '../models/user_model.dart'; // Importar si es necesario para heredar estilos o algo
import '../services/auth_service.dart';
import '../services/report_service.dart';
import 'package:fl_chart/fl_chart.dart';

class MonthlyReportScreen extends StatefulWidget {
  const MonthlyReportScreen({super.key});

  @override
  State<MonthlyReportScreen> createState() => _MonthlyReportScreenState();
}

class _MonthlyReportScreenState extends State<MonthlyReportScreen> {
  final _authService = AuthService();
  final _reportService = ReportService();

  late int _selectedYear;
  late int _selectedMonth;
  bool _isLoading = true;
  MonthlyReport? _report;
  String? _error;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedYear = now.year;
    _selectedMonth = now.month;
    _loadReport();
  }

  void _loadReport() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final token = _authService.token;
      if (token == null) throw Exception("No token");

      final report = await _reportService.getMonthlyReport(
        token, 
        _selectedYear, 
        _selectedMonth
      );

      if (mounted) {
        setState(() {
          _report = report;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _changeDate(int? year, int? month) {
    if (year != null) _selectedYear = year;
    if (month != null) _selectedMonth = month;
    _loadReport();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(child: Text("Error: $_error"))
                  : _buildReportContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.deepPurple,
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: const Text(
                  'Reporte Mensual',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Row(
                children: [
                  _buildYearSelector(),
                  const SizedBox(width: 10),
                  _buildMonthSelector(),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildYearSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _selectedYear,
          dropdownColor: Colors.deepPurple[700],
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          items: [2024, 2025, 2026].map((year) {
            return DropdownMenuItem(
              value: year,
              child: Text(year.toString()),
            );
          }).toList(),
          onChanged: (val) => _changeDate(val, null),
        ),
      ),
    );
  }

  Widget _buildMonthSelector() {
    final months = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _selectedMonth,
          dropdownColor: Colors.deepPurple[700],
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          items: List.generate(12, (index) {
            return DropdownMenuItem(
              value: index + 1,
              child: Text(months[index]),
            );
          }),
          onChanged: (val) => _changeDate(null, val),
        ),
      ),
    );
  }

  Widget _buildReportContent() {
    if (_report == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Resumen Ejecutivo
          _buildSummaryCards(),
          
          const SizedBox(height: 20),
          
          // 2. Insights
          if (_report!.insights.isNotEmpty) ...[
            const Text(
              "🧠 Análisis & Insights",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 10),
            ..._report!.insights.map((insight) => _buildInsightCard(insight)),
            if (_report!.comparisons.isNotEmpty)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => _showDetailedInsightsDialog(context),
                  icon: const Icon(Icons.analytics_outlined, size: 18),
                  label: const Text("Ver Comparativa Detallada"),
                  style: TextButton.styleFrom(foregroundColor: Colors.deepPurple),
                ),
              ),
            const SizedBox(height: 20),
          ],

          // 3. Deudas y Gráficos
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 900) {
                return Column(
                  children: [
                    _buildDebtSection(),
                    const SizedBox(height: 16),
                    _buildTopCategories(),
                  ],
                );
              } else {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: _buildDebtSection()),
                    const SizedBox(width: 16),
                    Expanded(flex: 2, child: _buildTopCategories()),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    final summary = _report!.summary;
    
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          return Column(
            children: [
              _buildMetricCard('Ingresos', summary.totalIncome, Colors.green, Icons.arrow_downward),
              const SizedBox(height: 12),
              _buildMetricCard('Gastos', summary.totalExpense, Colors.red, Icons.arrow_upward),
              const SizedBox(height: 12),
              _buildMetricCard('Balance', summary.balance, summary.balance >= 0 ? Colors.blue : Colors.orange, Icons.account_balance_wallet),
            ],
          );
        } else {
          return Row(
            children: [
              Expanded(child: _buildMetricCard('Ingresos', summary.totalIncome, Colors.green, Icons.arrow_downward)),
              const SizedBox(width: 12),
              Expanded(child: _buildMetricCard('Gastos', summary.totalExpense, Colors.red, Icons.arrow_upward)),
              const SizedBox(width: 12),
              Expanded(child: _buildMetricCard('Balance', summary.balance, summary.balance >= 0 ? Colors.blue : Colors.orange, Icons.account_balance_wallet)),
            ],
          );
        }
      },
    );
  }

  Widget _buildMetricCard(String title, double amount, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
        border: Border(left: BorderSide(color: color, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.grey[400], size: 18),
              const SizedBox(width: 6),
              Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '\$${NumberFormat("#,##0", "es_ES").format(amount.toInt())}',
            style: TextStyle(color: Colors.black87, fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard(ReportInsight insight) {
    Color bg;
    Color iconColor;
    
    switch (insight.type) {
        case InsightType.positive:
            bg = Colors.green[50]!;
            iconColor = Colors.green[700]!;
            break;
        case InsightType.alert:
            bg = Colors.orange[50]!;
            iconColor = Colors.orange[700]!;
            break;
        case InsightType.negative:
            bg = Colors.red[50]!;
            iconColor = Colors.red[700]!;
            break;
        default:
            bg = Colors.blue[50]!;
            iconColor = Colors.blue[700]!;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: iconColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(insight.icon, color: iconColor, size: 22),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              insight.message,
              style: TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDebtSection() {
    final debtStatus = _report!.debtStatus;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Flexible(
                child: Text(
                  "💳 Estado de Deudas",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.orange[50], borderRadius: BorderRadius.circular(12)),
                child: Text("${debtStatus.activeCount} Activas", style: TextStyle(color: Colors.orange[800], fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (debtStatus.activeList.isEmpty)
            const Text("No tienes deudas activas este mes. ¡Genial!", style: TextStyle(color: Colors.grey)),
            
          ...debtStatus.activeList.map((debt) => Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.credit_card, size: 20, color: Colors.blue),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        debt.description,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      Text("Cuota ${debt.progress}", style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                    ],
                  ),
                ),
                Text(
                  '\$${NumberFormat("#,##0", "es_ES").format(debt.amount)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          )),
          const Divider(height: 30),
          Wrap(
             alignment: WrapAlignment.end,
             crossAxisAlignment: WrapCrossAlignment.center,
             children: [
                 const Text("Total pagado en cuotas: ", style: TextStyle(fontSize: 12, color: Colors.grey)),
                 Text(
                     '\$${NumberFormat("#,##0", "es_ES").format(debtStatus.totalDebtPayment)}', 
                     style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.orange),
                 ),
             ],
          )
        ],
      )
    );
  }

  Widget _buildTopCategories() {
    final categories = _report!.expenseBreakdown.take(5).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            const Text("🏆 Top Gastos", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 20),
            if (categories.isEmpty)
              const Text("Sin gastos registrados", style: TextStyle(color: Colors.grey)),
              
            ...categories.asMap().entries.map((entry) {
                final cat = entry.value;
                final index = entry.key;
                final color = _getColor(cat.categoryName, index); 
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Row(
                    children: [
                       Container(
                         width: 4, height: 30, 
                         decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))
                       ),
                       const SizedBox(width: 12),
                       Expanded(
                           child: Column(
                             crossAxisAlignment: CrossAxisAlignment.start,
                             children: [
                               Text(cat.categoryName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                               Container(
                                 height: 4, 
                                 margin: const EdgeInsets.only(top: 4),
                                 child: LinearProgressIndicator(
                                     value: cat.percentage / 100, 
                                     backgroundColor: Colors.grey[100], 
                                     color: color,
                                     borderRadius: BorderRadius.circular(2),
                                 )
                               )
                             ],
                           )
                       ),
                       const SizedBox(width: 10),
                       Text('${cat.percentage.toStringAsFixed(1)}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                );
            }),
        ],
      ),
    );
  }
  
  Color _getColor(String name, int index) {
      final colors = [Colors.red, Colors.blue, Colors.orange, Colors.purple, Colors.teal];
      return colors[index % colors.length];
  }

  void _showDetailedInsightsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
           children: [
              Icon(Icons.compare_arrows, color: Colors.deepPurple),
              SizedBox(width: 10),
              Text("Comparativa vs Mes Anterior", style: TextStyle(fontSize: 18)),
           ],
        ),
        content: Container(
          width: double.maxFinite,
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _report!.comparisons.length,
            itemBuilder: (ctx, index) {
               return _buildComparisonCard(_report!.comparisons[index]);
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("Cerrar"),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonCard(CategoryComparison comp) {
    final isSaving = comp.difference <= 0;
    final color = isSaving ? Colors.green : Colors.red;
    final icon = isSaving ? Icons.trending_down : Icons.trending_up;
    final formatter = NumberFormat("#,##0", "es_ES");
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
           Container(
             padding: const EdgeInsets.all(6),
             decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
             child: Icon(icon, color: color, size: 18),
           ),
           const SizedBox(width: 12),
           Expanded(
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 Text(comp.categoryName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                 Row(
                   children: [
                     Text(
                        isSaving ? "Ahorro: " : "Aumento: ", 
                        style: TextStyle(fontSize: 12, color: Colors.grey[600])
                     ),
                     Text(
                       '\$${formatter.format(comp.difference.abs())}',
                       style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
                     ),
                   ],
                 )
               ],
             ),
           ),
           Column(
             crossAxisAlignment: CrossAxisAlignment.end,
             children: [
               Text(
                 '${comp.percentage.abs().toStringAsFixed(1)}%',
                 style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color),
               ),
               Text(
                 '\$${formatter.format(comp.currentAmount)}',
                 style: TextStyle(fontSize: 11, color: Colors.grey[500]),
               ),
             ],
           )
        ],
      ),
    );
  }
}
