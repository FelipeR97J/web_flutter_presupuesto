# 💰 Presupuesto - Aplicación de Gestión de Gastos e Ingresos

Una aplicación Flutter moderna y responsiva para gestionar tus finanzas personales con interfaz intuitiva, funcionalidades avanzadas y herramientas poderosas para mantener el control total de tu presupuesto.

## 🎯 ¿Por qué usar Presupuesto?

En un mundo donde controlar tus gastos es fundamental para lograr estabilidad financiera, **Presupuesto** te ofrece una solución completa y fácil de usar. Ya sea que estés ahorrando para un objetivo específico, queriendo entender en qué se va tu dinero, o simplemente mantener un registro organizado de tus transacciones, esta aplicación es tu aliada perfecta.

**Características que te enamorarán:**
- 📊 **Control total** - Sabe exactamente dónde va cada peso
- 💡 **Categorización inteligente** - Organiza tus gastos e ingresos como prefieras
- 📱 **Multiplataforma** - Accede desde web, mobile o desktop
- 🚀 **Rápido y eficiente** - Registra transacciones en segundos
- 🛡️ **Seguro** - Tus datos están protegidos con autenticación JWT

---

## ✨ Características Principales Implementadas

### 👤 Autenticación y Perfil
- ✅ **Registro seguro** con validación de datos personales (RUT, email, fecha de nacimiento)
- ✅ **Inicio de sesión** con recuperación de sesión persistente
- ✅ **Gestión de perfil** - Actualizar información personal
- ✅ **Cambio de contraseña** seguro
- ✅ **Logout** con cierre de sesión

### 💸 Gestión de Gastos
- ✅ **Crear gastos** con monto, categoría, descripción y fecha
- ✅ **Editar gastos** existentes
- ✅ **Eliminar gastos** con confirmación
- ✅ **Ver lista paginada** de gastos registrados
- ✅ **Total de gastos** calculado automáticamente con formateo de miles
- ✅ **Tema indigo** para mejor distinción visual
- ✅ **Bloqueo de botones** durante la operación (evita duplicados)

### 📈 Gestión de Ingresos
- ✅ **Crear ingresos** con monto, categoría, descripción y fecha
- ✅ **Editar ingresos** existentes
- ✅ **Eliminar ingresos** con confirmación
- ✅ **Ver lista paginada** de ingresos registrados
- ✅ **Total de ingresos** calculado automáticamente con formateo de miles
- ✅ **Tema verde** para mejor distinción visual
- ✅ **Bloqueo de botones** durante la operación (evita duplicados)

### 📂 Gestión de Categorías
- ✅ **Crear categorías personalizadas** para gastos e ingresos
- ✅ **Editar categorías** existentes
- ✅ **Inactivar categorías** (sin eliminar registros asociados)
- ✅ **Eliminar categorías** (solo si no tienen registros activos)
- ✅ **Vista de categorías activas e inactivas**
- ✅ **Validaciones inteligentes** - Previene eliminar/inactivar categorías con registros asociados

### 📊 Dashboard
- ✅ **Resumen de finanzas personales** - Visualiza tu situación financiera en un vistazo
- ✅ **Total de ingresos** del período
- ✅ **Total de gastos** del período
- ✅ **Balance neto** (Ingresos - Gastos)
- ✅ **Visualización clara** del estado financiero
- ✅ **Números formateados** con separador de miles ($X.XXX.XXX)

### 🎨 Experiencia de Usuario
- ✅ **Interfaz responsiva** - Funciona en web, mobile y desktop
- ✅ **Tema profesional** con colores coordinados
  - Ingresos: Verde
  - Gastos: Índigo
- ✅ **Formularios inteligentes** con validación en tiempo real
- ✅ **Solo números enteros** en montos (CLP no usa decimales)
- ✅ **Confirmaciones** antes de acciones destructivas
- ✅ **Mensajes de error** descriptivos en español
- ✅ **Indicadores de carga** durante operaciones

### 🔢 Formato de Números
- ✅ **Formateo automático** con separador de miles (punto)
- ✅ **Ejemplo**: $1.082.531 en lugar de $1082531
- ✅ **Locale Spanish (Chile)** configurado
- ✅ **Sin decimales** - CLP es moneda sin centavos

---

## 🚀 Roadmap - Próximas Características (v2.0)

### 📊 **Gráficas y Análisis Avanzados**

Estamos trabajando en agregar visualizaciones poderosas para entender tus patrones de gasto y tomar mejores decisiones financieras:

#### 📈 Gráficas Mensuales
- **Comparativa mensual** - Ve cómo varía tu presupuesto mes a mes
- **Mes más costoso 💸** - Identifica en qué mes gastaste más dinero
- **Mes más ahorrador 💚** - Descubre cuándo fuiste más prudente y controlado
- **Tendencias de gastos** - Analiza si tus gastos suben o bajan a lo largo del tiempo
- **Comparación ingreso vs gasto** - Visualiza la diferencia entre lo que entra y lo que sale

#### 📊 Gráficas por Categoría
- **Distribución de gastos** - Pastel o barras mostrando qué categoría consume más dinero
- **Top 5 categorías** - Las categorías donde más dinero se invierte
- **Análisis por período** - Filtra por semana, mes o año
- **Evolución de categorías** - Cómo cambia cada categoría en el tiempo

#### 💡 Insights Inteligentes y Recomendaciones
- "🔥 Este mes gastaste 25% más que el mes anterior"
- "💚 Excelente ahorro en transporte este mes"
- "⚠️ Tus gastos en comida son 40% de tu presupuesto mensual"
- "🎯 Según tu ritmo actual, ahorrarás $250.000 este mes"
- "📈 Tu categoría 'Entretenimiento' creció 15% respecto al mes pasado"

#### 📲 Exportación de Reportes
- Descarga reportes mensuales en PDF con gráficas incluidas
- Compartir análisis con contadores o asesores financieros
- Historial de transacciones detallado y filtrable

---

## 🛠️ Stack Tecnológico

- **Framework**: Flutter 3.x
- **Lenguaje**: Dart
- **Gestión de Estado**: StatefulWidget
- **HTTP Client**: http package
- **Localización**: intl package (para formato de números en locale Spanish/Chile)
- **Plataformas**: Web, iOS, Android, Windows, macOS, Linux

## 📋 Requisitos

- Flutter SDK 3.0 o superior
- Dart 3.0 o superior
- Backend API ejecutándose (ver [First-Bun-Backend](https://github.com/FelipeR97J/First-Bun-Backend-develop))

## 🚀 Instalación y Ejecución

### Clonar el repositorio
```bash
git clone https://github.com/FelipeR97J/web_flutter_presupuesto.git
cd web_flutter_presupuesto
```

### Instalar dependencias
```bash
flutter pub get
```

### Ejecutar la aplicación

**En Web (Chrome):**
```bash
flutter run -d chrome
```

**En dispositivo conectado:**
```bash
flutter run
```

**Build para Web (producción):**
```bash
flutter build web --release
```

## 🔗 Configuración de API

El archivo de configuración está en `lib/config/api_config.dart`. Asegúrate de que la URL base apunte a tu servidor backend:

```dart
static const String baseUrl = 'http://localhost:3000/api'; // Ajusta según tu servidor
```

## 📁 Estructura del Proyecto

```
lib/
├── main.dart                          # Punto de entrada
├── config/
│   └── api_config.dart               # Configuración del API
├── models/
│   ├── user_model.dart               # Modelo de usuario
│   ├── expense_model.dart            # Modelo de gasto
│   ├── income_model.dart             # Modelo de ingreso
│   ├── expense_category_model.dart   # Modelo de categoría de gasto
│   ├── income_category_model.dart    # Modelo de categoría de ingreso
│   └── pagination_model.dart         # Modelo de paginación
├── services/
│   ├── auth_service.dart             # Servicio de autenticación
│   ├── expense_service.dart          # Servicio de gastos
│   ├── income_service.dart           # Servicio de ingresos
│   ├── expense_category_service.dart # Servicio de categorías de gastos
│   └── income_category_service.dart  # Servicio de categorías de ingresos
├── screens/
│   ├── login_screen.dart             # Pantalla de inicio de sesión
│   ├── register_screen.dart          # Pantalla de registro
│   ├── home_screen.dart              # Dashboard principal
│   ├── expense_screen.dart           # Lista de gastos
│   ├── add_expense_screen.dart       # Crear/editar gastos
│   ├── edit_expense_screen.dart      # Edición específica de gastos
│   ├── income_screen.dart            # Lista de ingresos
│   ├── add_income_screen.dart        # Crear/editar ingresos
│   ├── edit_income_screen.dart       # Edición específica de ingresos
│   ├── expense_category_screen.dart  # Gestión de categorías de gastos
│   ├── income_category_screen.dart   # Gestión de categorías de ingresos
│   ├── edit_profile_screen.dart      # Editar perfil de usuario
│   └── change_password_screen.dart   # Cambiar contraseña
└── widgets/
    ├── expense_form_dialog.dart      # Diálogo de formulario de gastos
    ├── income_form_dialog.dart       # Diálogo de formulario de ingresos
    ├── category_form_dialog.dart     # Diálogo de formulario de categorías
    └── pagination_controls.dart      # Controles de paginación
```

## 🔐 Seguridad

- ✅ Autenticación JWT (JSON Web Tokens)
- ✅ Token almacenado de forma segura
- ✅ Cierre de sesión automático en caso de token expirado
- ✅ Validación de permisos en el servidor
- ✅ Datos del usuario nunca se exponen en el cliente

## 🐛 Manejo de Errores

La aplicación utiliza un **sistema de códigos de error consistente** del backend:

| Prefijo | Descripción |
|---------|-------------|
| `AUTH_XXX` | Errores de autenticación y login |
| `INC_XXX` | Errores relacionados con ingresos |
| `EXP_XXX` | Errores relacionados con gastos |
| `*_CAT_XXX` | Errores en gestión de categorías |
| `REG_XXX` | Errores durante el registro de usuario |
| `SRV_XXX` | Errores internos del servidor |

**Todos los mensajes de error se muestran en español** con claridad para facilitar la experiencia del usuario.

## 📊 Ejemplos de Uso

### Registrarse
1. Abre la app y haz clic en "No tengo cuenta"
2. Completa tus datos (RUT, email, contraseña, fecha de nacimiento)
3. Acepta términos y haz clic en "Registrarse"

### Crear un Gasto
1. Ve a la sección "Gastos"
2. Haz clic en el botón "Crear Gasto"
3. Completa monto, categoría, descripción y fecha
4. Haz clic en "Registrar Gasto"
5. ¡Listo! El gasto se agregará a tu lista

### Ver Análisis
1. Ve al Dashboard
2. Visualiza tu balance total y resumen mensual
3. Accede a Ingresos o Gastos para ver detalles

## 🤝 Contribuir

Las contribuciones son bienvenidas. Para cambios mayores:

1. Fork el repositorio
2. Crea una rama para tu feature (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request

## 📄 Licencia

Este proyecto está bajo la Licencia MIT. Ver `LICENSE` para más detalles.

## 👨‍💻 Autor

**Felipe R.**
- GitHub: [@FelipeR97J](https://github.com/FelipeR97J)
- Email: felipe@example.com

## 📞 Soporte

¿Encontraste un bug? ¿Tienes una sugerencia?
- Abre un [issue en GitHub](https://github.com/FelipeR97J/web_flutter_presupuesto/issues)
- Contacta directamente o deja tu feedback

---

**Última actualización**: Diciembre 2025

**Estado**: ✅ Versión 1.0 - En producción  
**Próxima versión**: 📅 v2.0 con Gráficas y Analytics (próximamente)

---

**¡Gracias por usar Presupuesto! Que comience tu viaje hacia una mejor gestión financiera 💰**
