# API Documentation

Complete API reference for the Inventory Audit Portal backend.

## Table of Contents

- [Base URLs](#base-urls)
- [Authentication](#authentication)
- [Inventory Item Endpoints](#inventory-item-endpoints)
- [Audit Event Endpoints](#audit-event-endpoints)
- [User Authentication Endpoints](#user-authentication-endpoints)
- [Error Handling](#error-handling)

## Base URLs

- **Local Development**: `http://localhost:8080`
- **Production**: Configure via `CORS_ALLOWED_ORIGINS` environment variable

## Authentication

All protected endpoints require a JWT token in the Authorization header:

```
Authorization: Bearer <token>
```

Tokens are obtained via the `/api/auth/login` endpoint and expire after 24 hours.

## Swagger UI

Interactive API documentation is available at:
- **Swagger UI**: `http://localhost:8080/swagger-ui.html`
- **API Docs**: `http://localhost:8080/api-docs`

## Health Checks

- **Health**: `GET http://localhost:8080/actuator/health`
- **Info**: `GET http://localhost:8080/actuator/info`
- **Metrics**: `GET http://localhost:8080/actuator/metrics`

## Inventory Item Endpoints

Base URL: `/api/inventory`

### List All Items

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

**Example:**
```bash
curl -X GET "http://localhost:8080/api/inventory?page=0&size=10&sortBy=name&sortDir=ASC" \
  -H "Authorization: Bearer <token>"
```

### Get Item by ID

```
GET /api/inventory/{id}
```

Returns a single inventory item by its ID.

**Path Parameters:**
- `id` - Item ID (Long)

**Response:** `InventoryItem`

**Example:**
```bash
curl -X GET "http://localhost:8080/api/inventory/1" \
  -H "Authorization: Bearer <token>"
```

### Get Item by SKU

```
GET /api/inventory/sku/{sku}
```

Returns a single inventory item by its unique SKU.

**Path Parameters:**
- `sku` - Stock Keeping Unit (String)

**Response:** `InventoryItem`

**Example:**
```bash
curl -X GET "http://localhost:8080/api/inventory/sku/ABC123" \
  -H "Authorization: Bearer <token>"
```

### Get Items by Location

```
GET /api/inventory/location/{location}
```

Returns paginated list of items filtered by location.

**Path Parameters:**
- `location` - Location identifier (String)

**Query Parameters:** Same as List All Items

**Response:** `Page<InventoryItem>`

**Example:**
```bash
curl -X GET "http://localhost:8080/api/inventory/location/Warehouse-A?page=0&size=20" \
  -H "Authorization: Bearer <token>"
```

### Search by SKU Pattern

```
GET /api/inventory/search/sku?pattern={pattern}
```

Performs case-insensitive partial match search on SKU field.

**Query Parameters:**
- `pattern` (required) - Search pattern (String)
- `page` (default: 0)
- `size` (default: 50)

**Response:** `Page<InventoryItem>`

**Example:**
```bash
curl -X GET "http://localhost:8080/api/inventory/search/sku?pattern=ABC&page=0&size=10" \
  -H "Authorization: Bearer <token>"
```

### Search by Name Pattern

```
GET /api/inventory/search/name?pattern={pattern}
```

Performs case-insensitive partial match search on name field.

**Query Parameters:** Same as Search by SKU Pattern

**Response:** `Page<InventoryItem>`

**Example:**
```bash
curl -X GET "http://localhost:8080/api/inventory/search/name?pattern=Widget" \
  -H "Authorization: Bearer <token>"
```

### Get Location Summary

```
GET /api/inventory/summary/location
```

Returns aggregated statistics grouped by location.

**Response:** `List<Object[]>` where each array contains [location, count, totalQty]

**Example:**
```bash
curl -X GET "http://localhost:8080/api/inventory/summary/location" \
  -H "Authorization: Bearer <token>"
```

**Response Example:**
```json
[
  ["Warehouse-A", 10, 500],
  ["Warehouse-B", 5, 250]
]
```

### Create Item

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

**Example:**
```bash
curl -X POST "http://localhost:8080/api/inventory" \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "sku": "ABC123",
    "name": "Widget",
    "qty": 100,
    "location": "Warehouse-A"
  }'
```

### Create Items Batch

```
POST /api/inventory/batch
```

Creates multiple inventory items in a single transaction.

**Request Body:** `List<InventoryItemRequest>`

**Response:** `List<InventoryItem>` (201 Created)

**Example:**
```bash
curl -X POST "http://localhost:8080/api/inventory/batch" \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '[
    {"sku": "ABC123", "name": "Widget", "qty": 100, "location": "Warehouse-A"},
    {"sku": "DEF456", "name": "Gadget", "qty": 50, "location": "Warehouse-B"}
  ]'
```

### Update Item

```
PUT /api/inventory/{id}
```

Updates an existing inventory item.

**Path Parameters:**
- `id` - Item ID (Long)

**Request Body:** Same as Create Item

**Response:** `InventoryItem`

**Example:**
```bash
curl -X PUT "http://localhost:8080/api/inventory/1" \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "sku": "ABC123",
    "name": "Updated Widget",
    "qty": 150,
    "location": "Warehouse-A"
  }'
```

### Delete Item

```
DELETE /api/inventory/{id}
```

Deletes an inventory item by ID.

**Path Parameters:**
- `id` - Item ID (Long)

**Response:** 204 No Content

**Example:**
```bash
curl -X DELETE "http://localhost:8080/api/inventory/1" \
  -H "Authorization: Bearer <token>"
```

## Audit Event Endpoints

Base URL: `/api/audit-events`

### List All Audit Events

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

**Example:**
```bash
curl -X GET "http://localhost:8080/api/audit-events?page=0&size=20" \
  -H "Authorization: Bearer <token>"
```

### Get Audit Event by ID

```
GET /api/audit-events/{id}
```

Returns a single audit event by ID.

**Path Parameters:**
- `id` - Event ID (Long)

**Response:** `AuditEvent`

**Example:**
```bash
curl -X GET "http://localhost:8080/api/audit-events/1" \
  -H "Authorization: Bearer <token>"
```

### Get Events by Entity

```
GET /api/audit-events/entity/{entityType}/{entityId}
```

Returns paginated audit events for a specific entity.

**Path Parameters:**
- `entityType` - Entity type (String)
- `entityId` - Entity ID (Long)

**Query Parameters:** Same as List All Audit Events

**Response:** `Page<AuditEvent>`

**Example:**
```bash
curl -X GET "http://localhost:8080/api/audit-events/entity/INVENTORY_ITEM/1" \
  -H "Authorization: Bearer <token>"
```

### Get Events by Entity Type

```
GET /api/audit-events/entity-type/{entityType}
```

Returns paginated audit events filtered by entity type.

**Path Parameters:**
- `entityType` - Entity type (String)

**Query Parameters:** Same as List All Audit Events

**Response:** `Page<AuditEvent>`

**Example:**
```bash
curl -X GET "http://localhost:8080/api/audit-events/entity-type/INVENTORY_ITEM" \
  -H "Authorization: Bearer <token>"
```

### Get Events by Event Type

```
GET /api/audit-events/event-type/{eventType}
```

Returns paginated audit events filtered by event type (CREATE, UPDATE, DELETE, READ).

**Path Parameters:**
- `eventType` - Event type (String)

**Query Parameters:** Same as List All Audit Events

**Response:** `Page<AuditEvent>`

**Example:**
```bash
curl -X GET "http://localhost:8080/api/audit-events/event-type/CREATE" \
  -H "Authorization: Bearer <token>"
```

### Get Events by User ID

```
GET /api/audit-events/user/{userId}
```

Returns paginated audit events filtered by user ID.

**Path Parameters:**
- `userId` - User identifier (String)

**Query Parameters:** Same as List All Audit Events

**Response:** `Page<AuditEvent>`

**Example:**
```bash
curl -X GET "http://localhost:8080/api/audit-events/user/admin" \
  -H "Authorization: Bearer <token>"
```

## User Authentication Endpoints

Base URL: `/api/auth`

### Register

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

**Example:**
```bash
curl -X POST "http://localhost:8080/api/auth/register" \
  -H "Content-Type: application/json" \
  -d '{
    "username": "newuser",
    "email": "user@example.com",
    "password": "securepassword123"
  }'
```

### Login

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

**Example:**
```bash
curl -X POST "http://localhost:8080/api/auth/login" \
  -H "Content-Type: application/json" \
  -d '{
    "username": "admin",
    "password": "admin123!"
  }'
```

**Response Example:**
```json
{
  "token": "eyJhbGciOiJIUzUxMiJ9...",
  "id": 1,
  "username": "admin",
  "email": "admin@example.com",
  "roles": ["ADMIN"]
}
```

### Forgot Password

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

**Example:**
```bash
curl -X POST "http://localhost:8080/api/auth/forgot-password" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com"
  }'
```

### Reset Password

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

**Example:**
```bash
curl -X POST "http://localhost:8080/api/auth/reset-password" \
  -H "Content-Type: application/json" \
  -d '{
    "token": "reset-token-here",
    "newPassword": "newsecurepassword123"
  }'
```

## Error Handling

The API uses a global exception handler that returns standardized error responses:

```json
{
  "timestamp": "2024-01-01T00:00:00Z",
  "status": 400,
  "error": "Bad Request",
  "message": "Error message",
  "path": "/api/inventory"
}
```

### Exception Types

- **400 Bad Request**: `BadRequestException` - Invalid input or business rule violation
- **400 Bad Request**: `MethodArgumentNotValidException` - Validation errors
- **401 Unauthorized**: `UnauthorizedException` - Authentication required
- **403 Forbidden**: `ForbiddenException` - Insufficient permissions
- **404 Not Found**: `NotFoundException` - Resource not found

### Common Error Scenarios

**Invalid Credentials:**
```json
{
  "timestamp": "2024-01-01T00:00:00Z",
  "status": 400,
  "error": "Bad Request",
  "message": "Invalid username or password",
  "path": "/api/auth/login"
}
```

**Resource Not Found:**
```json
{
  "timestamp": "2024-01-01T00:00:00Z",
  "status": 404,
  "error": "Not Found",
  "message": "Item not found",
  "path": "/api/inventory/999"
}
```

**Validation Error:**
```json
{
  "timestamp": "2024-01-01T00:00:00Z",
  "status": 400,
  "error": "Bad Request",
  "message": "Validation failed",
  "path": "/api/inventory",
  "errors": [
    {
      "field": "sku",
      "message": "SKU cannot be null or empty"
    }
  ]
}
```

**Unauthorized Access:**
```json
{
  "timestamp": "2024-01-01T00:00:00Z",
  "status": 401,
  "error": "Unauthorized",
  "message": "Authentication required",
  "path": "/api/inventory"
}
```

