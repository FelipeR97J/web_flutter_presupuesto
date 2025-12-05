import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/expense_model.dart';
import '../models/pagination_model.dart';

class ExpenseService {
  static final ExpenseService _instance = ExpenseService._internal();

  factory ExpenseService() {
    return _instance;
  }

  ExpenseService._internal();

  // ============================================
  // MÉTODO: Obtener lista de gastos con paginación
  // Aquí se obtienen gastos paginados del usuario
  // ============================================
  Future<PaginationResponse<Expense>> getExpensesPaginated(
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
          '${ApiConfig.baseUrl}${ApiConfig.expenseEndpoint}/?page=$page&limit=$limit',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('Get Expenses Paginated Response Status: ${response.statusCode}');
      debugPrint('Get Expenses Paginated Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        // Manejar respuesta con paginación
        if (jsonData is Map<String, dynamic>) {
          final data = jsonData['data'] as List<dynamic>? ?? [];
          final totalItems = jsonData['total'] as int? ?? data.length;
          final totalPages = jsonData['pages'] as int? ?? 1;

          final expenses = data
              .map((json) => Expense.fromJson(json as Map<String, dynamic>))
              .toList();

          return PaginationResponse<Expense>(
            data: expenses,
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
        throw Exception('Error al obtener gastos');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // ============================================
  // MÉTODO: Obtener lista de todos los gastos
  // Aquí se obtienen todos los gastos del usuario
  // ============================================
  Future<List<Expense>> getExpenses(String token) async {
    try {
      if (token.isEmpty) {
        throw Exception('Token no disponible');
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.expenseEndpoint}/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('Get Expenses Response Status: ${response.statusCode}');
      debugPrint('Get Expenses Response Body: ${response.body}');

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
        
        return jsonList.map((json) => Expense.fromJson(json as Map<String, dynamic>)).toList();
      } else {
        throw Exception('Error al obtener gastos');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // ============================================
  // MÉTODO: Crear nuevo gasto
  // Aquí se registra un nuevo gasto
  // ============================================
  Future<Expense> createExpense({
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

      debugPrint('Create Expense Request URL: ${ApiConfig.baseUrl}${ApiConfig.expenseEndpoint}/');
      debugPrint('Create Expense Request Body: $body');

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.expenseEndpoint}/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: body,
      );

      debugPrint('Create Expense Response Status: ${response.statusCode}');
      debugPrint('Create Expense Response Body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        // Manejar respuesta con wrapper 'data'
        if (jsonResponse is Map<String, dynamic> && jsonResponse.containsKey('data')) {
          return Expense.fromJson(jsonResponse['data'] as Map<String, dynamic>);
        }
        return Expense.fromJson(jsonResponse);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Error al crear gasto');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // ============================================
  // MÉTODO: Actualizar gasto existente
  // Aquí se edita un gasto
  // ============================================
  Future<Expense> updateExpense({
    required String token,
    required int expenseId,
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
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.expenseEndpoint}/$expenseId'),
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

      debugPrint('Update Expense Response Status: ${response.statusCode}');
      debugPrint('Update Expense Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return Expense.fromJson(jsonResponse);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Error al actualizar gasto');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // ============================================
  // MÉTODO: Eliminar gasto
  // Aquí se borra un gasto del servidor
  // ============================================
  Future<void> deleteExpense({
    required String token,
    required int expenseId,
  }) async {
    try {
      if (token.isEmpty) {
        throw Exception('Token no disponible');
      }

      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.expenseEndpoint}/$expenseId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('Delete Expense Response Status: ${response.statusCode}');

      if (response.statusCode != 200) {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Error al eliminar gasto');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // ============================================
  // MÉTODO: Calcular total de gastos
  // Aquí se suma todos los montos
  // ============================================
  double calculateTotal(List<Expense> expenses) {
    return expenses.fold(0.0, (sum, expense) => sum + expense.amount);
  }
}
