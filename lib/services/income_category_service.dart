import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/income_category_model.dart';
import '../models/pagination_model.dart';
import '../config/api_config.dart';

class IncomeCategoryService {
  static final IncomeCategoryService _instance = IncomeCategoryService._internal();

  factory IncomeCategoryService() {
    return _instance;
  }

  IncomeCategoryService._internal();

  /// Get all active income categories with pagination
  Future<PaginationResponse<IncomeCategory>> getCategories({
    int page = 1,
    int limit = 10,
    String sortBy = 'isActive,name',
    String sortOrder = 'desc,asc',
  }) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/income-categories/?page=$page&limit=$limit&sortBy=$sortBy&sortOrder=$sortOrder'),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        // Pasar una función que convierte cada item a IncomeCategory
        // La función recibe un item dinámico y retorna un IncomeCategory
        return PaginationResponse<IncomeCategory>.fromJson(
          jsonResponse,
          (item) => IncomeCategory.fromJson(item as Map<String, dynamic>),
        );
      } else {
        throw Exception('Failed to load income categories');
      }
    } catch (e) {
      throw Exception('Error loading income categories: $e');
    }
  }

  /// Create a new income category
  Future<IncomeCategory> createCategory(String token, String name, String? description) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/income-categories/'),
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
        return IncomeCategory.fromJson(jsonDecode(response.body));
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to create income category');
      }
    } catch (e) {
      throw Exception('Error creating income category: $e');
    }
  }

  /// Update an income category
  Future<IncomeCategory> updateCategory(
    String token,
    int categoryId,
    String name,
    String? description,
  ) async {
    try {
      final response = await http.patch(
        Uri.parse('${ApiConfig.baseUrl}/income-categories/$categoryId'),
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
        return IncomeCategory.fromJson(jsonDecode(response.body));
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to update income category');
      }
    } catch (e) {
      throw Exception('Error updating income category: $e');
    }
  }

  /// Deactivate an income category
  Future<IncomeCategory> deactivateCategory(String token, int categoryId) async {
    try {
      final response = await http.patch(
        Uri.parse('${ApiConfig.baseUrl}/income-categories/$categoryId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'id_estado': 2,
        }),
      );

      if (response.statusCode == 200) {
        return IncomeCategory.fromJson(jsonDecode(response.body));
      } else {
        final error = jsonDecode(response.body);
        final errorCode = error['code'] ?? error['error_code'];
        String errorMsg = error['error'] ?? error['message'] ?? 'No es posible actualizar su estado';
        
        // Traducir según código de error
        if (errorCode == 'ERROR_CAT_ASSO_01') {
          errorMsg = 'No es posible actualizar su estado, dado que contiene registros de ingreso vinculados';
        }
        
        throw Exception(errorMsg);
      }
    } catch (e) {
      String errorMessage = e.toString().replaceAll('Exception: ', '');
      throw Exception(errorMessage);
    }
  }

  /// Change category status between active (1) and inactive (2)
  Future<IncomeCategory> updateCategoryStatus(String token, int categoryId, int newStatus) async {
    try {
      final response = await http.patch(
        Uri.parse('${ApiConfig.baseUrl}/income-categories/$categoryId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'id_estado': newStatus,
        }),
      );

      if (response.statusCode == 200) {
        return IncomeCategory.fromJson(jsonDecode(response.body));
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to update category status');
      }
    } catch (e) {
      throw Exception('Error updating category status: $e');
    }
  }

  /// Delete an income category
  Future<void> deleteCategory(String token, int categoryId) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/income-categories/$categoryId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to delete income category');
      }
    } catch (e) {
      throw Exception('Error deleting income category: $e');
    }
  }
}
