class User {
  final int id;
  final String email;
  final String firstName;
  final String? paternalLastName;
  final String? maternalLastName;
  final String? rut;
  final DateTime? birthDate;
  final int? age;
  final String? phoneNumber;
  // ignore: non_constant_identifier_names
  final int id_estado;
  final DateTime? lastLoginAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isActive => id_estado == 1;

  User({
    required this.id,
    required this.email,
    required this.firstName,
    this.paternalLastName,
    this.maternalLastName,
    this.rut,
    this.birthDate,
    this.age,
    this.phoneNumber,
    // ignore: non_constant_identifier_names
    required this.id_estado,
    this.lastLoginAt,
    this.createdAt,
    this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int? ?? 0,
      email: json['email'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      paternalLastName: json['paternalLastName'] as String?,
      maternalLastName: json['maternalLastName'] as String?,
      rut: json['rut'] as String?,
      birthDate: json['birthDate'] != null ? DateTime.tryParse(json['birthDate'] as String) : null,
      age: json['age'] as int?,
      phoneNumber: json['phoneNumber'] as String?,
      id_estado: json['id_estado'] as int? ?? 1,
      lastLoginAt: json['lastLoginAt'] != null ? DateTime.tryParse(json['lastLoginAt'] as String) : null,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'firstName': firstName,
      'paternalLastName': paternalLastName,
      'maternalLastName': maternalLastName,
      'rut': rut,
      'birthDate': birthDate?.toIso8601String(),
      'age': age,
      'phoneNumber': phoneNumber,
      'id_estado': id_estado,
      'lastLoginAt': lastLoginAt?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}

class AuthResponse {
  final String message;
  final String token;
  final User user;

  AuthResponse({
    required this.message,
    required this.token,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      message: json['message'] as String,
      token: json['token'] as String,
      user: User.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}
