import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/expense_model.dart';
import '../services/auth_service.dart';
import '../services/expense_service.dart';
import '../widgets/pagination_controls.dart';
import '../widgets/expense_form_dialog.dart';

class ExpenseScreen extends StatefulWidget {
  const ExpenseScreen({super.key});

  @override
  State<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  final _authService = AuthService();
  final _expenseService = ExpenseService();

  List<Expense> _expenses = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Paginación
  int _currentPage = 1;
  int _totalPages = 1;
  final int _pageSize = 10;
  bool _isPaginationLoading = false;

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  // ============================================
  // MÉTODO: Cargar lista de gastos del servidor
  // Aquí se obtienen todos los gastos con paginación
  // ============================================
  Future<void> _loadExpenses({int page = 1}) async {
    setState(() {
      _isLoading = true;
      _isPaginationLoading = true;
      _errorMessage = null;
    });

    try {
      final token = _authService.token;
      if (token == null) {
        throw Exception('Token no disponible');
      }

      final response = await _expenseService.getExpensesPaginated(
        token,
        page: page,
        limit: _pageSize,
      );
      
      if (mounted) {
        setState(() {
          _expenses = response.data;
          _currentPage = page;
          _totalPages = response.totalPages;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isPaginationLoading = false;
        });
      }
    }
  }

  // ============================================
  // MÉTODO: Eliminar gasto con confirmación
  // ============================================
  void _handleDeleteExpense(Expense expense) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar Gasto'),
          content: Text('¿Estás seguro de que deseas eliminar "${expense.description}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                try {
                  final token = _authService.token;
                  if (token == null) {
                    if (mounted) {
                      final scaffoldMessenger = ScaffoldMessenger.of(context);
                      scaffoldMessenger.showMaterialBanner(
                        MaterialBanner(
                          content: const Text('No hay sesión activa'),
                          leading: const Icon(Icons.warning, color: Colors.orange),
                          backgroundColor: Colors.orange[50],
                          actions: [
                            TextButton(
                              onPressed: () {
                                scaffoldMessenger.clearMaterialBanners();
                              },
                              child: const Text('Descartar'),
                            ),
                          ],
                        ),
                      );
                      // Auto-descartar después de 3 segundos
                      Future.delayed(const Duration(seconds: 3), () {
                        if (mounted) {
                          scaffoldMessenger.clearMaterialBanners();
                        }
                      });
                    }
                    return;
                  }

                  await _expenseService.deleteExpense(
                    token: token,
                    expenseId: expense.id,
                  );
                  _loadExpenses(page: _currentPage);

                  if (mounted) {
                    final scaffoldMessenger = ScaffoldMessenger.of(context);
                    scaffoldMessenger.showMaterialBanner(
                      MaterialBanner(
                        content: const Text('Gasto eliminado exitosamente'),
                        leading: const Icon(Icons.delete, color: Colors.indigo),
                        backgroundColor: Colors.indigo[50],
                        actions: [
                          TextButton(
                            onPressed: () {
                              scaffoldMessenger.clearMaterialBanners();
                            },
                            child: const Text('Descartar'),
                          ),
                        ],
                      ),
                    );
                    // Auto-descartar después de 3 segundos
                    Future.delayed(const Duration(seconds: 3), () {
                      if (mounted) {
                        scaffoldMessenger.clearMaterialBanners();
                      }
                    });
                  }
                } catch (e) {
                  if (mounted) {
                    final scaffoldMessenger = ScaffoldMessenger.of(context);
                    scaffoldMessenger.showMaterialBanner(
                      MaterialBanner(
                        content: Text(e.toString().replaceAll('Exception: ', '')),
                        leading: const Icon(Icons.error_outline, color: Colors.indigo),
                        backgroundColor: Colors.indigo[50],
                        actions: [
                          TextButton(
                            onPressed: () {
                              scaffoldMessenger.clearMaterialBanners();
                            },
                            child: const Text('Descartar'),
                          ),
                        ],
                      ),
                    );
                    // Auto-descartar después de 3 segundos
                    Future.delayed(const Duration(seconds: 3), () {
                      if (mounted) {
                        scaffoldMessenger.clearMaterialBanners();
                      }
                    });
                  }
                }
              },
              child: const Text('Eliminar', style: TextStyle(color: Colors.indigo)),
            ),
          ],
        );
      },
    );
  }

  void _navigateToAddExpense() {
    showDialog(
      context: context,
      builder: (context) => ExpenseFormDialog(
        onExpenseSaved: () => _loadExpenses(page: 1),
      ),
    ).then((result) {
      // Si el diálogo retorna true, significa que fue exitoso
      if (result == true) {
        _loadExpenses(page: 1);
      }
    });
  }

  void _navigateToEditExpense(Expense expense) {
    showDialog(
      context: context,
      builder: (context) => ExpenseFormDialog(
        expense: expense,
        onExpenseSaved: () => _loadExpenses(page: _currentPage),
      ),
    ).then((result) {
      // Si el diálogo retorna true, significa que fue exitoso
      if (result == true) {
        _loadExpenses(page: _currentPage);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Gastos',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.indigo[600],
        elevation: 2,
        shadowColor: Colors.indigo[600]!.withValues(alpha: 0.5),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ElevatedButton.icon(
              onPressed: _navigateToAddExpense,
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Agregar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.indigo[600],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          ),
        ],
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      child: _isLoading
          ? const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()),
            )
          : _errorMessage != null
              ? Padding(
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error, size: 64, color: Colors.red[300]),
                        const SizedBox(height: 16),
                        Text('Error: $_errorMessage'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadExpenses,
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                )
              : _expenses.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(20),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.trending_down, size: 64, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            const Text('No hay gastos registrados'),
                          ],
                        ),
                      ),
                    )
                  : Column(
                      children: [
                        // ============================================
                        // TARJETA: Resumen de gastos totales
                        // ============================================
                        Container(
                          margin: const EdgeInsets.all(16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.indigo, Colors.indigo[300]!],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Total de Gastos',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '\$${NumberFormat('#,##0', 'es_ES').format(_expenseService.calculateTotal(_expenses).toInt())}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // ============================================
                        // LISTA: Gastos registrados
                        // ============================================
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _expenses.length,
                          itemBuilder: (context, index) {
                            final expense = _expenses[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: Colors.indigo[100],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Icon(
                                      Icons.trending_down,
                                      color: Colors.indigo[700],
                                    ),
                                  ),
                                ),
                                title: Text(expense.description),
                                subtitle: Text(expense.formattedDate),
                                trailing: Wrap(
                                  spacing: 8,
                                  children: [
                                    Text(
                                      expense.formattedAmount,
                                      style: TextStyle(
                                        color: Colors.indigo[700],
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                                      onPressed: () => _handleDeleteExpense(expense),
                                    ),
                                  ],
                                ),
                                onTap: () => _navigateToEditExpense(expense),
                              ),
                            );
                          },
                        ),

                        // ============================================
                        // PAGINACIÓN
                        // ============================================
                        if (_totalPages > 1)
                          PaginationControls(
                            currentPage: _currentPage,
                            totalPages: _totalPages,
                            isLoading: _isPaginationLoading,
                            onPreviousPage: _currentPage > 1
                                ? () => _loadExpenses(page: _currentPage - 1)
                                : () {},
                            onNextPage: _currentPage < _totalPages
                                ? () => _loadExpenses(page: _currentPage + 1)
                                : () {},
                          ),
                      ],
                    ),
    );
  }
}
