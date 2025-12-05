# Configuración para desarrollo de Flutter Web

## Variables de Entorno

No se requieren variables de entorno en este momento, pero aquí están preparadas para futuro:

```bash
# Backend API
API_BASE_URL=http://localhost:5000

# Ambiente
ENVIRONMENT=development
```

## Configuración Local

Asegurar que estos archivos están configurados:

1. **pubspec.yaml**: Ya tiene `http: ^1.1.0`
2. **lib/config/api_config.dart**: Base URL configurada en `http://localhost:5000`
3. **Backend**: Corriendo en puerto 5000

## Iniciar Desarrollo

```bash
# 1. Instalar dependencias (ya hecho)
flutter pub get

# 2. Ejecutar en Chrome
flutter run -d chrome

# 3. Ejecutar con hot reload
# - Presionar 'r' en terminal para hot reload
# - Presionar 'R' para hot restart
```

## Build para Producción

```bash
# Build web
flutter build web --release

# Output en: build/web/
```

## Cambiar Backend URL

Para cambiar la URL del backend, editar:
```dart
// lib/config/api_config.dart
static const String baseUrl = 'http://localhost:5000';
```

## Debugging

### Habilitar Logs
En `lib/services/auth_service.dart`, descomentar:
```dart
print('Login response: $jsonResponse');
```

### DevTools
```bash
# Abrir DevTools en Chrome
# - F12 o Ctrl+Shift+I
# - Console: Ver logs
# - Network: Ver requests HTTP
# - Application: Ver local storage (para futuro)
```

## Testing Manual

Credenciales de prueba:
- Email: `test@example.com`
- Contraseña: `Test123456`

---

Última actualización: Diciembre 2025
