# IBDPal Startup Script
# This script starts both the backend server and the Expo development server

Write-Host "Starting IBDPal Application..." -ForegroundColor Green
Write-Host "=================================" -ForegroundColor Green

# Check if Node.js is installed
try {
    $nodeVersion = node --version
    Write-Host "Node.js version: $nodeVersion" -ForegroundColor Cyan
} catch {
    Write-Host "Error: Node.js is not installed or not in PATH" -ForegroundColor Red
    exit 1
}

# Check if npm is installed
try {
    $npmVersion = npm --version
    Write-Host "npm version: $npmVersion" -ForegroundColor Cyan
} catch {
    Write-Host "Error: npm is not installed or not in PATH" -ForegroundColor Red
    exit 1
}

# Check if PostgreSQL is running (basic check)
Write-Host "Checking PostgreSQL connection..." -ForegroundColor Yellow
try {
    $pgCheck = Get-Process -Name "postgres" -ErrorAction SilentlyContinue
    if ($pgCheck) {
        Write-Host "PostgreSQL is running" -ForegroundColor Green
    } else {
        Write-Host "Warning: PostgreSQL process not found. Make sure PostgreSQL is running." -ForegroundColor Yellow
    }
} catch {
    Write-Host "Warning: Could not check PostgreSQL status" -ForegroundColor Yellow
}

# Install dependencies if node_modules doesn't exist
if (-not (Test-Path "node_modules")) {
    Write-Host "Installing dependencies..." -ForegroundColor Yellow
    npm install
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Error: Failed to install dependencies" -ForegroundColor Red
        exit 1
    }
}

# Setup database if needed
Write-Host "Setting up database..." -ForegroundColor Yellow
npm run db:setup
if ($LASTEXITCODE -ne 0) {
    Write-Host "Warning: Database setup failed. You may need to configure PostgreSQL first." -ForegroundColor Yellow
}

# Start backend server in background
Write-Host "Starting backend server..." -ForegroundColor Yellow
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$PWD'; npm run server" -WindowStyle Normal

# Wait a moment for server to start
Start-Sleep -Seconds 3

# Start Expo development server
Write-Host "Starting Expo development server..." -ForegroundColor Yellow
Write-Host "Press 'i' for iOS Simulator, 'a' for Android Emulator, or scan QR code with Expo Go app" -ForegroundColor Cyan
npm start

Write-Host "IBDPal startup complete!" -ForegroundColor Green 