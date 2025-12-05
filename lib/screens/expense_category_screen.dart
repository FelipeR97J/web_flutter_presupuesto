  import 'package:flutter/material.dart';
  import '../models/expense_category_model.dart';
  import '../services/expense_category_service.dart';
  import '../services/auth_service.dart';
  import '../widgets/pagination_controls.dart';
  import '../widgets/category_form_dialog.dart';class ExpenseCategoryScreen extends StatefulWidget {
  const ExpenseCategoryScreen({super.key});

  @override
  State<ExpenseCategoryScreen> createState() => _ExpenseCategoryScreenState();
}

  class _ExpenseCategoryScreenState extends State<ExpenseCategoryScreen> {
    late ExpenseCategoryService _categoryService;
    late AuthService _authService;
    List<ExpenseCategory> _categories = [];
    bool _isLoading = false;
    String? _errorMessage;
    
    // Paginación
    int _currentPage = 1;
    int _totalPages = 1;
    final int _pageSize = 10;
    bool _isPaginationLoading = false;  @override
  void initState() {
    super.initState();
    _categoryService = ExpenseCategoryService();
    _authService = AuthService();
    _loadCategories();
  }

    Future<void> _loadCategories({int page = 1}) async {
      setState(() {
        _isLoading = true;
        _isPaginationLoading = true;
        _errorMessage = null;
      });

      try {
        final response = await _categoryService.getCategories(
          page: page,
          limit: _pageSize,
          sortBy: 'isActive,name',
          sortOrder: 'desc,asc',
        );
        
        if (mounted) {
          setState(() {
            _categories = response.data;
            _currentPage = page;
            _totalPages = response.totalPages;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _errorMessage = e.toString().replaceAll('Exception: ', '');
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

  void _navigateToAddCategory() {
    showDialog(
      context: context,
      builder: (dialogContext) => CategoryFormDialog(
        title: 'Nueva Categoría de Gasto',
        onSave: (name, description, isActive) async {
          final token = _authService.token;
          if (token == null) {
            throw Exception('No hay sesión activa');
          }

          // Guardar referencia al ScaffoldMessenger ANTES del await
          final scaffoldMessenger = ScaffoldMessenger.of(context);

          await _categoryService.createCategory(
            token,
            name,
            description,
          );

          if (mounted) {
            scaffoldMessenger.showMaterialBanner(
              MaterialBanner(
                content: const Text('Categoría creada exitosamente'),
                leading: const Icon(Icons.check_circle, color: Colors.green),
                backgroundColor: Colors.green[50],
                actions: [
                  TextButton(
                    onPressed: () => scaffoldMessenger.clearMaterialBanners(),
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
            _loadCategories();
          }
        },
      ),
    );
  }

  // Método público para ser llamado desde GlobalKey
  void openAddCategoryDialog() => _navigateToAddCategory();

  void _navigateToEditCategory(ExpenseCategory category) {
    showDialog(
      context: context,
      builder: (dialogContext) => CategoryFormDialog(
        title: 'Editar Categoría de Gasto',
        initialName: category.name,
        initialDescription: category.description,
        isActive: category.isActive,
        onSave: (name, description, isActive) async {
          final token = _authService.token;
          if (token == null) {
            throw Exception('No hay sesión activa');
          }

          await _categoryService.updateCategory(
            token,
            category.id,
            name,
            description,
          );

          // Si el estado cambió, actualizar estado
          if (isActive != category.isActive) {
            final newStatus = isActive ? 1 : 2;
            await _categoryService.updateCategoryStatus(
              token,
              category.id,
              newStatus,
            );
          }

          if (mounted) {
            final scaffoldMessenger = ScaffoldMessenger.of(context);
            scaffoldMessenger.showMaterialBanner(
              MaterialBanner(
                content: const Text('Categoría actualizada exitosamente'),
                leading: const Icon(Icons.check_circle, color: Colors.green),
                backgroundColor: Colors.green[50],
                actions: [
                  TextButton(
                    onPressed: () => scaffoldMessenger.clearMaterialBanners(),
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
            _loadCategories();
          }
        },
      ),
    );
  }

    Future<void> _handleDeactivateCategory(ExpenseCategory category) async {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Inactivar Categoría'),
          content: Text(
            '¿Estás seguro de que deseas inactivar la categoría "${category.name}"?\n\n'
            'Los gastos existentes seguirán usando esta categoría, pero no podrás crear nuevos gastos con ella.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Inactivar'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        try {
          final token = _authService.token;
          if (token == null) {
            if (mounted) {
              ScaffoldMessenger.of(context).showMaterialBanner(
                MaterialBanner(
                  content: const Text('No hay sesión activa'),
                  leading: const Icon(Icons.error_outline, color: Colors.red),
                  backgroundColor: Colors.red[50],
                  actions: [
                    TextButton(
                      onPressed: () => ScaffoldMessenger.of(context).clearMaterialBanners(),
                      child: const Text('Descartar'),
                    ),
                  ],
                ),
              );
            }
            return;
          }

          await _categoryService.deactivateCategory(token, category.id);
          _loadCategories();

          if (mounted) {
            final scaffoldMessenger = ScaffoldMessenger.of(context);
            scaffoldMessenger.showMaterialBanner(
              MaterialBanner(
                content: const Text('Categoría inactivada exitosamente'),
                leading: const Icon(Icons.info, color: Colors.orange),
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
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showMaterialBanner(
              MaterialBanner(
                content: Text(e.toString().replaceAll('Exception: ', '')),
                leading: const Icon(Icons.error_outline, color: Colors.red),
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
          }
        }
      }
    }

    Future<void> _handleDeleteCategory(ExpenseCategory category) async {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Eliminar Categoría'),
          content: Text(
            '¿Estás seguro de que deseas eliminar la categoría "${category.name}"?\n\n'
            'Esta acción no se puede deshacer.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        try {
          final token = _authService.token;
          if (token == null) {
            if (mounted) {
              ScaffoldMessenger.of(context).showMaterialBanner(
                MaterialBanner(
                  content: const Text('No hay sesión activa'),
                  leading: const Icon(Icons.error_outline, color: Colors.red),
                  backgroundColor: Colors.red[50],
                  actions: [
                    TextButton(
                      onPressed: () => ScaffoldMessenger.of(context).clearMaterialBanners(),
                      child: const Text('Descartar'),
                    ),
                  ],
                ),
              );
            }
            return;
          }

          await _categoryService.deleteCategory(token, category.id);
          _loadCategories();

          if (mounted) {
            final scaffoldMessenger = ScaffoldMessenger.of(context);
            scaffoldMessenger.showMaterialBanner(
              MaterialBanner(
                content: const Text('Categoría eliminada exitosamente'),
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
            ScaffoldMessenger.of(context).showMaterialBanner(
              MaterialBanner(
                content: Text(e.toString().replaceAll('Exception: ', '')),
                leading: const Icon(Icons.error_outline, color: Colors.red),
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
          }
        }
      }
    }    @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Categorías de Gastos'),
          backgroundColor: const Color(0xFF00897B),
          elevation: 2,
          shadowColor: const Color(0xFF00897B).withValues(alpha: 0.5),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: ElevatedButton.icon(
                onPressed: _navigateToAddCategory,
                icon: const Icon(Icons.add, size: 20),
                label: const Text('Nueva'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF00897B),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
            ),
          ],
        ),
        body: _buildBody(),
      );
    }  Widget _buildBody() {
    if (_isLoading) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.red[300],
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadCategories,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    if (_categories.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(40),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.label_outline,
                size: 80,
                color: Colors.grey[300],
              ),
              const SizedBox(height: 24),
              Text(
                'Aún no hay categorías',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Crea tu primera categoría para\norganizar tus gastos',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 40),
                ElevatedButton.icon(
                  onPressed: _navigateToAddCategory,
                  icon: const Icon(Icons.add),
                  label: const Text('Crear Primera Categoría'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6200EE),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }    // Calcular rango de registros mostrados
      return Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ListView.builder(
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: Icon(
                        Icons.label_outline,
                        color: category.isActive ? const Color(0xFF00897B) : Colors.grey,
                      ),
                      title: Text(category.name),
                      subtitle: Text(
                        category.description ?? 'Sin descripción',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Wrap(
                        spacing: 8,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, size: 20),
                            onPressed: () => _navigateToEditCategory(category),
                          ),
                          if (category.isActive)
                            IconButton(
                              icon: const Icon(Icons.close, size: 20, color: Colors.red),
                              onPressed: () => _handleDeactivateCategory(category),
                            ),
                          IconButton(
                            icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                            onPressed: () => _handleDeleteCategory(category),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          if (_totalPages > 1)
            PaginationControls(
              currentPage: _currentPage,
              totalPages: _totalPages,
              isLoading: _isPaginationLoading,
              onPreviousPage: _currentPage > 1
                  ? () => _loadCategories(page: _currentPage - 1)
                  : () {},
              onNextPage: _currentPage < _totalPages
                  ? () => _loadCategories(page: _currentPage + 1)
                  : () {},
            ),
        ],
      );
    }
  }


class AddExpenseCategoryScreen extends StatefulWidget {
  const AddExpenseCategoryScreen({super.key});

  @override
  State<AddExpenseCategoryScreen> createState() =>
      _AddExpenseCategoryScreenState();
}

class _AddExpenseCategoryScreenState extends State<AddExpenseCategoryScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late ExpenseCategoryService _categoryService;
  late AuthService _authService;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
    _categoryService = ExpenseCategoryService();
    _authService = AuthService();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleCreateCategory() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = _authService.token;
      if (token == null) {
        throw Exception('No hay sesión activa');
      }

      await _categoryService.createCategory(
        token,
        _nameController.text.trim(),
        _descriptionController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showMaterialBanner(
          MaterialBanner(
            content: const Text('Categoría creada exitosamente'),
            leading: const Icon(Icons.check_circle, color: Colors.green),
            backgroundColor: Colors.green[50],
            actions: [
              TextButton(
                onPressed: () => ScaffoldMessenger.of(context).clearMaterialBanners(),
                child: const Text('Descartar'),
              ),
            ],
          ),
        );
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            Navigator.pop(context, true);
          }
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva Categoría de Gasto'),
        backgroundColor: const Color(0xFF6200EE),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 450),
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        border: Border.all(color: Colors.red[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red[700]),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(color: Colors.red[700]),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Nombre de la Categoría',
                      hintText: 'Ej: Alimentación, Transporte, etc',
                      prefixIcon: const Icon(Icons.label),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'El nombre es requerido';
                      }
                      if (value.length < 3) {
                        return 'El nombre debe tener al menos 3 caracteres';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Descripción (Opcional)',
                      hintText: 'Ej: Compras de comida y supermercado',
                      prefixIcon: const Icon(Icons.description),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleCreateCategory,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6200EE),
                        disabledBackgroundColor: Colors.grey[300],
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Crear Categoría',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
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
    );
  }
}

class EditExpenseCategoryScreen extends StatefulWidget {
  final ExpenseCategory category;

  const EditExpenseCategoryScreen({
    super.key,
    required this.category,
  });

  @override
  State<EditExpenseCategoryScreen> createState() =>
      _EditExpenseCategoryScreenState();
}

class _EditExpenseCategoryScreenState extends State<EditExpenseCategoryScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late ExpenseCategoryService _categoryService;
  late AuthService _authService;
  bool _isLoading = false;
  String? _errorMessage;
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category.name);
    _descriptionController =
        TextEditingController(text: widget.category.description);
    _categoryService = ExpenseCategoryService();
    _authService = AuthService();
    _isActive = widget.category.isActive;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleUpdateCategory() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = _authService.token;
      if (token == null) {
        throw Exception('No hay sesión activa');
      }

      await _categoryService.updateCategory(
        token,
        widget.category.id,
        _nameController.text.trim(),
        _descriptionController.text.trim(),
      );

      // Si el estado cambió, actualizar estado
      if (_isActive != widget.category.isActive) {
        final newStatus = _isActive ? 1 : 2;
        await _categoryService.updateCategoryStatus(token, widget.category.id, newStatus);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showMaterialBanner(
          MaterialBanner(
            content: const Text('Categoría actualizada exitosamente'),
            leading: const Icon(Icons.check_circle, color: Colors.green),
            backgroundColor: Colors.green[50],
            actions: [
              TextButton(
                onPressed: () => ScaffoldMessenger.of(context).clearMaterialBanners(),
                child: const Text('Descartar'),
              ),
            ],
          ),
        );
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            Navigator.pop(context, true);
          }
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Categoría de Gasto'),
        backgroundColor: const Color(0xFF6200EE),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 450),
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        border: Border.all(color: Colors.red[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red[700]),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(color: Colors.red[700]),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Nombre de la Categoría',
                      hintText: 'Ej: Alimentación, Transporte, etc',
                      prefixIcon: const Icon(Icons.label),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'El nombre es requerido';
                      }
                      if (value.length < 3) {
                        return 'El nombre debe tener al menos 3 caracteres';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Descripción (Opcional)',
                      hintText: 'Ej: Compras de comida y supermercado',
                      prefixIcon: const Icon(Icons.description),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),
                  // ============================================
                  // Estado: Activo/Inactivo
                  // ============================================
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _isActive ? Colors.green[50] : Colors.orange[50],
                      border: Border.all(
                        color: _isActive ? Colors.green[300]! : Colors.orange[300]!,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Estado de la Categoría',
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _isActive
                                    ? 'Activa - Puedes crear nuevos gastos'
                                    : 'Inactiva - No puedes crear nuevos gastos',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Switch(
                          value: _isActive,
                          onChanged: (value) {
                            setState(() {
                              _isActive = value;
                            });
                          },
                          activeThumbColor: Colors.green,
                          inactiveThumbColor: Colors.orange,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleUpdateCategory,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6200EE),
                        disabledBackgroundColor: Colors.grey[300],
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Guardar Cambios',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
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
    );
  }
}
