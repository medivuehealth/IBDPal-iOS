// Environment Configuration
const ENV = process.env.NODE_ENV || 'development';

// API Configuration
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

export const API_BASE_URL = getApiBaseUrl();

console.log('Config: Final API_BASE_URL:', API_BASE_URL);

// App Configuration
export const APP_CONFIG = {
  name: process.env.APP_NAME || 'IBDPal',
  version: process.env.APP_VERSION || '1.0.0',
  description: 'Pediatric IBD Care Mobile App',
  environment: ENV,
};

// Feature Flags
export const FEATURES = {
  nutritionAnalyzer: true,
  myLog: true,
  predictions: false, // Will be implemented later
  advocacy: false, // Will be implemented later
};

// Validation Rules
export const VALIDATION_RULES = {
  password: {
    minLength: 8,
    requireUppercase: false,
    requireLowercase: false,
    requireNumbers: false,
    requireSpecialChars: false,
  },
  email: {
    allowSubdomains: true,
  },
};

// UI Configuration
export const UI_CONFIG = {
  maxRetries: 3,
  timeout: 10000, // 10 seconds
  animationDuration: 300,
};

// Development Configuration
export const DEV_CONFIG = {
  enableLogging: ENV === 'development',
  enableDebugMode: ENV === 'development',
  mockApi: false, // Set to true for testing without backend
}; 