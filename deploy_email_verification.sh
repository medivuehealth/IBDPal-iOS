#!/bin/bash

echo "🚀 Deploying Email Verification System to Railway..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if we're in the right directory
if [ ! -f "database/migration_add_email_verification.sql" ]; then
    print_error "Email verification migration file not found. Please run this script from the project root."
    exit 1
fi

print_status "Starting deployment process..."

# Step 1: Run database migration
print_status "Step 1: Running database migration..."
if node run_email_verification_migration.js; then
    print_success "Database migration completed successfully!"
else
    print_error "Database migration failed!"
    exit 1
fi

# Step 2: Check if Railway CLI is installed
print_status "Step 2: Checking Railway CLI..."
if ! command -v railway &> /dev/null; then
    print_warning "Railway CLI not found. Please install it first:"
    echo "npm install -g @railway/cli"
    echo "Then run: railway login"
    exit 1
fi

# Step 3: Deploy to Railway
print_status "Step 3: Deploying to Railway..."
cd server

if railway up; then
    print_success "Deployment to Railway completed successfully!"
else
    print_error "Deployment to Railway failed!"
    exit 1
fi

cd ..

# Step 4: Verify deployment
print_status "Step 4: Verifying deployment..."
sleep 10  # Wait for deployment to complete

# Get the Railway URL
RAILWAY_URL=$(railway status --json | grep -o '"url":"[^"]*"' | cut -d'"' -f4)

if [ -n "$RAILWAY_URL" ]; then
    print_success "Railway URL: $RAILWAY_URL"
    
    # Test health endpoint
    if curl -f "$RAILWAY_URL/health" > /dev/null 2>&1; then
        print_success "Health check passed!"
    else
        print_warning "Health check failed. The service might still be starting up."
    fi
else
    print_warning "Could not retrieve Railway URL. Please check manually."
fi

print_success "Email verification system deployment completed!"
print_status "Next steps:"
echo "1. Test the registration flow with email verification"
echo "2. Check Railway logs for any issues"
echo "3. Verify that verification codes are being generated"
echo "4. Test the resend verification functionality"

print_warning "Note: Email sending is currently logged to console. Implement actual email service for production." 