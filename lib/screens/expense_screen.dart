import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/expense_model.dart';
import '../services/auth_service.dart';
import '../services/expense_service.dart';
import '../services/debt_service.dart'; // Added
import '../widgets/pagination_controls.dart';
import '../widgets/expense_form_dialog.dart';
import 'debt_detail_screen.dart'; // Added

class ExpenseScreen extends StatefulWidget {
  const ExpenseScreen({super.key});

  @override
  State<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  final _authService = AuthService();
  final _expenseService = ExpenseService();
  final _debtService = DebtService(); // Added

  List<Expense> _expenses = [];
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
  double _totalExpenses = 0.0; // Total de gastos normales
  double _totalInstallments = 0.0; // Total de cuotas de deuda

  @override
  void initState() {
    super.initState();
    _loadExpenses();
    _loadTotalAmount(); // Cargar total al inicio
  }

  // ============================================
  // MÉTODO: Cargar total del mes
  // ============================================
  Future<void> _loadTotalAmount() async {
    try {
      final token = _authService.token;
      if (token == null) return;

      // Usar getExpenses sin paginación pero con filtros de fecha y límite alto
      final allExpensesInMonth = await _expenseService.getExpenses(
        token,
        year: _selectedYear,
        month: _selectedMonth,
        limit: 1000,
      );

      final total = _expenseService.calculateTotal(allExpensesInMonth);
      final regularExpenses = total - _expenseService.calculateInstallmentsTotal(allExpensesInMonth);
      final installmentsTotal = _expenseService.calculateInstallmentsTotal(allExpensesInMonth);
      
      if (mounted) {
        setState(() {
          _totalExpenses = regularExpenses;
          _totalInstallments = installmentsTotal;
        });
      }
    } catch (e) {
      debugPrint('Error calculando total del mes: $e');
    }
  }

  // ============================================
  // MÉTODO: Cargar lista de gastos del servidor
  // Aquí se obtienen todos los gastos con paginación
  // ============================================
  Future<void> _loadExpenses({int page = 1}) async {
    debugPrint('Loading expenses page: $page');
    setState(() {
      _isLoading = true;
      _isPaginationLoading = true;
      _errorMessage = null;
    });

    // Recargar también el total global del mes si cambiamos de filtro (página 1 implica posible cambio de filtro o recarga inicial)
    if (page == 1) {
      _loadTotalAmount();
    }

    try {
      final token = _authService.token;
      if (token == null) {
        throw Exception('Token no disponible');
      }

      debugPrint('Calling service with page: $page, year: $_selectedYear, month: $_selectedMonth');
      final response = await _expenseService.getExpensesPaginated(
        token,
        page: page,
        limit: _pageSize,
        year: _selectedYear,
        month: _selectedMonth,
      );
      
      debugPrint('Response received. Total pages: ${response.totalPages}, Data length: ${response.data.length}');

      if (mounted) {
        setState(() {
          _expenses = response.data;
          _currentPage = page;
          
          // Lógica de paginación optimista:
          // Si la cantidad de items recibidos es igual al límite, asumimos que hay una página más,
          // independientemente de lo que diga la API (que a veces devuelve mal el total).
          if (response.data.length == _pageSize && response.totalPages <= page) {
            _totalPages = page + 1;
          } else {
            _totalPages = response.totalPages;
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading expenses: $e');
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
  // MÉTODO: Navegar al detalle de deuda
  // ============================================
  Future<void> _navigateToDebtDetail(int debtId) async {
    try {
      // Mostrar loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final token = _authService.token;
      if (token == null) throw Exception('Token no disponible');

      final debt = await _debtService.getDebtById(token, debtId);
      
      // Cerrar loading
      if (mounted) Navigator.of(context, rootNavigator: true).pop();

      if (mounted && debt != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DebtDetailScreen(debt: debt),
          ),
        );
      }
    } catch (e) {
      // Cerrar loading si hay error
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar detalle de deuda: $e'),
            backgroundColor: Colors.red,
          ),
        );
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    decoration: const InputDecoration(
                      labelText: 'Mes',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                    ),
                    value: _selectedMonth,
                    items: List.generate(12, (index) {
                      return DropdownMenuItem(
                        value: index + 1,
                        child: Text(DateFormat('MMMM', 'es_ES').format(DateTime(2022, index + 1))),
                      );
                    }),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedMonth = value;
                          _currentPage = 1; // Reset page
                        });
                        _loadExpenses(page: 1);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    decoration: const InputDecoration(
                      labelText: 'Año',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                    ),
                    value: _selectedYear,
                    items: List.generate(5, (index) {
                      final year = DateTime.now().year - 2 + index;
                      return DropdownMenuItem(
                        value: year,
                        child: Text(year.toString()),
                      );
                    }),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedYear = value;
                          _currentPage = 1; // Reset page
                        });
                        _loadExpenses(page: 1);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
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
                        // ============================================
                        // TARJETAS: Resumen de gastos separamos (Gastos vs Cuotas)
                        // ============================================
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          child: Row(
                            children: [
                              // Tarjeta de Gastos Normales
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [Colors.indigo, Colors.indigo[300]!],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.indigo.withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Gastos',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        '\$${NumberFormat('#,##0', 'es_ES').format(_totalExpenses.toInt())}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Tarjeta de Cuotas
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [Colors.orange[800]!, Colors.orange[400]!],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.orange.withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Total Cuotas',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        '\$${NumberFormat('#,##0', 'es_ES').format(_totalInstallments.toInt())}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
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
                            final isDebt = expense.isDebtPayment;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              color: isDebt ? const Color(0xFFFFF3E0) : null, // Naranja muy claro
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                leading: Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: isDebt ? Colors.orange[100] : Colors.indigo[100],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Icon(
                                      isDebt ? Icons.credit_card : Icons.trending_down,
                                      color: isDebt ? Colors.orange[800] : Colors.indigo[700],
                                    ),
                                  ),
                                ),
                                title: Text(
                                  expense.description,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(expense.formattedDate),
                                    if (isDebt)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 2),
                                        child: Text(
                                          'Gasto generado por deuda',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.orange[800],
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        if (isDebt)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            margin: const EdgeInsets.only(bottom: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.orange,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: const Text(
                                              'CUOTA',
                                              style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        Text(
                                          expense.formattedAmount,
                                          style: TextStyle(
                                            color: isDebt ? Colors.orange[800] : Colors.indigo[700],
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (!isDebt) ...[
                                      const SizedBox(width: 8),
                                      IconButton(
                                        icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                                        onPressed: () => _handleDeleteExpense(expense),
                                      ),
                                    ],
                                  ],
                                ),
                                onTap: isDebt 
                                  ? () {
                                      if (expense.debtId != null) {
                                        _navigateToDebtDetail(expense.debtId!);
                                      }
                                    }
                                  : () => _navigateToEditExpense(expense),
                              ),
                            );
                          },
                        ),

                        // ============================================
                        // PAGINACIÓN
                        // ============================================
                        // ============================================
                        // PAGINACIÓN
                        // ============================================
                        PaginationControls(
                          currentPage: _currentPage,
                          totalPages: _totalPages > 0 ? _totalPages : 1,
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
