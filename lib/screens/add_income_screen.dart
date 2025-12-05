import 'package:flutter/material.dart';
import '../models/income_category_model.dart';
import '../services/auth_service.dart';
import '../services/income_service.dart';
import '../services/income_category_service.dart';

class AddIncomeScreen extends StatefulWidget {
  final VoidCallback onIncomeSaved;

  const AddIncomeScreen({
    required this.onIncomeSaved,
    super.key,
  });

  @override
  State<AddIncomeScreen> createState() => _AddIncomeScreenState();
}

class _AddIncomeScreenState extends State<AddIncomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  final _incomeService = IncomeService();
  final _categoryService = IncomeCategoryService();

  // ============================================
  // Controladores de formulario
  // Aquí se guardan los datos del ingreso
  // ============================================
  late TextEditingController _amountController;
  late TextEditingController _descriptionController;
  late TextEditingController _dateController;

  bool _isLoading = false;
  bool _isCategoriesLoading = true;
  String? _errorMessage;
  String? _successMessage;
  DateTime _selectedDate = DateTime.now();
  
  // Variables para categorías
  List<IncomeCategory> _categories = [];
  int? _selectedCategoryId;
  String? _categoryError;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _descriptionController = TextEditingController();
    _dateController = TextEditingController(
      text: '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
    );
    _loadCategories();
  }

  // ============================================
  // MÉTODO: Cargar categorías de ingresos
  // ============================================
  Future<void> _loadCategories() async {
    try {
      // Obtener categorías paginadas y extraer solo las activas
      final response = await _categoryService.getCategories();
      if (mounted) {
        setState(() {
          // Usar .data para acceder a la lista de categorías
          _categories = response.data.where((cat) => cat.isActive).toList();
          _isCategoriesLoading = false;
          if (_categories.isNotEmpty) {
            _selectedCategoryId = _categories.first.id;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _categoryError = e.toString().replaceAll('Exception: ', '');
          _isCategoriesLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  // ============================================
  // MÉTODO: Seleccionar fecha
  // Aquí puedes cambiar el rango de fechas
  // ============================================
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = '${picked.day}/${picked.month}/${picked.year}';
      });
    }
  }

  void _handleSaveIncome() async {
    // ============================================
    // Prevenir doble clic
    // ============================================
    if (_isLoading) {
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCategoryId == null) {
      setState(() {
        _categoryError = 'Debes seleccionar una categoría';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
      _categoryError = null;
    });

    try {
      await _incomeService.createIncome(
        token: _authService.token!,
        amount: double.parse(_amountController.text.trim()),
        description: _descriptionController.text.trim(),
        date: _selectedDate,
        categoryId: _selectedCategoryId!,
      );

      if (mounted) {
        // ============================================
        // Éxito: cerrar el formulario inmediatamente
        // ============================================
        Navigator.pop(context);
        widget.onIncomeSaved();
      }
    } catch (e) {
      if (mounted) {
        // ============================================
        // Error: mostrar mensaje pero mantén botón bloqueado
        // ============================================
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          // NO DESBLOQUEAR: _isLoading se mantiene en true
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isLoading,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Registrar Ingreso'),
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          automaticallyImplyLeading: !_isLoading, // Bloquear botón atrás si está cargando
        ),
        body: SingleChildScrollView(
          child: Center(
            child: Container(
              // ============================================
              // Contenedor del formulario
              // Aquí puedes cambiar el ancho máximo
              // ============================================
              constraints: const BoxConstraints(maxWidth: 450),
              padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ============================================
                  // SECCIÓN: Mensajes de éxito/error
                  // ============================================
                  if (_successMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        border: Border.all(color: Colors.green[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green[700]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _successMessage!,
                              style: TextStyle(color: Colors.green[700]),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        border: Border.all(color: Colors.red[200]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error, color: Colors.red[700]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(color: Colors.red[700]),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ============================================
                  // CAMPO: Monto del ingreso
                  // ============================================
                  Text(
                    'Monto',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                  const SizedBox(height: 8),

                  TextFormField(
                    controller: _amountController,
                    decoration: InputDecoration(
                      labelText: 'Ingresa el monto',
                      prefixIcon: const Icon(Icons.attach_money),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'El monto es requerido';
                      if (int.tryParse(value!) == null) return 'Ingrese un número entero';
                      if (int.parse(value) <= 0) return 'El monto debe ser mayor a 0';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // ============================================
                  // CAMPO: Categoría del ingreso
                  // ============================================
                  Text(
                    'Categoría',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                  const SizedBox(height: 8),

                  if (_isCategoriesLoading)
                    const SizedBox(
                      height: 56,
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (_categoryError != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        border: Border.all(color: Colors.red[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Error: $_categoryError',
                        style: TextStyle(color: Colors.red[700]),
                      ),
                    )
                  else if (_categories.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        border: Border.all(color: Colors.orange[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'No hay categorías disponibles. Crea una en Configuración > Categorías de Ingresos',
                        style: TextStyle(color: Colors.orange[700]),
                      ),
                    )
                  else if (_selectedCategoryId != null)
                    DropdownButtonFormField<int>(
                      initialValue: _selectedCategoryId,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.label),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      items: _categories
                          .map(
                            (category) => DropdownMenuItem<int>(
                              value: category.id,
                              child: Text(category.name),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCategoryId = value;
                          _categoryError = null;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Debes seleccionar una categoría';
                        }
                        return null;
                      },
                    ),
                  const SizedBox(height: 16),
                  Text(
                    'Descripción',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                  const SizedBox(height: 8),

                  TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Ej: Salario, Freelance, etc',
                      prefixIcon: const Icon(Icons.description),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    maxLines: 2,
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'La descripción es requerida';
                      if (value!.length < 3) return 'Mínimo 3 caracteres';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // ============================================
                  // CAMPO: Fecha del ingreso
                  // ============================================
                  Text(
                    'Fecha',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                  const SizedBox(height: 8),

                  TextFormField(
                    controller: _dateController,
                    decoration: InputDecoration(
                      labelText: 'Selecciona la fecha',
                      prefixIcon: const Icon(Icons.calendar_today),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: () => _selectDate(context),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    readOnly: true,
                  ),
                  const SizedBox(height: 32),

                  // ============================================
                  // BOTONES: Guardar y Cancelar
                  // ============================================
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleSaveIncome,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        disabledBackgroundColor: Colors.grey[300],
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                          : const Text(
                        'Registrar Ingreso',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: _isLoading ? Colors.grey[300]! : Colors.deepPurple),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      ),
    );
  }
}
