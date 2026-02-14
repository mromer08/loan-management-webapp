# loan-management-webapp
Fullstack application for managing banking loan applications, customers, and payments, built with Java Spring Boot, SQL Server, and Next.js.

## Requisitos
- Docker y Docker Compose (para ejecucion con contenedores).
- SQL Server disponible (local o remoto) y base de datos creada.
- Java 25.
- Maven 3.9+ (o usar `./mvnw`).
- Node.js 20+.
- pnpm.

## Documentacion
- Diseno backend (espanol): `docs/backend-diseno-solucion.md`
- Script de base de datos: `docs/resources/scripts/chn-database.sql`
- Diagrama de base de datos: `docs/resources/images/db-diagram.png`

## Variables de entorno
### Backend (`backend/.env`)
```env
PORT=8080
DB_HOST=localhost
DB_PORT=1433
DB_NAME=ExamDB
DB_USERNAME=sa
DB_PASSWORD=12345!
CORS_ALLOWED_ORIGINS=http://localhost:3000
```

### Frontend (`frontend/.env`)
Para Docker Compose:
```env
NEXT_PUBLIC_API_BASE_URL=http://backend:8080
```

Para desarrollo local:
```env
NEXT_PUBLIC_API_BASE_URL=http://localhost:8080
```

## Opcion 1: Ejecutar con Docker Compose
1. Crear o actualizar `backend/.env` y `frontend/.env` con los valores anteriores.
2. Compilar el backend (el Dockerfile del backend usa el `.jar` generado en `target/`):
```bash
cd backend
./mvnw clean package -DskipTests
cd ..
```
3. Levantar contenedores:
```bash
docker compose up --build
```
4. Acceder a:
- Frontend: `http://localhost:3000`
- Backend API: `http://localhost:8080`
- Swagger: `http://localhost:8080/swagger-ui/index.html`

Nota: este `docker-compose.yaml` no crea SQL Server. Debes tener la base de datos disponible externamente y configurar `DB_HOST` correctamente.

## Opcion 2: Ejecutar en desarrollo local
1. Crear o actualizar `.env` en backend y frontend (usando `localhost`).
2. Ejecutar backend:
```bash
cd backend
./mvnw spring-boot:run
```
3. En otra terminal, ejecutar frontend:
```bash
cd frontend
corepack enable
pnpm install
pnpm dev
```
4. Acceder a:
- Frontend: `http://localhost:3000`
- Backend API: `http://localhost:8080`
- Swagger: `http://localhost:8080/swagger-ui/index.html`
