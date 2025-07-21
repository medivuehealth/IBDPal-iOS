import AsyncStorage from '@react-native-async-storage/async-storage';
import * as SecureStore from 'expo-secure-store';
import { Platform } from 'react-native';

// Platform-agnostic storage utility
class Storage {
  async getItem(key) {
    try {
      if (Platform.OS === 'web') {
        // Use AsyncStorage for web
        return await AsyncStorage.getItem(key);
      } else {
        // Use SecureStore for native platforms
        return await SecureStore.getItemAsync(key);
      }
    } catch (error) {
      console.error('Error getting item from storage:', error);
      return null;
    }
  }

  async setItem(key, value) {
    try {
      if (Platform.OS === 'web') {
        // Use AsyncStorage for web
        return await AsyncStorage.setItem(key, value);
      } else {
        // Use SecureStore for native platforms
        return await SecureStore.setItemAsync(key, value);
      }
    } catch (error) {
      console.error('Error setting item in storage:', error);
      throw error;
    }
  }

  async removeItem(key) {
    try {
      if (Platform.OS === 'web') {
        // Use AsyncStorage for web
        return await AsyncStorage.removeItem(key);
      } else {
        // Use SecureStore for native platforms
        return await SecureStore.deleteItemAsync(key);
      }
    } catch (error) {
      console.error('Error removing item from storage:', error);
      throw error;
    }
  }

  async clear() {
    try {
      if (Platform.OS === 'web') {
        // Use AsyncStorage for web
        return await AsyncStorage.clear();
      } else {
        // Note: SecureStore doesn't have a clear method, so we'll skip this for native
        console.log('SecureStore clear not implemented for native platforms');
      }
    } catch (error) {
      console.error('Error clearing storage:', error);
      throw error;
    }
  }
}

export default new Storage(); 