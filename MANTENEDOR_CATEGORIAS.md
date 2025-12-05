# 📋 Mantenedor de Categorías - Ingresos y Gastos

## Descripción General

Se han creado dos sistemas completos de mantenimiento de categorías para **Ingresos** y **Gastos**, permitiendo a los usuarios crear, editar e inactivar categorías de forma sencilla.

---

## 📁 Archivos Creados

### Modelos (Models)

#### `lib/models/income_category_model.dart`
- Modelo tipado para categorías de ingreso
- Métodos de serialización: `fromJson()`, `toJson()`
- Campos: `id`, `name`, `description`, `isActive`, `createdAt`, `updatedAt`

#### `lib/models/expense_category_model.dart`
- Modelo tipado para categorías de gasto
- Estructura idéntica a `IncomeCategory`
- Reutilizable para cualquier tipo de categoría

### Servicios (Services)

#### `lib/services/income_category_service.dart`
Singleton service con métodos CRUD:
- `getCategories()` - GET /income-categories/
- `createCategory(token, name, description)` - POST /income-categories/
- `updateCategory(token, categoryId, name, description)` - PATCH /income-categories/{id}
- `deactivateCategory(token, categoryId)` - Inactivar categoría
- `deleteCategory(token, categoryId)` - DELETE /income-categories/{id}

#### `lib/services/expense_category_service.dart`
Singleton service con los mismos métodos CRUD para gastos:
- `getCategories()` - GET /expense-categories/
- `createCategory()` - POST /expense-categories/
- `updateCategory()` - PATCH /expense-categories/{id}
- `deactivateCategory()` - Inactivar categoría
- `deleteCategory()` - DELETE /expense-categories/{id}

### Pantallas (Screens)

#### `lib/screens/income_category_screen.dart`

**IncomeCategoryScreen** (Pantalla Principal)
- Lista de todas las categorías activas
- Tarjetas con icono, nombre y descripción
- Estado visual diferente para categorías inactivas
- Menú popup con opciones:
  - ✏️ Editar
  - 🚫 Inactivar (con confirmación)
- Estados UI:
  - Loading (spinner)
  - Error (con botón reintentar)
  - Empty (sin categorías)
  - Populated (lista de categorías)

**AddIncomeCategoryScreen**
- Formulario para crear nueva categoría
- Campos validados:
  - Nombre (obligatorio, mín. 3 caracteres)
  - Descripción (obligatorio, mín. 5 caracteres)
- Mensaje de éxito antes de navegar
- Manejo de errores con mensaje legible

**EditIncomeCategoryScreen**
- Formulario pre-poblado con datos existentes
- Mismas validaciones que AddIncomeCategory
- Actualiza la categoría vía API
- Navega atrás después de guardar

#### `lib/screens/expense_category_screen.dart`

**ExpenseCategoryScreen** (Pantalla Principal)
- Estructura idéntica a IncomeCategoryScreen
- Lista de categorías de gastos
- Menú popup con Editar/Inactivar
- Mismo flujo de estados UI

**AddExpenseCategoryScreen**
- Formulario para crear nueva categoría de gasto
- Cambios de hint: "Alimentación, Transporte, etc"
- Validaciones idénticas

**EditExpenseCategoryScreen**
- Pre-poblada con datos de categoría
- Actualiza vía API
- Mismo flujo de navegación

---

## 🔗 Integración con HomeScreen

Se agregaron dos nuevas secciones en `HomeScreen`:

### 1. Módulos Disponibles (Ya Existente)
```
💰 Ingresos → IncomeScreen
💸 Gastos → (Próximamente)
📦 Inventario → (Próximamente)
```

### 2. Configuración de Categorías (NUEVA)
```
🏷️ Categorías de Ingresos → IncomeCategoryScreen
🏷️ Categorías de Gastos → ExpenseCategoryScreen
```

---

## 🎯 Funcionalidades Principales

### Crear Categoría
1. Usuario toca FAB o botón en card
2. Se abre formulario con campos validados
3. Envía POST a `/income-categories/` o `/expense-categories/`
4. Muestra mensaje de éxito
5. Navega atrás automáticamente
6. Se recarga la lista

### Editar Categoría
1. Usuario selecciona categoría activa (tap o menú)
2. Se abre formulario pre-poblado
3. Modifica campos validados
4. Envía PATCH a `/income-categories/{id}` o equivalente
5. Muestra mensaje de éxito
6. Navega atrás y recarga

### Inactivar Categoría
1. Usuario toca "Inactivar" en menú popup
2. Se muestra dialogo de confirmación
3. Envía PATCH con `isActive: false`
4. **Nota**: Los registros existentes siguen disponibles para auditoría
5. Se recarga la lista (categoría aparece como "Inactiva")
6. Categorías inactivas no pueden usarse para nuevos registros

### Restricciones

- **No se puede inactivar** una categoría si tiene registros activos asociados
  - El backend retorna error 400
  - La app muestra el mensaje de error al usuario
  
- **Categorías inactivas**:
  - No aparecen en lista (solo si GET /income-categories/ filtra activas)
  - Se muestran con estado "Inactiva" en gris
  - No se puede editar si está inactiva
  - Pueden tapped pero se deshabilita el tap

---

## 🎨 Diseño UI

### Tema
- Color primario: `Color(0xFF6200EE)` (Deep Purple)
- AppBar morado con botones
- Tarjetas con elevación
- Iconos personalizados por módulo

### Estados Visuales

**Categoría Activa**
```
🏷️ [Nombre]
   Descripción...
   ⋯ (Editar | Inactivar)
```

**Categoría Inactiva**
```
[Gris] Nombre (gris)
       Descripción (gris)
       [Inactiva] (badge)
```

### Formularios
- Validación en tiempo real
- Icons descriptivos
- Error container rojo si falla
- Loading spinner durante envío
- Botón deshabilitado mientras se carga

---

## 🔒 Seguridad

- Token JWT requerido para todas las operaciones de escritura
- Validación en cliente + servidor
- Mensajes de error genéricos cuando es apropiado
- Confirmación antes de acciones destructivas

---

## 📊 Endpoints API Utilizados

### Ingresos
- `GET /income-categories/` - Listar categorías activas
- `POST /income-categories/` - Crear categoría
- `PATCH /income-categories/{id}` - Editar o inactivar
- `DELETE /income-categories/{id}` - Eliminar

### Gastos
- `GET /expense-categories/` - Listar categorías activas
- `POST /expense-categories/` - Crear categoría
- `PATCH /expense-categories/{id}` - Editar o inactivar
- `DELETE /expense-categories/{id}` - Eliminar

---

## ✅ Validaciones

### Nombre
- Requerido
- Mínimo 3 caracteres
- Único por tipo (manejado por servidor)

### Descripción
- Requerido
- Mínimo 5 caracteres
- Máximo libre (texto)

### Estado
- `isActive` = true (nueva) o false (inactivada)
- No hay "eliminación física", solo lógica

---

## 🚀 Próximas Mejoras

1. **Búsqueda y Filtrado**
   - Buscar por nombre
   - Filtrar activas/inactivas

2. **Reasignación de Categorías**
   - Si se inactiva una categoría, reasignar registros

3. **Importación/Exportación**
   - CSV con listado de categorías
   - Importar categorías predefinidas

4. **Estadísticas**
   - Cuántos registros por categoría
   - Últimas usadas

---

## 📝 Notas Técnicas

- **Patrón Singleton**: Services reutilizan instancia única
- **Form Validation**: TextFormField con validators
- **Navigation**: MaterialPageRoute con resultados (true = recarga)
- **Error Handling**: Try/catch con mensajes legibles
- **State Management**: setState local + singleton services global
- **API Integration**: http package con Bearer token

---

**Estado**: ✅ Completado y compilado sin errores
**Próximo Paso**: Crear módulo de Gastos con categorías asociadas
