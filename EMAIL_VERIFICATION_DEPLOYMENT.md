# Email Verification System Deployment Guide

This guide covers the deployment of the email verification system to Railway, including database migrations and server updates.

## 📋 Overview

The email verification system adds the following features:
- **Email verification during registration**
- **6-digit verification codes** sent to user emails
- **Verification code validation** with expiration (15 minutes)
- **Resend verification code** functionality
- **Account locking** after failed verification attempts
- **Database tracking** of verification status

## 🗄️ Database Changes

### New Fields Added to `users` Table

| Field | Type | Description |
|-------|------|-------------|
| `email_verified` | BOOLEAN | Whether email is verified (default: FALSE) |
| `verification_code` | VARCHAR(6) | 6-digit verification code |
| `verification_code_expires` | TIMESTAMP | When verification code expires |
| `verification_attempts` | INTEGER | Number of failed verification attempts |
| `last_verification_attempt` | TIMESTAMP | Last verification attempt timestamp |

### Database Functions Added

- `generate_verification_code()` - Generates random 6-digit codes
- `is_verification_code_expires()` - Checks if code is expired

### Indexes Added

- `idx_users_verification_code` - For fast verification code lookups
- `idx_users_email_verified` - For email verification status queries

## 🚀 Deployment Steps

### Step 1: Run Database Migration

```bash
# Run the email verification migration
node run_email_verification_migration.js
```

**Expected Output:**
```
🚀 Starting Email Verification Database Migration...
✅ Connected to database
📝 Executing email verification migration...
✅ Email verification migration completed successfully!
📊 Added fields:
   - email_verified (BOOLEAN)
   - verification_code (VARCHAR(6))
   - verification_code_expires (TIMESTAMP)
   - verification_attempts (INTEGER)
   - last_verification_attempt (TIMESTAMP)
🔧 Added functions:
   - generate_verification_code()
   - is_verification_code_expired()
📈 Added indexes for performance
🔒 Added constraints for data integrity
🔌 Database connection closed
```

### Step 2: Deploy to Railway

#### Option A: Using Deployment Script (Recommended)

```bash
# Make script executable (if not already)
chmod +x deploy_email_verification.sh

# Run deployment
./deploy_email_verification.sh
```

#### Option B: Manual Deployment

```bash
# Navigate to server directory
cd server

# Deploy to Railway
railway up

# Check deployment status
railway status
```

### Step 3: Verify Deployment

```bash
# Test the health endpoint
curl https://your-railway-url.railway.app/health

# Expected response:
{
  "status": "OK",
  "timestamp": "2024-01-01T00:00:00.000Z",
  "app": "IBDPal",
  "version": "1.0.0",
  "environment": "production",
  "uptime": 123.456,
  "memory": {...},
  "database": "connected"
}
```

## 🧪 Testing the System

### Run Automated Tests

```bash
# Test the email verification system
node test_email_verification.js
```

### Manual Testing

1. **Registration Flow:**
   - Register a new user
   - Check that `requiresVerification: true` is returned
   - Verify code is logged to console (check Railway logs)

2. **Login Without Verification:**
   - Try to login with unverified account
   - Should receive 401 error with `requiresVerification: true`

3. **Resend Verification:**
   - Call resend verification endpoint
   - New code should be generated and logged

4. **Invalid Verification:**
   - Try to verify with wrong code
   - Should receive 400 error

## 🔧 Server Endpoints

### New Endpoints Added

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/auth/verify-email` | POST | Verify email with 6-digit code |
| `/api/auth/resend-verification` | POST | Resend verification code |

### Modified Endpoints

| Endpoint | Changes |
|----------|---------|
| `/api/auth/register` | Now requires email verification |
| `/api/auth/login` | Now checks for email verification |

## 📧 Email Integration (TODO)

Currently, verification codes are logged to the console. For production, implement actual email sending:

### Recommended Email Services

1. **SendGrid** - Popular email service
2. **Mailgun** - Developer-friendly
3. **AWS SES** - Cost-effective for high volume
4. **Nodemailer** - For custom SMTP

### Implementation Steps

1. Install email service package
2. Add email service credentials to environment variables
3. Replace console.log with actual email sending
4. Test email delivery

## 🔒 Security Features

### Rate Limiting
- Verification attempts tracked per user
- Account locked after 5 failed attempts
- 15-minute expiration for verification codes

### Data Protection
- Verification codes are 6-digit random numbers
- Codes are cleared after successful verification
- Failed attempts are logged and tracked

## 📊 Monitoring

### Railway Logs
```bash
# View Railway logs
railway logs

# Filter for verification codes
railway logs | grep "📧"
```

### Database Queries
```sql
-- Check verification status
SELECT email, email_verified, verification_attempts 
FROM users 
WHERE email_verified = FALSE;

-- Check locked accounts
SELECT email, verification_attempts, account_locked 
FROM users 
WHERE account_locked = TRUE;
```

## 🚨 Troubleshooting

### Common Issues

1. **Migration Fails**
   - Check database connection
   - Verify PostgreSQL version compatibility
   - Check for existing columns

2. **Deployment Fails**
   - Check Railway CLI installation
   - Verify environment variables
   - Check server logs

3. **Verification Not Working**
   - Check database migration completed
   - Verify new endpoints are accessible
   - Check Railway logs for errors

### Debug Commands

```bash
# Check database connection
node -e "require('./database/db.js').query('SELECT NOW()').then(console.log)"

# Test server locally
cd server && npm start

# Check Railway status
railway status
```

## 📝 Environment Variables

Ensure these are set in Railway:

```env
# Database
DB_HOST=your-db-host
DB_PORT=5432
DB_USER=your-db-user
DB_PASSWORD=your-db-password

# JWT
JWT_SECRET=your-jwt-secret
JWT_EXPIRES_IN=7d

# Server
NODE_ENV=production
SERVER_PORT=3004

# Email (for future implementation)
EMAIL_SERVICE=sendgrid
EMAIL_API_KEY=your-email-api-key
```

## ✅ Success Criteria

The deployment is successful when:

1. ✅ Database migration runs without errors
2. ✅ Railway deployment completes successfully
3. ✅ Health endpoint responds correctly
4. ✅ Registration requires email verification
5. ✅ Login blocks unverified users
6. ✅ Verification codes are generated and logged
7. ✅ Resend verification works
8. ✅ Invalid codes are rejected

## 🔄 Rollback Plan

If issues occur:

1. **Database Rollback:**
   ```sql
   -- Remove verification fields (if needed)
   ALTER TABLE users DROP COLUMN IF EXISTS email_verified;
   ALTER TABLE users DROP COLUMN IF EXISTS verification_code;
   ALTER TABLE users DROP COLUMN IF EXISTS verification_code_expires;
   ALTER TABLE users DROP COLUMN IF EXISTS verification_attempts;
   ALTER TABLE users DROP COLUMN IF EXISTS last_verification_attempt;
   ```

2. **Server Rollback:**
   - Revert to previous Railway deployment
   - Or deploy previous version of auth.js

## 📞 Support

For deployment issues:
1. Check Railway documentation
2. Review server logs
3. Test database connectivity
4. Verify environment variables

---

**Note:** This system is designed for educational purposes. For production use, implement proper email sending and additional security measures. 