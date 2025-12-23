import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/dashboard_model.dart';

class DashboardService {
  static final DashboardService _instance = DashboardService._internal();

  factory DashboardService() {
    return _instance;
  }

  DashboardService._internal();

  // ============================================
  // MÉTODO: Obtener resumen mensual
  // ============================================
  Future<DashboardSummary> getSummary(
    String token, {
    int? year,
    int? month,
  }) async {
    try {
      if (token.isEmpty) {
        throw Exception('Token no disponible');
      }

      String query = '';
      if (year != null) query += 'year=$year';
      if (month != null) {
        if (query.isNotEmpty) query += '&';
        query += 'month=$month';
      }

      final url = query.isEmpty
          ? '${ApiConfig.baseUrl}/dashboard/summary'
          : '${ApiConfig.baseUrl}/dashboard/summary?$query';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('Get Dashboard Summary Response Status: ${response.statusCode}');
      debugPrint('Get Dashboard Summary Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        return DashboardSummary.fromJson(jsonData);
      } else {
        throw Exception('Error al obtener resumen del dashboard');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // ============================================
  // MÉTODO: Obtener distribución por categoría
  // ============================================
  Future<CategoryDistribution> getCategoryDistribution(
    String token, {
    int? year,
    int? month,
  }) async {
    try {
      if (token.isEmpty) {
        throw Exception('Token no disponible');
      }

      String query = '';
      if (year != null) query += 'year=$year';
      if (month != null) {
        if (query.isNotEmpty) query += '&';
        query += 'month=$month';
      }

      final url = query.isEmpty
          ? '${ApiConfig.baseUrl}/dashboard/category-distribution'
          : '${ApiConfig.baseUrl}/dashboard/category-distribution?$query';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('Get Category Distribution Response Status: ${response.statusCode}');
      debugPrint('Get Category Distribution Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        return CategoryDistribution.fromJson(jsonData);
      } else {
        throw Exception('Error al obtener distribución de categorías');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // ============================================
  // MÉTODO: Obtener historial semestral
  // ============================================
  Future<DashboardHistory> getHistory(String token) async {
    try {
      if (token.isEmpty) {
        throw Exception('Token no disponible');
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/dashboard/history'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('Get Dashboard History Response Status: ${response.statusCode}');
      debugPrint('Get Dashboard History Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        return DashboardHistory.fromJson(jsonData);
      } else {
        throw Exception('Error al obtener historial del dashboard');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}
