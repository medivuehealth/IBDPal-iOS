import * as FileSystem from 'expo-file-system';
import logger from './logger';

class LogUploader {
  constructor() {
    this.logFile = `${FileSystem.documentDirectory}ibdpal_logs.txt`;
    this.maxLogSize = 1024 * 1024; // 1MB
  }

  async appendLog(level, message, data = null) {
    try {
      const timestamp = new Date().toISOString();
      const logEntry = `[${timestamp}] [${level.toUpperCase()}] ${message}`;
      const dataEntry = data ? `\nData: ${JSON.stringify(data, null, 2)}` : '';
      const fullEntry = `${logEntry}${dataEntry}\n\n`;

      // Append to log file
      await FileSystem.writeAsStringAsync(this.logFile, fullEntry, {
        append: true
      });

      // Check file size and rotate if needed
      const fileInfo = await FileSystem.getInfoAsync(this.logFile);
      if (fileInfo.exists && fileInfo.size > this.maxLogSize) {
        await this.rotateLogFile();
      }

    } catch (error) {
      console.error('Failed to write log:', error);
    }
  }

  async rotateLogFile() {
    try {
      const backupFile = `${FileSystem.documentDirectory}ibdpal_logs_backup.txt`;
      await FileSystem.moveAsync({
        from: this.logFile,
        to: backupFile
      });
    } catch (error) {
      console.error('Failed to rotate log file:', error);
    }
  }

  async uploadLogs() {
    try {
      const fileInfo = await FileSystem.getInfoAsync(this.logFile);
      if (!fileInfo.exists) {
        logger.info('No log file to upload');
        return;
      }

      // Read log file
      const logs = await FileSystem.readAsStringAsync(this.logFile);
      
      // Upload to a simple text sharing service
      // You can replace this with your preferred cloud storage
      const uploadUrl = 'https://pastebin.com/api/api_post.php';
      
      const formData = new FormData();
      formData.append('api_dev_key', 'your_pastebin_key'); // Replace with your key
      formData.append('api_option', 'paste');
      formData.append('api_paste_code', logs);
      formData.append('api_paste_name', `IBDPal Logs ${new Date().toISOString()}`);

      const response = await fetch(uploadUrl, {
        method: 'POST',
        body: formData
      });

      if (response.ok) {
        const pasteUrl = await response.text();
        logger.info('Logs uploaded successfully', { url: pasteUrl });
        return pasteUrl;
      } else {
        logger.error('Failed to upload logs', { status: response.status });
      }
    } catch (error) {
      logger.error('Upload logs error', { error: error.message });
    }
  }

  async getLogs() {
    try {
      const fileInfo = await FileSystem.getInfoAsync(this.logFile);
      if (fileInfo.exists) {
        return await FileSystem.readAsStringAsync(this.logFile);
      }
      return 'No logs found';
    } catch (error) {
      logger.error('Failed to read logs', { error: error.message });
      return 'Failed to read logs';
    }
  }

  async clearLogs() {
    try {
      await FileSystem.deleteAsync(this.logFile);
      logger.info('Logs cleared');
    } catch (error) {
      logger.error('Failed to clear logs', { error: error.message });
    }
  }
}

export default new LogUploader(); 