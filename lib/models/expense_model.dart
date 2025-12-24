// ============================================
// MODELO: Expense
// Representa un gasto registrado por el usuario
// Aquí puedes agregar más campos si es necesario
// ============================================
import 'package:intl/intl.dart';
import 'expense_category_model.dart'; // Added import

class Expense {
  final int id;
  final double amount;
  final String description;
  final DateTime date;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int categoryId;
  final int? debtId;
  final ExpenseCategory? category; // Added field

  Expense({
    required this.id,
    required this.amount,
    required this.description,
    required this.date,
    required this.createdAt,
    required this.updatedAt,
    required this.categoryId,
    this.debtId,
    this.category, // Added parameter
  });

  bool get isDebtPayment => debtId != null;

  // ============================================
  // MÉTODO: Convertir JSON a objeto Expense
  // Aquí se parsean los datos del servidor
  // ============================================
  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'] as int? ?? 0,
      amount: double.tryParse(json['amount'].toString()) ?? 0.0,
      description: json['description'] as String? ?? '',
      date: json['date'] != null ? DateTime.parse(json['date'] as String) : DateTime.now(),
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : DateTime.now(),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : DateTime.now(),
      categoryId: json['categoryId'] as int? ?? 0,
      debtId: json['debtId'] as int?,
      category: json['category'] != null ? ExpenseCategory.fromJson(json['category']) : null, // Added parsing
    );
  }

  // ============================================
  // MÉTODO: Convertir Expense a JSON
  // Aquí se preparan los datos para enviar al servidor
  // ============================================
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'description': description,
      'date': date.toIso8601String().split('T')[0],
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'categoryId': categoryId,
      'debtId': debtId,
      // We generally don't need to send the full category object back, so omitting it or sending just ID is fine.
    };
  }

  // ============================================
  // MÉTODO: Formattear monto para mostrar
  // Aquí puedes cambiar el formato de dinero
  // ============================================
  String get formattedAmount {
    // Usamos el locale por defecto inicializado en main.dart
    final formatter = NumberFormat('#,##0', 'es_ES');
    return '\$${formatter.format(amount.toInt())}';
  }

  // ============================================
  // MÉTODO: Formattear fecha para mostrar
  // ============================================
  String get formattedDate {
    return '${date.day}/${date.month}/${date.year}';
  }
}
