import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/income_model.dart';
import '../services/auth_service.dart';
import '../services/income_service.dart';
import '../widgets/pagination_controls.dart';
import '../widgets/income_form_dialog.dart';

class IncomeScreen extends StatefulWidget {
  const IncomeScreen({super.key});

  @override
  State<IncomeScreen> createState() => _IncomeScreenState();
}

class _IncomeScreenState extends State<IncomeScreen> {
  final _authService = AuthService();
  final _incomeService = IncomeService();

  List<Income> _incomes = [];
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
    _loadIncomes();
  }

  // ============================================
  // MÉTODO: Cargar lista de ingresos del servidor
  // Aquí se obtienen todos los ingresos con paginación
  // ============================================
  Future<void> _loadIncomes({int page = 1}) async {
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

      final response = await _incomeService.getIncomesPaginated(
        token,
        page: page,
        limit: _pageSize,
      );
      
      if (mounted) {
        setState(() {
          _incomes = response.data;
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
  // MÉTODO: Mostrar diálogo para agregar ingreso
  // ============================================
  void _navigateToAddIncome() {
    showDialog(
      context: context,
      builder: (context) => IncomeFormDialog(
        onIncomeSaved: () => _loadIncomes(page: 1),
      ),
    ).then((result) {
      // Si el diálogo retorna true, significa que fue exitoso
      if (result == true) {
        _loadIncomes(page: 1);
      }
    });
  }

  // ============================================
  // MÉTODO: Mostrar diálogo para editar ingreso
  // ============================================
  void _navigateToEditIncome(Income income) {
    showDialog(
      context: context,
      builder: (context) => IncomeFormDialog(
        income: income,
        onIncomeSaved: () => _loadIncomes(page: _currentPage),
      ),
    ).then((result) {
      // Si el diálogo retorna true, significa que fue exitoso
      if (result == true) {
        _loadIncomes(page: _currentPage);
      }
    });
  }

  // ============================================
  // MÉTODO: Eliminar ingreso con confirmación
  // ============================================
  void _handleDeleteIncome(Income income) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar Ingreso'),
          content: Text('¿Estás seguro de que deseas eliminar "${income.description}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                try {
                  await _incomeService.deleteIncome(
                    token: _authService.token!,
                    incomeId: income.id,
                  );
                  _loadIncomes(page: _currentPage);

                  if (mounted) {
                    final scaffoldMessenger = ScaffoldMessenger.of(context);
                    scaffoldMessenger.showMaterialBanner(
                      MaterialBanner(
                        content: const Text('Ingreso eliminado exitosamente'),
                        leading: const Icon(Icons.delete, color: Colors.red),
                        backgroundColor: Colors.red[50],
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
                        content: Text('Error: ${e.toString()}'),
                        leading: const Icon(Icons.error_outline, color: Colors.red),
                        backgroundColor: Colors.red[50],
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
              child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ingresos'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              onPressed: _navigateToAddIncome,
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Agregar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.deepPurple,
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
                          onPressed: _loadIncomes,
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                )
              : _incomes.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(20),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.trending_up, size: 64, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            const Text('No hay ingresos registrados'),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _navigateToAddIncome,
                              icon: const Icon(Icons.add),
                              label: const Text('Registrar Ingreso'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Column(
                      children: [
                        // ============================================
                        // TARJETA: Resumen de ingresos totales
                        // ============================================
                        Container(
                          margin: const EdgeInsets.all(16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.green, Colors.green[300]!],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Total de Ingresos',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '\$${NumberFormat('#,##0', 'es_ES').format(_incomeService.calculateTotal(_incomes).toInt())}',
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
                        // LISTA: Ingresos registrados
                        // ============================================
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _incomes.length,
                          itemBuilder: (context, index) {
                            final income = _incomes[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: Colors.green[100],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Icon(
                                      Icons.trending_up,
                                      color: Colors.green[700],
                                    ),
                                  ),
                                ),
                                title: Text(income.description),
                                subtitle: Text(income.formattedDate),
                                trailing: Wrap(
                                  spacing: 8,
                                  children: [
                                    Text(
                                      income.formattedAmount,
                                      style: TextStyle(
                                        color: Colors.green[700],
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                                      onPressed: () => _handleDeleteIncome(income),
                                    ),
                                  ],
                                ),
                                onTap: () => _navigateToEditIncome(income),
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
                                ? () => _loadIncomes(page: _currentPage - 1)
                                : () {},
                            onNextPage: _currentPage < _totalPages
                                ? () => _loadIncomes(page: _currentPage + 1)
                                : () {},
                          ),
                      ],
                    ),
    );
  }
}
