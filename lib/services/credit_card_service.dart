import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/credit_card_model.dart';

class CreditCardService {
  static final CreditCardService _instance = CreditCardService._internal();

  factory CreditCardService() {
    return _instance;
  }

  CreditCardService._internal();

  Future<List<CreditCard>> getCreditCards(String token) async {
    try {
      if (token.isEmpty) throw Exception('Token no disponible');

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/credit-card'),
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

        return jsonList.map((json) => CreditCard.fromJson(json)).toList();
      } else {
        throw Exception('Error al obtener tarjetas');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<CreditCard> createCreditCard(String token, String name, int bankId) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/credit-card'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'name': name,
          'bankId': bankId,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
         if (jsonData is Map<String, dynamic> && jsonData.containsKey('data')) {
          return CreditCard.fromJson(jsonData['data']);
        }
        return CreditCard.fromJson(jsonData);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Error al crear tarjeta');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<CreditCard> updateCreditCard(String token, int id, String name, bool isActive) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/credit-card/$id'),
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
        return CreditCard.fromJson(jsonData);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Error al actualizar tarjeta');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<void> deleteCreditCard(String token, int id) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/credit-card/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Error al eliminar tarjeta');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}
