# Inventory Audit Portal

A full-stack inventory management system with comprehensive audit logging, built with Spring Boot and React.

## Table of Contents

- [Features](#features)
- [Technology Stack](#technology-stack)
- [Quick Start](#quick-start)
- [Development Setup](#development-setup)
- [API Documentation](#api-documentation)
- [Architecture Overview](#architecture-overview)
- [Performance Optimizations](#performance-optimizations)
- [Production Deployment](#production-deployment)
- [Configuration](#configuration)
- [Project Structure](#project-structure)
- [Author](#author)

## Features

- **Inventory Management**: Full CRUD operations for inventory items
- **Search & Filter**: Search by SKU or name, filter by location
- **Audit Trail**: Complete audit logging for all changes
- **Location Summary**: Dashboard view of inventory distribution
- **RESTful API**: Well-documented REST API with Swagger
- **Responsive UI**: Modern React frontend with Tailwind CSS
- **User Authentication**: JWT-based authentication with role-based access control
- **Password Reset**: Email-based password reset functionality

## Technology Stack

### Backend
- Java 17
- Spring Boot 3.5.9
- PostgreSQL
- Spring Data JPA
- Caffeine Cache
- Flyway (Database Migrations)
- Spring Boot Actuator (Health Checks)
- Swagger/OpenAPI (API Documentation)
- Spring Security (JWT Authentication)

### Frontend
- React 18
- React Router
- Tailwind CSS
- Vite

## Quick Start

### Prerequisites
- **Docker Desktop 4.0+** (includes Docker Compose v2.0+) - Recommended
  - OR **Docker Engine 20.10+** with **Docker Compose v2.0+**
- **Git** (to clone the repository)
- OR for manual setup: Java 17+, Maven 3.6+, Node.js 18+, PostgreSQL 12+

### Docker Deployment (Recommended)

The easiest way to get started:

```bash
# Clone the repository
git clone <repository-url>
cd inventory-audit-portal

# Create .env file (optional - defaults provided)
# See Configuration section for details

# Start all services
docker-compose -f docker-compose.prod.yaml up -d
```

This will start:
- PostgreSQL database (port 5432)
- Spring Boot backend (port 8080)
- React frontend (port 3000)

Access the application:
- Frontend: `http://localhost:3000`
- Backend API: `http://localhost:8080`
- Swagger UI: `http://localhost:8080/swagger-ui.html`
- Health Check: `http://localhost:8080/actuator/health`

**Default Login Credentials:**
- Username: `vtiradoegas`
- Password: `walmart2002!`
- Email: `vtiradoegas@gmail.com`

## Development Setup

### 1. Start Database

```bash
cd db
docker-compose up -d
```

This starts PostgreSQL on port 5432 with:
- Database: `invdb`
- Username: `invuser`
- Password: `invpass`

### 2. Start Backend

```bash
cd backend
./mvnw spring-boot:run
```

Backend will be available at `http://localhost:8080`

### 3. Start Frontend

```bash
cd frontend
npm install
npm run dev
```

Frontend will be available at `http://localhost:5173`

### Running Tests

**Backend:**
```bash
cd backend
./mvnw test
```

**Backend Test Script:**
```bash
cd backend
./test-backend.sh
```

### Database Migrations

Migrations are handled automatically by Flyway. To create a new migration:

1. Create a file: `backend/src/main/resources/db/migration/V5__Your_migration_name.sql`
2. Flyway will run it automatically on next startup

## API Documentation

### Swagger UI

Once the backend is running, access Swagger UI at:
- `http://localhost:8080/swagger-ui.html`
- API Docs: `http://localhost:8080/api-docs`

### Health Checks

- Health: `http://localhost:8080/actuator/health`
- Info: `http://localhost:8080/actuator/info`
- Metrics: `http://localhost:8080/actuator/metrics`

### Inventory Item Endpoints

Base URL: `/api/inventory`

#### List All Items
```
GET /api/inventory
```
Returns paginated list of all inventory items.

**Query Parameters:**
- `page` (default: 0) - Page number (0-indexed)
- `size` (default: 50) - Page size (max: 1000)
- `sortBy` (default: "updatedAt") - Sort field: id, sku, name, qty, location, updatedAt
- `sortDir` (default: "DESC") - Sort direction: ASC or DESC

**Response:** `Page<InventoryItem>`

#### Get Item by ID
```
GET /api/inventory/{id}
```
Returns a single inventory item by its ID.

**Path Parameters:**
- `id` - Item ID (Long)

**Response:** `InventoryItem`

#### Get Item by SKU
```
GET /api/inventory/sku/{sku}
```
Returns a single inventory item by its unique SKU.

**Path Parameters:**
- `sku` - Stock Keeping Unit (String)

**Response:** `InventoryItem`

#### Get Items by Location
```
GET /api/inventory/location/{location}
```
Returns paginated list of items filtered by location.

**Path Parameters:**
- `location` - Location identifier (String)

**Query Parameters:** Same as List All Items

**Response:** `Page<InventoryItem>`

#### Search by SKU Pattern
```
GET /api/inventory/search/sku?pattern={pattern}
```
Performs case-insensitive partial match search on SKU field.

**Query Parameters:**
- `pattern` (required) - Search pattern (String)
- `page` (default: 0)
- `size` (default: 50)

**Response:** `Page<InventoryItem>`

#### Search by Name Pattern
```
GET /api/inventory/search/name?pattern={pattern}
```
Performs case-insensitive partial match search on name field.

**Query Parameters:** Same as Search by SKU Pattern

**Response:** `Page<InventoryItem>`

#### Get Location Summary
```
GET /api/inventory/summary/location
```
Returns aggregated statistics grouped by location.

**Response:** `List<Object[]>` where each array contains [location, count, totalQty]

#### Create Item
```
POST /api/inventory
```
Creates a new inventory item.

**Request Body:**
```json
{
  "sku": "string (required, unique)",
  "name": "string (required)",
  "qty": "integer (required, min: 0)",
  "location": "string (required)"
}
```

**Response:** `InventoryItem` (201 Created)

#### Create Items Batch
```
POST /api/inventory/batch
```
Creates multiple inventory items in a single transaction.

**Request Body:** `List<InventoryItemRequest>`

**Response:** `List<InventoryItem>` (201 Created)

#### Update Item
```
PUT /api/inventory/{id}
```
Updates an existing inventory item.

**Path Parameters:**
- `id` - Item ID (Long)

**Request Body:** Same as Create Item

**Response:** `InventoryItem`

#### Delete Item
```
DELETE /api/inventory/{id}
```
Deletes an inventory item by ID.

**Path Parameters:**
- `id` - Item ID (Long)

**Response:** 204 No Content

### Audit Event Endpoints

Base URL: `/api/audit-events`

#### List All Audit Events
```
GET /api/audit-events
```
Returns paginated list of all audit events.

**Query Parameters:**
- `page` (default: 0)
- `size` (default: 50)
- `sortBy` (default: "timestamp") - Sort field: id, eventType, entityType, entityId, userId, timestamp
- `sortDir` (default: "DESC") - Sort direction: ASC or DESC

**Response:** `Page<AuditEvent>`

#### Get Audit Event by ID
```
GET /api/audit-events/{id}
```
Returns a single audit event by ID.

**Path Parameters:**
- `id` - Event ID (Long)

**Response:** `AuditEvent`

#### Get Events by Entity
```
GET /api/audit-events/entity/{entityType}/{entityId}
```
Returns paginated audit events for a specific entity.

**Path Parameters:**
- `entityType` - Entity type (String)
- `entityId` - Entity ID (Long)

**Query Parameters:** Same as List All Audit Events

**Response:** `Page<AuditEvent>`

#### Get Events by Entity Type
```
GET /api/audit-events/entity-type/{entityType}
```
Returns paginated audit events filtered by entity type.

**Path Parameters:**
- `entityType` - Entity type (String)

**Query Parameters:** Same as List All Audit Events

**Response:** `Page<AuditEvent>`

#### Get Events by Event Type
```
GET /api/audit-events/event-type/{eventType}
```
Returns paginated audit events filtered by event type (CREATE, UPDATE, DELETE, READ).

**Path Parameters:**
- `eventType` - Event type (String)

**Query Parameters:** Same as List All Audit Events

**Response:** `Page<AuditEvent>`

#### Get Events by User ID
```
GET /api/audit-events/user/{userId}
```
Returns paginated audit events filtered by user ID.

**Path Parameters:**
- `userId` - User identifier (String)

**Query Parameters:** Same as List All Audit Events

**Response:** `Page<AuditEvent>`

### User Authentication Endpoints

Base URL: `/api/auth`

#### Register
```
POST /api/auth/register
```
Creates a new user account.

**Request Body:**
```json
{
  "username": "string (required)",
  "email": "string (required, email format)",
  "password": "string (required, min: 8)"
}
```

**Response:** `AuthResponse` (201 Created)

#### Login
```
POST /api/auth/login
```
Authenticates a user and returns a JWT token.

**Request Body:**
```json
{
  "username": "string (required)",
  "password": "string (required)"
}
```

**Response:** `AuthResponse` with JWT token

#### Forgot Password
```
POST /api/auth/forgot-password
```
Sends a password reset email (or logs reset URL if email disabled).

**Request Body:**
```json
{
  "email": "string (required, email format)"
}
```

**Response:** 200 OK

#### Reset Password
```
POST /api/auth/reset-password
```
Resets password using a reset token.

**Request Body:**
```json
{
  "token": "string (required)",
  "newPassword": "string (required, min: 8)"
}
```

**Response:** 200 OK

## Architecture Overview

The application follows a layered architecture pattern:

- **Controller Layer**: Handles HTTP requests, validates input, and returns responses
- **Service Layer**: Contains business logic and orchestrates data operations
- **Repository Layer**: Provides data access abstraction using Spring Data JPA
- **Entity Layer**: JPA entities representing database tables

All mutations (CREATE, UPDATE, DELETE) automatically generate audit events that track changes with timestamps, user information, and detailed change descriptions.

### Database Schema

#### InventoryItem Table
```sql
CREATE TABLE inventory_items (
    id BIGSERIAL PRIMARY KEY,
    sku VARCHAR(255) NOT NULL UNIQUE,
    name VARCHAR(255) NOT NULL,
    qty INTEGER NOT NULL,
    location VARCHAR(255) NOT NULL,
    updated_at TIMESTAMP NOT NULL
);

CREATE INDEX idx_sku ON inventory_items(sku);
CREATE INDEX idx_location ON inventory_items(location);
CREATE INDEX idx_updated_at ON inventory_items(updated_at);
CREATE INDEX idx_location_updated ON inventory_items(location, updated_at);
```

#### AuditEvent Table
```sql
CREATE TABLE audit_events (
    id BIGSERIAL PRIMARY KEY,
    event_type VARCHAR(255) NOT NULL,
    entity_type VARCHAR(255) NOT NULL,
    entity_id BIGINT NOT NULL,
    user_id VARCHAR(255),
    details TEXT,
    timestamp TIMESTAMP NOT NULL
);

CREATE INDEX idx_entity_type_id ON audit_events(entity_type, entity_id);
CREATE INDEX idx_user_id ON audit_events(user_id);
CREATE INDEX idx_timestamp ON audit_events(timestamp);
CREATE INDEX idx_event_type ON audit_events(event_type);
```

## Performance Optimizations

### Database Indexing Strategy

**InventoryItem Table:**
- `idx_sku`: Unique index on SKU for O(log n) lookups
- `idx_location`: Index on location for filtering
- `idx_updated_at`: Index on updatedAt for sorting
- `idx_location_updated`: Composite index on (location, updatedAt) for efficient location queries with sorting

**AuditEvent Table:**
- `idx_entity_type_id`: Composite index on (entityType, entityId) for entity-specific queries
- `idx_user_id`: Index on userId for user activity tracking
- `idx_timestamp`: Index on timestamp for chronological queries
- `idx_event_type`: Index on eventType for filtering by operation type

### Caching Strategy

**Caffeine Cache Configuration:**
- Maximum size: 10,000 entries
- Expire after write: 30 minutes
- Expire after access: 15 minutes
- Statistics enabled for monitoring

**Cached Operations:**
- `get(id)`: Cached by item ID
- `getBySku(sku)`: Cached by SKU with key prefix "sku:"

**Cache Invalidation:**
- All cache entries are invalidated on CREATE, UPDATE, DELETE operations
- Ensures data consistency at the cost of cache efficiency

### Connection Pooling

**HikariCP Configuration:**
- Maximum pool size: 20 connections
- Minimum idle: 5 connections
- Connection timeout: 30 seconds
- Idle timeout: 10 minutes
- Max lifetime: 30 minutes

### JPA Batch Processing

**Hibernate Batch Settings:**
- Batch size: 50 operations per batch
- Ordered inserts: Enabled
- Ordered updates: Enabled
- Batch versioned data: Enabled

These settings optimize batch operations by reducing database round trips.

## Production Deployment

### Docker Deployment

The easiest way to deploy is using Docker Compose:

```bash
docker-compose -f docker-compose.prod.yaml up -d
```

### Environment Configuration

Create a `.env` file in the project root:

```bash
# Database
DATABASE_NAME=invdb
DATABASE_USERNAME=invuser
DATABASE_PASSWORD=your-secure-password-here

# Backend
BACKEND_PORT=8080
CORS_ALLOWED_ORIGINS=https://yourdomain.com,https://www.yourdomain.com

# Frontend
FRONTEND_PORT=80
VITE_API_BASE_URL=https://api.yourdomain.com/api

# Database Port (if exposing)
DB_PORT=5432
```

### Manual Deployment

#### Backend

1. **Build the application:**
   ```bash
   cd backend
   ./mvnw clean package -DskipTests
   ```

2. **Set environment variables:**
   ```bash
   export DATABASE_URL=jdbc:postgresql://your-db-host:5432/invdb
   export DATABASE_USERNAME=invuser
   export DATABASE_PASSWORD=your-password
   export SPRING_PROFILES_ACTIVE=prod
   export CORS_ALLOWED_ORIGINS=https://yourdomain.com
   export SWAGGER_ENABLED=false
   export DDL_AUTO=validate
   ```

3. **Run the application:**
   ```bash
   java -jar target/inventory-audit-portal-0.0.1-SNAPSHOT.jar
   ```

#### Frontend

1. **Build the application:**
   ```bash
   cd frontend
   npm install
   npm run build
   ```

2. **Configure API URL:**
   Create `.env.production`:
   ```bash
   VITE_API_BASE_URL=https://api.yourdomain.com/api
   ```

3. **Serve the application:**
   - Copy `dist/` contents to your web server
   - Configure nginx/Apache to serve the files
   - Or use the provided Dockerfile

### Production Checklist

#### Security
- [ ] Change default database passwords
- [ ] Configure HTTPS/TLS certificates
- [ ] Set `CSRF_ENABLED=true` if using session auth
- [ ] Restrict CORS origins to your domain only
- [ ] Disable Swagger UI (`SWAGGER_ENABLED=false`)
- [ ] Review and restrict actuator endpoints
- [ ] Set up firewall rules
- [ ] Enable rate limiting (consider adding Spring Cloud Gateway)

#### Database
- [ ] Set `DDL_AUTO=validate` (prevents auto schema changes)
- [ ] Enable Flyway migrations (`FLYWAY_ENABLED=true`)
- [ ] Set up automated database backups
- [ ] Configure connection pooling appropriately
- [ ] Monitor database performance

#### Monitoring & Logging
- [ ] Configure log rotation
- [ ] Set up log aggregation (ELK, CloudWatch, etc.)
- [ ] Configure health check monitoring
- [ ] Set up alerts for errors
- [ ] Monitor application metrics
- [ ] Set up APM (Application Performance Monitoring)

#### Infrastructure
- [ ] Set up load balancing (if multiple instances)
- [ ] Configure auto-scaling
- [ ] Set up CI/CD pipeline
- [ ] Configure environment-specific configs
- [ ] Set up SSL certificates
- [ ] Configure DNS

#### Application
- [ ] Test all API endpoints
- [ ] Verify audit logging works
- [ ] Test search and filtering
- [ ] Verify pagination
- [ ] Test error handling
- [ ] Load testing

### Backup & Recovery

#### Database Backup

```bash
# Using pg_dump
pg_dump -h localhost -U invuser -d invdb > backup.sql

# Restore
psql -h localhost -U invuser -d invdb < backup.sql
```

#### Automated Backups

Set up a cron job or use your cloud provider's backup service:

```bash
# Daily backup at 2 AM
0 2 * * * pg_dump -h localhost -U invuser -d invdb > /backups/invdb_$(date +\%Y\%m\%d).sql
```

### Scaling

#### Horizontal Scaling

1. Run multiple backend instances behind a load balancer
2. Use sticky sessions if needed
3. Ensure shared database
4. Configure session replication (if using sessions)

#### Database Scaling

- Consider read replicas for read-heavy workloads
- Use connection pooling effectively
- Monitor query performance
- Consider database sharding for very large datasets

## Configuration

### Email Configuration

The application supports password reset emails via SMTP. For proof of concept, email is disabled by default and reset URLs are logged to the console.

#### Development (Email Disabled)

By default, email is disabled. When a user requests a password reset:
- The reset URL is logged to the backend console
- Copy the URL from the logs to reset the password
- No SMTP configuration needed

#### Production Email Setup

To enable email in production, configure SMTP settings:

**Environment Variables:**
```bash
EMAIL_ENABLED=true
SMTP_HOST=smtp.gmail.com          # or your SMTP provider
SMTP_PORT=587
SMTP_USERNAME=your-email@gmail.com
SMTP_PASSWORD=your-app-password   # Use App Password for Gmail
EMAIL_FROM=noreply@yourdomain.com
```

**Gmail Setup:**
1. Enable 2-Step Verification in your Google Account
2. Generate an App Password: Google Account → Security → App Passwords
3. Use the 16-character app password (not your regular password)

**Other Providers:**
- **SendGrid**: `smtp.sendgrid.net`, port 587
- **AWS SES**: Use AWS credentials and SES SMTP settings
- **Mailgun**: Use Mailgun SMTP settings
- **Office 365**: `smtp.office365.com`, port 587

**Security Note**: Never commit SMTP credentials to version control. Always use environment variables or a secrets manager.

### Admin User Configuration

A default admin user is automatically created on application startup if it doesn't already exist.

**Environment Variables:**
```bash
ADMIN_EMAIL=vtiradoegas@gmail.com    # Admin email address
ADMIN_USERNAME=vtiradoegas           # Admin username
ADMIN_PASSWORD=walmart2002!          # Admin password (CHANGE IN PRODUCTION!)
ADMIN_ENABLED=true                   # Set to false to disable admin creation
```

**Default Values (Development):**
- Email: `vtiradoegas@gmail.com`
- Username: `vtiradoegas`
- Password: `walmart2002!`
- Enabled: `true`

**Production Security:**
- **IMPORTANT**: Change the default admin password in production!
- Set `ADMIN_PASSWORD` environment variable to a strong password
- Consider disabling admin creation (`ADMIN_ENABLED=false`) after initial setup
- Use environment variables or secrets manager, never hardcode credentials

### Environment Variables Reference

#### Backend

| Variable | Default | Description |
|----------|---------|-------------|
| `SERVER_PORT` | 8080 | Server port |
| `DATABASE_URL` | jdbc:postgresql://localhost:5432/invdb | Database connection URL |
| `DATABASE_USERNAME` | invuser | Database username |
| `DATABASE_PASSWORD` | invpass | Database password |
| `DDL_AUTO` | update | Hibernate DDL mode (use `validate` in prod) |
| `FLYWAY_ENABLED` | true | Enable Flyway migrations |
| `CORS_ALLOWED_ORIGINS` | http://localhost:* | CORS allowed origins |
| `CSRF_ENABLED` | false | Enable CSRF protection |
| `SWAGGER_ENABLED` | true | Enable Swagger UI |
| `LOG_LEVEL` | INFO | Logging level |
| `LOG_FILE` | logs/inventory-audit-portal.log | Log file path |
| `JWT_SECRET` | defaultSecretKey... | JWT secret key (CHANGE IN PRODUCTION!) |
| `JWT_EXPIRATION` | 86400000 | JWT expiration in milliseconds (24 hours) |
| `EMAIL_ENABLED` | false | Enable email functionality |
| `SMTP_HOST` | smtp.gmail.com | SMTP server host |
| `SMTP_PORT` | 587 | SMTP server port |
| `SMTP_USERNAME` | | SMTP username |
| `SMTP_PASSWORD` | | SMTP password |
| `EMAIL_FROM` | noreply@inventory-audit-portal.com | From email address |

#### Frontend

| Variable | Default | Description |
|----------|---------|-------------|
| `VITE_API_BASE_URL` | /api | API base URL |

### Troubleshooting

#### Database Connection Issues

- Verify database is running and accessible
- Check connection string format
- Verify credentials
- Check firewall rules

#### CORS Errors

- Verify `CORS_ALLOWED_ORIGINS` includes your frontend domain
- Check browser console for specific CORS errors
- Ensure credentials are handled correctly

#### Migration Issues

- Check Flyway logs for migration errors
- Verify database user has CREATE/ALTER permissions
- Review migration files for syntax errors

#### Health Check Failures

- Verify database connectivity
- Check application logs
- Verify actuator endpoints are accessible

## Project Structure

```
inventory-audit-portal/
├── backend/              # Spring Boot API
│   ├── src/
│   │   ├── main/
│   │   │   ├── java/     # Java source code
│   │   │   │   └── com/inventory/audit/
│   │   │   │       ├── audit/          # Audit event domain
│   │   │   │       ├── common/         # Common utilities
│   │   │   │       ├── config/          # Configuration classes
│   │   │   │       ├── inventory/      # Inventory domain
│   │   │   │       └── user/           # User authentication domain
│   │   │   └── resources/
│   │   │       ├── db/migration/       # Flyway migrations
│   │   │       └── application.yaml    # Application configuration
│   │   └── test/         # Tests
│   ├── Dockerfile
│   └── pom.xml
├── frontend/             # React application
│   ├── src/
│   │   ├── components/  # React components
│   │   ├── contexts/    # React contexts (Auth)
│   │   ├── services/     # API service layer
│   │   └── App.jsx
│   ├── Dockerfile
│   └── package.json
├── db/                   # Database setup
│   └── docker-compose.yaml
├── docker-compose.prod.yaml  # Production Docker Compose
└── README.md
```

## Error Handling

The application uses a global exception handler that returns standardized error responses:

```json
{
  "timestamp": "2024-01-01T00:00:00Z",
  "status": 400,
  "error": "Bad Request",
  "message": "Error message",
  "path": "/api/inventory"
}
```

**Exception Types:**
- `BadRequestException`: 400 Bad Request - Invalid input or business rule violation
- `NotFoundException`: 404 Not Found - Resource not found
- `UnauthorizedException`: 401 Unauthorized - Authentication required
- `ForbiddenException`: 403 Forbidden - Insufficient permissions
- `MethodArgumentNotValidException`: 400 Bad Request - Validation errors

## Security

Current implementation includes:
- JWT-based authentication
- Role-based access control (ADMIN, USER roles)
- Password encryption (BCrypt)
- CORS configuration
- Input validation

For production deployment:
1. Use strong JWT secrets (change default)
2. Enable HTTPS
3. Implement rate limiting
4. Add request validation and sanitization
5. Configure CORS appropriately for production domains
6. Review and restrict actuator endpoints
7. Set up proper logging and monitoring

## Troubleshooting

### Port Already in Use

If you get an error like "port is already allocated" or "address already in use":

**Solution 1: Stop conflicting services**
```bash
# Check what's using the port
# On Linux/Mac:
lsof -i :8080  # or :5432, :3000

# On Windows:
netstat -ano | findstr :8080

# Stop the conflicting container/service
docker ps
docker stop <container-id>
```

**Solution 2: Use different ports**
Create a `.env` file in the project root:
```bash
DB_PORT=5433
BACKEND_PORT=8081
FRONTEND_PORT=3001
```

### Docker Compose Version Issues

If you see errors about unsupported features:

**Check your Docker Compose version:**
```bash
docker compose version
# Should be v2.0.0 or higher
```

**Update Docker Desktop** or install Docker Compose v2:
- Docker Desktop includes Docker Compose v2 automatically
- For Linux: Follow [Docker Compose installation guide](https://docs.docker.com/compose/install/)

### Permission Denied (Port 80/443)

If you get permission errors binding to port 80 or 443:

**Solution:** The default frontend port is now 3000 (no root required). If you need port 80:
- **Linux:** Run with `sudo` (not recommended for development)
- **macOS:** May require admin privileges
- **Windows:** Usually works without admin

### Container Won't Start / Health Check Fails

**Check container logs:**
```bash
# All services
docker-compose -f docker-compose.prod.yaml logs

# Specific service
docker logs inventory-backend
docker logs inventory-frontend
docker logs inventory-db
```

**Common issues:**
- Database not ready: Wait 30-60 seconds for database to become healthy
- Out of memory: Close other applications, ensure Docker has enough resources allocated
- Network issues: Restart Docker daemon

### Build Fails

**Clean rebuild:**
```bash
docker-compose -f docker-compose.prod.yaml down
docker-compose -f docker-compose.prod.yaml build --no-cache
docker-compose -f docker-compose.prod.yaml up -d
```

**Check disk space:**
```bash
docker system df
# If low on space:
docker system prune -a  # Removes unused images, containers, networks
```

### Database Connection Errors

**Verify database is running:**
```bash
docker ps | grep inventory-db
# Should show "healthy" status
```

**Test connection:**
```bash
docker exec inventory-db pg_isready -U invuser
```

**Reset database (WARNING: deletes all data):**
```bash
docker-compose -f docker-compose.prod.yaml down -v
docker-compose -f docker-compose.prod.yaml up -d
```

### Frontend Can't Connect to Backend

**Check CORS configuration:**
- Ensure `CORS_ALLOWED_ORIGINS` includes your frontend URL
- Default: `http://localhost:3000` (matches default frontend port)

**Verify backend is accessible:**
```bash
curl http://localhost:8080/actuator/health
# Should return JSON response
```

### Platform-Specific Issues

**ARM64 (Apple Silicon M1/M2/M3):**
- Docker images are built for multi-platform support
- If issues occur, rebuild: `docker-compose -f docker-compose.prod.yaml build --no-cache`

**Windows:**
- Use WSL2 for best compatibility
- Ensure line endings are correct (Git should handle this)

**Linux:**
- Ensure Docker daemon is running: `sudo systemctl status docker`
- User must be in `docker` group: `sudo usermod -aG docker $USER` (then logout/login)

### Still Having Issues?

1. **Check Docker Desktop/Engine is running**
2. **Verify minimum requirements:**
   - Docker Desktop 4.0+ or Docker Engine 20.10+
   - Docker Compose v2.0+
   - At least 4GB free RAM
   - At least 5GB free disk space
3. **Review logs** for specific error messages
4. **Try manual setup** (see Development Setup section) to isolate Docker issues

## Future Enhancements

1. **Full-Text Search**: Implement PostgreSQL full-text search or integrate Elasticsearch for better search performance
2. **Async Audit Logging**: Make audit event creation asynchronous to improve write performance
3. **Granular Cache Invalidation**: Implement cache invalidation by key instead of clearing entire cache
4. **API Versioning**: Add versioning support for API evolution
5. **Rate Limiting**: Implement rate limiting to prevent abuse
6. **Metrics and Monitoring**: Add metrics collection (Prometheus) and distributed tracing
7. **Database Read Replicas**: Implement read replicas for scaling read operations
8. **Event Sourcing**: Consider event sourcing pattern for audit events
9. **Multi-tenancy**: Add support for multiple organizations/tenants
10. **Advanced Reporting**: Add analytics and reporting features

## Author

Victor Tiradoegas
