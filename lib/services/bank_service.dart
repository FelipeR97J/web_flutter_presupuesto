import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/bank_model.dart';

class BankService {
  static final BankService _instance = BankService._internal();

  factory BankService() {
    return _instance;
  }

  BankService._internal();

  Future<List<Bank>> getBanks(String token) async {
    try {
      if (token.isEmpty) throw Exception('Token no disponible');

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/bank'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final List<dynamic> jsonList;
        
        if (jsonData is Map<String, dynamic> && jsonData.containsKey('data')) {
          jsonList = jsonData['data'];
        } else if (jsonData is List<dynamic>) {
          jsonList = jsonData;
        } else {
           jsonList = [];
        }

        return jsonList.map((json) => Bank.fromJson(json)).toList();
      } else {
        throw Exception('Error al obtener bancos');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<Bank> createBank(String token, String name) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/bank'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'name': name}),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
         if (jsonData is Map<String, dynamic> && jsonData.containsKey('data')) {
          return Bank.fromJson(jsonData['data']);
        }
        return Bank.fromJson(jsonData);
      } else {
         final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Error al crear banco');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<Bank> updateBank(String token, int id, String name, bool isActive) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/bank/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'name': name,
          'id_estado': isActive ? 1 : 2,
        }),
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        return Bank.fromJson(jsonData);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Error al actualizar banco');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<void> deleteBank(String token, int id) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/bank/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Error al eliminar banco');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}
