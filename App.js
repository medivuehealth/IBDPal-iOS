import React, { useState, useEffect } from 'react';
import { NavigationContainer } from '@react-navigation/native';
import { createStackNavigator } from '@react-navigation/stack';
import { createBottomTabNavigator } from '@react-navigation/bottom-tabs';
import { Provider as PaperProvider } from 'react-native-paper';
import { Icon } from 'react-native-paper';
import storage from './src/utils/storage';
import ErrorBoundary from './src/components/ErrorBoundary';
import { setupGlobalErrorHandler } from './src/utils/errorHandler';
import logger from './src/utils/logger';

// Import screens
import LoginScreen from './src/screens/LoginScreen';
import RegisterScreen from './src/screens/RegisterScreen';
import LoadingScreen from './src/screens/LoadingScreen';
import HomeScreen from './src/screens/HomeScreen';
import DailyLogScreen from './src/screens/DailyLogScreen';
import DiscoveryScreen from './src/screens/DiscoveryScreen';
import SearchScreen from './src/screens/SearchScreen';
import MoreScreen from './src/screens/MoreScreen';

// Import theme
import { theme, colors } from './src/theme';

const Stack = createStackNavigator();
const Tab = createBottomTabNavigator();

export default function App() {
  const [isLoading, setIsLoading] = useState(true);
  const [userToken, setUserToken] = useState(null);
  const [userData, setUserData] = useState(null);

  // Setup global error handler
  useEffect(() => {
    logger.info('🚀 IBDPal App Starting', { 
      version: '1.0.0', 
      buildNumber: '28',
      platform: 'iOS'
    });
    setupGlobalErrorHandler();
  }, []);

  useEffect(() => {
    // Check for stored authentication token
    const bootstrapAsync = async () => {
      try {
        const token = await storage.getItem('userToken');
        const user = await storage.getItem('userData');
        
        if (token && user) {
          setUserToken(token);
          setUserData(JSON.parse(user));
        }
      } catch (error) {
        console.error('Error loading stored authentication:', error);
      } finally {
        setIsLoading(false);
      }
    };

    bootstrapAsync();
  }, []);

  const authContext = {
    signIn: async (token, user) => {
      try {
        await storage.setItem('userToken', token);
        await storage.setItem('userData', JSON.stringify(user));
        setUserToken(token);
        setUserData(user);
      } catch (error) {
        console.error('Error storing authentication:', error);
      }
    },
    signOut: async () => {
      try {
        await storage.removeItem('userToken');
        await storage.removeItem('userData');
        setUserToken(null);
        setUserData(null);
      } catch (error) {
        console.error('Error removing authentication:', error);
      }
    },
    signUp: async (token, user) => {
      try {
        await storage.setItem('userToken', token);
        await storage.setItem('userData', JSON.stringify(user));
        setUserToken(token);
        setUserData(user);
      } catch (error) {
        console.error('Error storing authentication:', error);
      }
    }
  };

  // Tab Navigator for authenticated users
  const TabNavigator = () => (
    <Tab.Navigator
      screenOptions={({ route }) => ({
        tabBarIcon: ({ focused, color, size }) => {
          let iconName;

          if (route.name === 'Home') {
            iconName = 'home';
          } else if (route.name === 'DailyLog') {
            iconName = 'notebook';
          } else if (route.name === 'Discovery') {
            iconName = 'chart-line';
          } else if (route.name === 'Search') {
            iconName = 'magnify';
          } else if (route.name === 'More') {
            iconName = 'dots-horizontal';
          }

          return <Icon name={iconName} size={size} color={color} />;
        },
        tabBarActiveTintColor: colors.primary,
        tabBarInactiveTintColor: colors.placeholder,
        headerShown: false,
      })}
    >
      <Tab.Screen 
        name="Home" 
        component={HomeScreen}
        options={{ title: 'Home' }}
        initialParams={{ userData, authContext }}
      />
      <Tab.Screen 
        name="DailyLog" 
        component={DailyLogScreen}
        options={{ title: 'Daily Log' }}
        initialParams={{ userData, authContext }}
      />
      <Tab.Screen 
        name="Discovery" 
        component={DiscoveryScreen}
        options={{ title: 'Discovery' }}
        initialParams={{ userData, authContext }}
      />
      <Tab.Screen 
        name="Search" 
        component={SearchScreen}
        options={{ title: 'Search' }}
        initialParams={{ userData, authContext }}
      />
      <Tab.Screen 
        name="More" 
        component={MoreScreen}
        options={{ title: 'More' }}
        initialParams={{ userData, authContext }}
      />

    </Tab.Navigator>
  );

  if (isLoading) {
    return <LoadingScreen />;
  }

  return (
    <ErrorBoundary>
      <PaperProvider theme={theme}>
        <NavigationContainer>
          <Stack.Navigator
            screenOptions={{
              headerShown: false,
            }}
          >
            {userToken == null ? (
              // Auth screens
              <>
                <Stack.Screen 
                  name="Login" 
                  component={LoginScreen}
                  initialParams={{ authContext }}
                />
                <Stack.Screen 
                  name="Register" 
                  component={RegisterScreen}
                  initialParams={{ authContext }}
                />
              </>
            ) : (
              // Main app with tabs
              <>
                <Stack.Screen 
                  name="MainApp" 
                  component={TabNavigator}
                  initialParams={{ authContext, userData }}
                />
              </>
            )}
          </Stack.Navigator>
        </NavigationContainer>
      </PaperProvider>
    </ErrorBoundary>
  );
} 