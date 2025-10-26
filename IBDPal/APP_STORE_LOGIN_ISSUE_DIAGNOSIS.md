# App Store Review Login Issue Diagnosis

## Problem Description

**Issue**: App Store reviewers cannot login with `info@ibdpal.org` - getting "invalid email address" error, but the same credentials work on development builds.

## Root Cause Analysis

### **1. API Endpoint Configuration Differences**

#### **Development Build (Working)**
- Uses: `https://ibdpal-server-production.up.railway.app/api`
- Configuration: `src/config.js` - Development environment
- Environment: `NODE_ENV=development`

#### **App Store Build (Not Working)**
- Uses: Same endpoint but different build configuration
- Configuration: Production build settings
- Environment: `NODE_ENV=production`

### **2. Email Validation Differences**

#### **Client-Side Validation (React Native)**
```javascript
// src/screens/LoginScreen.js - Line 45
if (!/\S+@\S+\.\S+/.test(email)) {
  setEmailError('Please enter a valid email address');
  isValid = false;
}
```

#### **Server-Side Validation (Express.js)**
```javascript
// server/routes/auth.js - Line 411
const userResult = await db.query(
  'SELECT * FROM users WHERE email = $1',
  [email]
);
```

### **3. Build Configuration Differences**

#### **Development Build**
- Uses Metro bundler with live reload
- Environment variables from `config.env`
- API_BASE_URL: `https://ibdpal-server-production.up.railway.app/api`

#### **App Store Build**
- Uses bundled JavaScript
- Environment variables from build-time configuration
- May use different API endpoint or validation

## Potential Solutions

### **Solution 1: Verify API Endpoint Configuration**

#### **Check Current Configuration**
```javascript
// src/config.js
const getApiBaseUrl = () => {
  console.log('Config: Environment:', ENV);
  console.log('Config: process.env.API_BASE_URL:', process.env.API_BASE_URL);
  
  if (ENV === 'production') {
    const url = process.env.API_BASE_URL || 'https://ibdpal-server-production.up.railway.app/api';
    console.log('Config: Production URL:', url);
    return url;
  }
  // Use Railway URL for both development and production
  const url = 'https://ibdpal-server-production.up.railway.app/api';
  console.log('Config: Development URL:', url);
  return url;
};
```

#### **Fix: Ensure Consistent API Endpoint**
```javascript
// src/config.js - Updated
const getApiBaseUrl = () => {
  // Always use the same endpoint for both development and production
  const url = 'https://ibdpal-server-production.up.railway.app/api';
  console.log('Config: API URL:', url);
  return url;
};
```

### **Solution 2: Fix Email Validation**

#### **Current Email Validation (Too Restrictive)**
```javascript
// src/screens/LoginScreen.js - Line 45
if (!/\S+@\S+\.\S+/.test(email)) {
  setEmailError('Please enter a valid email address');
  isValid = false;
}
```

#### **Improved Email Validation**
```javascript
// src/screens/LoginScreen.js - Updated
const validateEmail = (email) => {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return emailRegex.test(email);
};

if (!validateEmail(email)) {
  setEmailError('Please enter a valid email address');
  isValid = false;
}
```

### **Solution 3: Add Debug Logging**

#### **Enhanced Login Debugging**
```javascript
// src/screens/LoginScreen.js - Updated
const handleLogin = async () => {
  if (!validateForm()) {
    return;
  }

  setIsLoading(true);
  
  // Debug logging
  console.log('🔐 Login Debug Info:');
  console.log('  Email:', email);
  console.log('  API URL:', API_BASE_URL);
  console.log('  Environment:', process.env.NODE_ENV);
  
  logger.info('🔐 Attempting login', { 
    url: API_BASE_URL, 
    email,
    environment: process.env.NODE_ENV 
  });

  try {
    const response = await fetch(`${API_BASE_URL}/auth/login`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        email: email.trim(),
        password: password,
      }),
    });

    const data = await response.json();
    
    // Enhanced error logging
    console.log('Login response:', {
      status: response.status,
      data: data,
      url: `${API_BASE_URL}/auth/login`
    });
    
    // ... rest of login logic
  } catch (error) {
    console.error('Login error:', error);
    // ... error handling
  }
};
```

### **Solution 4: Server-Side Email Validation Fix**

#### **Current Server Validation**
```javascript
// server/routes/auth.js - Line 411
const userResult = await db.query(
  'SELECT * FROM users WHERE email = $1',
  [email]
);
```

#### **Enhanced Server Validation**
```javascript
// server/routes/auth.js - Updated
router.post('/login', validateLogin, formatValidationErrors, async (req, res) => {
  try {
    const { email, password } = req.body;
    
    // Enhanced email validation
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      return res.status(400).json({
        error: 'Invalid email format',
        message: 'Please enter a valid email address'
      });
    }
    
    // Debug logging
    console.log('🔐 Server Login Attempt:', {
      email: email,
      timestamp: new Date().toISOString(),
      userAgent: req.headers['user-agent']
    });
    
    // Find user by email
    const userResult = await db.query(
      'SELECT * FROM users WHERE email = $1',
      [email.trim().toLowerCase()]
    );
    
    // ... rest of login logic
  } catch (error) {
    console.error('Login error:', error);
    // ... error handling
  }
});
```

### **Solution 5: Demo User Account Verification**

#### **Verify Demo User Exists**
```javascript
// Check if demo user exists in database
const checkDemoUser = async () => {
  try {
    const result = await db.query(
      'SELECT * FROM users WHERE email = $1',
      ['info@ibdpal.org']
    );
    
    if (result.rows.length === 0) {
      console.log('❌ Demo user not found');
      return false;
    }
    
    const user = result.rows[0];
    console.log('✅ Demo user found:', {
      email: user.email,
      verified: user.email_verified,
      status: user.account_status,
      created: user.created_at
    });
    
    return true;
  } catch (error) {
    console.error('Error checking demo user:', error);
    return false;
  }
};
```

## Implementation Steps

### **Step 1: Fix API Configuration**
1. Update `src/config.js` to use consistent API endpoint
2. Remove environment-specific logic
3. Ensure both development and production use same endpoint

### **Step 2: Fix Email Validation**
1. Update client-side email validation regex
2. Update server-side email validation
3. Add debug logging for email validation

### **Step 3: Add Debug Logging**
1. Add comprehensive logging to login process
2. Log API endpoint, email, and environment
3. Log server-side validation results

### **Step 4: Verify Demo User**
1. Check if demo user exists in database
2. Verify email verification status
3. Check account status

### **Step 5: Test Both Builds**
1. Test development build with debug logging
2. Test production build with debug logging
3. Compare logs to identify differences

## Quick Fix for App Store Review

### **Immediate Solution**
1. **Update API Configuration**: Ensure consistent endpoint
2. **Fix Email Validation**: Use proper regex pattern
3. **Add Debug Logging**: Identify exact failure point
4. **Verify Demo User**: Ensure account exists and is verified

### **Long-term Solution**
1. **Environment Configuration**: Proper build-time configuration
2. **Error Handling**: Better error messages for debugging
3. **Testing**: Comprehensive testing of both build types
4. **Monitoring**: Server-side logging for production issues

## Expected Outcome

After implementing these fixes:
- ✅ App Store reviewers can login with `info@ibdpal.org`
- ✅ Consistent behavior between development and production builds
- ✅ Better error handling and debugging
- ✅ Reliable demo user account for testing

The issue should be resolved by ensuring consistent API endpoints and proper email validation across all build types.


