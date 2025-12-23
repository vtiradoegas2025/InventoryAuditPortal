# Security Documentation

**IMPORTANT**: This repository contains demo credentials for local testing only. These would never be committed or noted for production ready.

## Security Overview
This document outlines security configurations, credentials management, and best practices for the Inventory Audit Portal.

## Demo Credentials

**For local testing only. Not production-safe.**

- **Username**: `admin`
- **Password**: `admin123!`
- **Email**: `admin@example.com`

These credentials are automatically created when `DEMO_MODE=true` is set. They are clearly labeled as demo-only and should never be used in production environments.

## Security Features

### Authentication & Authorization
- **JWT-Based Authentication**: Stateless token-based authentication
- **Role-Based Access Control**: ADMIN and USER roles with different permissions
- **Password Encryption**: BCrypt hashing with salt rounds
- **Token Expiration**: 24-hour JWT token lifetime

### Input Validation
- **Request Validation**: Jakarta Validation annotations on all DTOs
- **SQL Injection Prevention**: Spring Data JPA uses parameterized queries
- **XSS Prevention**: Input sanitization and proper content types

### CORS Configuration
- **Restricted Origins**: Only specific localhost ports allowed (3000, 5173)
- **No Wildcards**: Explicit origin list prevents unauthorized access
- **Credentials Support**: Configured for authenticated requests

### Security Headers
- **X-Frame-Options**: SAMEORIGIN (prevents clickjacking)
- **X-Content-Type-Options**: nosniff (prevents MIME sniffing)
- **CSRF Protection**: Disabled for stateless JWT auth (can be enabled if needed)

## Production Security Checklist

Before deploying to production, ensure the following:

### Credentials & Secrets
- [ ] Change all default database passwords
- [ ] Set strong JWT secret (minimum 32 characters, random)
- [ ] Set `DEMO_MODE=false` to disable demo admin creation
- [ ] Set `ADMIN_ENABLED=false` after initial admin setup
- [ ] Use environment variables or secrets manager (never hardcode)
- [ ] Rotate secrets regularly

### Network & Infrastructure
- [ ] Configure HTTPS/TLS certificates
- [ ] Set up firewall rules
- [ ] Restrict database access to application servers only
- [ ] Use VPN or private networks for database connections
- [ ] Enable rate limiting (consider Spring Cloud Gateway)

### Application Configuration
- [ ] Set `CSRF_ENABLED=true` if using session-based auth
- [ ] Restrict CORS origins to production domains only
- [ ] Disable Swagger UI (`SWAGGER_ENABLED=false`)
- [ ] Review and restrict actuator endpoints
- [ ] Set `DDL_AUTO=validate` (prevents auto schema changes)
- [ ] Enable Flyway migrations (`FLYWAY_ENABLED=true`)

### Monitoring & Logging
- [ ] Set up log aggregation (ELK, CloudWatch, etc.)
- [ ] Configure log rotation
- [ ] Monitor authentication failures
- [ ] Set up alerts for security events
- [ ] Review audit logs regularly

## Demo Mode Configuration
The application includes a `DEMO_MODE` flag that gates admin user creation:

### How It Works
- **Default in application.yaml**: `DEMO_MODE=true` (for local development)
- **Default in docker-compose.prod.yaml**: `DEMO_MODE=false` (for production)
- **Admin Creation**: Only occurs when both `DEMO_MODE=true` AND `ADMIN_ENABLED=true`

### Configuration
**Environment Variables:**
```bash
DEMO_MODE=true                       # Enable demo mode (required for admin creation)
ADMIN_EMAIL=admin@example.com        # Admin email address (demo only)
ADMIN_USERNAME=admin                 # Admin username (demo only)
ADMIN_PASSWORD=admin123!             # Admin password (demo only - CHANGE IN PRODUCTION!)
ADMIN_ENABLED=true                   # Set to false to disable admin creation
```

**Default Values (Development/Demo):**
- Email: `admin@example.com`
- Username: `admin`
- Password: `admin123!`
- Demo Mode: `true` (in application.yaml), `false` (in docker-compose.prod.yaml)
- Enabled: `true`

**Production Security:**
- **IMPORTANT**: These are demo credentials for local testing only!
- Set `DEMO_MODE=false` and `ADMIN_ENABLED=false` in production
- Create admin users manually or through a secure initialization process

## Environment Variables Reference

### Security-Related Variables

| Variable | Default | Description | Production Action |
|----------|---------|-------------|-------------------|
| `DEMO_MODE` | true | Enable demo mode (set to false in production) | **Set to false** |
| `ADMIN_ENABLED` | true | Enable admin user creation | **Set to false** |
| `ADMIN_EMAIL` | admin@example.com | Admin email (demo only) | **Change** |
| `ADMIN_USERNAME` | admin | Admin username (demo only) | **Change** |
| `ADMIN_PASSWORD` | admin123! | Admin password (demo only) | **Change** |
| `JWT_SECRET` | DEMO_SECRET_KEY... | JWT secret key (demo only) | **Change** |
| `JWT_EXPIRATION` | 86400000 | JWT expiration (24 hours) | Review |
| `DATABASE_PASSWORD` | demo_password... | Database password (demo only) | **Change** |
| `CORS_ALLOWED_ORIGINS` | localhost:3000,5173 | CORS allowed origins | **Restrict to production domains** |
| `CSRF_ENABLED` | false | Enable CSRF protection | Enable if using sessions |
| `SWAGGER_ENABLED` | true | Enable Swagger UI | **Set to false** |

## Password Reset Security

### Email Configuration
The application supports password reset emails via SMTP. For proof of concept, email is disabled by default and reset URLs are logged to the console.

**Security Note**: Never commit SMTP credentials to version control. Always use environment variables or a secrets manager.
### Production Email Setup

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
1. Enable 2-Step Verification in a Google Account
2. Generate an App Password: Google Account → Security → App Passwords
3. Use the 16-character app password (not your regular password)

**Other Providers:**
- **SendGrid**: `smtp.sendgrid.net`, port 587
- **AWS SES**: Use AWS credentials and SES SMTP settings
- **Mailgun**: Use Mailgun SMTP settings
- **Office 365**: `smtp.office365.com`, port 587


