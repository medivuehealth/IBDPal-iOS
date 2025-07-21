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
  Checkbox,
} from 'react-native-paper';
import { colors } from '../theme';
import { API_BASE_URL } from '../config';
import CustomModal from '../components/CustomModal';

const RegisterScreen = ({ navigation, route }) => {
  const [formData, setFormData] = useState({
    email: '',
    password: '',
    confirmPassword: '',
    firstName: '',
    lastName: '',
  });
  const [agreeToTerms, setAgreeToTerms] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const [showPassword, setShowPassword] = useState(false);
  const [showConfirmPassword, setShowConfirmPassword] = useState(false);
  const [errors, setErrors] = useState({});
  const [showErrorModal, setShowErrorModal] = useState(false);
  const [errorMessage, setErrorMessage] = useState('');
  const [errorTitle, setErrorTitle] = useState('Registration Failed');

  const { authContext } = route.params;

  // Check if form is complete for visual feedback
  const isFormComplete = () => {
    return (
      formData.email.trim() &&
      formData.firstName.trim() &&
      formData.lastName.trim() &&
      formData.password &&
      formData.confirmPassword &&
      formData.password === formData.confirmPassword &&
      agreeToTerms
    );
  };

  const updateFormData = (field, value) => {
    setFormData(prev => ({ ...prev, [field]: value }));
    // Clear error when user starts typing
    if (errors[field]) {
      setErrors(prev => ({ ...prev, [field]: '' }));
    }
    
    // Real-time validation for password confirmation
    if (field === 'password' && formData.confirmPassword) {
      if (value !== formData.confirmPassword) {
        setErrors(prev => ({ ...prev, confirmPassword: 'Passwords do not match' }));
      } else {
        setErrors(prev => ({ ...prev, confirmPassword: '' }));
      }
    }
    
    if (field === 'confirmPassword' && formData.password) {
      if (value !== formData.password) {
        setErrors(prev => ({ ...prev, confirmPassword: 'Passwords do not match' }));
      } else {
        setErrors(prev => ({ ...prev, confirmPassword: '' }));
      }
    }
  };

  const validateForm = () => {
    const newErrors = {};

    // Email validation - Required and format check
    if (!formData.email.trim()) {
      newErrors.email = 'Email is required';
    } else if (!/\S+@\S+\.\S+/.test(formData.email)) {
      newErrors.email = 'Please enter a valid email address';
    }

    // First Name validation - Required and not just whitespace
    if (!formData.firstName.trim()) {
      newErrors.firstName = 'First name is required';
    } else if (formData.firstName.trim().length < 1) {
      newErrors.firstName = 'First name cannot be empty';
    }

    // Last Name validation - Required and not just whitespace
    if (!formData.lastName.trim()) {
      newErrors.lastName = 'Last name is required';
    } else if (formData.lastName.trim().length < 1) {
      newErrors.lastName = 'Last name cannot be empty';
    }

    // Password validation - Required and minimum length
    if (!formData.password) {
      newErrors.password = 'Password is required';
    } else if (formData.password.length < 8) {
      newErrors.password = 'Password must be at least 8 characters long';
    }

    // Confirm password validation - Required and must match
    if (!formData.confirmPassword) {
      newErrors.confirmPassword = 'Password confirmation is required';
    } else if (formData.password !== formData.confirmPassword) {
      newErrors.confirmPassword = 'Passwords do not match';
    }

    // Terms agreement validation - Required
    if (!agreeToTerms) {
      newErrors.terms = 'You must agree to the terms of use, privacy policy, and disclaimer';
    }

    setErrors(newErrors);
    
            // Show modal if there are validation errors
        if (Object.keys(newErrors).length > 0) {
          setErrorMessage('Please fill in all required fields and ensure all information is correct.');
          setErrorTitle('Please Complete All Fields');
          setShowErrorModal(true);
        }
    
    return Object.keys(newErrors).length === 0;
  };

  const handleRegister = async () => {
    if (!validateForm()) {
      return;
    }

    setIsLoading(true);

    try {
      const response = await fetch(`${API_BASE_URL}/auth/register`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          email: formData.email.trim(),
          password: formData.password,
          confirmPassword: formData.confirmPassword,
          firstName: formData.firstName.trim(),
          lastName: formData.lastName.trim(),
          agreeToTerms: agreeToTerms,
        }),
      });

      const data = await response.json();
      
      // Debug logging
      console.log('Registration response status:', response.status);
      console.log('Registration response data:', data);

      if (response.ok) {
        // Registration successful - show success message and redirect to login
        setErrorMessage('Your IBDPal account has been created. Please sign in with your email and password.');
        setErrorTitle('Account Created Successfully!');
        setShowErrorModal(true);
        
        // Clear form data
        setFormData({
          email: '',
          password: '',
          confirmPassword: '',
          firstName: '',
          lastName: '',
        });
        setAgreeToTerms(false);
        setErrors({});
        
        // Navigate to login screen after modal is closed
        setTimeout(() => {
          navigation.navigate('Login');
        }, 2000);
      } else {
        // Debug logging for error cases
        console.log('Registration failed - Status:', response.status);
        console.log('Registration failed - Error data:', data);
        
        // Handle specific error cases
        let errorMessage = data.message || 'Unable to create account. Please try again.';
        let errorTitle = 'Registration Failed';
        
        // Handle validation errors (they have a different structure)
        if (data.error === 'Validation failed' && data.details && data.details.length > 0) {
          // This is a validation error
          const firstError = data.details[0];
          errorMessage = firstError.msg || 'Please check your input and try again.';
          errorTitle = 'Validation Error';
        } else if (response.status === 409 || data.error === 'User already exists') {
          // Check for duplicate email error
          console.log('Duplicate email detected');
          errorMessage = `An account with the email address "${formData.email.trim()}" already exists. Please use a different email or sign in with your existing account.`;
          errorTitle = 'Account Already Exists';
        }
        
        // Show custom error modal instead of Alert.alert
        setErrorMessage(errorMessage);
        setErrorTitle(errorTitle);
        setShowErrorModal(true);
        
        // Clear only the email field for duplicate email errors
        if (response.status === 409 || data.error === 'User already exists') {
          setFormData(prev => ({ ...prev, email: '' }));
          setErrors(prev => ({ ...prev, email: 'Email already exists' }));
        }
      }
    } catch (error) {
      console.error('Registration error:', error);
      setErrorMessage('Unable to connect to the server. Please check your internet connection and try again.');
      setErrorTitle('Connection Error');
      setShowErrorModal(true);
    } finally {
      setIsLoading(false);
    }
  };

  const handleLoginPress = () => {
    navigation.navigate('Login');
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
            <Title style={styles.title}>Create Account (Updated)</Title>
            <Paragraph style={styles.subtitle}>
              Join IBDPal to start your journey
            </Paragraph>
          </View>

          <View style={styles.form}>
            <TextInput
              label="Email Address"
              value={formData.email}
              onChangeText={(value) => updateFormData('email', value)}
              mode="outlined"
              keyboardType="email-address"
              autoCapitalize="none"
              autoCorrect={false}
              style={styles.input}
              error={!!errors.email}
              disabled={isLoading}
              right={errors.email === 'Email already exists' ? 
                <TextInput.Icon icon="alert-circle" color="#f44336" /> : null
              }
            />
            <HelperText type="error" visible={!!errors.email}>
              {errors.email}
            </HelperText>

            <TextInput
              label="First Name"
              value={formData.firstName}
              onChangeText={(value) => updateFormData('firstName', value)}
              mode="outlined"
              autoCapitalize="words"
              style={styles.input}
              error={!!errors.firstName}
              disabled={isLoading}
            />
            <HelperText type="error" visible={!!errors.firstName}>
              {errors.firstName}
            </HelperText>

            <TextInput
              label="Last Name"
              value={formData.lastName}
              onChangeText={(value) => updateFormData('lastName', value)}
              mode="outlined"
              autoCapitalize="words"
              style={styles.input}
              error={!!errors.lastName}
              disabled={isLoading}
            />
            <HelperText type="error" visible={!!errors.lastName}>
              {errors.lastName}
            </HelperText>

            <TextInput
              label="Password"
              value={formData.password}
              onChangeText={(value) => updateFormData('password', value)}
              mode="outlined"
              secureTextEntry={!showPassword}
              right={
                <TextInput.Icon
                  icon={showPassword ? 'eye-off' : 'eye'}
                  onPress={() => setShowPassword(!showPassword)}
                />
              }
              style={styles.input}
              error={!!errors.password}
              disabled={isLoading}
            />
            <HelperText type="error" visible={!!errors.password}>
              {errors.password}
            </HelperText>

            <TextInput
              label="Confirm Password"
              value={formData.confirmPassword}
              onChangeText={(value) => updateFormData('confirmPassword', value)}
              mode="outlined"
              secureTextEntry={!showConfirmPassword}
              right={
                <TextInput.Icon
                  icon={showConfirmPassword ? 'eye-off' : 'eye'}
                  onPress={() => setShowConfirmPassword(!showConfirmPassword)}
                />
              }
              style={styles.input}
              error={!!errors.confirmPassword}
              disabled={isLoading}
            />
            <HelperText type="error" visible={!!errors.confirmPassword}>
              {errors.confirmPassword}
            </HelperText>

            <View style={styles.termsContainer}>
              <Checkbox
                status={agreeToTerms ? 'checked' : 'unchecked'}
                onPress={() => setAgreeToTerms(!agreeToTerms)}
                disabled={isLoading}
              />
              <View style={styles.termsTextContainer}>
                <Text style={styles.termsText}>
                  I agree to the{' '}
                  <Text style={styles.linkText}>Terms of Use</Text>,{' '}
                  <Text style={styles.linkText}>Privacy Policy</Text>, and{' '}
                  <Text style={styles.linkText}>Disclaimer</Text>
                </Text>
              </View>
            </View>
            <HelperText type="error" visible={!!errors.terms}>
              {errors.terms}
            </HelperText>

            <Button
              mode="contained"
              onPress={handleRegister}
              style={[
                styles.button,
                !isFormComplete() && styles.buttonDisabled
              ]}
              loading={isLoading}
              disabled={isLoading || !isFormComplete()}
            >
              {isFormComplete() ? 'Create Account' : 'Complete All Fields'}
            </Button>

            <View style={styles.loginContainer}>
              <Text style={styles.loginText}>Already have an account? </Text>
              <Button
                mode="text"
                onPress={handleLoginPress}
                disabled={isLoading}
                style={styles.loginButton}
              >
                Sign In
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
  termsContainer: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    marginVertical: 16,
  },
  termsTextContainer: {
    flex: 1,
    marginLeft: 8,
  },
  termsText: {
    fontSize: 14,
    color: colors.text,
    lineHeight: 20,
  },
  linkText: {
    color: colors.primary,
    textDecorationLine: 'underline',
  },
  button: {
    marginTop: 16,
    marginBottom: 24,
    paddingVertical: 8,
  },
  buttonDisabled: {
    opacity: 0.6,
  },
  loginContainer: {
    flexDirection: 'row',
    justifyContent: 'center',
    alignItems: 'center',
  },
  loginText: {
    fontSize: 16,
    color: colors.text,
  },
  loginButton: {
    marginLeft: -8,
  },
});

export default RegisterScreen; 