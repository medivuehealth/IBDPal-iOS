import logger from './logger';

// Global error handler for unhandled promise rejections and errors
export const setupGlobalErrorHandler = () => {
  // Handle unhandled promise rejections
  const originalHandler = global.ErrorUtils.setGlobalHandler;
  
  global.ErrorUtils.setGlobalHandler((error, isFatal) => {
    logger.crash(error, null);
    
    console.error('=== GLOBAL ERROR HANDLER ===');
    console.error('Error:', error);
    console.error('Is Fatal:', isFatal);
    console.error('Stack:', error.stack);
    console.error('=== END GLOBAL ERROR ===');
    
    // Call the original handler
    if (originalHandler) {
      originalHandler(error, isFatal);
    }
  });

  // Handle unhandled promise rejections
  const originalUnhandledRejectionHandler = global.onunhandledrejection;
  
  global.onunhandledrejection = (event) => {
    logger.error('UNHANDLED PROMISE REJECTION', {
      reason: event.reason,
      promise: event.promise
    });
    
    console.error('=== UNHANDLED PROMISE REJECTION ===');
    console.error('Reason:', event.reason);
    console.error('Promise:', event.promise);
    console.error('=== END UNHANDLED PROMISE REJECTION ===');
    
    // Call the original handler if it exists
    if (originalUnhandledRejectionHandler) {
      originalUnhandledRejectionHandler(event);
    }
  };

  // Handle console errors
  const originalConsoleError = console.error;
  console.error = (...args) => {
    console.log('=== CONSOLE ERROR ===');
    originalConsoleError(...args);
    console.log('=== END CONSOLE ERROR ===');
  };

  console.log('🔧 Global error handler setup complete');
}; 