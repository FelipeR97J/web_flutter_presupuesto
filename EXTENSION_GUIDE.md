# 🛠️ Guía de Extensión - Próximas Funcionalidades

## Cómo Agregar Nuevas Características

### 1. Agregar un Nuevo Servicio (Ingresos)

**Crear: `lib/models/income_model.dart`**
```dart
class Income {
  final int id;
  final double amount;
  final String description;
  final DateTime date;
  final DateTime createdAt;
  final DateTime updatedAt;

  Income({
    required this.id,
    required this.amount,
    required this.description,
    required this.date,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Income.fromJson(Map<String, dynamic> json) {
    return Income(
      id: json['id'],
      amount: double.parse(json['amount'].toString()),
      description: json['description'],
      date: DateTime.parse(json['date']),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}
```

**Crear: `lib/services/income_service.dart`**
```dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/income_model.dart';

class IncomeService {
  static final IncomeService _instance = IncomeService._internal();
  
  final String? _token;

  factory IncomeService({String? token}) {
    return _instance;
  }

  IncomeService._internal() : _token = null;

  Future<Income> createIncome({
    required double amount,
    required String description,
    required DateTime date,
  }) async {
    if (_token == null) throw Exception('No token');

    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.incomeEndpoint}'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
      },
      body: jsonEncode({
        'amount': amount,
        'description': description,
        'date': date.toIso8601String().split('T')[0],
      }),
    );

    if (response.statusCode == 201) {
      return Income.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Error creating income');
    }
  }

  Future<List<Income>> getIncomes() async {
    if (_token == null) throw Exception('No token');

    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.incomeEndpoint}'),
      headers: {
        'Authorization': 'Bearer $_token',
      },
    );

    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List;
      return list.map((e) => Income.fromJson(e)).toList();
    } else {
      throw Exception('Error fetching incomes');
    }
  }
}
```

### 2. Agregar una Nueva Pantalla

**Crear: `lib/screens/income_screen.dart`**
```dart
import 'package:flutter/material.dart';
import '../models/income_model.dart';
import '../services/income_service.dart';

class IncomeScreen extends StatefulWidget {
  const IncomeScreen({super.key});

  @override
  State<IncomeScreen> createState() => _IncomeScreenState();
}

class _IncomeScreenState extends State<IncomeScreen> {
  final _incomeService = IncomeService();
  late Future<List<Income>> _incomesFuture;

  @override
  void initState() {
    super.initState();
    _incomesFuture = _incomeService.getIncomes();
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return const AddIncomeDialog();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ingresos'),
        backgroundColor: Colors.deepPurple,
      ),
      body: FutureBuilder<List<Income>>(
        future: _incomesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No hay ingresos'));
          }

          final incomes = snapshot.data!;
          return ListView.builder(
            itemCount: incomes.length,
            itemBuilder: (context, index) {
              final income = incomes[index];
              return ListTile(
                title: Text(income.description),
                subtitle: Text(income.date.toString()),
                trailing: Text('\$${income.amount}'),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class AddIncomeDialog extends StatefulWidget {
  const AddIncomeDialog({super.key});

  @override
  State<AddIncomeDialog> createState() => _AddIncomeDialogState();
}

class _AddIncomeDialogState extends State<AddIncomeDialog> {
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  late DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Agregar Ingreso'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Monto',
              prefixText: '\$',
            ),
          ),
          TextField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Descripción',
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (date != null) {
                setState(() => _selectedDate = date);
              }
            },
            child: Text('Fecha: ${_selectedDate.toLocal()}'.split(' ')[0]),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () {
            // Lógica para guardar ingreso
            Navigator.pop(context);
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
```

### 3. Agregar Navegación en Home

**Actualizar: `lib/screens/home_screen.dart`**
```dart
// En _buildFeatureCard, cambiar onPressed:
_buildFeatureCard(
  '💰 Ingresos',
  'Registra tus ingresos',
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const IncomeScreen()),
    );
  },
),
```

### 4. Crear un Provider para Estado Global

**Crear: `lib/providers/auth_provider.dart`**
```dart
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final _authService = AuthService();
  User? _user;
  bool _isAuthenticated = false;

  User? get user => _user;
  bool get isAuthenticated => _isAuthenticated;

  Future<void> login(String email, String password) async {
    final response = await _authService.login(
      email: email,
      password: password,
    );
    _user = response.user;
    _isAuthenticated = true;
    notifyListeners();
  }

  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    _isAuthenticated = false;
    notifyListeners();
  }
}
```

### 5. Agregar Persistencia (Local Storage)

**Actualizar pubspec.yaml:**
```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  http: ^1.1.0
  shared_preferences: ^2.2.0
```

**En AuthService:**
```dart
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // ...
  
  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<void> logout() async {
    try {
      if (_token == null) {
        throw Exception('No hay token de autenticación');
      }

      await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.logoutEndpoint}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
      );
    } catch (e) {
      // Continue logout even if request fails
    } finally {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      _token = null;
      _currentUser = null;
    }
  }
}
```

## Estructura Recomendada para Nuevas Features

```
Nueva Funcionalidad (Ej: Gastos)
├── lib/models/
│   └── expense_model.dart
├── lib/services/
│   └── expense_service.dart
├── lib/screens/
│   ├── expense_list_screen.dart
│   ├── expense_detail_screen.dart
│   └── add_expense_screen.dart
└── lib/providers/ (opcional)
    └── expense_provider.dart
```

## Testing de Nuevas Funcionalidades

```dart
// lib/tests/services/expense_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

void main() {
  group('ExpenseService', () {
    test('should create expense', () async {
      // Arrange
      final service = ExpenseService();
      
      // Act
      final expense = await service.createExpense(
        amount: 45.99,
        category: 'alimentos',
        description: 'Test',
        date: DateTime.now(),
      );
      
      // Assert
      expect(expense.id, isNotNull);
      expect(expense.amount, 45.99);
    });
  });
}
```

## Mejores Prácticas

1. **Mantener AuthService como Singleton** - Acceso centralizado a tokens
2. **Separar Lógica de UI** - Services manejan lógica, Screens manejan UI
3. **Validaciones Claras** - Mostrar errores específicos al usuario
4. **Manejo de Errores Robusto** - Try/catch en operaciones async
5. **Documentación** - Comentar código complejo
6. **Testing** - Escribir tests para servicios
7. **Performance** - Usar FutureBuilder y StreamBuilder apropiadamente

## Recursos Útiles

- Flutter docs: https://flutter.dev/docs
- Dart docs: https://dart.dev/guides
- HTTP package: https://pub.dev/packages/http
- Shared Preferences: https://pub.dev/packages/shared_preferences
- Provider: https://pub.dev/packages/provider

---

**Última actualización**: Diciembre 2025
