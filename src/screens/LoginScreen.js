import React, { useState } from 'react';
import {
  View,
  StyleSheet,
  ScrollView,
  KeyboardAvoidingView,
  Platform,
} from 'react-native';
import {
  TextInput,
  Button,
  Text,
  Surface,
  Title,
  Paragraph,
  HelperText,
} from 'react-native-paper';
import { colors } from '../theme';
import { API_BASE_URL } from '../config';
import CustomModal from '../components/CustomModal';
import logger from '../utils/logger';

const LoginScreen = ({ navigation, route }) => {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [showPassword, setShowPassword] = useState(false);
  const [emailError, setEmailError] = useState('');
  const [passwordError, setPasswordError] = useState('');
  const [showErrorModal, setShowErrorModal] = useState(false);
  const [errorMessage, setErrorMessage] = useState('');
  const [errorTitle, setErrorTitle] = useState('Login Failed');

  const { authContext } = route.params;

  const validateForm = () => {
    let isValid = true;
    setEmailError('');
    setPasswordError('');

    // Email validation
    if (!email.trim()) {
      setEmailError('Email is required');
      isValid = false;
    } else if (!/\S+@\S+\.\S+/.test(email)) {
      setEmailError('Please enter a valid email address');
      isValid = false;
    }

    // Password validation
    if (!password.trim()) {
      setPasswordError('Password is required');
      isValid = false;
    }

    return isValid;
  };

  const handleLogin = async () => {
    if (!validateForm()) {
      return;
    }

    setIsLoading(true);
    logger.info('🔐 Attempting login', { url: API_BASE_URL, email });

    try {
      logger.apiCall(`${API_BASE_URL}/auth/login`, 'POST', { email });
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
      logger.apiResponse(`${API_BASE_URL}/auth/login`, 'POST', response.status, data);
      console.log('Login response:', response.status, data);

      if (response.ok) {
        await authContext.signIn(data.token, data.user);
      } else {
        console.log('Showing alert with message:', data.message);
        
        // Handle validation errors (they have a different structure)
        let errorMessage = 'Invalid email or password. Please try again.';
        let errorTitle = 'Login Failed';
        
        if (data.error === 'Validation failed' && data.details && data.details.length > 0) {
          // This is a validation error
          const firstError = data.details[0];
          errorMessage = firstError.msg || 'Please check your input and try again.';
          errorTitle = 'Validation Error';
        } else {
          // This is an authentication error
          errorMessage = data.message || data.error || 'Invalid email or password. Please try again.';
          errorTitle = 'Login Failed';
        }
        
        console.log('Final error message:', errorMessage);
        console.log('Final error title:', errorTitle);
        
        // Show custom error modal instead of Alert.alert
        setErrorMessage(errorMessage);
        setErrorTitle(errorTitle);
        setShowErrorModal(true);
      }
    } catch (error) {
      logger.error('Login error', {
        name: error.name,
        message: error.message,
        stack: error.stack
      });
      console.error('Login error:', error);
      console.error('Error details:', {
        name: error.name,
        message: error.message,
        stack: error.stack
      });
      
      setErrorMessage('Unable to connect to the server. Please check your internet connection and try again.');
      setErrorTitle('Connection Error');
      setShowErrorModal(true);
    } finally {
      setIsLoading(false);
    }
  };

  const handleRegisterPress = () => {
    navigation.navigate('Register');
  };

  return (
    <KeyboardAvoidingView
      style={styles.container}
      behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
    >
      <ScrollView
        contentContainerStyle={styles.scrollContainer}
        keyboardShouldPersistTaps="handled"
      >
        <Surface style={styles.surface}>
          <View style={styles.header}>
            <Title style={styles.title}>Welcome to IBDPal</Title>
            <Paragraph style={styles.subtitle}>
              Your pediatric IBD care companion
            </Paragraph>
          </View>

          <View style={styles.form}>
            <TextInput
              label="Email Address"
              value={email}
              onChangeText={setEmail}
              mode="outlined"
              keyboardType="email-address"
              autoCapitalize="none"
              autoCorrect={false}
              style={styles.input}
              error={!!emailError}
              disabled={isLoading}
            />
            <HelperText type="error" visible={!!emailError}>
              {emailError}
            </HelperText>

            <TextInput
              label="Password"
              value={password}
              onChangeText={setPassword}
              mode="outlined"
              secureTextEntry={!showPassword}
              right={
                <TextInput.Icon
                  icon={showPassword ? 'eye-off' : 'eye'}
                  onPress={() => setShowPassword(!showPassword)}
                />
              }
              style={styles.input}
              error={!!passwordError}
              disabled={isLoading}
            />
            <HelperText type="error" visible={!!passwordError}>
              {passwordError}
            </HelperText>

            <Button
              mode="contained"
              onPress={handleLogin}
              style={styles.button}
              loading={isLoading}
              disabled={isLoading}
            >
              Sign In
            </Button>

            <View style={styles.registerContainer}>
              <Text style={styles.registerText}>Don't have an account? </Text>
              <Button
                mode="text"
                onPress={handleRegisterPress}
                disabled={isLoading}
                style={styles.registerButton}
              >
                Create Account
              </Button>
            </View>
          </View>
        </Surface>
      </ScrollView>
      
      <CustomModal
        visible={showErrorModal}
        onClose={() => setShowErrorModal(false)}
        title={errorTitle}
        message={errorMessage}
      />
    </KeyboardAvoidingView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.background,
  },
  scrollContainer: {
    flexGrow: 1,
    justifyContent: 'center',
    padding: 20,
  },
  surface: {
    padding: 24,
    borderRadius: 12,
    elevation: 4,
    shadowColor: '#000',
    shadowOffset: {
      width: 0,
      height: 2,
    },
    shadowOpacity: 0.25,
    shadowRadius: 3.84,
  },
  header: {
    alignItems: 'center',
    marginBottom: 32,
  },
  title: {
    fontSize: 28,
    fontWeight: 'bold',
    color: colors.primary,
    marginBottom: 8,
  },
  subtitle: {
    fontSize: 16,
    color: colors.placeholder,
    textAlign: 'center',
  },
  form: {
    width: '100%',
  },
  input: {
    marginBottom: 8,
  },
  button: {
    marginTop: 16,
    marginBottom: 24,
    paddingVertical: 8,
  },
  registerContainer: {
    flexDirection: 'row',
    justifyContent: 'center',
    alignItems: 'center',
  },
  registerText: {
    fontSize: 16,
    color: colors.text,
  },
  registerButton: {
    marginLeft: -8,
  },

});

export default LoginScreen; 