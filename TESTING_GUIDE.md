# 🧪 Guía de Testing - Flutter Web App

## 🚀 Cómo Ejecutar

```bash
cd d:\app\flutter_application_1
flutter run -d chrome
```

La app se abrirá en: `http://localhost:60503` (puerto puede variar)

## 📋 Credenciales de Prueba

Usar las siguientes credenciales para probar (primero registrarse):

### Registro de Prueba
```
Email: test@example.com
Contraseña: Test123456
Nombre: Juan
Apellido Paterno: Pérez
Apellido Materno: García
RUT: 20.000.000-0
Fecha Nacimiento: 1990-01-15
```

### Login de Prueba
```
Email: test@example.com
Contraseña: Test123456
```

## ✅ Casos de Prueba

### 1. Pantalla de Login
- [ ] Cargar página principal
- [ ] Verificar formulario de login
- [ ] Intentar login sin datos (mostrar errores)
- [ ] Intentar login con email inválido
- [ ] Intentar login con contraseña incorrecta
- [ ] Login exitoso redirige a Home
- [ ] Botón "Regístrate aquí" abre pantalla de registro

### 2. Pantalla de Registro
- [ ] Acceder desde botón "Regístrate aquí"
- [ ] Validar campos vacíos
- [ ] Validar email inválido
- [ ] Validar contraseña < 6 caracteres
- [ ] Validar contraseñas no coinciden
- [ ] Validar RUT requerido
- [ ] Validar fecha de nacimiento requerida
- [ ] Selector de fecha funciona correctamente
- [ ] Registro exitoso redirige a Home
- [ ] Botón "Inicia sesión" vuelve a login

### 3. Pantalla Home
- [ ] Muestra datos del usuario correctamente
- [ ] Muestra email, RUT, edad, teléfono
- [ ] Muestra estado de cuenta (Activo/Inactivo)
- [ ] Muestra último login
- [ ] Botón logout en AppBar funciona
- [ ] Confirma logout antes de cerrar sesión
- [ ] Logout redirige a login

### 4. Validaciones de Formulario
- [ ] Email requerido
- [ ] Email debe contener @
- [ ] Contraseña mínimo 6 caracteres
- [ ] Confirmación de contraseña debe coincidir
- [ ] Nombre requerido
- [ ] Apellido paterno requerido
- [ ] RUT requerido
- [ ] Fecha nacimiento requerida

### 5. Manejo de Errores
- [ ] Error 401: Usuario no encontrado
- [ ] Error 400: Email ya registrado
- [ ] Error 400: RUT ya registrado
- [ ] Error 400: RUT inválido
- [ ] Conexión fallida a backend
- [ ] Mensajes de error claros y útiles

## 🔄 Flujos Completos

### Flujo 1: Nuevo Usuario
1. Abrir app
2. Clic en "Regístrate aquí"
3. Llenar formulario de registro
4. Clic "Crear Cuenta"
5. Verificar redirección a Home
6. Verificar datos mostrados correctamente
7. Logout y verificar redirección a Login

### Flujo 2: Usuario Existente
1. Abrir app (en login)
2. Ingresar email y contraseña
3. Clic "Iniciar Sesión"
4. Verificar redirección a Home
5. Verificar datos son los correctos

### Flujo 3: Manejo de Token
1. Login exitoso
2. Token se obtiene y almacena
3. Logout
4. Token se invalida
5. Intentar acceder a /auth/profile falla (401)

## 🖥️ Testing en Diferentes Navegadores

Probar en:
- [ ] Chrome/Chromium
- [ ] Firefox
- [ ] Safari (macOS)
- [ ] Edge

## 📐 Responsive Design

Probar en diferentes tamaños:
- [ ] Desktop (1920x1080)
- [ ] Tablet (768x1024)
- [ ] Teléfono (375x667)

Verificar:
- [ ] Formularios legibles
- [ ] Botones clicables
- [ ] Texto visible
- [ ] Layout sin overflow

## 🔌 Backend API

Antes de ejecutar la app web, asegurar que backend esté corriendo:

```bash
cd path/to/backend
npm start
# O con nodemon: npm run dev
```

Verificar que API esté disponible:
```bash
curl http://localhost:5000/
# Respuesta esperada: "Se ha conectado correctamente..."
```

## 🛠️ Developer Tools

### Console
- [ ] No hay errores no controlados
- [ ] No hay warnings críticos
- [ ] Logs de autenticación visibles (opcional)

### Network
- [ ] Petición login a `POST /auth/login` (200)
- [ ] Petición register a `POST /auth/register` (201)
- [ ] Petición profile a `GET /auth/profile` (200)
- [ ] Headers Authorization correctos

### Performance
- [ ] App carga en < 3 segundos
- [ ] Sin memory leaks evidentes
- [ ] Hot reload funciona (flutter run)

## 🐛 Bugs Conocidos / Por Corregir

```
[RESOLVER]
- [ ] Validación de RUT chileno (formato y dígito verificador)
- [ ] Manejo de errores 500 del backend
- [ ] Re-intentos automáticos en caso de timeout
- [ ] Guardar token en local storage (persistencia)
```

## 📊 Checklist Final

- [ ] App inicia sin errores
- [ ] Login funciona
- [ ] Registro funciona
- [ ] Home muestra datos correctos
- [ ] Logout funciona
- [ ] Validaciones funcionan
- [ ] Errores mostrados correctamente
- [ ] Responsive en múltiples pantallas
- [ ] API conecta correctamente
- [ ] Sin memory leaks
- [ ] UI/UX es intuitiva

## 📞 Contacto / Soporte

En caso de errores durante testing:
1. Revisar console en DevTools
2. Verificar backend está corriendo
3. Revisar networking en DevTools
4. Comprobar credentials correctas

---

**Última actualización**: Diciembre 2025
