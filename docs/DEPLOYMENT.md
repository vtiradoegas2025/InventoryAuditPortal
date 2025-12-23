# Deployment Guide

Complete guide for deploying the Inventory Audit Portal to production.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Docker Deployment](#docker-deployment)
- [Manual Deployment](#manual-deployment)
- [Environment Configuration](#environment-configuration)
- [Production Checklist](#production-checklist)
- [Backup & Recovery](#backup--recovery)
- [Scaling](#scaling)

## Prerequisites

- Docker Desktop 4.0+ (includes Docker Compose v2.0+)
- OR Docker Engine 20.10+ with Docker Compose v2.0+
- OR for manual setup: Java 17+, Maven 3.6+, Node.js 18+, PostgreSQL 12+

## Docker Deployment

The easiest way to deploy is using Docker Compose:

```bash
docker-compose -f docker-compose.prod.yaml up -d
```

### Environment Configuration

**Important:** Copy `.env.example` to `.env` and customize for your production environment:

```bash
cp .env.example .env
# Edit .env with your production values
```

**Critical:** The `DATABASE_PASSWORD` must match in both:
- `docker-compose.prod.yaml` (used by PostgreSQL container)
- `application.yaml` (used by Spring Boot application)

Both read from the `DATABASE_PASSWORD` environment variable, so setting it in `.env` ensures consistency.

**Example `.env` file:**
```bash
# Database - IMPORTANT: This password is used by both docker-compose and Spring Boot
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

# Security (IMPORTANT - Change these!)
DEMO_MODE=false
ADMIN_ENABLED=false
JWT_SECRET=your-strong-random-secret-minimum-32-characters
DATABASE_PASSWORD=your-secure-database-password
```

## Manual Deployment

### Backend

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
   export DEMO_MODE=false
   export ADMIN_ENABLED=false
   export JWT_SECRET=your-strong-random-secret-minimum-32-characters
   ```

3. **Run the application:**
   ```bash
   java -jar target/inventory-audit-portal-0.0.1-SNAPSHOT.jar
   ```

### Frontend

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

## Environment Configuration

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

### Environment Variables Reference

#### Backend

| Variable | Default | Description |
|----------|---------|-------------|
| `SERVER_PORT` | 8080 | Server port |
| `DATABASE_URL` | jdbc:postgresql://localhost:5432/invdb | Database connection URL |
| `DATABASE_USERNAME` | invuser | Database username |
| `DATABASE_PASSWORD` | demo_password_change_in_production | Database password (demo only) |
| `DDL_AUTO` | update | Hibernate DDL mode (use `validate` in prod) |
| `FLYWAY_ENABLED` | true | Enable Flyway migrations |
| `CORS_ALLOWED_ORIGINS` | http://localhost:3000,http://localhost:5173 | CORS allowed origins |
| `CSRF_ENABLED` | false | Enable CSRF protection |
| `SWAGGER_ENABLED` | true | Enable Swagger UI |
| `LOG_LEVEL` | INFO | Logging level |
| `LOG_FILE` | logs/inventory-audit-portal.log | Log file path |
| `DEMO_MODE` | true | Enable demo mode (set to false in production) |
| `ADMIN_EMAIL` | admin@example.com | Admin email (demo only) |
| `ADMIN_USERNAME` | admin | Admin username (demo only) |
| `ADMIN_PASSWORD` | admin123! | Admin password (demo only - CHANGE IN PRODUCTION!) |
| `ADMIN_ENABLED` | true | Enable admin user creation |
| `JWT_SECRET` | DEMO_SECRET_KEY... | JWT secret key (demo only - CHANGE IN PRODUCTION!) |
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

## Production Checklist

### Security

- [ ] Change default database passwords
- [ ] Configure HTTPS/TLS certificates
- [ ] Set `CSRF_ENABLED=true` if using session auth
- [ ] Restrict CORS origins to your domain only
- [ ] Disable Swagger UI (`SWAGGER_ENABLED=false`)
- [ ] Review and restrict actuator endpoints
- [ ] Set up firewall rules
- [ ] Enable rate limiting (consider adding Spring Cloud Gateway)
- [ ] Set `DEMO_MODE=false`
- [ ] Set `ADMIN_ENABLED=false`
- [ ] Change JWT secret to strong random value
- [ ] Use secrets manager for sensitive data

### Database

- [ ] Set `DDL_AUTO=validate` (prevents auto schema changes)
- [ ] Enable Flyway migrations (`FLYWAY_ENABLED=true`)
- [ ] Set up automated database backups
- [ ] Configure connection pooling appropriately
- [ ] Monitor database performance
- [ ] Set up database replication (if needed)

### Monitoring & Logging

- [ ] Configure log rotation
- [ ] Set up log aggregation (ELK, CloudWatch, etc.)
- [ ] Configure health check monitoring
- [ ] Set up alerts for errors
- [ ] Monitor application metrics
- [ ] Set up APM (Application Performance Monitoring)

### Infrastructure

- [ ] Set up load balancing (if multiple instances)
- [ ] Configure auto-scaling
- [ ] Set up CI/CD pipeline
- [ ] Configure environment-specific configs
- [ ] Set up SSL certificates
- [ ] Configure DNS

### Application

- [ ] Test all API endpoints
- [ ] Verify audit logging works
- [ ] Test search and filtering
- [ ] Verify pagination
- [ ] Test error handling
- [ ] Load testing

## Backup & Recovery

### Database Backup

```bash
# Using pg_dump
pg_dump -h localhost -U invuser -d invdb > backup.sql

# Restore
psql -h localhost -U invuser -d invdb < backup.sql
```

### Automated Backups

Set up a cron job or use your cloud provider's backup service:

```bash
# Daily backup at 2 AM
0 2 * * * pg_dump -h localhost -U invuser -d invdb > /backups/invdb_$(date +\%Y\%m\%d).sql
```

### Backup Strategy Recommendations

1. **Full Backups**: Daily at low-traffic times
2. **Incremental Backups**: Every 6 hours
3. **Retention**: Keep daily backups for 30 days, weekly for 12 weeks
4. **Testing**: Regularly test restore procedures
5. **Offsite Storage**: Store backups in separate location/region

## Scaling

### Horizontal Scaling

1. Run multiple backend instances behind a load balancer
2. Use sticky sessions if needed (not required for stateless JWT auth)
3. Ensure shared database
4. Configure session replication (if using sessions)

### Database Scaling

- Consider read replicas for read-heavy workloads
- Use connection pooling effectively
- Monitor query performance
- Consider database sharding for very large datasets

### Load Balancer Configuration

**Nginx Example:**
```nginx
upstream backend {
    least_conn;
    server backend1:8080;
    server backend2:8080;
    server backend3:8080;
}

server {
    listen 80;
    server_name api.yourdomain.com;

    location / {
        proxy_pass http://backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
```

### Auto-Scaling Considerations

- Monitor CPU and memory usage
- Set up auto-scaling based on request rate
- Ensure database can handle increased connections
- Configure health checks for scaling decisions

