import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

class EditProfileScreen extends StatefulWidget {
  final User user;
  final VoidCallback onProfileUpdated;

  const EditProfileScreen({
    required this.user,
    required this.onProfileUpdated,
    super.key,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();

  late TextEditingController _emailController;
  late TextEditingController _firstNameController;
  late TextEditingController _paternalLastNameController;
  late TextEditingController _maternalLastNameController;
  late TextEditingController _phoneNumberController;
  late TextEditingController _birthDateController;

  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _emailController = TextEditingController(text: widget.user.email);
    _firstNameController = TextEditingController(text: widget.user.firstName);
    _paternalLastNameController =
        TextEditingController(text: widget.user.paternalLastName ?? '');
    _maternalLastNameController =
        TextEditingController(text: widget.user.maternalLastName ?? '');
    _phoneNumberController =
        TextEditingController(text: widget.user.phoneNumber ?? '');
    _birthDateController = TextEditingController(
      text: widget.user.birthDate != null
          ? '${widget.user.birthDate!.year}-${widget.user.birthDate!.month.toString().padLeft(2, '0')}-${widget.user.birthDate!.day.toString().padLeft(2, '0')}'
          : '',
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _firstNameController.dispose();
    _paternalLastNameController.dispose();
    _maternalLastNameController.dispose();
    _phoneNumberController.dispose();
    _birthDateController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: widget.user.birthDate ?? DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _birthDateController.text =
            '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  void _handleSaveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      await _authService.updateProfile(
        firstName: _firstNameController.text.trim(),
        paternalLastName: _paternalLastNameController.text.trim(),
        maternalLastName: _maternalLastNameController.text.trim().isEmpty
            ? null
            : _maternalLastNameController.text.trim(),
        email: _emailController.text.trim(),
        phoneNumber: _phoneNumberController.text.trim().isEmpty
            ? null
            : _phoneNumberController.text.trim(),
        birthDate: _birthDateController.text.isEmpty
            ? null
            : _birthDateController.text,
      );

      if (mounted) {
        setState(() {
          _successMessage = '✅ Perfil actualizado correctamente';
          _isLoading = false;
        });

        // Mostrar snackbar y volver
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pop(context);
            widget.onProfileUpdated();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Perfil'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            // ============================================
            // CONTENEDOR PRINCIPAL: Aquí puedes cambiar el ancho máximo del formulario
            // Aumenta maxWidth para que sea más ancho (ej: 500)
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
                  // Aquí puedes cambiar los colores y estilos
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
                  // SECCIÓN: Información Personal
                  // Aquí puedes agregar más campos si es necesario
                  // ============================================
                  Text(
                    'Información Personal',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Email
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Correo Electrónico',
                      prefixIcon: const Icon(Icons.email),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'El correo es requerido';
                      if (!value!.contains('@')) return 'Ingresa un correo válido';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // First Name
                  TextFormField(
                    controller: _firstNameController,
                    decoration: InputDecoration(
                      labelText: 'Nombre',
                      prefixIcon: const Icon(Icons.person),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'El nombre es requerido';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Paternal Last Name
                  TextFormField(
                    controller: _paternalLastNameController,
                    decoration: InputDecoration(
                      labelText: 'Apellido Paterno',
                      prefixIcon: const Icon(Icons.person),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'El apellido paterno es requerido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Maternal Last Name
                  TextFormField(
                    controller: _maternalLastNameController,
                    decoration: InputDecoration(
                      labelText: 'Apellido Materno (Opcional)',
                      prefixIcon: const Icon(Icons.person),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ============================================
                  // SECCIÓN: Información de Contacto
                  // Aquí puedes agregar más campos de contacto
                  // ============================================
                  Text(
                    'Información de Contacto',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Phone Number
                  TextFormField(
                    controller: _phoneNumberController,
                    decoration: InputDecoration(
                      labelText: 'Teléfono (Opcional)',
                      prefixIcon: const Icon(Icons.phone),
                      hintText: '+56912345678',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        if (value.length < 7 || value.length > 20) {
                          return 'El teléfono debe tener entre 7 y 20 caracteres';
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Birth Date
                  TextFormField(
                    controller: _birthDateController,
                    decoration: InputDecoration(
                      labelText: 'Fecha de Nacimiento (Opcional)',
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
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        try {
                          DateTime.parse(value);
                        } catch (e) {
                          return 'Fecha inválida';
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),

                  // ============================================
                  // SECCIÓN: Botones de acción
                  // Aquí puedes cambiar los colores y estilos de los botones
                  // ============================================
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleSaveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
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
                        'Guardar Cambios',
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
                        side: const BorderSide(color: Colors.deepPurple),
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
    );
  }
}
