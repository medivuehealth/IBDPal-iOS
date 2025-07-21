import React, { useState, useEffect } from 'react';
import { View, StyleSheet, ScrollView, Alert } from 'react-native';
import { Text, Surface, Title, Paragraph, Card, Button, ActivityIndicator, IconButton, Chip } from 'react-native-paper';
import { colors } from '../theme';
import NutritionAnalyzer from '../components/NutritionAnalyzer';
import FlarePredictions from '../components/FlarePredictions';
import { API_BASE_URL } from '../config';

const HomeScreen = ({ navigation, route }) => {
  const { userData } = route.params;
  const [loading, setLoading] = useState(true);
  const [last7DaysStats, setLast7DaysStats] = useState({
    logEntries: 0,
    mealsLogged: 0,
    symptoms: 'None',
    averageEntries: 0,
    mostActiveDay: 'None'
  });
  const [reminders, setReminders] = useState([]);
  const [diagnosisCompleted, setDiagnosisCompleted] = useState(false);
  const [loadingDiagnosis, setLoadingDiagnosis] = useState(true);

  // Load user data on component mount
  useEffect(() => {
    if (userData?.username) {
      checkDiagnosisStatus();
      loadLast7DaysStats();
    }
  }, [userData?.username]);

  const checkDiagnosisStatus = async () => {
    try {
      setLoadingDiagnosis(true);
      console.log('🏥 Checking diagnosis status for user:', userData?.username);
      const response = await fetch(`${API_BASE_URL}/diagnosis/${userData?.username}`);
      
      if (response.ok) {
        const diagnosisData = await response.json();
        // Check if diagnosis has been completed (has diagnosis field filled)
        setDiagnosisCompleted(!!diagnosisData.diagnosis);
      } else if (response.status === 404) {
        // No diagnosis data found
        setDiagnosisCompleted(false);
      } else {
        console.error('Error checking diagnosis status:', response.status);
        setDiagnosisCompleted(false);
      }
    } catch (error) {
      console.error('Error checking diagnosis status:', error);
      setDiagnosisCompleted(false);
    } finally {
      setLoadingDiagnosis(false);
    }
  };

  const loadLast7DaysStats = async () => {
    try {
      setLoading(true);
      console.log('📊 Loading last 7 days stats for user:', userData?.username);
      
      // Fetch all entries
      const response = await fetch(`${API_BASE_URL}/journal/entries/${userData?.username}`);
      
      if (response.ok) {
        const entries = await response.json();
        
        // Calculate date range for last 7 days
        const today = new Date();
        const sevenDaysAgo = new Date(today);
        sevenDaysAgo.setDate(today.getDate() - 7);
        
        const todayStr = today.toISOString().split('T')[0];
        const sevenDaysAgoStr = sevenDaysAgo.toISOString().split('T')[0];
        
        console.log('Date range:', sevenDaysAgoStr, 'to', todayStr);
        console.log('Current user ID:', userData?.username);
        console.log('All entries:', entries);
        
        // Filter entries for last 7 days
        const last7DaysEntries = entries.filter(entry => {
          const entryDate = entry.entry_date;
          
          // Handle different date formats
          if (typeof entryDate === 'string') {
            const datePart = entryDate.split('T')[0];
            return datePart >= sevenDaysAgoStr && datePart <= todayStr;
          } else if (entryDate instanceof Date) {
            const datePart = entryDate.toISOString().split('T')[0];
            return datePart >= sevenDaysAgoStr && datePart <= todayStr;
          } else if (entryDate && typeof entryDate === 'object' && entryDate.toISOString) {
            const datePart = entryDate.toISOString().split('T')[0];
            return datePart >= sevenDaysAgoStr && datePart <= todayStr;
          }
          return false;
        });
        
        console.log('Last 7 days entries:', last7DaysEntries);
        
        // Group entries by date for analysis
        const entriesByDate = {};
        last7DaysEntries.forEach(entry => {
          let dateKey;
          if (typeof entry.entry_date === 'string') {
            dateKey = entry.entry_date.split('T')[0];
          } else if (entry.entry_date instanceof Date) {
            dateKey = entry.entry_date.toISOString().split('T')[0];
          } else if (entry.entry_date && typeof entry.entry_date === 'object' && entry.entry_date.toISOString) {
            dateKey = entry.entry_date.toISOString().split('T')[0];
          } else {
            dateKey = entry.entry_date;
          }
          
          if (!entriesByDate[dateKey]) {
            entriesByDate[dateKey] = [];
          }
          entriesByDate[dateKey].push(entry);
        });
        
        // Calculate statistics
        const totalEntries = last7DaysEntries.length;
        const mealsLogged = last7DaysEntries.filter(entry => 
          entry.calories > 0 || entry.protein > 0 || entry.carbs > 0
        ).length;
        
        const hasSymptoms = last7DaysEntries.some(entry => 
          entry.pain_severity > 0 || entry.bowel_frequency > 0 || entry.blood_present
        );
        
        // Calculate average entries per day
        const averageEntries = totalEntries > 0 ? Math.round((totalEntries / 7) * 10) / 10 : 0;
        
        // Find most active day
        let mostActiveDay = 'None';
        let maxEntries = 0;
        Object.keys(entriesByDate).forEach(date => {
          if (entriesByDate[date].length > maxEntries) {
            maxEntries = entriesByDate[date].length;
            const dateObj = new Date(date);
            mostActiveDay = dateObj.toLocaleDateString('en-US', { 
              weekday: 'long',
              month: 'short',
              day: 'numeric'
            });
          }
        });
        
        setLast7DaysStats({
          logEntries: totalEntries,
          mealsLogged: mealsLogged,
          symptoms: hasSymptoms ? 'Reported' : 'None',
          averageEntries: averageEntries,
          mostActiveDay: mostActiveDay
        });

        // Generate reminders based on last 7 days data
        generateReminders(last7DaysEntries);
      }
    } catch (error) {
      console.error('Error loading last 7 days stats:', error);
    } finally {
      setLoading(false);
    }
  };

  const generateReminders = (last7DaysEntries) => {
    const newReminders = [];
    
    // Check if any log entries exist for the last 7 days
    if (last7DaysEntries.length === 0) {
      newReminders.push({
        id: 'weekly-log',
        type: 'warning',
        title: 'Weekly Log Missing',
        message: 'You haven\'t logged anything in the past 7 days. Regular tracking helps identify patterns.',
        action: 'Add Entry',
        icon: 'plus-circle',
        priority: 'high'
      });
    } else {
      // Check for specific missing categories in the last 7 days
      const hasNutrition = last7DaysEntries.some(entry => 
        entry.calories > 0 || entry.protein > 0 || entry.carbs > 0 || entry.fiber > 0
      );
      const hasBowel = last7DaysEntries.some(entry => 
        entry.bowel_frequency > 0 || entry.bristol_scale > 0
      );
      const hasPain = last7DaysEntries.some(entry => 
        entry.pain_severity > 0 || entry.pain_location
      );
      const hasMedication = last7DaysEntries.some(entry => 
        entry.medication_taken || entry.medication_type
      );
      const hasLifestyle = last7DaysEntries.some(entry => 
        entry.sleep_hours > 0 || entry.stress_level > 0 || entry.fatigue_level > 0
      );

      // Calculate average entries per day
      const averageEntries = last7DaysEntries.length / 7;
      
      if (averageEntries < 1) {
        newReminders.push({
          id: 'low-activity',
          type: 'warning',
          title: 'Low Activity Level',
          message: `You're averaging ${Math.round(averageEntries * 10) / 10} entries per day. More frequent logging provides better insights.`,
          action: 'Log More',
          icon: 'chart-line',
          priority: 'high'
        });
      }

      if (!hasNutrition) {
        newReminders.push({
          id: 'nutrition',
          type: 'info',
          title: 'Nutrition Tracking',
          message: 'Consider logging your meals to track nutrition and identify food triggers.',
          action: 'Log Meal',
          icon: 'food-apple',
          priority: 'medium'
        });
      }

      if (!hasBowel) {
        newReminders.push({
          id: 'bowel',
          type: 'info',
          title: 'Bowel Health',
          message: 'Tracking bowel movements helps monitor your digestive health.',
          action: 'Log Bowel',
          icon: 'medical-bag',
          priority: 'medium'
        });
      }

      if (!hasPain) {
        newReminders.push({
          id: 'pain',
          type: 'info',
          title: 'Pain & Discomfort',
          message: 'Log any pain or discomfort to track symptom patterns.',
          action: 'Log Pain',
          icon: 'heart-pulse',
          priority: 'medium'
        });
      }

      if (!hasMedication) {
        newReminders.push({
          id: 'medication',
          type: 'info',
          title: 'Medication Tracking',
          message: 'Keep track of your medications and dosages.',
          action: 'Log Medication',
          icon: 'pill',
          priority: 'medium'
        });
      }

      if (!hasLifestyle) {
        newReminders.push({
          id: 'lifestyle',
          type: 'info',
          title: 'Lifestyle Factors',
          message: 'Track sleep, stress, and daily activities that may affect your health.',
          action: 'Log Lifestyle',
          icon: 'bed',
          priority: 'low'
        });
      }
    }

    setReminders(newReminders);
  };

  const handleReminderAction = (reminder) => {
    switch (reminder.id) {
      case 'weekly-log':
      case 'low-activity':
      case 'nutrition':
        navigation.navigate('DailyLog');
        break;
      case 'bowel':
      case 'pain':
      case 'medication':
      case 'lifestyle':
        navigation.navigate('DailyLog');
        break;
      default:
        navigation.navigate('DailyLog');
    }
  };

  return (
    <View style={styles.container}>
      <ScrollView contentContainerStyle={styles.scrollContainer}>
        <Surface style={styles.surface}>
          <View style={styles.header}>
            <Title style={styles.title}>Welcome back, {userData?.firstName || 'User'}!</Title>
            <Paragraph style={styles.subtitle}>
              How are you feeling today?
            </Paragraph>
          </View>

          <View style={styles.content}>
            {/* Diagnosis Assessment Card - Only show if not completed */}
            {!diagnosisCompleted && !loadingDiagnosis && (
              <Card style={[styles.card, styles.diagnosisCard]}>
                <Card.Content>
                  <View style={styles.diagnosisHeader}>
                    <IconButton
                      icon="medical-bag"
                      size={32}
                      iconColor={colors.primary}
                      style={styles.diagnosisIcon}
                    />
                    <View style={styles.diagnosisText}>
                      <Title style={styles.diagnosisTitle}>Complete Your Diagnosis Assessment</Title>
                      <Paragraph style={styles.diagnosisDescription}>
                        Help us provide personalized care by completing your IBD diagnosis information.
                      </Paragraph>
                    </View>
                  </View>
                  <Button
                    mode="contained"
                    onPress={() => navigation.navigate('More', { userData, authContext: route.params.authContext })}
                    style={styles.diagnosisButton}
                    icon="arrow-right"
                  >
                    Start Assessment
                  </Button>
                </Card.Content>
              </Card>
            )}

            {/* Diagnosis Completed Card - Show if completed */}
            {diagnosisCompleted && !loadingDiagnosis && (
              <Card style={[styles.card, styles.diagnosisCompletedCard]}>
                <Card.Content>
                  <View style={styles.diagnosisHeader}>
                    <IconButton
                      icon="check-circle"
                      size={32}
                      iconColor={colors.success || '#4CAF50'}
                      style={styles.diagnosisIcon}
                    />
                    <View style={styles.diagnosisText}>
                      <Title style={styles.diagnosisTitle}>Diagnosis Assessment Complete</Title>
                      <Paragraph style={styles.diagnosisDescription}>
                        Your diagnosis information has been saved. We can now provide personalized care recommendations.
                      </Paragraph>
                    </View>
                  </View>
                  <Button
                    mode="outlined"
                    onPress={() => navigation.navigate('More', { userData, authContext: route.params.authContext })}
                    style={styles.diagnosisButton}
                    icon="pencil"
                  >
                    Update Assessment
                  </Button>
                </Card.Content>
              </Card>
            )}

            {/* Reminders */}
            <Card style={styles.card}>
              <Card.Content>
                <View style={styles.reminderHeader}>
                  <Title style={styles.cardTitle}>Reminders</Title>
                  {reminders.length > 0 && (
                    <Chip 
                      mode="outlined" 
                      textStyle={{ fontSize: 12 }}
                      style={styles.reminderCount}
                    >
                      {reminders.length}
                    </Chip>
                  )}
                </View>
                
                {loading ? (
                  <View style={styles.loadingContainer}>
                    <ActivityIndicator size="small" color={colors.primary} />
                    <Text style={styles.loadingText}>Loading reminders...</Text>
                  </View>
                ) : reminders.length > 0 ? (
                  reminders.map((reminder, index) => (
                    <View key={reminder.id} style={styles.reminderItem}>
                      <View style={styles.reminderContent}>
                        <View style={styles.reminderIconContainer}>
                          <IconButton
                            icon={reminder.icon}
                            size={24}
                            iconColor={reminder.type === 'warning' ? colors.error : colors.primary}
                            style={styles.reminderIcon}
                          />
                        </View>
                        <View style={styles.reminderText}>
                          <Text style={styles.reminderTitle}>{reminder.title}</Text>
                          <Text style={styles.reminderMessage}>{reminder.message}</Text>
                        </View>
                      </View>
                      <Button
                        mode="contained"
                        onPress={() => handleReminderAction(reminder)}
                        style={[
                          styles.reminderAction,
                          reminder.priority === 'high' && styles.highPriorityAction
                        ]}
                        labelStyle={styles.reminderActionLabel}
                      >
                        {reminder.action}
                      </Button>
                    </View>
                  ))
                ) : (
                  <View style={styles.noRemindersContainer}>
                    <IconButton
                      icon="check-circle"
                      size={32}
                      iconColor={colors.success || '#4CAF50'}
                      style={styles.noRemindersIcon}
                    />
                    <Text style={styles.noRemindersTitle}>All Caught Up!</Text>
                    <Text style={styles.noRemindersMessage}>
                      You've logged all your daily entries. Great job staying on track!
                    </Text>
                  </View>
                )}
              </Card.Content>
            </Card>

            {/* Last 7 Days Summary */}
            <Card style={styles.card}>
              <Card.Content>
                <Title style={styles.cardTitle}>Last 7 Days Summary</Title>
                {loading ? (
                  <View style={styles.loadingContainer}>
                    <ActivityIndicator size="small" color={colors.primary} />
                    <Text style={styles.loadingText}>Loading...</Text>
                  </View>
                ) : (
                  <>
                    <View style={styles.summaryItem}>
                      <Text style={styles.summaryLabel}>Total Entries:</Text>
                      <Text style={styles.summaryValue}>{last7DaysStats.logEntries}</Text>
                    </View>
                    <View style={styles.summaryItem}>
                      <Text style={styles.summaryLabel}>Meals Logged:</Text>
                      <Text style={styles.summaryValue}>{last7DaysStats.mealsLogged}</Text>
                    </View>
                    <View style={styles.summaryItem}>
                      <Text style={styles.summaryLabel}>Avg. Entries/Day:</Text>
                      <Text style={styles.summaryValue}>{last7DaysStats.averageEntries}</Text>
                    </View>
                    <View style={styles.summaryItem}>
                      <Text style={styles.summaryLabel}>Most Active Day:</Text>
                      <Text style={styles.summaryValue}>{last7DaysStats.mostActiveDay}</Text>
                    </View>
                    <View style={styles.summaryItem}>
                      <Text style={styles.summaryLabel}>Symptoms:</Text>
                      <Text style={styles.summaryValue}>{last7DaysStats.symptoms}</Text>
                    </View>
                  </>
                )}
              </Card.Content>
            </Card>

            {/* Nutrition Analyzer */}
            <NutritionAnalyzer userId={userData?.username} />

            {/* Flare Predictions */}
            <FlarePredictions userId={userData?.username} />

            {/* Tips */}
            <Card style={styles.card}>
              <Card.Content>
                <Title style={styles.cardTitle}>Weekly Insight</Title>
                <Paragraph style={styles.tipText}>
                  Tracking your health over the past week helps identify patterns and triggers. 
                  Consistent logging provides valuable insights for managing your condition.
                </Paragraph>
              </Card.Content>
            </Card>
          </View>
        </Surface>
      </ScrollView>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.background,
  },
  scrollContainer: {
    flexGrow: 1,
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
  header: {
    alignItems: 'center',
    marginBottom: 32,
  },
  title: {
    fontSize: 28,
    fontWeight: 'bold',
    color: colors.primary,
    marginBottom: 8,
    textAlign: 'center',
  },
  subtitle: {
    fontSize: 16,
    color: colors.placeholder,
    textAlign: 'center',
  },
  content: {
    flex: 1,
  },
  card: {
    marginBottom: 16,
  },
  cardTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    color: colors.primary,
    marginBottom: 16,
  },
  actionButtons: {
    flexDirection: 'row',
    justifyContent: 'space-around',
  },
  // Reminder styles
  reminderHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 16,
  },
  reminderCount: {
    backgroundColor: colors.primary,
  },
  reminderItem: {
    backgroundColor: colors.surface,
    borderRadius: 12,
    padding: 16,
    marginBottom: 12,
    borderLeftWidth: 4,
    borderLeftColor: colors.primary,
    shadowColor: '#000',
    shadowOffset: {
      width: 0,
      height: 1,
    },
    shadowOpacity: 0.1,
    shadowRadius: 2,
    elevation: 2,
  },
  reminderContent: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    marginBottom: 12,
  },
  reminderIconContainer: {
    marginRight: 12,
    marginTop: 2,
  },
  reminderIcon: {
    margin: 0,
  },
  reminderText: {
    flex: 1,
  },
  reminderTitle: {
    fontSize: 16,
    fontWeight: '600',
    color: colors.text,
    marginBottom: 4,
  },
  reminderMessage: {
    fontSize: 14,
    color: colors.placeholder,
    lineHeight: 20,
  },
  reminderAction: {
    borderRadius: 8,
    height: 36,
  },
  highPriorityAction: {
    backgroundColor: colors.error,
  },
  reminderActionLabel: {
    fontSize: 12,
    fontWeight: '600',
  },
  noRemindersContainer: {
    alignItems: 'center',
    paddingVertical: 24,
  },
  noRemindersIcon: {
    marginBottom: 12,
  },
  noRemindersTitle: {
    fontSize: 18,
    fontWeight: '600',
    color: colors.success || '#4CAF50',
    marginBottom: 8,
  },
  noRemindersMessage: {
    fontSize: 14,
    color: colors.placeholder,
    textAlign: 'center',
    lineHeight: 20,
  },
  actionButton: {
    flex: 1,
    marginHorizontal: 8,
  },
  summaryItem: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: 8,
  },
  summaryLabel: {
    fontSize: 16,
    color: colors.text,
  },
  summaryValue: {
    fontSize: 16,
    fontWeight: 'bold',
    color: colors.primary,
  },
  loadingContainer: {
    alignItems: 'center',
    paddingVertical: 20,
  },
  loadingText: {
    marginTop: 8,
    fontSize: 14,
    color: colors.placeholder,
  },
  tipText: {
    fontSize: 16,
    color: colors.text,
    lineHeight: 22,
  },
  // Diagnosis card styles
  diagnosisCard: {
    backgroundColor: colors.primary + '10',
    borderLeftWidth: 4,
    borderLeftColor: colors.primary,
    marginBottom: 20,
  },
  diagnosisCompletedCard: {
    backgroundColor: (colors.success || '#4CAF50') + '10',
    borderLeftWidth: 4,
    borderLeftColor: colors.success || '#4CAF50',
    marginBottom: 20,
  },
  diagnosisHeader: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    marginBottom: 16,
  },
  diagnosisIcon: {
    marginRight: 12,
    marginTop: 4,
  },
  diagnosisText: {
    flex: 1,
  },
  diagnosisTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    color: colors.primary,
    marginBottom: 4,
  },
  diagnosisDescription: {
    fontSize: 14,
    color: colors.placeholder,
    lineHeight: 20,
  },
  diagnosisButton: {
    borderRadius: 8,
  },
});

export default HomeScreen; 