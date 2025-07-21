# IBDPal Architecture Documentation

## Multi-Platform Healthcare Ecosystem

This document describes the architecture of the IBDPal iOS application and its relationship with the MediVue web application.

## System Overview

```
┌─────────────────┐    ┌─────────────────┐
│   IBDPal iOS    │    │  MediVue Web    │
│   Application   │    │  Application    │
└─────────┬───────┘    └─────────┬───────┘
          │                      │
          │  ┌─────────────────┐ │
          └──┤  Shared MediVue │◄┘
             │   Database      │
             │  (PostgreSQL)   │
             └─────────────────┘
```

## Applications

### IBDPal (iOS App)
- **Platform**: iOS mobile application
- **Technology**: React Native with Expo
- **Purpose**: Pediatric IBD care mobile app
- **Repository**: This repository
- **Configuration**: `config.env` and `deployment/azure-config.env`

### MediVue (Web App)
- **Platform**: Web application
- **Technology**: Web-based (separate repository)
- **Purpose**: Pediatric IBD care web platform
- **Repository**: Separate repository
- **Configuration**: Separate configuration files

## Shared Database

Both applications use the same **MediVue PostgreSQL database** to ensure:

- **Data Consistency**: Users can access their data from both platforms
- **Single Source of Truth**: All data is stored in one location
- **Unified Authentication**: Users can log in with the same credentials
- **Real-time Sync**: Changes made on one platform are immediately available on the other

## Database Schema

The shared MediVue database includes comprehensive tables for healthcare applications:

### Core Tables
- `users` - Email-based authentication with comprehensive profiles
- `journal_entries` - Daily symptom and nutrition tracking
- `flare_predictions` - ML model predictions
- `medical_history` - Diagnosis and treatment information
- `healthcare_providers` - Provider contact information
- `appointments` - Scheduled medical appointments
- `reminders` - Medication and appointment reminders

### Security & Audit Tables
- `user_sessions` - Active user sessions
- `login_history` - Authentication logs
- `audit_logs` - Security and compliance tracking
- `logs` - Application monitoring

## Configuration Separation

### IBDPal Configuration
- **File**: `config.env`
- **Purpose**: IBDPal-specific settings
- **Key Settings**:
  - `APP_NAME=IBDPal`
  - `APP_TYPE=ios`
  - `JWT_SECRET=ibdpal_jwt_secret_key_here`
  - `DB_NAME=medivue` (shared database)
  - `CORS_ORIGIN` (allows both apps)

### MediVue Configuration
- **File**: Separate configuration file (in MediVue repository)
- **Purpose**: MediVue-specific settings
- **Key Settings**:
  - `APP_NAME=MediVue`
  - `APP_TYPE=web`
  - `JWT_SECRET=medivue_jwt_secret_key_here`
  - `DB_NAME=medivue` (shared database)
  - `CORS_ORIGIN` (allows both apps)

## Authentication Flow

1. **User Registration**: User registers on either platform
2. **Database Storage**: User data stored in shared MediVue database
3. **Cross-Platform Login**: User can log in from either platform using same credentials
4. **Session Management**: Each platform manages its own JWT tokens
5. **Data Access**: Both platforms can read/write to shared database

## Deployment Architecture

### Development
```
┌─────────────────┐    ┌─────────────────┐
│   IBDPal Dev    │    │  MediVue Dev    │
│   localhost:3001│    │  localhost:3000 │
└─────────┬───────┘    └─────────┬───────┘
          │                      │
          │  ┌─────────────────┐ │
          └──┤  Local MediVue  │◄┘
             │   Database      │
             │  localhost:5432 │
             └─────────────────┘
```

### Production
```
┌─────────────────┐    ┌─────────────────┐
│  IBDPal API     │    │  MediVue Web    │
│  Azure App      │    │  Azure App      │
│  Service        │    │  Service        │
└─────────┬───────┘    └─────────┬───────┘
          │                      │
          │  ┌─────────────────┐ │
          └──┤  Azure Database │◄┘
             │  for PostgreSQL │
             │  (Shared)       │
             └─────────────────┘
```

## Security Considerations

### Separate Secrets
- Each application has its own JWT secret
- Each application has its own encryption keys
- Database credentials are shared but can be different users

### CORS Configuration
- Both applications are configured to allow cross-origin requests
- CORS settings include both development and production URLs

### Database Access
- Both applications connect to the same database
- Each application can read/write to all tables
- Row-level security can be implemented if needed

## Development Workflow

1. **Database Changes**: Made in the shared MediVue database schema
2. **IBDPal Development**: Changes to iOS app functionality
3. **MediVue Development**: Changes to web app functionality
4. **Testing**: Test both applications with shared database
5. **Deployment**: Deploy both applications separately

## Benefits of This Architecture

1. **Data Consistency**: Users see the same data on both platforms
2. **Development Efficiency**: Single database schema to maintain
3. **User Experience**: Seamless experience across platforms
4. **Scalability**: Each application can scale independently
5. **Maintenance**: Centralized data management

## Configuration Files Summary

### IBDPal (This Repository)
- `config.env` - Development configuration
- `deployment/azure-config.env` - Production configuration
- `database/setup.js` - Database setup script
- `database/db.js` - Database connection

### MediVue (Separate Repository)
- Separate configuration files
- Separate deployment settings
- Same database connection settings

## Next Steps

1. Configure actual database credentials in `config.env`
2. Set up the shared MediVue database
3. Deploy both applications with their respective configurations
4. Test cross-platform functionality
5. Monitor shared database performance 