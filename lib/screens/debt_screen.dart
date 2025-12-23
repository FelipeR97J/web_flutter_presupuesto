import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/debt_model.dart';
import '../services/debt_service.dart';
import '../services/auth_service.dart';
import '../widgets/pagination_controls.dart';
import '../widgets/debt_form_dialog.dart';
import 'debt_detail_screen.dart';

class DebtScreen extends StatefulWidget {
  const DebtScreen({super.key});

  @override
  State<DebtScreen> createState() => _DebtScreenState();
}

class _DebtScreenState extends State<DebtScreen> {
  final _debtService = DebtService();
  final _authService = AuthService();

  List<Debt> _debts = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Filtros
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  // Paginación
  int _currentPage = 1;
  int _totalPages = 1;
  final int _pageSize = 10;
  bool _isPaginationLoading = false;

  @override
  void initState() {
    super.initState();
    _loadDebts();
  }

  Future<void> _loadDebts({int page = 1}) async {
    setState(() {
      _isLoading = true;
      _isPaginationLoading = true;
      _errorMessage = null;
    });

    try {
      final token = _authService.token;
      if (token == null) throw Exception('No hay sesión activa');

      final response = await _debtService.getDebts(
        token,
        year: _selectedYear,
        month: _selectedMonth,
        page: page,
        limit: _pageSize,
      );

      if (mounted) {
        setState(() {
          _debts = response.data;
          _currentPage = page;
          _totalPages = response.totalPages;
          _isLoading = false;
          _isPaginationLoading = false;
        });

        // "Enrich" the list by fetching details for each debt to get the category info
        // This is necessary because the List API returns categoryId: 0
        final List<Debt> enrichedDebts = [];
        // We do this in parallel but limit concurrency if needed, here we just do all at once for the page (usually 10 items)
        final results = await Future.wait(
          response.data.map((d) => _debtService.getDebtById(token, d.id)).toList(),
        );
        
        // If all successful, update the list
        if (mounted) {
           setState(() {
             // Replace items in _debts with enriched ones matching IDs in case order changed (unlikely with map)
             // But simpler to just assign results if they map 1:1
             _debts = results;
           });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
          _isPaginationLoading = false;
        });
      }
    }
  }

  void _onMonthChanged(int? newValue) {
    if (newValue != null) {
      setState(() => _selectedMonth = newValue);
      _loadDebts(page: 1);
    }
  }

  void _onYearChanged(int? newValue) {
    if (newValue != null) {
      setState(() => _selectedYear = newValue);
      _loadDebts(page: 1);
    }
  }

  void _navigateToAddDebt() {
    showDialog(
      context: context,
      builder: (context) => const DebtFormDialog(),
    ).then((result) {
      if (result == true) {
        _loadDebts(page: 1);
      }
    });
  }

  void _navigateToDetail(Debt debt) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DebtDetailScreen(debt: debt),
      ),
    ).then((_) => _loadDebts(page: _currentPage));
  }

  Future<void> _handleDeleteDebt(Debt debt) async {
     final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Deuda'),
        content: Text('¿Eliminar "${debt.description}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed == true) {
       try {
        final token = _authService.token;
        if (token == null) return;
        await _debtService.deleteDebt(token, debt.id);
        _loadDebts(page: _currentPage);
         if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deuda eliminada')));
         }
      } catch (e) {
        if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
         }
      }
    }
  }
  
  void _openEditDialog(Debt debt) {
     showDialog(
      context: context,
      builder: (context) => DebtFormDialog(debt: debt),
    ).then((result) {
      if (result == true) {
        _loadDebts(page: _currentPage);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Deudas'),
        backgroundColor: Colors.redAccent,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              onPressed: _navigateToAddDebt,
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Agregar'),
              style: ElevatedButton.styleFrom(
                 foregroundColor: Colors.redAccent,
                 backgroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _selectedMonth,
                    decoration: const InputDecoration(labelText: 'Mes', border: OutlineInputBorder()),
                    items: List.generate(12, (index) {
                      return DropdownMenuItem(value: index + 1, child: Text(DateFormat('MMMM', 'es_ES').format(DateTime(2000, index + 1))));
                    }),
                    onChanged: _onMonthChanged,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _selectedYear,
                    decoration: const InputDecoration(labelText: 'Año', border: OutlineInputBorder()),
                    items: List.generate(5, (index) {
                      final year = DateTime.now().year - 2 + index;
                      return DropdownMenuItem(value: year, child: Text(year.toString()));
                    }),
                    onChanged: _onYearChanged,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                            const SizedBox(height: 16),
                            Text('Error: $_errorMessage'),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadDebts(page: 1),
                              child: const Text('Reintentar'),
                            ),
                          ],
                        ),
                      )
                    : _debts.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.credit_card_off, size: 64, color: Colors.grey[300]),
                                const SizedBox(height: 16),
                                const Text('No hay deudas para este periodo'),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: _navigateToAddDebt,
                                  icon: const Icon(Icons.add),
                                  label: const Text('Agregar Deuda'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.redAccent,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : GridView.builder(
                            padding: const EdgeInsets.all(16),
                            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 400,
                              childAspectRatio: 1.2,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                            itemCount: _debts.length,
                            itemBuilder: (context, index) {
                              final debt = _debts[index];
                              return Card(
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: InkWell(
                                  onTap: () => _navigateToDetail(debt),
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Colors.red[400]!,
                                          Colors.red[600]!,
                                        ],
                                      ),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Header con título y monto
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      debt.description,
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 18,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                      maxLines: 2,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: Colors.white.withOpacity(0.2),
                                                        borderRadius: BorderRadius.circular(12),
                                                      ),
                                                      child: Text(
                                                        '${debt.installments} cuotas',
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 12,
                                                          fontWeight: FontWeight.w600,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: Colors.white.withOpacity(0.2),
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: const Icon(
                                                  Icons.credit_card,
                                                  color: Colors.white,
                                                  size: 32,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const Spacer(),
                                          // Monto total
                                          Text(
                                            debt.formattedTotalAmount,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 28,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          // Información de tarjeta y banco
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(0.15),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    const Icon(
                                                      Icons.payment,
                                                      color: Colors.white70,
                                                      size: 16,
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Expanded(
                                                      child: Text(
                                                        debt.creditCard?.name ?? "ID: ${debt.creditCardId}",
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 13,
                                                          fontWeight: FontWeight.w500,
                                                        ),
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 6),
                                                Row(
                                                  children: [
                                                    const Icon(
                                                      Icons.account_balance,
                                                      color: Colors.white70,
                                                      size: 16,
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Expanded(
                                                      child: Text(
                                                        debt.creditCard?.bank?.name ?? "-",
                                                        style: const TextStyle(
                                                          color: Colors.white70,
                                                          fontSize: 12,
                                                        ),
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          // Botones de acción
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.end,
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.edit, color: Colors.white),
                                                onPressed: () => _openEditDialog(debt),
                                                tooltip: 'Editar',
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.delete, color: Colors.white70),
                                                onPressed: () => _handleDeleteDebt(debt),
                                                tooltip: 'Eliminar',
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
          ),
          if (_totalPages > 1)
            PaginationControls(
              currentPage: _currentPage,
              totalPages: _totalPages,
              isLoading: _isPaginationLoading,
              onPreviousPage: () => _loadDebts(page: _currentPage - 1),
              onNextPage: () => _loadDebts(page: _currentPage + 1),
            ),
        ],
      ),
    );
  }
}
