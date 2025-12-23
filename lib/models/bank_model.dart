class Bank {
  final int id;
  final String name;
  final bool active;

  Bank({
    required this.id,
    required this.name,
    required this.active,
  });

  factory Bank.fromJson(Map<String, dynamic> json) {
    return Bank(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      // Asumiendo que el campo de estado puede venir como 'active' boolean o 'id_estado' int
      active: json['active'] as bool? ?? (json['id_estado'] == 1),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'active': active,
      'id_estado': active ? 1 : 2,
    };
  }
}
