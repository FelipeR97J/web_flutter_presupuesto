import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/debt_model.dart';
import '../models/pagination_model.dart';

class DebtService {
  static final DebtService _instance = DebtService._internal();

  factory DebtService() {
    return _instance;
  }

  DebtService._internal();

  Future<PaginationResponse<Debt>> getDebts(
    String token, {
    int? year,
    int? month,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      if (token.isEmpty) throw Exception('Token no disponible');

      String query = 'page=$page&limit=$limit';
      if (year != null) query += '&year=$year';
      if (month != null) query += '&month=$month';

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/debt?$query'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        if (jsonData is Map<String, dynamic>) {
          final data = jsonData['data'] as List<dynamic>? ?? [];
          final totalItems = jsonData['total'] as int? ?? data.length;
          final totalPages = jsonData['pages'] as int? ?? 1;

          if (data.isNotEmpty) {
             debugPrint('RAW DEBT JSON: ${jsonEncode(data[0])}');
          }
          final debts = data
              .map((json) => Debt.fromJson(json as Map<String, dynamic>))
              .toList();

          return PaginationResponse<Debt>(
            data: debts,
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
        throw Exception('Error al obtener deudas');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<Debt> createDebt({
    required String token,
    required int creditCardId,
    required double totalAmount,
    required int installments,
    required int categoryId,
    required String description,
    required DateTime startDate,
  }) async {
    try {
      final body = jsonEncode({
        'creditCardId': creditCardId,
        'totalAmount': totalAmount,
        'installments': installments,
        'categoryId': categoryId,
        'description': description,
        'startDate': startDate.toIso8601String().split('T')[0],
      });

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/debt'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: body,
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
         if (jsonData is Map<String, dynamic> && jsonData.containsKey('data')) {
            return Debt.fromJson(jsonData['data']);
         }
        return Debt.fromJson(jsonData);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Error al crear deuda');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<Debt> updateDebt({
    required String token,
    required int id,
    int? creditCardId,
    double? totalAmount,
    int? installments,
    int? categoryId,
    String? description,
    DateTime? startDate,
  }) async {
    try {
      final Map<String, dynamic> data = {};
      if (creditCardId != null) data['creditCardId'] = creditCardId;
      if (totalAmount != null) data['totalAmount'] = totalAmount;
      if (installments != null) data['installments'] = installments;
      if (categoryId != null) data['categoryId'] = categoryId;
      if (description != null) data['description'] = description;
      if (startDate != null) data['startDate'] = startDate.toIso8601String().split('T')[0];

      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/debt/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        return Debt.fromJson(jsonData);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Error al actualizar deuda');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<void> deleteDebt(String token, int id) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/debt/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Error al eliminar deuda');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<Debt> getDebtById(String token, int id) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/debt/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        return Debt.fromJson(jsonData);
      } else {
        throw Exception('Error al obtener detalle de la deuda');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}
