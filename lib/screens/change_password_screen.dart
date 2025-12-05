import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class ChangePasswordScreen extends StatefulWidget {
  final VoidCallback onPasswordChanged;
  final VoidCallback onLogoutRequired;

  const ChangePasswordScreen({
    required this.onPasswordChanged,
    required this.onLogoutRequired,
    super.key,
  });

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();

  // ============================================
  // Controladores para los campos de contraseña
  // Aquí puedes agregar más validaciones si es necesario
  // ============================================
  late TextEditingController _currentPasswordController;
  late TextEditingController _newPasswordController;
  late TextEditingController _confirmPasswordController;

  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;

  @override
  void initState() {
    super.initState();
    _currentPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ============================================
  // MÉTODO: Validar la nueva contraseña
  // Aquí puedes cambiar los requisitos mínimos
  // ============================================
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'La contraseña es requerida';
    }
    if (value.length < 6) {
      return 'Mínimo 6 caracteres';
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Debe contener al menos una mayúscula';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Debe contener al menos un número';
    }
    return null;
  }

  void _handleChangePassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // ============================================
    // Validar que las contraseñas coincidan
    // ============================================
    if (_newPasswordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = 'Las nuevas contraseñas no coinciden';
      });
      return;
    }

    // ============================================
    // Validar que la nueva contraseña sea diferente
    // ============================================
    if (_currentPasswordController.text == _newPasswordController.text) {
      setState(() {
        _errorMessage =
            'La nueva contraseña debe ser diferente a la actual';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      await _authService.changePassword(
        password: _newPasswordController.text,
        confirmPassword: _confirmPasswordController.text,
        currentPassword: _currentPasswordController.text,
      );

      if (mounted) {
        setState(() {
          _successMessage = '✅ Contraseña actualizada correctamente';
          _isLoading = false;
        });

        // ============================================
        // Logout automático después de cambiar contraseña
        // Por seguridad, el usuario debe volver a autenticarse
        // ============================================
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            // Limpiar sesión
            _authService.clearSession();
            // Ejecutar logout callback
            Navigator.pop(context);
            widget.onLogoutRequired();
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
        title: const Text('Cambiar Contraseña'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            // ============================================
            // CONTENEDOR PRINCIPAL: Aquí puedes cambiar el ancho máximo
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
                  // Aquí puedes cambiar los colores de los mensajes
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
                  // SECCIÓN: Información y advertencia
                  // Aquí puedes cambiar el texto informativo
                  // ============================================
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      border: Border.all(color: Colors.blue[200]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue[700]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Por seguridad, ingresa tu contraseña actual',
                            style: TextStyle(
                              color: Colors.blue[700],
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ============================================
                  // SECCIÓN: Contraseña actual
                  // ============================================
                  Text(
                    'Contraseña Actual',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                  const SizedBox(height: 8),

                  TextFormField(
                    controller: _currentPasswordController,
                    obscureText: !_showCurrentPassword,
                    decoration: InputDecoration(
                      labelText: 'Ingresa tu contraseña actual',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _showCurrentPassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _showCurrentPassword = !_showCurrentPassword;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'La contraseña actual es requerida';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // ============================================
                  // SECCIÓN: Nueva contraseña
                  // Aquí se validan los requisitos de seguridad
                  // ============================================
                  Text(
                    'Nueva Contraseña',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                  const SizedBox(height: 8),

                  TextFormField(
                    controller: _newPasswordController,
                    obscureText: !_showNewPassword,
                    decoration: InputDecoration(
                      labelText: 'Ingresa una nueva contraseña',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _showNewPassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _showNewPassword = !_showNewPassword;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                      helperText: 'Mín. 6 caracteres, 1 mayúscula, 1 número',
                      helperMaxLines: 2,
                    ),
                    validator: _validatePassword,
                  ),
                  const SizedBox(height: 16),

                  // ============================================
                  // SECCIÓN: Confirmar nueva contraseña
                  // ============================================
                  Text(
                    'Confirmar Nueva Contraseña',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                  const SizedBox(height: 8),

                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: !_showConfirmPassword,
                    decoration: InputDecoration(
                      labelText: 'Confirma tu nueva contraseña',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _showConfirmPassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _showConfirmPassword = !_showConfirmPassword;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Confirma tu nueva contraseña';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),

                  // ============================================
                  // SECCIÓN: Botones de acción
                  // Aquí puedes cambiar los colores de los botones
                  // ============================================
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleChangePassword,
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
                        'Cambiar Contraseña',
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
