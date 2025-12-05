import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/user_model.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  
  String? _token;
  User? _currentUser;
  // ============================================
  // Claves para persistencia en localStorage
  // Aquí puedes cambiar los nombres de las claves
  // ============================================
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'auth_user';

  factory AuthService() {
    return _instance;
  }

  AuthService._internal();

  // Getters
  String? get token => _token;
  User? get currentUser => _currentUser;
  bool get isAuthenticated => _token != null && _currentUser != null;

  /// ============================================
  /// MÉTODO: Restaurar sesión desde almacenamiento local
  /// Aquí se cargan los datos guardados al iniciar la app
  /// ============================================
  Future<void> restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString(_tokenKey);
      final userJson = prefs.getString(_userKey);
      
      if (userJson != null) {
        _currentUser = User.fromJson(jsonDecode(userJson));
      }
      
      debugPrint('Sesión restaurada: ${isAuthenticated ? 'Autenticado' : 'No autenticado'}');
    } catch (e) {
      debugPrint('Error al restaurar sesión: $e');
    }
  }

  /// ============================================
  /// MÉTODO: Guardar sesión en almacenamiento local
  /// Aquí se persisten los datos al login
  /// ============================================
  Future<void> _saveSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_token != null) {
        await prefs.setString(_tokenKey, _token!);
      }
      if (_currentUser != null) {
        await prefs.setString(_userKey, jsonEncode(_currentUser!.toJson()));
      }
    } catch (e) {
      debugPrint('Error al guardar sesión: $e');
    }
  }

  /// ============================================
  /// MÉTODO: Limpiar sesión del almacenamiento local
  /// Aquí se eliminan los datos al logout
  /// ============================================
  Future<void> _clearSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.remove(_userKey);
    } catch (e) {
      debugPrint('Error al limpiar sesión: $e');
    }
  }

  /// Login con email y contraseña
  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.loginEndpoint}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      debugPrint('Login Response Status: ${response.statusCode}');
      debugPrint('Login Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        debugPrint('Login JSON Response: $jsonResponse');
        
        final authResponse = AuthResponse.fromJson(jsonResponse);
        
        _token = authResponse.token;
        _currentUser = authResponse.user;
        
        // ============================================
        // Guardar sesión en almacenamiento local
        // ============================================
        await _saveSession();
        
        return authResponse;
      } else if (response.statusCode == 401) {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Email o contraseña incorrectos');
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Error de autenticación');
      }
    } on FormatException catch (e) {
      debugPrint('Format Exception: ${e.message}');
      throw Exception('Error en respuesta del servidor: ${e.message}');
    } catch (e) {
      debugPrint('Login Error: $e');
      throw Exception('Error en login: $e');
    }
  }

  /// Registrar nuevo usuario
  Future<AuthResponse> register({
    required String email,
    required String password,
    required String firstName,
    required String paternalLastName,
    String? maternalLastName,
    required String rut,
    required String birthDate,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.registerEndpoint}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'firstName': firstName,
          'paternalLastName': paternalLastName,
          'maternalLastName': maternalLastName,
          'rut': rut,
          'birthDate': birthDate,
        }),
      );

      if (response.statusCode == 201) {
        final jsonResponse = jsonDecode(response.body);
        final authResponse = AuthResponse.fromJson(jsonResponse);
        
        _token = authResponse.token;
        _currentUser = authResponse.user;
        
        return authResponse;
      } else if (response.statusCode == 400) {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Error en registro');
      } else {
        throw Exception('Error de servidor');
      }
    } catch (e) {
      throw Exception('Error en registro: $e');
    }
  }

  /// Obtener perfil del usuario
  Future<User> getProfile() async {
    try {
      if (_token == null) {
        throw Exception('No hay token de autenticación');
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.profileEndpoint}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        _currentUser = User.fromJson(jsonResponse);
        return _currentUser!;
      } else if (response.statusCode == 401) {
        _token = null;
        _currentUser = null;
        throw Exception('Sesión expirada. Inicia sesión nuevamente');
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Error al obtener perfil');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  /// Actualizar perfil del usuario
  Future<User> updateProfile({
    String? firstName,
    String? paternalLastName,
    String? maternalLastName,
    String? email,
    String? phoneNumber,
    String? birthDate,
  }) async {
    try {
      if (_token == null) {
        throw Exception('No hay token de autenticación');
      }

      final Map<String, dynamic> body = {};
      if (firstName != null) body['firstName'] = firstName;
      if (paternalLastName != null) body['paternalLastName'] = paternalLastName;
      if (maternalLastName != null) body['maternalLastName'] = maternalLastName;
      if (email != null) body['email'] = email;
      if (phoneNumber != null) body['phoneNumber'] = phoneNumber;
      if (birthDate != null) body['birthDate'] = birthDate;

      final response = await http.patch(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.profileEndpoint}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        _currentUser = User.fromJson(jsonResponse['user']);
        return _currentUser!;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Error al actualizar perfil');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  /// Cambiar contraseña
  Future<void> changePassword({
    required String password,
    required String confirmPassword,
    String? currentPassword,
  }) async {
    try {
      if (_token == null) {
        throw Exception('No hay token de autenticación');
      }

      final body = {
        'password': password,
        'confirmPassword': confirmPassword,
      };

      // ============================================
      // Agregar contraseña actual si se proporciona
      // Algunos backends la requieren por seguridad
      // ============================================
      if (currentPassword != null) {
        body['currentPassword'] = currentPassword;
      }

      final response = await http.patch(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.changePasswordEndpoint}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode != 200) {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Error al cambiar contraseña');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  /// Logout
  Future<void> logout() async {
    try {
      if (_token == null) {
        throw Exception('No hay sesión activa');
      }

      await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.logoutEndpoint}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
      );
    } catch (e) {
      // Continue logout even if request fails
    } finally {
      _token = null;
      _currentUser = null;
      // ============================================
      // Limpiar sesión del almacenamiento local
      // ============================================
      await _clearSession();
    }
  }

  /// Eliminar cuenta
  Future<void> deleteAccount() async {
    try {
      if (_token == null) {
        throw Exception('No hay token de autenticación');
      }

      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.deleteAccountEndpoint}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
      );

      if (response.statusCode != 200) {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Error al eliminar cuenta');
      }

      _token = null;
      _currentUser = null;
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  /// Limpiar sesión localmente
  void clearSession() {
    _token = null;
    _currentUser = null;
  }
}
