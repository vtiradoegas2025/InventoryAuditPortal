# Test Suite Documentation

This directory contains comprehensive test scripts for the Inventory Audit Portal.

## Directory Structure

```
tests/
├── test-comprehensive.sh    # Main comprehensive test script (API, builds, integration)
├── test-backend.sh           # Backend API test script with edge cases
├── test-frontend.sh          # Frontend test script with edge cases
├── test-database.sh          # Database functionality test script (schema, constraints, indexes)
├── logs/                     # Test execution logs and endpoint documentation
└── README.md                # This file
```

## Test Script: test-comprehensive.sh

### Overview

The comprehensive test script performs:
- **Endpoint Discovery**: Documents all API endpoints with their authentication and role requirements
- **Docker Build Tests**: Verifies backend and frontend Docker images build successfully
- **Frontend Build Tests**: Tests production build of React application
- **Backend Compilation Tests**: Verifies Java code compiles successfully
- **Authentication Tests**: Tests user registration and login for both USER and ADMIN roles
- **Role-Based Permission Tests**: Verifies USER vs ADMIN access permissions
- **Inventory API Tests**: Full CRUD operations on inventory items
- **Audit Events API Tests**: Tests audit trail functionality
- **Security Tests**: Tests unauthorized access and validation
- **Frontend UI Tests**: Verifies frontend accessibility
- **Integration Tests**: End-to-end workflow tests

### Usage

```bash
# From project root
cd tests
./test-comprehensive.sh

# Or from project root directly
./tests/test-comprehensive.sh
```

### Prerequisites
- `curl` - For HTTP requests
- `docker` - For Docker build tests
- `docker-compose` - For service management
- `mvn` or `./backend/mvnw` - For backend compilation tests (optional)
- `node` and `npm` - For frontend build tests (optional)

### Test Output
The script generates two types of logs:

1. **Test Results Log** (`logs/test-results-YYYYMMDD-HHMMSS.log`)
   - Detailed test execution log
   - Timestamped entries for each test
   - Pass/fail status for debugging

2. **Endpoint Documentation** (`logs/endpoints-YYYYMMDD-HHMMSS.txt`)
   - Complete list of all API endpoints
   - Format: `METHOD|ENDPOINT|AUTH_REQUIRED|ROLE_REQUIRED`
   - Useful for API documentation and security audits

### Role-Based Permission Testing

The script tests role-based access control by:

1. **Creating a regular USER account** and obtaining a token
2. **Logging in as ADMIN** and obtaining an admin token
3. **Testing USER permissions**:
   - USER can access regular authenticated endpoints (`/api/inventory`, `/api/audit-events`)
   - USER cannot access admin-only endpoints (`/api/auth/admin/**`)
4. **Testing ADMIN permissions**:
   - ADMIN can access all regular endpoints
   - ADMIN can access admin-only endpoints

### Example Output

```
==========================================
0. API Endpoint Discovery
==========================================

Public Endpoints (No Authentication Required):
  GET  /actuator/health
  POST /api/auth/register
  POST /api/auth/login
  ...

Authenticated Endpoints (Any Authenticated User):
  GET  /api/inventory
  POST /api/inventory
  GET  /api/audit-events
  ...

Admin-Only Endpoints (ADMIN Role Required):
  POST /api/auth/admin/reset-password

==========================================
7. Role-Based Permission Tests
==========================================

7.1 Testing USER Role Permissions...
  Testing: USER can access /api/inventory...
  ✓ PASS (HTTP 200)
  Testing: USER cannot access admin-only endpoint...
  ✓ USER correctly denied access to admin endpoint (HTTP 403)

7.2 Testing ADMIN Role Permissions...
  Testing: ADMIN can access admin-only endpoint...
  ✓ ADMIN can access admin endpoint (HTTP 200 - permission granted)
```

### Exit Codes

- `0` - All tests passed
- `1` - Some tests failed

### Notes

- The script continues testing even if individual tests fail
- Tests that require services (backend/frontend) will be skipped if services aren't running
- The script will prompt you to start services if they're not detected
- All logs are saved in the `logs/` directory with timestamps

## Log Files

All test logs are stored in the `logs/` directory:
- `test-results-*.log` - Detailed test execution logs
- `endpoints-*.txt` - API endpoint documentation

Logs are automatically created with timestamps to avoid overwriting previous test runs.

## Integration with CI/CD
This test script can be integrated into CI/CD pipelines:

```yaml
# Example GitHub Actions
- name: Run Comprehensive Tests
  run: |
    cd tests
    ./test-comprehensive.sh
```

The script will:
- Exit with code 0 if all tests pass
- Exit with code 1 if any tests fail
- Generate logs for analysis

## Troubleshooting

### Backend Not Running

If you see "Backend not responding", start the backend:
```bash
# Option 1: Docker Compose
docker-compose -f docker-compose.prod.yaml up -d

# Option 2: Local development
cd backend
./mvnw spring-boot:run
```

### Frontend Not Running

If frontend tests are skipped, start the frontend:
```bash
# Option 1: Docker Compose
docker-compose -f docker-compose.prod.yaml up -d frontend

# Option 2: Local development
cd frontend
npm run dev
```

### Missing Dependencies

Install missing dependencies:
- **Maven**: Use `./backend/mvnw` wrapper (included) or install Maven
- **Node/npm**: Install Node.js 18+ from nodejs.org

## Security Testing

The script includes security tests for:
- Unauthorized access attempts
- Invalid authentication tokens
- Role-based access control
- Input validation

These tests help ensure the application's security posture is maintained.

## Test Script: test-backend.sh

### Overview

The backend test script performs comprehensive backend API testing with extensive edge cases:

- **Authentication & Authorization**: User registration, login, role-based access
- **Input Validation Edge Cases**: Empty/invalid JSON, missing fields, empty strings, whitespace, negative values, very large numbers, long strings, special characters, null values, wrong data types
- **Pagination Edge Cases**: Invalid parameters, boundary values, missing params, invalid sort fields
- **CRUD Operations Edge Cases**: Duplicate SKU, non-existent items, invalid updates, concurrent updates
- **Search & Filter Edge Cases**: Empty patterns, special characters, non-existent locations, very long patterns
- **Security Edge Cases**: Unauthorized access, invalid tokens, path traversal, XSS attempts, role-based access control
- **Audit Events Edge Cases**: Invalid event types, invalid entity IDs, query edge cases
- **Performance & Load**: Batch operations, large result sets, rapid sequential requests
- **Content-Type & Headers**: Missing/wrong Content-Type, extra headers

### Usage

```bash
cd tests
./test-backend.sh

# With custom backend URL
BACKEND_URL=http://localhost:8080 ./test-backend.sh
```

### Prerequisites

- `curl` - For HTTP requests
- Backend service running at `$BACKEND_URL` (default: `http://localhost:8080`)

## Test Script: test-frontend.sh

### Overview

The frontend test script performs comprehensive frontend testing with edge cases:

- **Frontend Build Tests**: npm build, output directory, essential files (HTML, JS, CSS)
- **Accessibility Tests**: HTML structure, page title, viewport meta, static assets, CORS headers, security headers
- **Route & Navigation Edge Cases**: Non-existent routes, special characters, path traversal, very long URLs
- **API Integration Edge Cases**: CORS configuration, endpoint availability, error responses
- **Content & Asset Edge Cases**: Asset loading, missing assets, path traversal in assets
- **Performance & Load**: Page load time, concurrent requests, large response handling
- **Security Edge Cases**: XSS prevention, HTTP method restrictions, header injection
- **Browser Compatibility**: Different User-Agent strings, Accept headers
- **Error Handling**: Malformed requests, very large requests, timeout handling

### Usage

```bash
cd tests
./test-frontend.sh

# With custom URLs
FRONTEND_URL=http://localhost:3000 BACKEND_URL=http://localhost:8080 ./test-frontend.sh
```

### Prerequisites

- `curl` - For HTTP requests
- `npm` - For build tests (optional)
- Frontend service running at `$FRONTEND_URL` (default: `http://localhost:3000`)
- Backend service running at `$BACKEND_URL` (default: `http://localhost:8080`) - for API integration tests

## Test Script: test-database.sh

### Overview

The database test script performs comprehensive database functionality testing:

- **Table Existence**: Verifies all required tables exist
- **Column Existence and Data Types**: Validates column definitions match schema
- **Constraint Tests**: Tests NOT NULL, UNIQUE, PRIMARY KEY, and FOREIGN KEY constraints
- **Index Tests**: Verifies all indexes are created and functional
- **Data Integrity Tests**: Tests constraint enforcement (duplicate prevention, null checks)
- **Default Values**: Tests default value assignments
- **CRUD Operations**: Tests Create, Read, Update, Delete operations
- **Referential Integrity**: Tests CASCADE DELETE behavior
- **Index Performance**: Verifies indexes are being used in queries
- **Flyway Migration Tests**: Verifies all migrations were applied successfully
- **Data Type Validation**: Tests data type constraints
- **Query Performance**: Performance tests for common queries

### Usage

```bash
# From tests directory
cd tests
./test-database.sh

# Or from project root
./tests/test-database.sh

# With custom database connection (optional)
DB_HOST=localhost DB_PORT=5432 DB_NAME=invdb DB_USER=invuser DB_PASSWORD=yourpass ./test-database.sh
```

### Prerequisites

- **PostgreSQL client tools** (`psql` command)
  - macOS: `brew install postgresql`
  - Ubuntu/Debian: `sudo apt-get install postgresql-client`
  - Windows: Install PostgreSQL which includes psql
- **Database must be running** and accessible
- **Connection credentials** must match your database configuration

### Configuration

The script uses environment variables for database connection (with defaults):

- `DB_HOST` - Database host (default: `localhost`)
- `DB_PORT` - Database port (default: `5432`)
- `DB_NAME` - Database name (default: `invdb`)
- `DB_USER` - Database user (default: `invuser`)
- `DB_PASSWORD` - Database password (default: `invpass`)

You can also use `.env` file variables:
- `DATABASE_NAME` → `DB_NAME`
- `DATABASE_USERNAME` → `DB_USER`
- `DATABASE_PASSWORD` → `DB_PASSWORD`

### Test Output

The script generates:

- **Test Results Log** (`logs/db-test-results-YYYYMMDD-HHMMSS.log`)
  - Detailed test execution log
  - Timestamped entries for each test
  - Pass/fail status for debugging

### Example Output

```
==========================================
1. Table Existence Tests
==========================================

Testing: inventory_items table exists... ✓ PASS
Testing: audit_events table exists... ✓ PASS
Testing: users table exists... ✓ PASS
...

==========================================
3. Constraint Tests
==========================================

Testing: inventory_items.sku is NOT NULL... ✓ PASS
Testing: inventory_items.sku has UNIQUE constraint... ✓ PASS
...

==========================================
7. CRUD Operations Tests
==========================================

Testing: CREATE operation... ✓ PASS (ID: 123)
Testing: READ operation... ✓ PASS
Testing: UPDATE operation... ✓ PASS
Testing: DELETE operation... ✓ PASS
```

### What Gets Tested

1. **Schema Validation**
   - All tables exist with correct names
   - All columns exist with correct data types
   - All constraints are properly defined

2. **Constraint Enforcement**
   - UNIQUE constraints prevent duplicates
   - NOT NULL constraints prevent null values
   - FOREIGN KEY constraints maintain referential integrity
   - PRIMARY KEY constraints ensure uniqueness

3. **Index Functionality**
   - All indexes are created
   - Indexes are used in query execution plans
   - Composite indexes work correctly

4. **Data Operations**
   - INSERT operations work correctly
   - SELECT queries return expected results
   - UPDATE operations modify data correctly
   - DELETE operations remove data correctly

5. **Referential Integrity**
   - CASCADE DELETE removes related records
   - Foreign key violations are prevented

6. **Migration Status**
   - All Flyway migrations were applied
   - Migration history is correct

### Exit Codes

- `0` - All tests passed
- `1` - Some tests failed or database connection failed

### Notes

- The script creates temporary test data and cleans it up automatically
- Tests are non-destructive (test data is removed after testing)
- The script requires direct database access (not through the API)
- All tests use read-only queries where possible, with minimal test data insertion

### Troubleshooting

**psql not found:**
```bash
# macOS
brew install postgresql

# Ubuntu/Debian
sudo apt-get install postgresql-client

# Verify installation
psql --version
```

**Database connection failed:**
- Verify database is running: `docker ps | grep inventory-db`
- Check connection parameters match your `.env` file
- Test connection manually: `psql -h localhost -U invuser -d invdb`

**Permission denied:**
- Ensure database user has necessary permissions
- Check if user can create/read/update/delete test data

