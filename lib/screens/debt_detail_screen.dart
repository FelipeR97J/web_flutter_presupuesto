import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/debt_model.dart';

class DebtDetailScreen extends StatelessWidget {
  final Debt debt;

  const DebtDetailScreen({super.key, required this.debt});

  @override
  Widget build(BuildContext context) {
    // Cálculos
    final installmentAmount = debt.totalAmount / debt.installments;
    final formatter = NumberFormat('#,##0', 'es_ES');
    final now = DateTime.now();
    
    // Calcular cuotas pagadas (las que ya pasaron)
    int paidInstallments = 0;
    for (int i = 0; i < debt.installments; i++) {
      final installmentDate = DateTime(
        debt.startDate.year,
        debt.startDate.month + i,
        debt.startDate.day,
      );
      if (installmentDate.isBefore(now)) {
        paidInstallments++;
      }
    }
    
    final pendingInstallments = debt.installments - paidInstallments;
    final paidAmount = installmentAmount * paidInstallments;
    final pendingAmount = installmentAmount * pendingInstallments;
    final progress = paidInstallments / debt.installments;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          debt.description,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.orange[700],
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ============================================
            // SECCIÓN: Resumen de la Deuda
            // ============================================
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Resumen de la Deuda',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange[700],
                          ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricTile(
                            '💰 Monto Total',
                            '\$${formatter.format(debt.totalAmount.toInt())}',
                            Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMetricTile(
                            '📅 Cuotas',
                            '${debt.installments} meses',
                            Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricTile(
                            '💳 Cuota Mensual',
                            '\$${formatter.format(installmentAmount.toInt())}',
                            Colors.deepPurple,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMetricTile(
                            '📆 Inicio',
                            debt.formattedStartDate,
                            Colors.teal,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                    _buildInfoRow('Tarjeta', debt.creditCard?.name ?? 'N/A'),
                    const SizedBox(height: 8),
                    _buildInfoRow('Categoría', debt.expenseCategory?.name ?? 'ID: ${debt.categoryId}'),
                    const SizedBox(height: 8),
                    _buildInfoRow('Banco', debt.creditCard?.bank?.name ?? 'N/A'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ============================================
            // SECCIÓN: Progreso de Pago
            // ============================================
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Progreso de Pago',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange[700],
                          ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pagado: $paidInstallments de ${debt.installments}',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  minHeight: 20,
                                  backgroundColor: Colors.grey[200],
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    progress >= 1.0 ? Colors.green : Colors.orange,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${(progress * 100).toStringAsFixed(0)}% completado',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: progress >= 1.0 ? Colors.green : Colors.orange[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildProgressTile(
                            '✅ Pagado',
                            '\$${formatter.format(paidAmount.toInt())}',
                            '$paidInstallments cuotas',
                            Colors.green,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildProgressTile(
                            '⏳ Pendiente',
                            '\$${formatter.format(pendingAmount.toInt())}',
                            '$pendingInstallments cuotas',
                            Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ============================================
            // SECCIÓN: Detalle de Cuotas
            // ============================================
            Text(
              'Detalle de Cuotas',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: debt.installments,
              itemBuilder: (context, index) {
                final installmentDate = DateTime(
                  debt.startDate.year,
                  debt.startDate.month + index,
                  debt.startDate.day,
                );
                final isPast = installmentDate.isBefore(now);
                final isCurrent = installmentDate.month == now.month && 
                                  installmentDate.year == now.year;

                return Card(
                  elevation: isCurrent ? 3 : 1,
                  color: isPast
                      ? Colors.green[50]
                      : isCurrent
                          ? Colors.orange[50]
                          : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: isCurrent
                        ? BorderSide(color: Colors.orange[700]!, width: 2)
                        : BorderSide.none,
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isPast
                          ? Colors.green
                          : isCurrent
                              ? Colors.orange[700]
                              : Colors.grey[400],
                      child: Icon(
                        isPast ? Icons.check : Icons.schedule,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      'Cuota ${index + 1} de ${debt.installments}',
                      style: TextStyle(
                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    subtitle: Text(
                      DateFormat('dd/MM/yyyy').format(installmentDate),
                      style: TextStyle(
                        color: isCurrent ? Colors.orange[700] : Colors.grey[600],
                      ),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '\$${formatter.format(installmentAmount.toInt())}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isPast ? Colors.green : Colors.black87,
                          ),
                        ),
                        if (isCurrent)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange[700],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'ACTUAL',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile(String title, String value, Color color) {
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
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressTile(String title, String value, String subtitle, Color color) {
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
              fontSize: 11,
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
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.grey[600], fontSize: 13),
        ),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ],
    );
  }
}
