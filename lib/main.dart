import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'services/auth_service.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  await initializeDateFormatting('es_ES', null);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Finanzas & Inventario',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final _authService = AuthService();
  bool _showLogin = true;
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    // ============================================
    // Restaurar sesión al iniciar la aplicación
    // Esto permite mantener la sesión al refrescar la página
    // ============================================
    _restoreSessionAndNavigate();
  }

  Future<void> _restoreSessionAndNavigate() async {
    await _authService.restoreSession();
    if (mounted) {
      setState(() {
        _isInitializing = false;
        _showLogin = !_authService.isAuthenticated;
      });
    }
  }

  void _handleLoginSuccess() {
    setState(() {
      _showLogin = false;
    });
  }

  void _handleLogout() {
    setState(() {
      _showLogin = true;
    });
  }

  void _navigateToLogin() {
    setState(() {
      _showLogin = true;
    });
  }

  void _navigateToRegister() {
    setState(() {
      _showLogin = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // ============================================
    // Mostrar pantalla de carga mientras se restaura la sesión
    // ============================================
    if (_isInitializing) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
          ),
        ),
      );
    }

    // Check if user is already authenticated
    if (_authService.isAuthenticated && !_showLogin) {
      return HomeScreen(onLogout: _handleLogout);
    }

    if (_showLogin) {
      return LoginScreen(
        onLoginSuccess: _handleLoginSuccess,
        onNavigateToRegister: _navigateToRegister,
      );
    } else {
      return RegisterScreen(
        onRegisterSuccess: _handleLoginSuccess,
        onNavigateToLogin: _navigateToLogin,
      );
    }
  }
}
