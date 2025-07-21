// Environment Configuration
const ENV = process.env.NODE_ENV || 'development';

// API Configuration
const getApiBaseUrl = () => {
  if (ENV === 'production') {
    return process.env.API_BASE_URL || 'https://your-api-domain.com/api';
  }
  // Use IP address for development - replace with your actual IP
  return 'http://192.168.1.154:3004/api'; // Your actual IP address
};

export const API_BASE_URL = getApiBaseUrl();

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