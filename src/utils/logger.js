import { Platform } from 'react-native';
import logUploader from './logUploader';

// Enhanced logger that works in production builds
class Logger {
  constructor() {
    this.logs = [];
    this.maxLogs = 100;
  }

  log(level, message, data = null) {
    const timestamp = new Date().toISOString();
    const logEntry = {
      timestamp,
      level,
      message,
      data,
      platform: Platform.OS,
      version: '1.0.0',
      buildNumber: '28'
    };

    // Add to memory logs
    this.logs.push(logEntry);
    if (this.logs.length > this.maxLogs) {
      this.logs.shift();
    }

    // Format the log message
    const formattedMessage = `[${timestamp}] [${level.toUpperCase()}] ${message}`;
    
    // Use different logging methods based on platform
    if (Platform.OS === 'ios') {
      // iOS specific logging that shows up in device logs
      console.log(formattedMessage);
      if (data) {
        console.log('Data:', JSON.stringify(data, null, 2));
      }
      
      // Also log to native iOS logging
      if (global.nativeLoggingHook) {
        global.nativeLoggingHook(formattedMessage);
      }
    } else {
      // Android and other platforms
      console.log(formattedMessage);
      if (data) {
        console.log('Data:', JSON.stringify(data, null, 2));
      }
    }

    // Force flush to ensure logs are written
    if (global.flushLogs) {
      global.flushLogs();
    }

    // Also write to file for later retrieval
    logUploader.appendLog(level, message, data);
  }

  info(message, data = null) {
    this.log('info', message, data);
  }

  warn(message, data = null) {
    this.log('warn', message, data);
  }

  error(message, data = null) {
    this.log('error', message, data);
  }

  debug(message, data = null) {
    this.log('debug', message, data);
  }

  // Log API calls
  apiCall(url, method, requestData = null) {
    this.info(`API ${method.toUpperCase()} ${url}`, {
      method,
      url,
      requestData,
      timestamp: new Date().toISOString()
    });
  }

  // Log API responses
  apiResponse(url, method, status, responseData = null, error = null) {
    this.info(`API ${method.toUpperCase()} ${url} - ${status}`, {
      method,
      url,
      status,
      responseData,
      error: error ? error.message : null,
      timestamp: new Date().toISOString()
    });
  }

  // Log crashes
  crash(error, componentStack = null) {
    this.error('CRASH DETECTED', {
      message: error.message,
      stack: error.stack,
      componentStack,
      timestamp: new Date().toISOString()
    });
  }

  // Get all logs
  getLogs() {
    return this.logs;
  }

  // Clear logs
  clearLogs() {
    this.logs = [];
  }
}

export default new Logger(); 