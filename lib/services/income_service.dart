import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/income_model.dart';
import '../models/pagination_model.dart';

class IncomeService {
  static final IncomeService _instance = IncomeService._internal();

  factory IncomeService() {
    return _instance;
  }

  IncomeService._internal();

  // ============================================
  // MÉTODO: Obtener lista de ingresos con paginación
  // Aquí se obtienen ingresos paginados del usuario
  // ============================================
  Future<PaginationResponse<Income>> getIncomesPaginated(
    String token, {
    int page = 1,
    int limit = 10,
  }) async {
    try {
      if (token.isEmpty) {
        throw Exception('Token no disponible');
      }

      final response = await http.get(
        Uri.parse(
          '${ApiConfig.baseUrl}${ApiConfig.incomeEndpoint}/?page=$page&limit=$limit',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('Get Incomes Paginated Response Status: ${response.statusCode}');
      debugPrint('Get Incomes Paginated Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        // Manejar respuesta con paginación
        if (jsonData is Map<String, dynamic>) {
          final data = jsonData['data'] as List<dynamic>? ?? [];
          final totalItems = jsonData['total'] as int? ?? data.length;
          final totalPages = jsonData['pages'] as int? ?? 1;

          final incomes = data
              .map((json) => Income.fromJson(json as Map<String, dynamic>))
              .toList();

          return PaginationResponse<Income>(
            data: incomes,
            total: totalItems,
            totalPages: totalPages,
            currentPage: page,
            limit: limit,
            hasNextPage: page < totalPages,
            hasPrevPage: page > 1,
          );
        } else {
          throw Exception('Formato de respuesta inesperado');
        }
      } else {
        throw Exception('Error al obtener ingresos');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // ============================================
  // MÉTODO: Obtener lista de todos los ingresos
  // Aquí se obtienen todos los ingresos del usuario
  // ============================================
  Future<List<Income>> getIncomes(String token) async {
    try {
      if (token.isEmpty) {
        throw Exception('Token no disponible');
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.incomeEndpoint}/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('Get Incomes Response Status: ${response.statusCode}');
      debugPrint('Get Incomes Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        
        // Si la respuesta es un Map con una clave 'data', usar eso
        final List<dynamic> jsonList;
        if (jsonData is Map<String, dynamic> && jsonData.containsKey('data')) {
          jsonList = jsonData['data'] as List<dynamic>;
        } else if (jsonData is List<dynamic>) {
          jsonList = jsonData;
        } else {
          throw Exception('Formato de respuesta inesperado');
        }
        
        return jsonList.map((json) => Income.fromJson(json as Map<String, dynamic>)).toList();
      } else {
        throw Exception('Error al obtener ingresos');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // ============================================
  // MÉTODO: Crear nuevo ingreso
  // Aquí se registra un nuevo ingreso
  // ============================================
  Future<Income> createIncome({
    required String token,
    required double amount,
    required String description,
    required DateTime date,
    required int categoryId,
  }) async {
    try {
      if (token.isEmpty) {
        throw Exception('Token no disponible');
      }

      final body = jsonEncode({
        'amount': amount,
        'categoryId': categoryId,
        'description': description,
        'date': date.toIso8601String().split('T')[0],
      });

      debugPrint('Create Income Request URL: ${ApiConfig.baseUrl}${ApiConfig.incomeEndpoint}/');
      debugPrint('Create Income Request Body: $body');

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.incomeEndpoint}/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: body,
      );

      debugPrint('Create Income Response Status: ${response.statusCode}');
      debugPrint('Create Income Response Body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        // Manejar respuesta con wrapper 'data'
        if (jsonResponse is Map<String, dynamic> && jsonResponse.containsKey('data')) {
          return Income.fromJson(jsonResponse['data'] as Map<String, dynamic>);
        }
        return Income.fromJson(jsonResponse);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Error al crear ingreso');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // ============================================
  // MÉTODO: Actualizar ingreso existente
  // Aquí se edita un ingreso
  // ============================================
  Future<Income> updateIncome({
    required String token,
    required int incomeId,
    required double amount,
    required String description,
    required DateTime date,
    required int categoryId,
  }) async {
    try {
      if (token.isEmpty) {
        throw Exception('Token no disponible');
      }

      final response = await http.patch(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.incomeEndpoint}/$incomeId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'amount': amount,
          'description': description,
          'date': date.toIso8601String().split('T')[0],
          'categoryId': categoryId,
        }),
      );

      debugPrint('Update Income Response Status: ${response.statusCode}');
      debugPrint('Update Income Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return Income.fromJson(jsonResponse);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Error al actualizar ingreso');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // ============================================
  // MÉTODO: Eliminar ingreso
  // Aquí se borra un ingreso del servidor
  // ============================================
  Future<void> deleteIncome({
    required String token,
    required int incomeId,
  }) async {
    try {
      if (token.isEmpty) {
        throw Exception('Token no disponible');
      }

      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.incomeEndpoint}/$incomeId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('Delete Income Response Status: ${response.statusCode}');

      if (response.statusCode != 200) {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Error al eliminar ingreso');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // ============================================
  // MÉTODO: Calcular total de ingresos
  // Aquí se suma todos los montos
  // ============================================
  double calculateTotal(List<Income> incomes) {
    return incomes.fold(0.0, (sum, income) => sum + income.amount);
  }
}
