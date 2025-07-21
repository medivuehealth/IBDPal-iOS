import React, { useState, useEffect } from 'react';
import { View, ScrollView, StyleSheet, Share } from 'react-native';
import { Text, Button, Card, Title, Paragraph } from 'react-native-paper';
import logUploader from '../utils/logUploader';
import logger from '../utils/logger';

const LogViewerScreen = () => {
  const [logs, setLogs] = useState('');
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    loadLogs();
  }, []);

  const loadLogs = async () => {
    setLoading(true);
    try {
      const logContent = await logUploader.getLogs();
      setLogs(logContent);
    } catch (error) {
      setLogs('Failed to load logs: ' + error.message);
    } finally {
      setLoading(false);
    }
  };

  const shareLogs = async () => {
    try {
      await Share.share({
        message: logs,
        title: 'IBDPal Crash Logs'
      });
    } catch (error) {
      logger.error('Failed to share logs', { error: error.message });
    }
  };

  const uploadLogs = async () => {
    setLoading(true);
    try {
      const url = await logUploader.uploadLogs();
      if (url) {
        setLogs(prev => prev + '\n\n=== LOGS UPLOADED ===\n' + url);
      }
    } catch (error) {
      setLogs(prev => prev + '\n\n=== UPLOAD FAILED ===\n' + error.message);
    } finally {
      setLoading(false);
    }
  };

  const clearLogs = async () => {
    try {
      await logUploader.clearLogs();
      setLogs('Logs cleared');
    } catch (error) {
      setLogs('Failed to clear logs: ' + error.message);
    }
  };

  return (
    <View style={styles.container}>
      <Card style={styles.card}>
        <Card.Content>
          <Title>IBDPal Logs</Title>
          <Paragraph>View and share crash logs</Paragraph>
        </Card.Content>
      </Card>

      <View style={styles.buttonContainer}>
        <Button 
          mode="contained" 
          onPress={loadLogs} 
          loading={loading}
          style={styles.button}
        >
          Refresh Logs
        </Button>
        <Button 
          mode="outlined" 
          onPress={shareLogs} 
          style={styles.button}
        >
          Share Logs
        </Button>
        <Button 
          mode="outlined" 
          onPress={uploadLogs} 
          style={styles.button}
        >
          Upload Logs
        </Button>
        <Button 
          mode="outlined" 
          onPress={clearLogs} 
          style={styles.button}
        >
          Clear Logs
        </Button>
      </View>

      <ScrollView style={styles.logContainer}>
        <Text style={styles.logText}>{logs || 'No logs available'}</Text>
      </ScrollView>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    padding: 16,
    backgroundColor: '#f5f5f5',
  },
  card: {
    marginBottom: 16,
  },
  buttonContainer: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    marginBottom: 16,
  },
  button: {
    margin: 4,
    flex: 1,
    minWidth: 100,
  },
  logContainer: {
    flex: 1,
    backgroundColor: '#fff',
    borderRadius: 8,
    padding: 16,
  },
  logText: {
    fontFamily: 'monospace',
    fontSize: 12,
    color: '#333',
  },
});

export default LogViewerScreen; 