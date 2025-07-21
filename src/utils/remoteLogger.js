import logger from './logger';

// Remote logging service
class RemoteLogger {
  constructor() {
    this.logEndpoint = 'https://webhook.site/your-unique-url'; // Replace with your webhook URL
    this.enabled = true;
  }

  async sendLog(level, message, data = null) {
    if (!this.enabled) return;

    try {
      const logData = {
        timestamp: new Date().toISOString(),
        level,
        message,
        data,
        platform: 'iOS',
        appVersion: '1.0.0',
        buildNumber: '29',
        deviceInfo: {
          // Add device info if available
        }
      };

      // Send to remote endpoint
      await fetch(this.logEndpoint, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(logData),
      });

      // Also log locally
      logger.log(level, `[REMOTE] ${message}`, data);
    } catch (error) {
      // Fallback to local logging if remote fails
      logger.error('Remote logging failed', { error: error.message });
    }
  }

  info(message, data = null) {
    this.sendLog('info', message, data);
  }

  error(message, data = null) {
    this.sendLog('error', message, data);
  }

  warn(message, data = null) {
    this.sendLog('warn', message, data);
  }

  crash(error, componentStack = null) {
    this.sendLog('error', 'CRASH DETECTED', {
      message: error.message,
      stack: error.stack,
      componentStack,
    });
  }
}

export default new RemoteLogger(); 