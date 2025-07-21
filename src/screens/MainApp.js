import React from 'react';
import { View, StyleSheet } from 'react-native';
import { Text, Button, Surface, Title, Paragraph } from 'react-native-paper';
import { colors } from '../theme';

const MainApp = ({ route }) => {
  const { authContext, userData } = route.params;

  const handleLogout = async () => {
    await authContext.signOut();
  };

  return (
    <View style={styles.container}>
      <Surface style={styles.surface}>
        <Title style={styles.title}>Welcome to IBDPal!</Title>
        <Paragraph style={styles.subtitle}>
          Hello, {userData?.firstName || 'User'}!
        </Paragraph>
        
        <View style={styles.content}>
          <Text style={styles.text}>
            This is the main app screen. Here you'll find:
          </Text>
          
          <View style={styles.featuresList}>
            <Text style={styles.featureItem}>• My Log - Track your symptoms and activities</Text>
            <Text style={styles.featureItem}>• Nutrition Analyzer - Analyze your meals and get recommendations</Text>
            <Text style={styles.featureItem}>• Predictions - AI-powered flare predictions (coming soon)</Text>
            <Text style={styles.featureItem}>• Advocacy - Connect with the IBD community (coming soon)</Text>
          </View>
          
          <Text style={styles.text}>
            These features will be implemented in the next phase of development.
          </Text>
        </View>

        <Button
          mode="outlined"
          onPress={handleLogout}
          style={styles.logoutButton}
        >
          Sign Out
        </Button>
      </Surface>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.background,
    padding: 20,
  },
  surface: {
    flex: 1,
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
  title: {
    fontSize: 28,
    fontWeight: 'bold',
    color: colors.primary,
    textAlign: 'center',
    marginBottom: 8,
  },
  subtitle: {
    fontSize: 18,
    color: colors.placeholder,
    textAlign: 'center',
    marginBottom: 32,
  },
  content: {
    flex: 1,
    justifyContent: 'center',
  },
  text: {
    fontSize: 16,
    color: colors.text,
    marginBottom: 16,
    textAlign: 'center',
  },
  featuresList: {
    marginVertical: 20,
  },
  featureItem: {
    fontSize: 16,
    color: colors.text,
    marginBottom: 8,
    paddingLeft: 20,
  },
  logoutButton: {
    marginTop: 20,
  },
});

export default MainApp; 