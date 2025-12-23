import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/expense_category_model.dart';
import '../models/pagination_model.dart';
import '../config/api_config.dart';

class ExpenseCategoryService {
  static final ExpenseCategoryService _instance = ExpenseCategoryService._internal();

  factory ExpenseCategoryService() {
    return _instance;
  }

  ExpenseCategoryService._internal();

  /// Get all active expense categories with pagination
  Future<PaginationResponse<ExpenseCategory>> getCategories({
    int page = 1,
    int limit = 20,
    String sortBy = 'isActive,name',
    String sortOrder = 'desc,asc',
  }) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/expense-categories/?page=$page&limit=$limit&sortBy=$sortBy&sortOrder=$sortOrder'),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        // Pasar una función que convierte cada item a ExpenseCategory
        // La función recibe un item dinámico y retorna un ExpenseCategory
        return PaginationResponse<ExpenseCategory>.fromJson(
          jsonResponse,
          (item) => ExpenseCategory.fromJson(item as Map<String, dynamic>),
        );
      } else {
        throw Exception('Failed to load expense categories');
      }
    } catch (e) {
      throw Exception('Error loading expense categories: $e');
    }
  }

  /// Get a single expense category by ID
  Future<ExpenseCategory> getCategoryById(String token, int categoryId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/expense-categories/$categoryId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return ExpenseCategory.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to load expense category');
      }
    } catch (e) {
      throw Exception('Error loading expense category: $e');
    }
  }

  /// Create a new expense category
  Future<ExpenseCategory> createCategory(String token, String name, String? description) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/expense-categories/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name': name,
          'description': description,
        }),
      );

      if (response.statusCode == 201) {
        return ExpenseCategory.fromJson(jsonDecode(response.body));
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to create expense category');
      }
    } catch (e) {
      throw Exception('Error creating expense category: $e');
    }
  }

  /// Update an expense category
  Future<ExpenseCategory> updateCategory(
    String token,
    int categoryId,
    String name,
    String? description,
  ) async {
    try {
      final response = await http.patch(
        Uri.parse('${ApiConfig.baseUrl}/expense-categories/$categoryId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name': name,
          'description': description,
        }),
      );

      if (response.statusCode == 200) {
        return ExpenseCategory.fromJson(jsonDecode(response.body));
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to update expense category');
      }
    } catch (e) {
      throw Exception('Error updating expense category: $e');
    }
  }

  /// Deactivate an expense category
  Future<ExpenseCategory> deactivateCategory(String token, int categoryId) async {
    try {
      final response = await http.patch(
        Uri.parse('${ApiConfig.baseUrl}/expense-categories/$categoryId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'id_estado': 2,
        }),
      );

      if (response.statusCode == 200) {
        return ExpenseCategory.fromJson(jsonDecode(response.body));
      } else {
        final error = jsonDecode(response.body);
        final errorCode = error['code'] ?? error['error_code'];
        String errorMsg = error['error'] ?? error['message'] ?? 'No es posible actualizar su estado';
        
        // Traducir según código de error
        if (errorCode == 'ERROR_CAT_ASSO_01') {
          errorMsg = 'No es posible actualizar su estado, dado que contiene registros de gastos vinculados';
        }
        
        throw Exception(errorMsg);
      }
    } catch (e) {
      String errorMessage = e.toString().replaceAll('Exception: ', '');
      throw Exception(errorMessage);
    }
  }

  /// Change category status between active (1) and inactive (2)
  Future<ExpenseCategory> updateCategoryStatus(String token, int categoryId, int newStatus) async {
    try {
      final response = await http.patch(
        Uri.parse('${ApiConfig.baseUrl}/expense-categories/$categoryId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'id_estado': newStatus,
        }),
      );

      if (response.statusCode == 200) {
        return ExpenseCategory.fromJson(jsonDecode(response.body));
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to update category status');
      }
    } catch (e) {
      throw Exception('Error updating category status: $e');
    }
  }

  /// Delete an expense category
  Future<void> deleteCategory(String token, int categoryId) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/expense-categories/$categoryId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to delete expense category');
      }
    } catch (e) {
      throw Exception('Error deleting expense category: $e');
    }
  }
}
