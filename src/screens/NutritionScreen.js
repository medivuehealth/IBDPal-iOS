import React, { useState, useEffect } from 'react';
import {
  View,
  StyleSheet,
  ScrollView,
  KeyboardAvoidingView,
  Platform,
} from 'react-native';
import { Picker } from '@react-native-picker/picker';
import {
  TextInput,
  Button,
  Text,
  Surface,
  Title,
  Paragraph,
  Chip,
  Card,
  Divider,
  ProgressBar,
  FAB,
} from 'react-native-paper';
import { colors } from '../theme';
import CustomModal from '../components/CustomModal';
import FoodSearch from '../components/FoodSearch';
import FoodDatabase from '../services/FoodDatabase';
import { API_BASE_URL } from '../config';

const NutritionScreen = ({ navigation, route }) => {
  const [nutritionData, setNutritionData] = useState([]);
  const [currentMeal, setCurrentMeal] = useState('');
  const [mealDescription, setMealDescription] = useState('');
  const [mealTime, setMealTime] = useState('');
  const [showAddModal, setShowAddModal] = useState(false);
  const [showFoodSearch, setShowFoodSearch] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const [showSuccessModal, setShowSuccessModal] = useState(false);
  const [selectedFoods, setSelectedFoods] = useState([]);
  const [nutritionSummary, setNutritionSummary] = useState({
    totalCalories: 0,
    totalProtein: 0,
    totalCarbs: 0,
    totalFiber: 0,
    mealsCount: 0,
    hydrationLevel: 0,
  });

  const { userData } = route.params;

  // Meal time options
  const mealTimeOptions = [
    { label: 'Select meal time', value: '' },
    { label: 'Breakfast', value: 'breakfast' },
    { label: 'Morning Snack', value: 'morning_snack' },
    { label: 'Lunch', value: 'lunch' },
    { label: 'Afternoon Snack', value: 'afternoon_snack' },
    { label: 'Dinner', value: 'dinner' },
    { label: 'Evening Snack', value: 'evening_snack' },
  ];

  // Load nutrition data from Daily Log entries
  useEffect(() => {
    loadNutritionData();
  }, []);

  // Add focus listener to refresh data when screen comes into focus
  useEffect(() => {
    const unsubscribe = navigation.addListener('focus', () => {
      loadNutritionData();
    });

    return unsubscribe;
  }, [navigation]);

  // Update nutrition summary when selected foods change
  useEffect(() => {
    if (selectedFoods.length > 0) {
      const totals = FoodDatabase.calculateNutritionTotals(selectedFoods);
      setNutritionSummary(prev => ({
        ...prev,
        totalCalories: totals.calories,
        totalProtein: totals.protein,
        totalCarbs: totals.carbs,
        totalFiber: totals.fiber,
      }));
    } else {
      // Reset to default values when no foods are selected
      setNutritionSummary(prev => ({
        ...prev,
        totalCalories: 0,
        totalProtein: 0,
        totalCarbs: 0,
        totalFiber: 0,
      }));
    }
  }, [selectedFoods]);

  const loadNutritionData = async () => {
    try {
      setIsLoading(true);
      // This would fetch nutrition data from your backend
      // For now, we'll simulate data based on Daily Log entries
      const mockData = [
        {
          id: 1,
          entry_date: new Date().toISOString().split('T')[0],
          breakfast: 'Oatmeal with berries and honey',
          lunch: 'Grilled chicken salad with mixed greens',
          dinner: 'Salmon with quinoa and steamed vegetables',
          snacks: 'Apple and almonds',
          calories: 1850,
          protein: 120,
          carbs: 180,
          fiber: 35,
          hydration_level: 8,
        },
        {
          id: 2,
          entry_date: new Date(Date.now() - 86400000).toISOString().split('T')[0],
          breakfast: 'Greek yogurt with granola',
          lunch: 'Turkey sandwich with whole grain bread',
          dinner: 'Lean beef stir-fry with brown rice',
          snacks: 'Carrot sticks and hummus',
          calories: 2100,
          protein: 140,
          carbs: 220,
          fiber: 28,
          hydration_level: 7,
        }
      ];
      
      setNutritionData(mockData);
      calculateNutritionSummary(mockData);
    } catch (error) {
      console.error('Error loading nutrition data:', error);
    } finally {
      setIsLoading(false);
    }
  };

  const calculateNutritionSummary = (data) => {
    if (!data || data.length === 0) return;

    const summary = data.reduce((acc, entry) => {
      return {
        totalCalories: acc.totalCalories + (parseInt(entry.calories) || 0),
        totalProtein: acc.totalProtein + (parseInt(entry.protein) || 0),
        totalCarbs: acc.totalCarbs + (parseInt(entry.carbs) || 0),
        totalFiber: acc.totalFiber + (parseInt(entry.fiber) || 0),
        mealsCount: acc.mealsCount + 1,
        hydrationLevel: acc.hydrationLevel + (parseInt(entry.hydration_level) || 0),
      };
    }, {
      totalCalories: 0,
      totalProtein: 0,
      totalCarbs: 0,
      totalFiber: 0,
      mealsCount: 0,
      hydrationLevel: 0,
    });

    // Calculate average hydration level
    summary.hydrationLevel = summary.mealsCount > 0 ? summary.hydrationLevel / summary.mealsCount : 0;
    
    setNutritionSummary(summary);
  };

  const addMeal = () => {
    if (currentMeal && mealDescription && mealTime) {
      const meal = {
        type: currentMeal,
        description: mealDescription,
        time: mealTime,
        timestamp: new Date().toISOString(),
      };
      setNutritionData([...nutritionData, meal]);
      setCurrentMeal('');
      setMealDescription('');
      setMealTime('');
      setShowAddModal(false);
    }
  };

  const removeMeal = (index) => {
    setNutritionData(nutritionData.filter((_, i) => i !== index));
  };

  const analyzeNutrition = () => {
    console.log('Analyzing nutrition for meals:', nutritionData);
    setShowSuccessModal(true);
  };

  const getNutritionTips = () => {
    const tips = [
      'Consider adding more fiber-rich foods to help with digestion',
      'Stay hydrated throughout the day',
      'Avoid trigger foods that worsen your symptoms',
      'Eat smaller, more frequent meals',
      'Keep a food diary to identify patterns',
    ];
    return tips[Math.floor(Math.random() * tips.length)];
  };

  const getHydrationStatus = (level) => {
    if (level >= 8) return { status: 'Excellent', color: '#4CAF50' };
    if (level >= 6) return { status: 'Good', color: '#FF9800' };
    return { status: 'Needs Improvement', color: '#F44336' };
  };

  const getCalorieStatus = (calories) => {
    if (calories >= 1800 && calories <= 2200) return { status: 'Optimal', color: '#4CAF50' };
    if (calories >= 1500 && calories <= 2500) return { status: 'Good', color: '#FF9800' };
    return { status: 'Needs Adjustment', color: '#F44336' };
  };

  const handleFoodSelect = (food) => {
    setSelectedFoods([...selectedFoods, food]);
  };

  const handleFoodsChange = (foods) => {
    setSelectedFoods(foods);
  };

  const refreshNutritionData = () => {
    loadNutritionData();
  };

  return (
    <KeyboardAvoidingView
      style={styles.container}
      behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
    >
      <ScrollView contentContainerStyle={styles.scrollContainer}>
        <Surface style={styles.surface}>
          <View style={styles.header}>
            <View style={styles.headerRow}>
              <Title style={styles.title}>Nutrition Tracker</Title>
              <Button
                mode="text"
                onPress={refreshNutritionData}
                icon="refresh"
                loading={isLoading}
                compact
              >
                Refresh
              </Button>
            </View>
            <Paragraph style={styles.subtitle}>
              Track your daily nutrition and get personalized insights
            </Paragraph>
          </View>

          <View style={styles.content}>
            {/* Nutrition Summary Card */}
            <Card style={styles.card}>
              <Card.Content>
                <Title style={styles.cardTitle}>Today's Nutrition Summary</Title>
                <Paragraph style={styles.summaryNote}>
                  This summary updates automatically when you log nutrition data in the Daily Log tab.
                </Paragraph>
                
                {nutritionData.length > 0 ? (
                  <View style={styles.summaryContainer}>
                    {/* Calories */}
                    <View style={styles.summaryItem}>
                      <Text style={styles.summaryLabel}>Total Calories</Text>
                      <Text style={styles.summaryValue}>{nutritionSummary.totalCalories}</Text>
                      <Text style={[styles.summaryStatus, { color: getCalorieStatus(nutritionSummary.totalCalories).color }]}>
                        {getCalorieStatus(nutritionSummary.totalCalories).status}
                      </Text>
                    </View>

                    {/* Macronutrients */}
                    <View style={styles.macrosContainer}>
                      <View style={styles.macroItem}>
                        <Text style={styles.macroLabel}>Protein</Text>
                        <Text style={styles.macroValue}>{nutritionSummary.totalProtein}g</Text>
                        <ProgressBar 
                          progress={Math.min(nutritionSummary.totalProtein / 120, 1)} 
                          color={colors.primary}
                          style={styles.progressBar}
                        />
                      </View>
                      
                      <View style={styles.macroItem}>
                        <Text style={styles.macroLabel}>Carbs</Text>
                        <Text style={styles.macroValue}>{nutritionSummary.totalCarbs}g</Text>
                        <ProgressBar 
                          progress={Math.min(nutritionSummary.totalCarbs / 200, 1)} 
                          color={colors.secondary}
                          style={styles.progressBar}
                        />
                      </View>
                      
                      <View style={styles.macroItem}>
                        <Text style={styles.macroLabel}>Fiber</Text>
                        <Text style={styles.macroValue}>{nutritionSummary.totalFiber}g</Text>
                        <ProgressBar 
                          progress={Math.min(nutritionSummary.totalFiber / 30, 1)} 
                          color={colors.accent}
                          style={styles.progressBar}
                        />
                      </View>
                    </View>

                    {/* Hydration */}
                    <View style={styles.hydrationContainer}>
                      <Text style={styles.hydrationLabel}>Hydration Level</Text>
                      <Text style={styles.hydrationValue}>{nutritionSummary.hydrationLevel.toFixed(1)}/10</Text>
                      <Text style={[styles.hydrationStatus, { color: getHydrationStatus(nutritionSummary.hydrationLevel).color }]}>
                        {getHydrationStatus(nutritionSummary.hydrationLevel).status}
                      </Text>
                    </View>
                  </View>
                ) : (
                  <Text style={styles.emptyText}>No nutrition data available</Text>
                )}
              </Card.Content>
            </Card>

            {/* Food Search Section */}
            <Card style={styles.card}>
              <Card.Content>
                <Title style={styles.cardTitle}>Food Database</Title>
                <Paragraph style={styles.infoText}>
                  Search and select foods from our comprehensive international database with nutrition information.
                </Paragraph>
                <Button
                  mode="contained"
                  onPress={() => setShowFoodSearch(true)}
                  icon="food-apple"
                  style={styles.addButton}
                >
                  Search Foods
                </Button>
              </Card.Content>
            </Card>

            {/* Selected Foods */}
            {selectedFoods.length > 0 && (
              <Card style={styles.card}>
                <Card.Content>
                  <Title style={styles.cardTitle}>Selected Foods</Title>
                  <View style={styles.selectedFoodsContainer}>
                    {selectedFoods.map((food, index) => (
                      <View key={index} style={styles.selectedFoodItem}>
                        <Text style={styles.selectedFoodName}>{food.name}</Text>
                        <Text style={styles.selectedFoodNutrition}>
                          {food.calories} cal | P: {food.protein}g | C: {food.carbs}g | F: {food.fiber}g
                        </Text>
                        {food.ibd_friendly && (
                          <Chip mode="outlined" compact style={styles.ibdChip}>
                            IBD Safe
                          </Chip>
                        )}
                      </View>
                    ))}
                  </View>
                </Card.Content>
              </Card>
            )}

            {/* Recent Meals */}
            <Card style={styles.card}>
              <Card.Content>
                <Title style={styles.cardTitle}>Recent Meals</Title>
                {nutritionData.length === 0 ? (
                  <Text style={styles.emptyText}>No meals logged today</Text>
                ) : (
                  <View style={styles.mealsList}>
                    {nutritionData.slice(0, 3).map((entry, index) => (
                      <View key={index} style={styles.mealItem}>
                        <View style={styles.mealHeader}>
                          <Text style={styles.mealDate}>{entry.entry_date}</Text>
                          <Text style={styles.mealCalories}>{entry.calories} cal</Text>
                        </View>
                        
                        {entry.breakfast && (
                          <View style={styles.mealSection}>
                            <Text style={styles.mealType}>Breakfast:</Text>
                            <Text style={styles.mealDescription}>{entry.breakfast}</Text>
                          </View>
                        )}
                        
                        {entry.lunch && (
                          <View style={styles.mealSection}>
                            <Text style={styles.mealType}>Lunch:</Text>
                            <Text style={styles.mealDescription}>{entry.lunch}</Text>
                          </View>
                        )}
                        
                        {entry.dinner && (
                          <View style={styles.mealSection}>
                            <Text style={styles.mealType}>Dinner:</Text>
                            <Text style={styles.mealDescription}>{entry.dinner}</Text>
                          </View>
                        )}
                        
                        {entry.snacks && (
                          <View style={styles.mealSection}>
                            <Text style={styles.mealType}>Snacks:</Text>
                            <Text style={styles.mealDescription}>{entry.snacks}</Text>
                          </View>
                        )}
                        
                        <View style={styles.nutritionBreakdown}>
                          <Text style={styles.nutritionText}>P: {entry.protein}g | C: {entry.carbs}g | F: {entry.fiber}g</Text>
                        </View>
                      </View>
                    ))}
                  </View>
                )}
              </Card.Content>
            </Card>

            {/* Quick Add Meal */}
            <Card style={styles.card}>
              <Card.Content>
                <Title style={styles.cardTitle}>Add Meal</Title>
                <Paragraph style={styles.infoText}>
                  Add meals through the Daily Log tab to update your nutrition summary automatically.
                </Paragraph>
                <Button
                  mode="contained"
                  onPress={() => setShowAddModal(true)}
                  icon="plus"
                  style={styles.addButton}
                >
                  Log New Meal
                </Button>
              </Card.Content>
            </Card>

            {/* Nutrition Analysis */}
            {nutritionData.length > 0 && (
              <Card style={styles.card}>
                <Card.Content>
                  <Title style={styles.cardTitle}>Nutrition Analysis</Title>
                  <Paragraph style={styles.analysisText}>
                    {getNutritionTips()}
                  </Paragraph>
                  <Button
                    mode="outlined"
                    onPress={analyzeNutrition}
                    style={styles.analyzeButton}
                    icon="chart-line"
                  >
                    Analyze Nutrition
                  </Button>
                </Card.Content>
              </Card>
            )}

            {/* Nutrition Tips */}
            <Card style={styles.card}>
              <Card.Content>
                <Title style={styles.cardTitle}>IBD Nutrition Tips</Title>
                <View style={styles.tipsList}>
                  <Text style={styles.tipItem}>• Eat smaller, frequent meals</Text>
                  <Text style={styles.tipItem}>• Stay well hydrated</Text>
                  <Text style={styles.tipItem}>• Avoid trigger foods</Text>
                  <Text style={styles.tipItem}>• Include probiotic foods</Text>
                  <Text style={styles.tipItem}>• Monitor fiber intake</Text>
                </View>
              </Card.Content>
            </Card>
          </View>
        </Surface>
      </ScrollView>

      {/* Food Search Modal */}
      <CustomModal
        visible={showFoodSearch}
        onClose={() => setShowFoodSearch(false)}
        title="Food Database"
        message=""
        customContent={
          <View style={styles.modalContent}>
            <FoodSearch
              onFoodSelect={handleFoodSelect}
              selectedFoods={selectedFoods}
              onFoodsChange={handleFoodsChange}
            />
          </View>
        }
      />

      {/* Add Meal Modal */}
      <CustomModal
        visible={showAddModal}
        onClose={() => setShowAddModal(false)}
        title="Log Meal"
        message=""
        customContent={
          <View style={styles.modalContent}>
            <TextInput
              label="Meal Name"
              value={currentMeal}
              onChangeText={setCurrentMeal}
              mode="outlined"
              style={styles.input}
            />
            <TextInput
              label="Description (what you ate)"
              value={mealDescription}
              onChangeText={setMealDescription}
              mode="outlined"
              multiline
              numberOfLines={3}
              style={styles.input}
            />
            <View style={styles.pickerContainer}>
              <Text style={styles.label}>Meal Time</Text>
              <View style={styles.pickerWrapper}>
                <Picker
                  selectedValue={mealTime}
                  onValueChange={setMealTime}
                  style={styles.picker}
                >
                  {mealTimeOptions.map((option) => (
                    <Picker.Item
                      key={option.value}
                      label={option.label}
                      value={option.value}
                    />
                  ))}
                </Picker>
              </View>
            </View>
            <Button
              mode="contained"
              onPress={addMeal}
              style={styles.modalButton}
              disabled={!currentMeal || !mealDescription || !mealTime}
            >
              Add Meal
            </Button>
          </View>
        }
      />

      {/* Success Modal */}
      <CustomModal
        visible={showSuccessModal}
        onClose={() => setShowSuccessModal(false)}
        title="Analysis Complete"
        message="Your nutrition analysis is ready. Check the insights tab for detailed recommendations."
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
  headerRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    width: '100%',
    marginBottom: 8,
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
  addButton: {
    marginTop: 8,
  },
  emptyText: {
    fontSize: 16,
    color: colors.placeholder,
    textAlign: 'center',
    fontStyle: 'italic',
  },
  infoText: {
    fontSize: 14,
    color: colors.placeholder,
    marginBottom: 16,
    fontStyle: 'italic',
  },
  summaryNote: {
    fontSize: 12,
    color: colors.placeholder,
    marginBottom: 16,
    fontStyle: 'italic',
  },
  summaryContainer: {
    marginTop: 8,
  },
  summaryItem: {
    marginBottom: 16,
    alignItems: 'center',
  },
  summaryLabel: {
    fontSize: 16,
    color: colors.text,
    marginBottom: 4,
  },
  summaryValue: {
    fontSize: 24,
    fontWeight: 'bold',
    color: colors.primary,
    marginBottom: 4,
  },
  summaryStatus: {
    fontSize: 14,
    fontWeight: '500',
  },
  macrosContainer: {
    marginBottom: 16,
  },
  macroItem: {
    marginBottom: 12,
  },
  macroLabel: {
    fontSize: 14,
    color: colors.text,
    marginBottom: 4,
  },
  macroValue: {
    fontSize: 16,
    fontWeight: 'bold',
    color: colors.primary,
    marginBottom: 4,
  },
  progressBar: {
    height: 6,
    borderRadius: 3,
  },
  hydrationContainer: {
    alignItems: 'center',
    marginTop: 8,
  },
  hydrationLabel: {
    fontSize: 16,
    color: colors.text,
    marginBottom: 4,
  },
  hydrationValue: {
    fontSize: 20,
    fontWeight: 'bold',
    color: colors.primary,
    marginBottom: 4,
  },
  hydrationStatus: {
    fontSize: 14,
    fontWeight: '500',
  },
  selectedFoodsContainer: {
    marginTop: 8,
  },
  selectedFoodItem: {
    borderBottomWidth: 1,
    borderBottomColor: colors.placeholder,
    paddingVertical: 12,
  },
  selectedFoodName: {
    fontSize: 16,
    fontWeight: 'bold',
    color: colors.primary,
    marginBottom: 4,
  },
  selectedFoodNutrition: {
    fontSize: 14,
    color: colors.text,
    marginBottom: 4,
  },
  ibdChip: {
    alignSelf: 'flex-start',
    marginTop: 4,
  },
  mealsList: {
    marginTop: 8,
  },
  mealItem: {
    borderBottomWidth: 1,
    borderBottomColor: colors.placeholder,
    paddingVertical: 12,
  },
  mealHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 8,
  },
  mealDate: {
    fontSize: 14,
    fontWeight: 'bold',
    color: colors.primary,
  },
  mealCalories: {
    fontSize: 14,
    color: colors.secondary,
    fontWeight: '500',
  },
  mealSection: {
    marginBottom: 6,
  },
  mealType: {
    fontSize: 14,
    fontWeight: 'bold',
    color: colors.text,
    marginBottom: 2,
  },
  mealDescription: {
    fontSize: 14,
    color: colors.text,
    marginBottom: 4,
  },
  nutritionBreakdown: {
    marginTop: 8,
  },
  nutritionText: {
    fontSize: 12,
    color: colors.placeholder,
    fontStyle: 'italic',
  },
  analysisText: {
    fontSize: 16,
    color: colors.text,
    lineHeight: 22,
    marginBottom: 16,
  },
  analyzeButton: {
    marginTop: 8,
  },
  tipsList: {
    marginTop: 8,
  },
  tipItem: {
    fontSize: 16,
    color: colors.text,
    marginBottom: 8,
    lineHeight: 22,
  },
  modalContent: {
    padding: 20,
    height: 500,
  },
  input: {
    marginBottom: 16,
  },
  pickerContainer: {
    marginBottom: 20,
  },
  label: {
    fontSize: 16,
    fontWeight: 'bold',
    color: colors.text,
    marginBottom: 8,
  },
  pickerWrapper: {
    borderWidth: 1,
    borderColor: colors.placeholder,
    borderRadius: 8,
    backgroundColor: 'white',
  },
  picker: {
    height: 50,
  },
  modalButton: {
    paddingVertical: 8,
  },
});

export default NutritionScreen; 