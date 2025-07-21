@echo off
echo Building IBDPal - Stable Build 18
echo =================================

echo.
echo 1. Cleaning previous builds...
if exist .expo rmdir /s /q .expo
if exist node_modules rmdir /s /q node_modules

echo.
echo 2. Installing dependencies...
npm install

echo.
echo 3. Starting development server...
echo.
echo To build for iOS:
echo - Run: eas build --platform ios --profile preview
echo.
echo To build for Android:
echo - Run: eas build --platform android --profile preview
echo.
echo To test locally:
echo - Run: npm start
echo.

pause 