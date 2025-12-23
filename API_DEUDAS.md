# Documentación API de Deudas, Bancos y Tarjetas
> **Nota:** Requiere `Authorization: Bearer <TOKEN>` en todos los endpoints.

## 1. Maestros: Bancos y Tarjetas

### Bancos
*   `GET /bank`: Listar bancos activos.
*   `POST /bank`: Crear banco.
    *   Body: `{ "name": "Banco Estado" }`
*   `PUT /bank/:id`: Editar/Desactivar.
    *   Body: `{ "name": "Nuevo Nombre", "id_estado": 2 }` (2 = Inactivo)
*   `DELETE /bank/:id`: Eliminar (Soft Delete).

### Tarjetas
*   `GET /credit-card`: Listar tarjetas activas (incluye info de su banco).
*   `POST /credit-card`: Crear tarjeta.
    *   Body: `{ "name": "Cuenta RUT", "bankId": 1 }`
*   `PUT /credit-card/:id`: Editar/Desactivar.
    *   Body: `{ "name": "Nueva Visa", "id_estado": 2 }`
*   `DELETE /credit-card/:id`: Eliminar (Soft Delete).

---

## 2. Deudas (Debts)

### Crear Deuda
Ahora se vincula a una **Tarjeta** (`creditCardId`) en lugar de escribir textos.

```json
POST /debt
{
  "creditCardId": 1, 
  "totalAmount": 1200000,
  "installments": 12,
  "categoryId": 1,
  "description": "Compra Gamer",
  "startDate": "2024-01-05" 
}
```

### Listar Deudas
```
GET /debt?year=2024&month=12
```
Retorna listado con info de la deuda + tarjeta + banco.

### Editar Deuda
```json
PUT /debt/:id
{
  "installments": 6, 
  "creditCardId": 2 
}
```
*Si cambias tarjeta, cuotas, monto o fecha, se regeneran los gastos futuros.*
