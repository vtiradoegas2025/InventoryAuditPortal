# Inventory Audit Portal

A full-stack inventory management system with comprehensive audit logging, built with Spring Boot and React.

## Table of Contents

- [Features](#features)
- [Technology Stack](#technology-stack)
- [Quick Start](#quick-start)
- [Architecture Overview](#architecture-overview)
- [Design Decisions](#design-decisions)
- [Project Structure](#project-structure)
- [Testing](#testing)
- [Documentation](#documentation)
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

**Important:** The database password defaults to `invpass` in both `docker-compose.prod.yaml` and `application.yaml`. 
If you set `DATABASE_PASSWORD` environment variable, ensure it matches in both places. For production, use a `.env` file.

The easiest way to get started:

```bash
# Clone the repository
git clone <repository-url>
cd inventory-audit-portal

# Optional: Copy and customize environment variables
cp .env.example .env
# Edit .env if you want different passwords/ports/configuration
# See .env.example for all available configuration options

# Start all services
docker-compose -f docker-compose.prod.yaml up -d
```

**For Production Deployment:**
- Copy `.env.example` to `.env` and configure all production values
- Ensure `DATABASE_PASSWORD` matches in both docker-compose and application config
- Set `SWAGGER_ENABLED=false`, `DEMO_MODE=false`, and use strong secrets
- See [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md) for detailed production setup

This will start:
- PostgreSQL database (port 5432)
- Spring Boot backend (port 8080)
- React frontend (port 3000)

Access the application:
- Frontend: `http://localhost:3000`
- Backend API: `http://localhost:8080`
- Swagger UI: `http://localhost:8080/swagger-ui.html`
- Health Check: `http://localhost:8080/actuator/health`

**Demo / Local Credentials (For local testing only. Not production-safe.):**
- Username: `admin`
- Password: `admin123!`
- Email: `admin@example.com`

⚠️ **Security Note**: See [SECURITY.md](SECURITY.md) for important security information.

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

## Design Decisions

### Backend Design Choices

#### 1. Layered Architecture
- **Rationale**: Separation of concerns, testability, and maintainability
- **Implementation**: Clear separation between Controllers, Services, Repositories, and Entities
- **Benefits**: Easy to test individual layers, clear responsibility boundaries

#### 2. JWT-Based Authentication
- **Rationale**: Stateless authentication suitable for REST APIs
- **Implementation**: Spring Security with JWT tokens, 24-hour expiration
- **Benefits**: Scalable, no server-side session storage needed

#### 3. Automatic Audit Logging
- **Rationale**: Compliance and accountability requirements
- **Implementation**: Service layer automatically creates audit events for all mutations
- **Benefits**: Complete change history without manual intervention

#### 4. Caffeine Cache
- **Rationale**: Reduce database load for frequently accessed items
- **Implementation**: Cache by ID and SKU with 30-minute TTL
- **Benefits**: Improved response times for read operations

#### 5. Flyway Migrations
- **Rationale**: Version-controlled database schema changes
- **Implementation**: SQL migration files in `db/migration/`
- **Benefits**: Reproducible deployments, schema versioning

#### 6. Pagination
- **Rationale**: Handle large datasets efficiently
- **Implementation**: Spring Data JPA Pageable with configurable page size (max 1000)
- **Benefits**: Memory-efficient, better user experience

#### 7. Input Validation
- **Rationale**: Data integrity and security
- **Implementation**: Jakarta Validation annotations on request DTOs
- **Benefits**: Prevents invalid data from entering the system

### Frontend Design Choices

#### 1. Component-Based Architecture
- **Rationale**: Reusability and maintainability
- **Implementation**: React functional components with hooks
- **Benefits**: Modular code, easier testing, better code organization

#### 2. Context API for State Management
- **Rationale**: Simple state management for authentication without external dependencies
- **Implementation**: AuthContext for user authentication state
- **Benefits**: Lightweight, no additional libraries needed

#### 3. Protected Routes
- **Rationale**: Secure access to authenticated pages
- **Implementation**: ProtectedRoute component wrapping authenticated routes
- **Benefits**: Centralized authentication checks

#### 4. Role-Based UI Rendering
- **Rationale**: Different user experiences based on permissions
- **Implementation**: RoleGuard component for conditional rendering
- **Benefits**: Clean separation of admin/user features

#### 5. Tailwind CSS
- **Rationale**: Rapid UI development with utility classes
- **Implementation**: Utility-first CSS framework
- **Benefits**: Fast development, consistent design, small bundle size

#### 6. Vite Build Tool
- **Rationale**: Fast development experience and optimized builds
- **Implementation**: Vite for development and production builds
- **Benefits**: Hot module replacement, fast builds

#### 7. API Service Layer
- **Rationale**: Centralized API communication logic
- **Implementation**: `services/api.js` with fetch-based HTTP client
- **Benefits**: Reusable API calls, centralized error handling

### Performance Optimizations

#### Database Indexing Strategy

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

#### Caching Strategy

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

#### Connection Pooling

**HikariCP Configuration:**
- Maximum pool size: 20 connections
- Minimum idle: 5 connections
- Connection timeout: 30 seconds
- Idle timeout: 10 minutes
- Max lifetime: 30 minutes

#### JPA Batch Processing

**Hibernate Batch Settings:**
- Batch size: 50 operations per batch
- Ordered inserts: Enabled
- Ordered updates: Enabled
- Batch versioned data: Enabled

These settings optimize batch operations by reducing database round trips.

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
│   │   └── test/         # Unit tests
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
├── tests/                # Comprehensive test suites
│   ├── test-comprehensive.sh    # Main comprehensive test suite
│   ├── test-backend.sh           # Backend API tests with edge cases
│   ├── test-frontend.sh          # Frontend tests with edge cases
│   ├── test-database.sh          # Database functionality tests
│   ├── logs/                     # Test execution logs
│   └── README.md                 # Test suite documentation
├── db/                   # Database setup
│   └── docker-compose.yaml
├── docs/                  # Documentation
│   ├── API.md           # API documentation
│   ├── DEPLOYMENT.md    # Deployment guide
│   └── DEVELOPMENT.md   # Development setup
├── docker-compose.prod.yaml  # Production Docker Compose
├── .env.example         # Environment variables template (copy to .env)
├── SECURITY.md          # Security documentation
└── README.md            # This file
```

## Testing

The project includes comprehensive test scripts in the `tests/` directory:

- **[tests/test-comprehensive.sh](tests/test-comprehensive.sh)** - Main comprehensive test suite covering API endpoints, Docker builds, frontend builds, authentication, role-based permissions, CRUD operations, audit events, security, and integration tests
- **[tests/test-backend.sh](tests/test-backend.sh)** - Backend API test suite with extensive edge cases including input validation, pagination, CRUD operations, search/filter, security, audit events, performance, and content-type handling
- **[tests/test-frontend.sh](tests/test-frontend.sh)** - Frontend test suite covering build verification, accessibility, routes, API integration, assets, performance, security, browser compatibility, and error handling
- **[tests/test-database.sh](tests/test-database.sh)** - Database functionality tests covering schema validation, constraints, indexes, data integrity, CRUD operations, referential integrity, performance, migrations, and edge cases

### Running Tests

```bash
# Run all comprehensive tests
cd tests
./test-comprehensive.sh

# Run specific test suites
./test-backend.sh      # Backend API tests
./test-frontend.sh     # Frontend tests
./test-database.sh     # Database tests
```

All test scripts generate detailed logs in `tests/logs/` with timestamps. See **[tests/README.md](tests/README.md)** for detailed documentation on each test script.

## Documentation

- **[SECURITY.md](SECURITY.md)** - Security configuration, credentials, and best practices
- **[docs/API.md](docs/API.md)** - Complete API endpoint documentation
- **[docs/DEPLOYMENT.md](docs/DEPLOYMENT.md)** - Production deployment guide
- **[docs/DEVELOPMENT.md](docs/DEVELOPMENT.md)** - Development setup and troubleshooting
- **[tests/README.md](tests/README.md)** - Test suite documentation and usage guide

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
