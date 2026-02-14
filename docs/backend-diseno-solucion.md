# Diseño de la Solución Backend

## 1. Objetivo
Este backend implementa una API REST para gestionar:

- Clientes.
- Solicitudes de préstamo.
- Aprobación/rechazo de solicitudes.
- Registro de pagos de préstamos aprobados.
- Cálculo y seguimiento de saldo pendiente.

La solución está construida con **Spring Boot + JPA (Hibernate) + SQL Server**.

## 2. Alcance funcional implementado
En relación con el enunciado del examen, el backend cubre:

### Gestión de clientes
- Crear cliente con validaciones de negocio y formato.
- Listar clientes con paginación y filtro por término de búsqueda.
- Consultar cliente por ID.
- Editar cliente.
- Eliminar cliente.
- Regla adicional: no permite eliminar cliente si tiene préstamos aprobados no pagados.

### Solicitudes de préstamo
- Crear solicitud para un cliente existente.
- Consultar préstamos de un cliente (con filtro por estado).
- Consultar préstamo por ID.
- Aprobar solicitud (calculando monto total y saldo inicial).
- Rechazar solicitud.
- Registrar historial de estados por cada cambio.

### Préstamos aprobados y pagos
- Listar pagos por préstamo.
- Registrar pago en efectivo.
- Actualizar saldo pendiente automáticamente.
- Actualizar estado de pago: `UNPAID`, `PARTIALLY_PAID`, `PAID`.

## 3. Arquitectura técnica
Se usa una arquitectura en capas:

- `controller`: expone endpoints REST.
- `service`: reglas de negocio y validaciones de dominio.
- `repository`: acceso a datos con Spring Data JPA.
- `model`: entidades JPA y enums.
- `dto`: contratos de entrada/salida.
- `mapper`: transformación entidad <-> DTO con MapStruct.
- `common`: manejo global de excepciones, paginación, configuración CORS/OpenAPI.

Patrones aplicados:

- Transacciones con `@Transactional` en servicios.
- Validación con Bean Validation (`@Valid`, `@NotNull`, `@Pattern`, etc.).
- Búsquedas dinámicas con `Specification`.
- Auditoría automática de `createdAt` y `updatedAt`.

## 4. Modelo de datos
El diseño físico está en:

- `docs/resources/scripts/chn-database.sql`
- `backend/src/main/resources/db/migration/`

Tablas principales:

1. `customers`
- Datos personales y contacto.
- Unicidad en `identification_number`, `email` y `phone_number`.

2. `loans`
- Relación N:1 con `customers`.
- Estado del flujo de préstamo (`IN_PROCESS`, `APPROVED`, `REJECTED`).
- Datos financieros: monto, plazo, interés, total a pagar, saldo pendiente.
- Estado de pago: `UNPAID`, `PARTIALLY_PAID`, `PAID`.

3. `loan_status_history`
- Bitácora de cambios de estado por préstamo.
- Guarda notas de revisión.

4. `loan_payments`
- Pagos realizados por préstamo.
- Método de pago actual soportado: `CASH`.

Relaciones:

- `customers` 1 -> N `loans` (con borrado en cascada).
- `loans` 1 -> N `loan_status_history` (cascada).
- `loans` 1 -> N `loan_payments` (cascada).

## 5. Reglas de negocio clave
### Clientes
- No se permite duplicar número de identificación, correo o teléfono.
- La eliminación de cliente se bloquea si tiene préstamos `APPROVED` con estado de pago distinto de `PAID`.

### Préstamos
- Toda solicitud nueva entra como `IN_PROCESS`.
- Tasa anual por defecto: `5.00` cuando no se envía.
- Solo se puede aprobar/rechazar si el estado actual es `IN_PROCESS`.
- Al aprobar:
  - Calcula `totalPayable`.
  - Inicializa `outstandingBalance = totalPayable`.
  - Define `paymentStatus = UNPAID`.
  - Cambia estado a `APPROVED`.
- Al rechazar:
  - Cambia estado a `REJECTED`.
- Cada transición crea un registro en `loan_status_history`.

Fórmula usada para monto total a pagar:

```text
termInYears = termMonths / 12
totalInterest = amount * annualInterestRate * termInYears / 100
totalPayable = amount + totalInterest
```

### Pagos
- Solo acepta pagos para préstamos `APPROVED`.
- El monto del pago no puede exceder el saldo pendiente.
- Si saldo queda en `0.00` -> `PAID`; si no -> `PARTIALLY_PAID`.

## 6. Contrato de API (resumen)
Prefijo base: `/api/v1`

### Clientes
- `GET /customers`
  - Query: `searchTerm`, parámetros de paginación (`page`, `size`, `sort`).
- `GET /customers/{id}`
- `POST /customers`
- `PUT /customers/{id}`
- `DELETE /customers/{id}`

### Préstamos
- `GET /loans/{loanId}`
- `GET /customers/{customerId}/loans`
  - Query opcional: `status` (`IN_PROCESS`, `APPROVED`, `REJECTED`).
- `GET /loans/{loanId}/history`
- `POST /customers/{customerId}/loans`
- `POST /loans/{loanId}/approve`
- `POST /loans/{loanId}/reject`

### Pagos
- `GET /loans/{loanId}/payments`
- `POST /loans/{loanId}/payments`

## 7. Validaciones de entrada
Ejemplos relevantes:

- Cliente:
  - `firstName` y `lastName`: 2..50.
  - `identificationNumber`: exactamente 13 dígitos.
  - `phone`: exactamente 8 dígitos.
  - `birthDate`: fecha pasada.
  - `email`: formato válido.
- Solicitud de préstamo:
  - `amount` > 0, con 2 decimales.
  - `termMonths` positivo.
  - `annualInterestRate` opcional, mínimo 0.
- Revisión de solicitud:
  - `notes` obligatorio.
- Pago:
  - `amount` > 0.
  - `paymentMethod` obligatorio (`CASH`).

## 8. Manejo de errores
Se usa `GlobalExceptionHandler` con respuestas tipo `ProblemDetail`:

- `404 Not Found`: entidad no encontrada.
- `409 Conflict`: entidad duplicada.
- `400 Bad Request`: regla de negocio o validación.

Para errores de validación de campos, la respuesta incluye:

- `title = "Validation Error"`
- `errors` con detalle por campo.

## 9. Configuración y ejecución
Configuración principal en `backend/src/main/resources/application.yaml`:

- Puerto por defecto: `8080`.
- Base de datos: SQL Server (`jdbc:sqlserver://...`).
- CORS para `/api/**` (origen por defecto: `http://localhost:3000`).
- OpenAPI activo.

Variables usadas (archivo `backend/.env`):

- `PORT`
- `DB_NAME`
- `DB_USERNAME`
- `DB_PASSWORD`
- `CORS_ALLOWED_ORIGINS`

## 10. Endpoints de soporte
- Swagger UI: `/swagger-ui/index.html`
- OpenAPI JSON: `/v3/api-docs`

## 11. Decisiones de diseño
- UUID como llave primaria para evitar colisiones y facilitar integración distribuida.
- Historial de estado separado (`loan_status_history`) para trazabilidad.
- Lógica de negocio concentrada en servicios para mantener controladores livianos.
- DTOs para desacoplar contrato API del modelo de persistencia.
- Paginación estándar reutilizable con `PagedResponseDTO`.

## 12. Cobertura del examen
El backend cumple los tres bloques del enunciado:

1. Gestión de clientes.
2. Ciclo de solicitud y revisión de préstamos.
3. Gestión de préstamos aprobados, pagos y saldo pendiente.

Con esto la capa backend queda lista para consumo por el frontend y pruebas manuales desde Swagger o cliente HTTP.
