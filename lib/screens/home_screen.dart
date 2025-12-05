import 'package:flutter/material.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../services/income_service.dart';
import '../services/expense_service.dart';
import '../services/income_category_service.dart';
import '../services/expense_category_service.dart';
import '../models/user_model.dart';
import '../models/income_model.dart';
import '../models/expense_model.dart';
import '../models/income_category_model.dart';
import '../models/expense_category_model.dart';
import 'edit_profile_screen.dart';
import 'change_password_screen.dart';
import 'income_screen.dart';
import 'expense_screen.dart';
import 'income_category_screen.dart';
import 'expense_category_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onLogout;

  const HomeScreen({
    required this.onLogout,
    super.key,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _authService = AuthService();
  final _incomeService = IncomeService();
  final _expenseService = ExpenseService();
  final _incomeCategoryService = IncomeCategoryService();
  final _expenseCategoryService = ExpenseCategoryService();
  
  late User _user;
  bool _isLoading = true;
  
  List<Income> _incomes = [];
  List<Expense> _expenses = [];
  List<IncomeCategory> _incomeCategories = [];
  List<ExpenseCategory> _expenseCategories = [];
  bool _dashboardLoading = false;
  Timer? _autoRefreshTimer;
  
  // Navegación
  String _currentPage = 'dashboard';

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    
    // Configurar auto-refresh cada 10 segundos
    _autoRefreshTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) {
        if (mounted && _currentPage == 'dashboard') {
          _loadDashboardData();
        }
      },
    );
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  void _loadUserProfile() async {
    try {
      final user = await _authService.getProfile();
      if (mounted) {
        setState(() {
          _user = user;
          _isLoading = false;
        });
        // Cargar datos del dashboard después de obtener el usuario
        _loadDashboardData();
      }
    } catch (e) {
      if (mounted) {
        final errorMsg = e.toString().replaceFirst('Exception: ', '');
        
        // Mostrar error como MaterialBanner arriba
        ScaffoldMessenger.of(context).showMaterialBanner(
          MaterialBanner(
            content: Text(errorMsg),
            leading: Icon(Icons.error_outline, color: Colors.red[700]),
            backgroundColor: Colors.red[50],
            actions: [
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).clearMaterialBanners();
                },
                child: const Text('Descartar'),
              ),
            ],
          ),
        );
        
        // Reintentar después de 3 segundos
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            ScaffoldMessenger.of(context).clearMaterialBanners();
            _loadUserProfile();
          }
        });
      }
    }
  }

  void _loadDashboardData() async {
    setState(() {
      _dashboardLoading = true;
    });

    try {
      final token = _authService.token ?? '';
      
      final incomes = await _incomeService.getIncomes(token);
      final expenses = await _expenseService.getExpenses(token);
      final incomeCategories = await _incomeCategoryService.getCategories();
      final expenseCategories = await _expenseCategoryService.getCategories();

      if (mounted) {
        setState(() {
          _incomes = incomes;
          _expenses = expenses;
          _incomeCategories = incomeCategories.data;
          _expenseCategories = expenseCategories.data;
          _dashboardLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _dashboardLoading = false;
        });
      }
      debugPrint('Error al cargar datos del dashboard: $e');
    }
  }

  void _handleLogout() async {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Cerrar Sesión'),
          content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                try {
                  await _authService.logout();
                  if (mounted) {
                    widget.onLogout();
                  }
                } catch (e) {
                  // Error handled silently, user will be on home screen
                  debugPrint('Logout error: $e');
                }
              },
              child: const Text('Cerrar Sesión'),
            ),
          ],
        );
      },
    );
  }

  void _navigateToEditProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(
          user: _user,
          onProfileUpdated: _loadUserProfile,
        ),
      ),
    );
  }

  void _navigateToChangePassword() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChangePasswordScreen(
          onPasswordChanged: _loadUserProfile,
          onLogoutRequired: _handleLogout,
        ),
      ),
    );
  }

  void _navigateToIncome() {
    setState(() {
      _currentPage = 'income';
    });
  }

  void _navigateToExpense() {
    setState(() {
      _currentPage = 'expense';
    });
  }

  void _navigateToIncomeCategories() {
    setState(() {
      _currentPage = 'income_categories';
    });
  }

  void _navigateToExpenseCategories() {
    setState(() {
      _currentPage = 'expense_categories';
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Inicio'),
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inicio'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _navigateToEditProfile,
            tooltip: 'Editar Perfil',
          ),
          IconButton(
            icon: const Icon(Icons.lock),
            onPressed: _navigateToChangePassword,
            tooltip: 'Cambiar Contraseña',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
            tooltip: 'Cerrar Sesión',
          ),
        ],
      ),
      body: Row(
        children: [
          // ============================================
          // SIDEBAR - Navegación lateral (Desktop)
          // ============================================
          _buildSidebarDesktop(),
          
          // ============================================
          // CONTENIDO PRINCIPAL
          // ============================================
          Expanded(
            child: _buildMainContent(),
          ),
        ],
      ),
    );
  }

  // ============================================
  // MÉTODO: Construir Sidebar para Desktop
  // ============================================
  Widget _buildSidebarDesktop() {
    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: Colors.deepPurple[900],
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header con info del usuario
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.deepPurple[800],
              border: Border(
                bottom: BorderSide(
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  child: Text(
                    _user.firstName[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '${_user.firstName} ${_user.paternalLastName ?? ''}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  _user.email,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 11,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          
          // Menu Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildSidebarItem(
                  Icons.dashboard,
                  'Dashboard',
                  'dashboard',
                ),
                _buildSidebarItem(
                  Icons.money,
                  'Ingresos',
                  'income',
                  onTap: _navigateToIncome,
                ),
                _buildSidebarItem(
                  Icons.shopping_cart,
                  'Gastos',
                  'expense',
                  onTap: _navigateToExpense,
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(color: Colors.white30, height: 1),
                ),
                _buildSidebarItem(
                  Icons.category,
                  'Cat. Ingresos',
                  'income_categories',
                  onTap: _navigateToIncomeCategories,
                ),
                _buildSidebarItem(
                  Icons.category,
                  'Cat. Gastos',
                  'expense_categories',
                  onTap: _navigateToExpenseCategories,
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(color: Colors.white30, height: 1),
                ),
                _buildSidebarItem(
                  Icons.inventory,
                  'Inventario',
                  'inventory',
                ),
              ],
            ),
          ),
          
          // Footer
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
            ),
            child: Column(
              children: [
                _buildSidebarItem(
                  Icons.settings,
                  'Configuración',
                  'settings',
                ),
                _buildSidebarItem(
                  Icons.logout,
                  'Cerrar Sesión',
                  'logout',
                  onTap: _handleLogout,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // MÉTODO: Item del Sidebar
  // ============================================
  Widget _buildSidebarItem(
    IconData icon,
    String label,
    String pageId, {
    VoidCallback? onTap,
  }) {
    final isActive = _currentPage == pageId;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap ?? () {
          setState(() {
            _currentPage = pageId;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? Colors.deepPurple[700] : Colors.transparent,
            border: Border(
              left: BorderSide(
                color: isActive ? Colors.amber : Colors.transparent,
                width: 4,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: Colors.white,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================
  // MÉTODO: Construir contenido principal
  // ============================================
  Widget _buildMainContent() {
    switch (_currentPage) {
      case 'income':
        return _incomeScreenEmbedded();
      case 'expense':
        return _expenseScreenEmbedded();
      case 'income_categories':
        return _incomeCategoryScreenEmbedded();
      case 'expense_categories':
        return _expenseCategoryScreenEmbedded();
        default:
        return Column(
          children: [
            // ============================================
            // SECCIÓN: Bienvenida (FIJA ARRIBA - NO SCROLLABLE)
            // ============================================
            Padding(
              padding: const EdgeInsets.only(left: 20, top: 20, right: 20),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.deepPurple, Colors.deepPurple[300]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '¡Bienvenido, ${_user.firstName} ${_user.paternalLastName ?? ''}!',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.white.withValues(alpha: 0.3),
                        child: Text(
                          _user.firstName[0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            
            // ============================================
            // SECCIÓN: Scrollable (Perfil, Dashboard)
            // ============================================
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ============================================
                    // COLUMNA IZQUIERDA: Información de Perfil
                    // ============================================
                    Expanded(
                      flex: 1,
                      child: Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Información de Perfil',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepPurple,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _buildCompactInfoCard('📧 Correo', _user.email),
                              if (_user.rut != null)
                                _buildCompactInfoCard('🆔 RUT', _user.rut!),
                              if (_user.age != null)
                                _buildCompactInfoCard('🎂 Edad', _user.age.toString()),
                              if (_user.phoneNumber != null)
                                _buildCompactInfoCard('📱 Teléfono', _user.phoneNumber!),
                              if (_user.birthDate != null)
                                _buildCompactInfoCard(
                                  '📅 Nacimiento',
                                  '${_user.birthDate!.day}/${_user.birthDate!.month}/${_user.birthDate!.year}',
                                ),
                              const SizedBox(height: 16),
                              // Estado de Cuenta
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: _user.isActive ? Colors.green[50] : Colors.red[50],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: _user.isActive ? Colors.green[200]! : Colors.red[200]!,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      _user.isActive
                                          ? Icons.check_circle
                                          : Icons.cancel,
                                      color: _user.isActive
                                          ? Colors.green
                                          : Colors.red,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _user.isActive
                                                ? 'Activo'
                                                : 'Inactivo',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                              color: _user.isActive
                                                  ? Colors.green[700]
                                                  : Colors.red[700],
                                            ),
                                          ),
                                          if (_user.lastLoginAt != null)
                                            Text(
                                              'Último: ${_user.lastLoginAt!.toLocal().day}/${_user.lastLoginAt!.toLocal().month}',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // ============================================
                    // COLUMNA DERECHA: Dashboard
                    // ============================================
                    Expanded(
                      flex: 1,
                      child: _dashboardLoading
                          ? Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                            )
                          : Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Dashboard',
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.deepPurple,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    
                                    // ============================================
                                    // Items en HORIZONTAL (Row)
                                    // ============================================
                                    SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Row(
                                        children: [
                                          // Resumen de Ingresos
                                          SizedBox(
                                            width: 120,
                                            child: _buildDashboardMetric(
                                              '💰 Ingresos',
                                              _incomes.isEmpty ? '\$0' : '\$${NumberFormat('#,##0', 'es_ES').format(_incomeService.calculateTotal(_incomes).toInt())}',
                                              _incomes.length.toString(),
                                              Colors.green,
                                            ),
                                          ),
                                          const SizedBox(width: 12),

                                          // Resumen de Gastos
                                          SizedBox(
                                            width: 120,
                                            child: _buildDashboardMetric(
                                              '💸 Gastos',
                                              _expenses.isEmpty ? '\$0' : '\$${NumberFormat('#,##0', 'es_ES').format(_expenseService.calculateTotal(_expenses).toInt())}',
                                              _expenses.length.toString(),
                                              Colors.red,
                                            ),
                                          ),
                                          const SizedBox(width: 12),

                                          // Resumen de Categorías de Ingresos
                                          SizedBox(
                                            width: 120,
                                            child: _buildDashboardMetric(
                                              '🏷️ Cat. Ingresos',
                                              _incomeCategories.length.toString(),
                                              'activas',
                                              Colors.blue,
                                            ),
                                          ),
                                          const SizedBox(width: 12),

                                          // Resumen de Categorías de Gastos
                                          SizedBox(
                                            width: 120,
                                            child: _buildDashboardMetric(
                                              '🏷️ Cat. Gastos',
                                              _expenseCategories.length.toString(),
                                              'activas',
                                              Colors.orange,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    
                                    // Botón de actualizar
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        onPressed: _loadDashboardData,
                                        icon: const Icon(Icons.refresh),
                                        label: const Text('Actualizar'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.deepPurple,
                                          foregroundColor: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
    }
  }

  // Wrappers simples para las pantallas embedded
  Widget _incomeScreenEmbedded() {
    return const IncomeScreen();
  }

  Widget _expenseScreenEmbedded() {
    return const ExpenseScreen();
  }

  Widget _incomeCategoryScreenEmbedded() {
    return const IncomeCategoryScreen();
  }

  Widget _expenseCategoryScreenEmbedded() {
    return const ExpenseCategoryScreen();
  }

  // ============================================
  // MÉTODO AUXILIAR: Construir tarjeta de información compacta
  // ============================================
  Widget _buildCompactInfoCard(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // MÉTODO AUXILIAR: Construir métrica del dashboard
  // ============================================
  Widget _buildDashboardMetric(
    String title,
    String value,
    String subtitle,
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
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
