  import 'package:flutter/material.dart';
  import '../models/income_category_model.dart';
  import '../services/income_category_service.dart';
  import '../services/auth_service.dart';
  import '../widgets/pagination_controls.dart';
  import '../widgets/category_form_dialog.dart';

  class IncomeCategoryScreen extends StatefulWidget {
    const IncomeCategoryScreen({super.key});

    @override
    State<IncomeCategoryScreen> createState() => _IncomeCategoryScreenState();
  }

  class _IncomeCategoryScreenState extends State<IncomeCategoryScreen> {
    late IncomeCategoryService _categoryService;
    late AuthService _authService;
    List<IncomeCategory> _categories = [];
    bool _isLoading = false;
    String? _errorMessage;
    
    // Paginación
    int _currentPage = 1;
    int _totalPages = 1;
    final int _pageSize = 10;
    bool _isPaginationLoading = false;

    @override
    void initState() {
      super.initState();
      _categoryService = IncomeCategoryService();
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
          title: 'Nueva Categoría de Ingreso',
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
              _loadCategories();
            }
          },
        ),
      );
    }

    // Método público para ser llamado desde GlobalKey
    void openAddCategoryDialog() => _navigateToAddCategory();

    void _navigateToEditCategory(IncomeCategory category) {
      showDialog(
        context: context,
        builder: (dialogContext) => CategoryFormDialog(
          title: 'Editar Categoría de Ingreso',
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
              _loadCategories();
            }
          },
        ),
      );
    }

    Future<void> _handleDeactivateCategory(IncomeCategory category) async {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Inactivar Categoría'),
          content: Text(
            '¿Estás seguro de que deseas inactivar la categoría "${category.name}"?\n\n'
            'Los ingresos existentes seguirán usando esta categoría, pero no podrás crear nuevos ingresos con ella.',
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

    Future<void> _handleDeleteCategory(IncomeCategory category) async {
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
    }

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Categorías de Ingresos'),
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
    }

    Widget _buildBody() {
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
                  'Crea tu primera categoría para\norganizar tus ingresos',
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
      }

      return Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  return _buildCategoryCard(_categories[index]);
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

  Widget _buildCategoryCard(IncomeCategory category) {
    final color = _getColorForCategory(category.name);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _navigateToEditCategory(category),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: category.isActive ? color.withOpacity(0.1) : Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    category.isActive ? Icons.attach_money : Icons.money_off,
                    color: category.isActive ? color : Colors.grey,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: category.isActive ? Colors.black87 : Colors.grey,
                          decoration: category.isActive ? null : TextDecoration.lineThrough,
                        ),
                      ),
                      if (category.description != null && category.description!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            category.description!,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.blueGrey),
                        tooltip: 'Editar',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => _navigateToEditCategory(category),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                        icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                        tooltip: 'Eliminar',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => _handleDeleteCategory(category),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getColorForCategory(String name) {
    final colors = [
      Colors.green, Colors.teal, Colors.lightGreen, Colors.lime, 
      Colors.cyan, Colors.blue, Colors.indigo, Colors.purple,
      Colors.amber, Colors.orange, Colors.deepOrange, Colors.brown
    ];
    return colors[name.hashCode.abs() % colors.length];
  }
}
  
  class AddIncomeCategoryScreen extends StatefulWidget {
    const AddIncomeCategoryScreen({super.key});

    @override
    State<AddIncomeCategoryScreen> createState() => _AddIncomeCategoryScreenState();
  }

  class _AddIncomeCategoryScreenState extends State<AddIncomeCategoryScreen> {
    final _formKey = GlobalKey<FormState>();
    late TextEditingController _nameController;
    late TextEditingController _descriptionController;
    late IncomeCategoryService _categoryService;
    late AuthService _authService;
    bool _isLoading = false;
    String? _errorMessage;

    @override
    void initState() {
      super.initState();
      _nameController = TextEditingController();
      _descriptionController = TextEditingController();
      _categoryService = IncomeCategoryService();
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
          title: const Text('Nueva Categoría de Ingreso'),
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
                        hintText: 'Ej: Salario, Bonus, etc',
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
                        hintText: 'Ej: Sueldo del trabajo principal',
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

  class EditIncomeCategoryScreen extends StatefulWidget {
    final IncomeCategory category;

    const EditIncomeCategoryScreen({
      super.key,
      required this.category,
    });

    @override
    State<EditIncomeCategoryScreen> createState() =>
        _EditIncomeCategoryScreenState();
  }

  class _EditIncomeCategoryScreenState extends State<EditIncomeCategoryScreen> {
    final _formKey = GlobalKey<FormState>();
    late TextEditingController _nameController;
    late TextEditingController _descriptionController;
    late IncomeCategoryService _categoryService;
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
      _categoryService = IncomeCategoryService();
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
          title: const Text('Editar Categoría de Ingreso'),
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
                        hintText: 'Ej: Salario, Bonus, etc',
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
                        hintText: 'Ej: Sueldo del trabajo principal',
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
                                      ? 'Activa - Puedes crear nuevos ingresos'
                                      : 'Inactiva - No puedes crear nuevos ingresos',
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
