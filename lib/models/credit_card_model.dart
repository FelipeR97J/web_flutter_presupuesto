import 'bank_model.dart';

class CreditCard {
  final int id;
  final String name;
  final int bankId;
  final bool active;
  final Bank? bank;

  CreditCard({
    required this.id,
    required this.name,
    required this.bankId,
    required this.active,
    this.bank,
  });

  factory CreditCard.fromJson(Map<String, dynamic> json) {
    return CreditCard(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      bankId: json['bankId'] as int? ?? 0,
      active: json['active'] as bool? ?? (json['id_estado'] == 1),
      bank: json['bank'] != null ? Bank.fromJson(json['bank']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'bankId': bankId,
      'active': active,
      'id_estado': active ? 1 : 2,
    };
  }
}
