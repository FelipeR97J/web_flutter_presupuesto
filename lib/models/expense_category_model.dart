class ExpenseCategory {
  final int id;
  final String name;
  final String? description;
  // ignore: non_constant_identifier_names
  final int id_estado;
  final DateTime createdAt;
  final DateTime updatedAt;

  ExpenseCategory({
    required this.id,
    required this.name,
    this.description,
    // ignore: non_constant_identifier_names
    required this.id_estado,
    required this.createdAt,
    required this.updatedAt,
  });

  // Helper para verificar si está activo
  bool get isActive => id_estado == 1;

  factory ExpenseCategory.fromJson(Map<String, dynamic> json) {
    return ExpenseCategory(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      id_estado: json['id_estado'] as int? ?? 1,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'id_estado': id_estado,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
