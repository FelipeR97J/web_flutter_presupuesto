import 'package:intl/intl.dart';
import 'credit_card_model.dart';
import 'expense_category_model.dart';

class Debt {
  final int id;
  final int creditCardId;
  final double totalAmount;
  final int installments;
  final int categoryId;
  final String description;
  final DateTime startDate;
  
  // Optional expanded fields
  final CreditCard? creditCard;
  final ExpenseCategory? expenseCategory;

  Debt({
    required this.id,
    required this.creditCardId,
    required this.totalAmount,
    required this.installments,
    required this.categoryId,
    required this.description,
    required this.startDate,
    this.creditCard,
    this.expenseCategory,
  });

  factory Debt.fromJson(Map<String, dynamic> json) {
    return Debt(
      id: json['id'] as int? ?? 0,
      creditCardId: json['creditCardId'] as int? ?? 0,
      totalAmount: double.tryParse(json['totalAmount'].toString()) ?? 0.0,
      installments: json['installments'] as int? ?? 1,
      categoryId: json['categoryId'] as int? ?? 0,
      description: json['description'] as String? ?? '',
      startDate: json['startDate'] != null 
          ? DateTime.parse(json['startDate'] as String) 
          : DateTime.now(),
      creditCard: json['creditCard'] != null 
          ? CreditCard.fromJson(json['creditCard']) 
          : null,
      expenseCategory: json['category'] != null 
          ? ExpenseCategory.fromJson(json['category']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'creditCardId': creditCardId,
      'totalAmount': totalAmount,
      'installments': installments,
      'categoryId': categoryId,
      'description': description,
      'startDate': startDate.toIso8601String().split('T')[0],
    };
  }

  String get formattedTotalAmount {
    final formatter = NumberFormat('#,##0', 'es_ES');
    return '\$${formatter.format(totalAmount.toInt())}';
  }

  String get formattedStartDate {
    return '${startDate.day}/${startDate.month}/${startDate.year}';
  }
}
