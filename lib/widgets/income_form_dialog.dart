import 'package:flutter/material.dart';
import '../models/income_model.dart';
import '../models/income_category_model.dart';
import '../services/auth_service.dart';
import '../services/income_service.dart';
import '../services/income_category_service.dart';

class IncomeFormDialog extends StatefulWidget {
  final Income? income; // null si es crear, completo si es editar
  final VoidCallback onIncomeSaved;

  const IncomeFormDialog({
    this.income,
    required this.onIncomeSaved,
    super.key,
  });

  @override
  State<IncomeFormDialog> createState() => _IncomeFormDialogState();
}

class _IncomeFormDialogState extends State<IncomeFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  final _incomeService = IncomeService();
  final _categoryService = IncomeCategoryService();

  late TextEditingController _amountController;
  late TextEditingController _descriptionController;
  late TextEditingController _dateController;

  bool _isLoading = false;
  bool _isCategoriesLoading = true;
  String? _errorMessage;
  String? _successMessage;
  late DateTime _selectedDate;

  List<IncomeCategory> _categories = [];
  late int _selectedCategoryId;
  String? _categoryError;

  bool get _isEditing => widget.income != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _selectedDate = widget.income!.date;
      _amountController = TextEditingController(text: widget.income!.amount.toString());
      _descriptionController = TextEditingController(text: widget.income!.description);
      _dateController = TextEditingController(text: widget.income!.formattedDate);
      _selectedCategoryId = widget.income!.categoryId;
    } else {
      _selectedDate = DateTime.now();
      _amountController = TextEditingController();
      _descriptionController = TextEditingController();
      _dateController = TextEditingController(
        text: '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
      );
      _selectedCategoryId = 0;
    }
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final response = await _categoryService.getCategories();
      if (mounted) {
        setState(() {
          _categories = response.data.where((cat) => cat.isActive).toList();
          _isCategoriesLoading = false;
          if (!_categories.any((cat) => cat.id == _selectedCategoryId) && _selectedCategoryId == 0) {
            if (_categories.isNotEmpty) {
              _selectedCategoryId = _categories.first.id;
            }
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
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCategoryId == 0 || !_categories.any((cat) => cat.id == _selectedCategoryId)) {
      setState(() {
        _categoryError = 'Debes seleccionar una categoría válida';
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
      if (_isEditing) {
        await _incomeService.updateIncome(
          token: _authService.token!,
          incomeId: widget.income!.id,
          amount: double.parse(_amountController.text.trim()),
          description: _descriptionController.text.trim(),
          date: _selectedDate,
          categoryId: _selectedCategoryId,
        );
      } else {
        await _incomeService.createIncome(
          token: _authService.token!,
          amount: double.parse(_amountController.text.trim()),
          categoryId: _selectedCategoryId,
          description: _descriptionController.text.trim(),
          date: _selectedDate,
        );
      }

      // ============================================
      // Éxito: cerrar inmediatamente SIN setState
      // Llamar onIncomeSaved DESPUÉS de cerrar para evitar rebuilds
      // ============================================
      if (mounted) {
        Navigator.pop(context, true); // Devolver true para indicar éxito
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false; // Desbloquear el botón para reintentar
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Título
                Text(
                  _isEditing ? 'Editar Ingreso' : 'Agregar Ingreso',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
                const SizedBox(height: 16),

                // Mensajes
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

                // Monto
                Text(
                  'Monto',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green[600],
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _amountController,
                  decoration: InputDecoration(
                    labelText: 'Ingresa el monto',
                    prefixIcon: const Icon(Icons.attach_money),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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

                // Categoría
                Text(
                  'Categoría',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green[600],
                  ),
                ),
                const SizedBox(height: 8),
                if (_isCategoriesLoading)
                  const SizedBox(
                    height: 56,
                    child: Center(child: CircularProgressIndicator()),
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
                else
                  DropdownButtonFormField<int>(
                    initialValue: _selectedCategoryId,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.label),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    items: _categories
                        .map((category) => DropdownMenuItem<int>(
                          value: category.id,
                          child: Text(category.name),
                        ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCategoryId = value ?? _selectedCategoryId;
                        _categoryError = null;
                      });
                    },
                    validator: (value) {
                      if (value == null) return 'Debes seleccionar una categoría';
                      return null;
                    },
                  ),
                const SizedBox(height: 16),

                // Descripción
                Text(
                  'Descripción',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green[600],
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Ej: Salario, Venta, etc',
                    prefixIcon: const Icon(Icons.description),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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

                // Fecha
                Text(
                  'Fecha',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green[600],
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
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  readOnly: true,
                ),
                const SizedBox(height: 24),

                // Botones
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _handleSaveIncome,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[600],
                        disabledBackgroundColor: Colors.grey[300],
                      ),
                      child: _isLoading
                          ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                          : const Text(
                        'Crear Ingreso',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            ),
          ),
        ),
      ),
    );
  }
}
