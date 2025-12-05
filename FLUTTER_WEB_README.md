# 📱 Finanzas & Inventario - Flutter Web

Aplicación Flutter Web para gestión de finanzas e inventario con autenticación JWT integrada.

## 🚀 Características Implementadas

### ✅ Autenticación (Login/Registro)
- **Login**: Autenticación con email y contraseña
- **Registro**: Crear nueva cuenta con validaciones
  - Email único
  - RUT chileno validado
  - Contraseñas sincronizadas
  - Fecha de nacimiento requerida
- **Perfil**: Ver información del usuario
- **Logout**: Cerrar sesión de forma segura
- **Token JWT**: Almacenamiento y gestión de tokens

### 🎨 Interfaz de Usuario
- Diseño moderno con Material Design 3
- Tema personalizado (Deep Purple)
- Validaciones de formularios en tiempo real
- Mensajes de error claros
- Responsive para web

## 📋 Estructura del Proyecto

```
lib/
├── config/
│   └── api_config.dart         # Configuración de API
├── models/
│   └── user_model.dart         # Modelos User y AuthResponse
├── services/
│   └── auth_service.dart       # Servicio de autenticación
├── screens/
│   ├── login_screen.dart       # Pantalla de login
│   ├── register_screen.dart    # Pantalla de registro
│   └── home_screen.dart        # Pantalla de inicio
└── main.dart                   # Punto de entrada
```

## 🔧 Configuración

### Backend requerido
El proyecto espera un servidor backend en:
```
http://localhost:5000
```

Endpoints utilizados:
- `POST /auth/login` - Login de usuario
- `POST /auth/register` - Registro de usuario
- `GET /auth/profile` - Obtener perfil
- `PATCH /auth/profile` - Actualizar perfil
- `PATCH /auth/change-password` - Cambiar contraseña
- `DELETE /auth/profile` - Eliminar cuenta
- `GET /auth/logout` - Logout

### Dependencias
```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  http: ^1.1.0
```

## 🏃 Ejecutar la Aplicación

### Desarrollo
```bash
flutter run -d chrome
```

### Build para producción
```bash
flutter build web --release
```

## 📝 Flujo de Autenticación

1. **Usuario nuevo**: Clic en "Regístrate aquí"
   - Completa formulario con datos personales
   - Valida email, RUT y contraseñas
   - Sistema crea cuenta y retorna token JWT

2. **Usuario existente**: 
   - Ingresa email y contraseña
   - Sistema valida credenciales
   - Retorna token y datos de usuario
   - Acceso automático al home

3. **Sesión activa**:
   - Token almacenado en memoria
   - Todas las peticiones incluyen token en header
   - Al logout, token se invalida

## 🔐 Seguridad

- ✅ Tokens JWT en Authorization header
- ✅ Validaciones de email y formato
- ✅ Contraseñas hasheadas en backend
- ✅ Validación de RUT chileno
- ✅ Soft delete de cuentas
- ✅ Verificación de usuario activo

## 📦 Modelos de Datos

### User
```dart
class User {
  final int id;
  final String email;
  final String firstName;
  final String? paternalLastName;
  final String? maternalLastName;
  final String rut;
  final DateTime? birthDate;
  final int? age;
  final String? phoneNumber;
  final bool isActive;
  final DateTime? lastLoginAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
}
```

### AuthResponse
```dart
class AuthResponse {
  final String message;
  final String token;
  final User user;
}
```

## 🛠️ Servicio de Autenticación

El `AuthService` es un singleton que maneja:
- Login/Registro
- Almacenamiento de token
- Peticiones HTTP autenticadas
- Gestión de sesión
- Cierre de sesión seguro

### Métodos principales:
```dart
Future<AuthResponse> login({required email, required password})
Future<AuthResponse> register({...})
Future<User> getProfile()
Future<User> updateProfile({...})
Future<void> changePassword({...})
Future<void> logout()
Future<void> deleteAccount()
```

## 🎯 Próximas Funcionalidades

- [ ] Gestión de Ingresos (HU1)
- [ ] Gestión de Gastos (HU2)
- [ ] Inventario de Productos (HU7-HU10)
- [ ] Reportes y Estadísticas
- [ ] Sincronización con backend

## 📱 Requisitos Técnicos

- Flutter 3.10.1+
- Dart 3.10.1+
- Navegador moderno (Chrome, Firefox, Safari, Edge)
- Conexión a localhost:5000 para desarrollo

## 🐛 Solución de Problemas

### Error de conexión a API
- Verificar que el backend esté corriendo en `http://localhost:5000`
- Revisar CORS en backend si está habilitado
- Comprobar red/firewall

### Token expirado
- Hacer logout y login nuevamente
- El token se invalida al hacer logout

### RUT inválido
- Formato: `XX.XXX.XXX-K` (ej: `30.123.456-K`)
- También acepta sin puntos: `123456789`
- El dígito verificador se valida automáticamente

## 📄 Licencia

Este proyecto es privado y de propósito educativo.

---

**Última actualización**: Diciembre 2025
