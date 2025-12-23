# Development Guide

Complete guide for setting up and developing the Inventory Audit Portal locally.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Development Setup](#development-setup)
- [Running Tests](#running-tests)
- [Database Migrations](#database-migrations)
- [Troubleshooting](#troubleshooting)

## Prerequisites

- **Java 17+**
- **Maven 3.6+**
- **Node.js 18+**
- **PostgreSQL 12+**
- **Docker** (optional, for database)

## Development Setup

### ⚠️ Important: Password Configuration

The database password must match between:
- `docker-compose.prod.yaml` (POSTGRES_PASSWORD)
- `application.yaml` (spring.datasource.password)

**Default password:** `invpass` (for local development only)

If you change the password, update both files or use a `.env` file:
```bash
# Create .env file from template
cp .env.example .env
# Edit .env to set DATABASE_PASSWORD=yourpassword
# This will be used by both docker-compose and Spring Boot
```

### 1. Start Database

**Option A: Using Docker (Recommended)**

```bash
cd db
docker-compose up -d
```

This starts PostgreSQL on port 5432 with:
- Database: `invdb`
- Username: `invuser`
- Password: `invpass` (default - matches application.yaml)

**Option B: Local PostgreSQL**

Create a database:
```sql
CREATE DATABASE invdb;
CREATE USER invuser WITH PASSWORD 'invpass';
GRANT ALL PRIVILEGES ON DATABASE invdb TO invuser;
```

### 2. Start Backend

```bash
cd backend
./mvnw spring-boot:run
```

Backend will be available at `http://localhost:8080`

**With Custom Database Password:**

Option 1: Using environment variable
```bash
DATABASE_PASSWORD=yourpassword ./mvnw spring-boot:run
```

Option 2: Using .env file (recommended)
```bash
# From project root
cp .env.example .env
# Edit .env and set DATABASE_PASSWORD=yourpassword
# Then run backend - it will read from .env automatically
cd backend
./mvnw spring-boot:run
```

**Note:** If you're using Docker Compose, the `.env` file in the project root will be automatically loaded by docker-compose.

### 3. Start Frontend

```bash
cd frontend
npm install
npm run dev
```

Frontend will be available at `http://localhost:5173`

## Running Tests

### Backend Tests

**Run all tests:**
```bash
cd backend
./mvnw test
```

**Run specific test class:**
```bash
./mvnw test -Dtest=InventoryItemServiceTest
```

**Run with coverage:**
```bash
./mvnw test jacoco:report
```

**Backend Test Script:**
```bash
cd backend
./test-backend.sh
```

### Frontend Tests

(Add when test framework is configured)

## Database Migrations

Migrations are handled automatically by Flyway. To create a new migration:

1. Create a file: `backend/src/main/resources/db/migration/V5__Your_migration_name.sql`
2. Follow naming convention: `V{version}__{description}.sql`
3. Flyway will run it automatically on next startup

**Example Migration:**
```sql
-- V5__Add_notes_column_to_inventory_items.sql
ALTER TABLE inventory_items ADD COLUMN notes TEXT;
```

**Migration Best Practices:**
- Always use transactions
- Make migrations reversible when possible
- Test migrations on a copy of production data
- Never modify existing migration files after they've been applied

## Troubleshooting

### Port Already in Use

If you get an error like "port is already allocated" or "address already in use":

**Solution 1: Stop conflicting services**
```bash
# Check what's using the port
# On Linux/Mac:
lsof -i :8080  # or :5432, :3000, :5173

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

### Database Connection Issues

**Common Error:** `FATAL: password authentication failed for user "invuser"`

This happens when the database password doesn't match between:
- Docker Compose configuration (`docker-compose.prod.yaml`)
- Spring Boot configuration (`application.yaml`)

**Solution:**

1. **Check current database password:**
   ```bash
   # If using Docker
   docker exec inventory-db env | grep POSTGRES_PASSWORD
   ```

2. **Ensure passwords match:**
   - Default password is `invpass` in both places
   - If you changed it, ensure `DATABASE_PASSWORD` environment variable is set consistently
   - Or use `.env` file (recommended):
     ```bash
     cp .env.example .env
     # Edit .env and set DATABASE_PASSWORD=yourpassword
     # This will be used by both docker-compose and Spring Boot
     ```

3. **Verify configuration:**
   - `docker-compose.prod.yaml`: `POSTGRES_PASSWORD: ${DATABASE_PASSWORD:-invpass}`
   - `application.yaml`: `password: ${DATABASE_PASSWORD:invpass}`
   - Both should use the same default or environment variable

**Other Database Issues:**
- Verify database is running and accessible
- Check connection string format
- Verify credentials match database configuration
- Check firewall rules
- Ensure database user has proper permissions

**Test connection:**
```bash
# Docker
docker exec inventory-db pg_isready -U invuser

# Local PostgreSQL
psql -h localhost -U invuser -d invdb
```

### CORS Errors

- Verify `CORS_ALLOWED_ORIGINS` includes your frontend URL
- Default: `http://localhost:3000,http://localhost:5173`
- Check browser console for specific CORS errors
- Ensure credentials are handled correctly

**Common CORS Issues:**
- Frontend running on different port than configured
- Missing `Access-Control-Allow-Credentials` header
- Preflight OPTIONS request failing

### Migration Issues

- Check Flyway logs for migration errors
- Verify database user has CREATE/ALTER permissions
- Review migration files for syntax errors
- Ensure migration version numbers are sequential

**View migration status:**
```bash
# Check Flyway logs in application logs
tail -f backend/logs/inventory-audit-portal.log | grep -i flyway
```

**Reset migrations (WARNING: deletes all data):**
```bash
# Drop and recreate database
docker-compose -f db/docker-compose.yaml down -v
docker-compose -f db/docker-compose.yaml up -d
```

### Health Check Failures

- Verify database connectivity
- Check application logs for errors
- Verify actuator endpoints are accessible
- Check if database migrations completed successfully

**Test health endpoint:**
```bash
curl http://localhost:8080/actuator/health
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

**Check API base URL:**
- Verify `VITE_API_BASE_URL` in frontend `.env` file
- Default: `/api` (relative URL)

### Build Fails

**Clean rebuild:**
```bash
# Backend
cd backend
./mvnw clean install

# Frontend
cd frontend
rm -rf node_modules dist
npm install
npm run build
```

**Check disk space:**
```bash
df -h
# If low on space, clean up:
docker system prune -a  # Removes unused images, containers, networks
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

## Development Tips

### Hot Reload

**Backend:**
- Spring Boot DevTools enables automatic restart on code changes
- Changes to Java files trigger application restart
- Changes to resources (YAML, properties) trigger restart

**Frontend:**
- Vite provides Hot Module Replacement (HMR)
- Changes to React components update without full page reload
- CSS changes apply instantly

### Debugging

**Backend Debugging:**
```bash
# Run with debug port
./mvnw spring-boot:run -Dspring-boot.run.jvmArguments="-Xdebug -Xrunjdwp:transport=dt_socket,server=y,suspend=n,address=5005"
```

**Frontend Debugging:**
- Use browser DevTools
- React DevTools extension recommended
- Source maps enabled in development mode

### Code Quality

**Backend:**
- Run linter: `./mvnw checkstyle:check`
- Format code: Configure IDE to use Google Java Style Guide

**Frontend:**
- Run linter: `npm run lint` (if configured)
- Format code: `npm run format` (if configured)

### Database Management

**Access PostgreSQL:**
```bash
# Docker
docker exec -it inventory-db psql -U invuser -d invdb

# Local
psql -h localhost -U invuser -d invdb
```

**Useful SQL Commands:**
```sql
-- List all tables
\dt

-- Describe table structure
\d inventory_items

-- View migration history
SELECT * FROM flyway_schema_history;

-- Count records
SELECT COUNT(*) FROM inventory_items;
```

