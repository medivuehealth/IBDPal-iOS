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
  FAB,
  IconButton,
  List,
} from 'react-native-paper';
import { colors } from '../theme';
import CustomModal from '../components/CustomModal';
import FoodSearch from '../components/FoodSearch';
import FoodDatabase from '../services/FoodDatabase';
import { API_BASE_URL } from '../config';

const DailyLogScreen = ({ navigation, route }) => {
  const [showFormModal, setShowFormModal] = useState(false);
  const [formType, setFormType] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [showSuccessModal, setShowSuccessModal] = useState(false);
  const [showErrorModal, setShowErrorModal] = useState(false);
  const [errorMessage, setErrorMessage] = useState('');
  const [showFoodSearch, setShowFoodSearch] = useState(false);
  const [currentMealField, setCurrentMealField] = useState('');
  
  // New state for edit functionality
  const [existingEntries, setExistingEntries] = useState([]);
  const [isEditMode, setIsEditMode] = useState(false);
  const [editingEntryId, setEditingEntryId] = useState(null);
  const [showExistingEntriesModal, setShowExistingEntriesModal] = useState(false);

  // Form data state - matching Medivue web app structure
  const [formData, setFormData] = useState({
    // Date
    entry_date: new Date().toISOString().split('T')[0],
    
    // Nutrition fields
    calories: '',
    protein: '',
    carbs: '',
    fiber: '',
    has_allergens: '',
    meals_per_day: '',
    hydration_level: '',
    
    // Individual meal fields (like Medivue web app)
    breakfast: '',
    lunch: '',
    dinner: '',
    snacks: '',
    
    // Bowel health fields
    bowel_frequency: '',
    bristol_scale: '',
    urgency_level: '',
    blood_present: '',
    
    // Pain fields
    pain_location: '',
    pain_severity: '',
    pain_time: '',
    
    // Medication fields
    medication_taken: '',
    medication_type: '',
    dosage_level: '',
    
    // Lifestyle fields
    sleep_hours: '',
    stress_level: '',
    menstruation: '',
    fatigue_level: '',
    
    // Notes
    notes: '',
  });

  // Nutrition calculation state
  const [nutritionTotals, setNutritionTotals] = useState({
    calories: 0,
    protein: 0,
    carbs: 0,
    fiber: 0,
  });

  const { userData } = route.params;

  // Add shouldShowMenstruation check (like Medivue web app)
  const shouldShowMenstruation = userData?.gender === 'female';

  // Load existing entries for the current date
  useEffect(() => {
    if (userData?.username) {
      loadExistingEntries();
    }
  }, [userData?.username, formData.entry_date]);

  // Update form data when user prop changes to ensure correct menstruation default
  useEffect(() => {
    const newShouldShowMenstruation = userData?.gender === 'female';
    setFormData(prev => ({
      ...prev,
      menstruation: newShouldShowMenstruation ? 'no' : 'not_applicable'
    }));
  }, [userData?.gender]);

  // Load existing entries for the selected date
  const loadExistingEntries = async () => {
    try {
      console.log('Loading existing entries for user:', userData?.username, 'date:', formData.entry_date);
      const response = await fetch(`${API_BASE_URL}/journal/entries/${userData.username}`);
      if (response.ok) {
        const entries = await response.json();
        console.log('All entries loaded:', entries);
        // Filter entries for the current date - convert API date to YYYY-MM-DD format for comparison
        const todayEntries = entries.filter(entry => {
          const entryDate = new Date(entry.entry_date).toISOString().split('T')[0];
          console.log('Comparing dates:', { entryDate, formDataDate: formData.entry_date, match: entryDate === formData.entry_date });
          return entryDate === formData.entry_date;
        });
        console.log('Today entries:', todayEntries);
        setExistingEntries(todayEntries);
        
        // If there's an existing entry for today, load it into the form
        if (todayEntries.length > 0) {
          const existingEntry = todayEntries[0]; // Take the first entry for today
          loadEntryForEditing(existingEntry);
          setEditingEntryId(existingEntry.entry_id);
          console.log('Loaded existing entry for editing:', existingEntry);
        }
      } else {
        console.error('Failed to load entries:', response.status, response.statusText);
      }
    } catch (error) {
      console.error('Error loading existing entries:', error);
    }
  };

  // Check if an entry exists for the current date and type
  const checkExistingEntry = (date, type) => {
    console.log('Checking for existing entry:', { date, type, existingEntries });
    const foundEntry = existingEntries.find(entry => {
      // For nutrition entries, check if any nutrition-related fields are filled
      if (type === 'nutrition') {
        return entry.calories > 0 || entry.protein > 0 || entry.carbs > 0 || 
               entry.fiber > 0 || entry.meals_per_day > 0 || entry.hydration_level > 0;
      }
      // For bowel entries, check bowel-related fields
      if (type === 'bowel') {
        return entry.bowel_frequency > 0 || entry.bristol_scale > 0 || entry.urgency_level > 0;
      }
      // For pain entries, check pain-related fields
      if (type === 'pain') {
        return entry.pain_location || entry.pain_severity > 0 || entry.pain_time;
      }
      // For medication entries, check medication-related fields
      if (type === 'medication') {
        return entry.medication_taken || entry.medication_type || entry.dosage_level > 0;
      }
      // For lifestyle entries, check lifestyle-related fields
      if (type === 'lifestyle') {
        return entry.sleep_hours > 0 || entry.stress_level > 0 || entry.fatigue_level > 0;
      }
      return false;
    });
    console.log('Found existing entry:', foundEntry);
    return foundEntry;
  };

  // Get entry type based on form data
  const getEntryType = (data) => {
    if (data.calories > 0 || data.protein > 0 || data.carbs > 0 || data.fiber > 0 || 
        data.meals_per_day > 0 || data.hydration_level > 0) {
      return 'nutrition';
    }
    if (data.bowel_frequency > 0 || data.bristol_scale > 0 || data.urgency_level > 0) {
      return 'bowel';
    }
    if (data.pain_location || data.pain_severity > 0 || data.pain_time) {
      return 'pain';
    }
    if (data.medication_taken || data.medication_type || data.dosage_level > 0) {
      return 'medication';
    }
    if (data.sleep_hours > 0 || data.stress_level > 0 || data.fatigue_level > 0) {
      return 'lifestyle';
    }
    return null;
  };

  // Load existing entry data for editing
  const loadEntryForEditing = (entry) => {
    // Convert API date format to YYYY-MM-DD format for the form
    const entryDate = new Date(entry.entry_date).toISOString().split('T')[0];
    
    setFormData({
      entry_date: entryDate,
      calories: entry.calories?.toString() || '',
      protein: entry.protein?.toString() || '',
      carbs: entry.carbs?.toString() || '',
      fiber: entry.fiber?.toString() || '',
      has_allergens: entry.has_allergens ? 'yes' : 'no',
      meals_per_day: entry.meals_per_day?.toString() || '',
      hydration_level: entry.hydration_level?.toString() || '',
      breakfast: entry.breakfast || '',
      lunch: entry.lunch || '',
      dinner: entry.dinner || '',
      snacks: entry.snacks || '',
      bowel_frequency: entry.bowel_frequency?.toString() || '',
      bristol_scale: entry.bristol_scale?.toString() || '',
      urgency_level: entry.urgency_level?.toString() || '',
      blood_present: entry.blood_present ? 'yes' : 'no',
      pain_location: entry.pain_location || '',
      pain_severity: entry.pain_severity?.toString() || '',
      pain_time: entry.pain_time || '',
      medication_taken: entry.medication_taken ? 'yes' : 'no',
      medication_type: entry.medication_type || '',
      dosage_level: entry.dosage_level?.toString() || '',
      sleep_hours: entry.sleep_hours?.toString() || '',
      stress_level: entry.stress_level?.toString() || '',
      menstruation: entry.menstruation || '',
      fatigue_level: entry.fatigue_level?.toString() || '',
      notes: entry.notes || '',
    });
    
    // Calculate nutrition totals from individual meal nutrition data
    const totalCalories = (parseFloat(entry.breakfast_calories) || 0) + 
                         (parseFloat(entry.lunch_calories) || 0) + 
                         (parseFloat(entry.dinner_calories) || 0) + 
                         (parseFloat(entry.snack_calories) || 0);
    
    const totalProtein = (parseFloat(entry.breakfast_protein) || 0) + 
                        (parseFloat(entry.lunch_protein) || 0) + 
                        (parseFloat(entry.dinner_protein) || 0) + 
                        (parseFloat(entry.snack_protein) || 0);
    
    const totalCarbs = (parseFloat(entry.breakfast_carbs) || 0) + 
                      (parseFloat(entry.lunch_carbs) || 0) + 
                      (parseFloat(entry.dinner_carbs) || 0) + 
                      (parseFloat(entry.snack_carbs) || 0);
    
    const totalFiber = (parseFloat(entry.breakfast_fiber) || 0) + 
                      (parseFloat(entry.lunch_fiber) || 0) + 
                      (parseFloat(entry.dinner_fiber) || 0) + 
                      (parseFloat(entry.snack_fiber) || 0);
    
    setNutritionTotals({
      calories: totalCalories,
      protein: totalProtein,
      carbs: totalCarbs,
      fiber: totalFiber,
    });
    
    setEditingEntryId(entry.entry_id);
    setIsEditMode(true);
    console.log('Loaded entry for editing:', entry);
  };

  // Get description for entry display
  const getEntryDescription = (entry, type) => {
    switch (type) {
      case 'nutrition':
        return `Calories: ${entry.calories || 0}, Protein: ${entry.protein || 0}g`;
      case 'bowel':
        return `Frequency: ${entry.bowel_frequency || 0}, Scale: ${entry.bristol_scale || 0}`;
      case 'pain':
        return `Severity: ${entry.pain_severity || 0}/10, Location: ${entry.pain_location || 'N/A'}`;
      case 'medication':
        return `Type: ${entry.medication_type || 'N/A'}, Dosage: ${entry.dosage_level || 'N/A'}`;
      case 'lifestyle':
        return `Sleep: ${entry.sleep_hours || 0}h, Stress: ${entry.stress_level || 0}/10`;
      default:
        return 'Log entry';
    }
  };

  // Calculate nutrition totals from meal inputs
  const calculateNutritionTotals = () => {
    const allFoods = [];
    
    // Parse breakfast foods
    if (formData.breakfast && formData.breakfast.trim()) {
      const breakfastFoods = parseFoodInput(formData.breakfast);
      allFoods.push(...breakfastFoods);
    }
    
    // Parse lunch foods
    if (formData.lunch && formData.lunch.trim()) {
      const lunchFoods = parseFoodInput(formData.lunch);
      allFoods.push(...lunchFoods);
    }
    
    // Parse dinner foods
    if (formData.dinner && formData.dinner.trim()) {
      const dinnerFoods = parseFoodInput(formData.dinner);
      allFoods.push(...dinnerFoods);
    }
    
    // Parse snacks
    if (formData.snacks && formData.snacks.trim()) {
      const snackFoods = parseFoodInput(formData.snacks);
      allFoods.push(...snackFoods);
    }
    
    // Calculate totals
    const totals = FoodDatabase.calculateNutritionTotals(allFoods);
    setNutritionTotals(totals);
    
    // Update form data with calculated totals
    setFormData(prev => ({
      ...prev,
      calories: totals.calories.toString(),
      protein: totals.protein.toString(),
      carbs: totals.carbs.toString(),
      fiber: totals.fiber.toString(),
    }));
  };

  // Parse food input to find matching foods in database
  const parseFoodInput = (input) => {
    const foods = [];
    const words = input.toLowerCase().split(/[,\s]+/);
    
    words.forEach(word => {
      if (word.length > 2) { // Only search for words longer than 2 characters
        const searchResults = FoodDatabase.searchFoods(word);
        if (searchResults.length > 0) {
          // Take the first match and assume 1 serving
          foods.push(searchResults[0]);
        }
      }
    });
    
    return foods;
  };

  // Handle food selection from food search
  const handleFoodSelect = (food) => {
    const currentValue = formData[currentMealField] || '';
    const newValue = currentValue ? `${currentValue}, ${food.name}` : food.name;
    
    setFormData(prev => ({
      ...prev,
      [currentMealField]: newValue,
    }));
    
    // Close food search modal
    setShowFoodSearch(false);
    
    // Recalculate nutrition totals after a short delay
    setTimeout(calculateNutritionTotals, 100);
  };

  // Open food search for specific meal field
  const openFoodSearch = (mealField) => {
    setCurrentMealField(mealField);
    setShowFoodSearch(true);
  };

  // Medication type options with dosage options (matching Medivue web app)
  const medicationTypeOptions = [
    { 
      value: 'immunosuppressant', 
      label: 'Immunosuppressant',
      dosageOptions: [
        { value: 'daily', label: 'Daily' },
        { value: 'twice_daily', label: 'Twice Daily' },
        { value: 'weekly', label: 'Weekly' }
      ]
    },
    {
      value: 'biologic',
      label: 'Biologic',
      dosageOptions: [
        { value: 'every_2_weeks', label: 'Every 2 Weeks' },
        { value: 'every_4_weeks', label: 'Every 4 Weeks' },
        { value: 'every_8_weeks', label: 'Every 8 Weeks' }
      ]
    },
    {
      value: 'steroid',
      label: 'Steroid',
      dosageOptions: [
        { value: '5', label: '5mg' },
        { value: '10', label: '10mg' },
        { value: '20', label: '20mg' }
      ]
    }
  ];

  // Icon categories for different log types
  const logCategories = [
    {
      id: 'nutrition',
      title: 'Nutrition',
      icon: 'food-apple',
      color: '#4CAF50',
      description: 'Log meals, calories, and nutrition',
    },
    {
      id: 'bowel',
      title: 'Bowel Health',
      icon: 'medical-bag',
      color: '#FF9800',
      description: 'Track bowel movements and symptoms',
    },
    {
      id: 'pain',
      title: 'Pain & Discomfort',
      icon: 'heart-pulse',
      color: '#F44336',
      description: 'Record pain levels and locations',
    },
    {
      id: 'medication',
      title: 'Medication',
      icon: 'pill',
      color: '#2196F3',
      description: 'Log medications and dosages',
    },
    {
      id: 'lifestyle',
      title: 'Lifestyle',
      icon: 'bed',
      color: '#9C27B0',
      description: 'Sleep, stress, and daily activities',
    },
  ];

  const openFormModal = (type) => {
    setFormType(type);
    
    // Check if an entry already exists for this date and type
    const existingEntry = checkExistingEntry(formData.entry_date, type);
    
    if (existingEntry) {
      // Load existing entry for editing
      loadEntryForEditing(existingEntry);
      setEditingEntryId(existingEntry.entry_id);
      console.log('Opening form for editing existing entry:', existingEntry);
    } else {
      // Reset form data for new entry, but preserve the current date
      setFormData(prevData => ({
        ...prevData,
        // Only reset fields related to the current form type
        ...(type === 'nutrition' && {
          calories: '',
          protein: '',
          carbs: '',
          fiber: '',
          has_allergens: '',
          meals_per_day: '',
          hydration_level: '',
          breakfast: '',
          lunch: '',
          dinner: '',
          snacks: '',
        }),
        ...(type === 'bowel' && {
          bowel_frequency: '',
          bristol_scale: '',
          urgency_level: '',
          blood_present: '',
        }),
        ...(type === 'pain' && {
          pain_location: '',
          pain_severity: '',
          pain_time: '',
        }),
        ...(type === 'medication' && {
          medication_taken: '',
          medication_type: '',
          dosage_level: '',
        }),
        ...(type === 'lifestyle' && {
          sleep_hours: '',
          stress_level: '',
          fatigue_level: '',
          menstruation: shouldShowMenstruation ? 'no' : 'not_applicable',
        }),
      }));
      setEditingEntryId(null);
      console.log('Opening form for new entry of type:', type);
    }
    
    setShowFormModal(true);
  };

  const handleSave = async () => {
    setIsLoading(true);
    
    try {
      // Validate required fields based on form type
      const requiredFields = getRequiredFields(formType);
      const missingFields = requiredFields.filter(field => !formData[field]);
      
      if (missingFields.length > 0) {
        setErrorMessage(`Please fill in: ${missingFields.join(', ')}`);
        setShowErrorModal(true);
        setIsLoading(false);
        return;
      }

      // Prepare data for API - only include fields relevant to the current form type
      const baseData = {
        username: userData?.username,
        entry_date: formData.entry_date,
      };

      // Add fields based on form type
      let transformedData = { ...baseData };

      switch (formType) {
        case 'nutrition':
          // Calculate nutrition from individual meals
          const breakfastFoods = formData.breakfast ? parseFoodInput(formData.breakfast) : [];
          const lunchFoods = formData.lunch ? parseFoodInput(formData.lunch) : [];
          const dinnerFoods = formData.dinner ? parseFoodInput(formData.dinner) : [];
          const snackFoods = formData.snacks ? parseFoodInput(formData.snacks) : [];
          
          const breakfastNutrition = FoodDatabase.calculateNutritionTotals(breakfastFoods);
          const lunchNutrition = FoodDatabase.calculateNutritionTotals(lunchFoods);
          const dinnerNutrition = FoodDatabase.calculateNutritionTotals(dinnerFoods);
          const snackNutrition = FoodDatabase.calculateNutritionTotals(snackFoods);
          
          transformedData = {
            ...baseData,
            calories: Number(formData.calories) || 0,
            protein: Number(formData.protein) || 0,
            carbs: Number(formData.carbs) || 0,
            fiber: Number(formData.fiber) || 0,
            has_allergens: formData.has_allergens === 'yes',
            meals_per_day: Number(formData.meals_per_day) || 0,
            hydration_level: Number(formData.hydration_level) || 0,
            breakfast: formData.breakfast || '',
            lunch: formData.lunch || '',
            dinner: formData.dinner || '',
            snacks: formData.snacks || '',
            // Individual meal nutrition
            breakfast_calories: breakfastNutrition.calories,
            breakfast_protein: breakfastNutrition.protein,
            breakfast_carbs: breakfastNutrition.carbs,
            breakfast_fiber: breakfastNutrition.fiber,
            breakfast_fat: breakfastNutrition.fat || 0,
            lunch_calories: lunchNutrition.calories,
            lunch_protein: lunchNutrition.protein,
            lunch_carbs: lunchNutrition.carbs,
            lunch_fiber: lunchNutrition.fiber,
            lunch_fat: lunchNutrition.fat || 0,
            dinner_calories: dinnerNutrition.calories,
            dinner_protein: dinnerNutrition.protein,
            dinner_carbs: dinnerNutrition.carbs,
            dinner_fiber: dinnerNutrition.fiber,
            dinner_fat: dinnerNutrition.fat || 0,
            snack_calories: snackNutrition.calories,
            snack_protein: snackNutrition.protein,
            snack_carbs: snackNutrition.carbs,
            snack_fiber: snackNutrition.fiber,
            snack_fat: snackNutrition.fat || 0,
          };
          break;
        case 'bowel':
          transformedData = {
            ...baseData,
            bowel_frequency: Number(formData.bowel_frequency) || 0,
            bristol_scale: Number(formData.bristol_scale) || 0,
            urgency_level: Number(formData.urgency_level) || 0,
            blood_present: formData.blood_present === 'yes',
          };
          break;
        case 'pain':
          transformedData = {
            ...baseData,
            pain_location: formData.pain_location || '',
            pain_severity: Number(formData.pain_severity) || 0,
            pain_time: formData.pain_time || '',
          };
          break;
        case 'medication':
          transformedData = {
            ...baseData,
            medication_taken: formData.medication_taken === 'yes',
            medication_type: formData.medication_type || '',
            dosage_level: formData.dosage_level || '',
          };
          break;
        case 'lifestyle':
          transformedData = {
            ...baseData,
            sleep_hours: Number(formData.sleep_hours) || 0,
            stress_level: Number(formData.stress_level) || 0,
            fatigue_level: Number(formData.fatigue_level) || 0,
            menstruation: formData.menstruation || (shouldShowMenstruation ? 'no' : 'not_applicable'),
          };
          break;
      }

      console.log('Saving log entry for type:', formType, 'data:', transformedData);

      // Determine if this is an update or new entry
      const isUpdate = isEditMode && editingEntryId;
      const url = isUpdate 
        ? `${API_BASE_URL}/journal/entries/${editingEntryId}`
        : `${API_BASE_URL}/journal/entries`;
      const method = isUpdate ? 'PUT' : 'POST';

      // Save to database via API
      const response = await fetch(url, {
        method: method,
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(transformedData),
      });

      if (!response.ok) {
        throw new Error(`Failed to ${isUpdate ? 'update' : 'save'} log entry`);
      }

      // Reset edit mode
      setIsEditMode(false);
      setEditingEntryId(null);
      setShowFormModal(false);
      setShowSuccessModal(true);
      
      // Reload existing entries
      await loadExistingEntries();
      
    } catch (error) {
      console.error('Error saving log entry:', error);
      setErrorMessage(`Failed to ${isEditMode ? 'update' : 'save'} log entry. Please try again.`);
      setShowErrorModal(true);
    } finally {
      setIsLoading(false);
    }
  };

  const getRequiredFields = (type) => {
    switch (type) {
      case 'nutrition':
        return ['calories', 'meals_per_day', 'hydration_level'];
      case 'bowel':
        return ['bowel_frequency', 'bristol_scale', 'urgency_level'];
      case 'pain':
        return ['pain_location', 'pain_severity', 'pain_time'];
      case 'medication':
        return ['medication_taken', 'medication_type', 'dosage_level'];
      case 'lifestyle':
        return ['sleep_hours', 'stress_level', 'fatigue_level'];
      default:
        return [];
    }
  };

  const getDosageOptions = (medicationType) => {
    const medication = medicationTypeOptions.find(opt => opt.value === medicationType);
    return medication ? medication.dosageOptions : [];
  };

  const renderFormFields = () => {
    switch (formType) {
      case 'nutrition':
        return (
          <View style={styles.formContent}>
            <Title style={styles.formTitle}>
              {isEditMode ? 'Edit Nutrition Log' : 'Nutrition Log'}
            </Title>
            
            {/* Date */}
            <TextInput
              label="Date"
              value={formData.entry_date}
              onChangeText={(text) => setFormData({...formData, entry_date: text})}
              mode="outlined"
              style={styles.input}
            />
            
            {/* Individual Meal Inputs (like Medivue web app) */}
            <View style={styles.mealInputSection}>
              <Text style={styles.mealLabel}>Breakfast</Text>
              <TextInput
                label="What did you have for breakfast?"
                value={formData.breakfast}
                onChangeText={(text) => {
                  setFormData({...formData, breakfast: text});
                  // Recalculate nutrition totals immediately when text changes
                  calculateNutritionTotals();
                }}
                mode="outlined"
                multiline
                numberOfLines={2}
                style={styles.input}
                placeholder="e.g., Oatmeal with berries and honey"
              />
              <View style={styles.mealButtons}>
                <Button
                  mode="text"
                  onPress={() => openFoodSearch('breakfast')}
                  icon="food-apple"
                  compact
                >
                  Search Foods
                </Button>
                <Button
                  mode="text"
                  onPress={() => {
                    setFormData({...formData, breakfast: ''});
                    calculateNutritionTotals();
                  }}
                  icon="close"
                  compact
                  textColor={colors.error}
                >
                  Clear
                </Button>
              </View>
            </View>
            
            <View style={styles.mealInputSection}>
              <Text style={styles.mealLabel}>Lunch</Text>
              <TextInput
                label="What did you have for lunch?"
                value={formData.lunch}
                onChangeText={(text) => {
                  setFormData({...formData, lunch: text});
                  calculateNutritionTotals();
                }}
                mode="outlined"
                multiline
                numberOfLines={2}
                style={styles.input}
                placeholder="e.g., Grilled chicken salad with mixed greens"
              />
              <View style={styles.mealButtons}>
                <Button
                  mode="text"
                  onPress={() => openFoodSearch('lunch')}
                  icon="food-apple"
                  compact
                >
                  Search Foods
                </Button>
                <Button
                  mode="text"
                  onPress={() => {
                    setFormData({...formData, lunch: ''});
                    calculateNutritionTotals();
                  }}
                  icon="close"
                  compact
                  textColor={colors.error}
                >
                  Clear
                </Button>
              </View>
            </View>
            
            <View style={styles.mealInputSection}>
              <Text style={styles.mealLabel}>Dinner</Text>
              <TextInput
                label="What did you have for dinner?"
                value={formData.dinner}
                onChangeText={(text) => {
                  setFormData({...formData, dinner: text});
                  calculateNutritionTotals();
                }}
                mode="outlined"
                multiline
                numberOfLines={2}
                style={styles.input}
                placeholder="e.g., Salmon with quinoa and steamed vegetables"
              />
              <View style={styles.mealButtons}>
                <Button
                  mode="text"
                  onPress={() => openFoodSearch('dinner')}
                  icon="food-apple"
                  compact
                >
                  Search Foods
                </Button>
                <Button
                  mode="text"
                  onPress={() => {
                    setFormData({...formData, dinner: ''});
                    calculateNutritionTotals();
                  }}
                  icon="close"
                  compact
                  textColor={colors.error}
                >
                  Clear
                </Button>
              </View>
            </View>
            
            <View style={styles.mealInputSection}>
              <Text style={styles.mealLabel}>Snacks</Text>
              <TextInput
                label="Any snacks throughout the day?"
                value={formData.snacks}
                onChangeText={(text) => {
                  setFormData({...formData, snacks: text});
                  calculateNutritionTotals();
                }}
                mode="outlined"
                multiline
                numberOfLines={2}
                style={styles.input}
                placeholder="e.g., Apple and almonds"
              />
              <View style={styles.mealButtons}>
                <Button
                  mode="text"
                  onPress={() => openFoodSearch('snacks')}
                  icon="food-apple"
                  compact
                >
                  Search Foods
                </Button>
                <Button
                  mode="text"
                  onPress={() => {
                    setFormData({...formData, snacks: ''});
                    calculateNutritionTotals();
                  }}
                  icon="close"
                  compact
                  textColor={colors.error}
                >
                  Clear
                </Button>
              </View>
            </View>
            
            {/* Nutrition Summary */}
            <Text style={styles.sectionTitle}>Nutrition Summary</Text>
            
            <View style={styles.nutritionSummaryContainer}>
              <View style={styles.nutritionItem}>
                <Text style={styles.nutritionLabel}>Total Calories</Text>
                <Text style={styles.nutritionValue}>{nutritionTotals.calories}</Text>
                <Text style={styles.nutritionSource}>Calculated from foods</Text>
              </View>
              
              <View style={styles.nutritionItem}>
                <Text style={styles.nutritionLabel}>Protein (g)</Text>
                <Text style={styles.nutritionValue}>{nutritionTotals.protein.toFixed(1)}</Text>
              </View>
              
              <View style={styles.nutritionItem}>
                <Text style={styles.nutritionLabel}>Carbs (g)</Text>
                <Text style={styles.nutritionValue}>{nutritionTotals.carbs.toFixed(1)}</Text>
              </View>
              
              <View style={styles.nutritionItem}>
                <Text style={styles.nutritionLabel}>Fiber (g)</Text>
                <Text style={styles.nutritionValue}>{nutritionTotals.fiber.toFixed(1)}</Text>
              </View>
            </View>
            

            

            
            <View style={styles.pickerContainer}>
              <Text style={styles.label}>Allergens Present</Text>
              <View style={styles.pickerWrapper}>
                <Picker
                  selectedValue={formData.has_allergens}
                  onValueChange={(value) => setFormData({...formData, has_allergens: value})}
                  style={styles.picker}
                >
                  <Picker.Item label="Select..." value="" />
                  <Picker.Item label="Yes" value="yes" />
                  <Picker.Item label="No" value="no" />
                </Picker>
              </View>
            </View>
            
            <TextInput
              label="Meals per Day"
              value={formData.meals_per_day}
              onChangeText={(text) => setFormData({...formData, meals_per_day: text})}
              mode="outlined"
              keyboardType="numeric"
              style={styles.input}
            />
            
            <TextInput
              label="Hydration Level (0-10)"
              value={formData.hydration_level}
              onChangeText={(text) => setFormData({...formData, hydration_level: text})}
              mode="outlined"
              keyboardType="numeric"
              style={styles.input}
            />
          </View>
        );

      case 'bowel':
        return (
          <View style={styles.formContent}>
            <Title style={styles.formTitle}>
              {isEditMode ? 'Edit Bowel Health Log' : 'Bowel Health Log'}
            </Title>
            
            {/* Date */}
            <TextInput
              label="Date"
              value={formData.entry_date}
              onChangeText={(text) => setFormData({...formData, entry_date: text})}
              mode="outlined"
              style={styles.input}
            />
            
            <TextInput
              label="Bowel Frequency (times per day)"
              value={formData.bowel_frequency}
              onChangeText={(text) => setFormData({...formData, bowel_frequency: text})}
              mode="outlined"
              keyboardType="numeric"
              style={styles.input}
            />
            
            <View style={styles.pickerContainer}>
              <Text style={styles.label}>Bristol Scale (1-7)</Text>
              <View style={styles.pickerWrapper}>
                <Picker
                  selectedValue={formData.bristol_scale}
                  onValueChange={(value) => setFormData({...formData, bristol_scale: value})}
                  style={styles.picker}
                >
                  <Picker.Item label="Select..." value="" />
                  <Picker.Item label="1 - Hard, separate lumps" value="1" />
                  <Picker.Item label="2 - Sausage-like but lumpy" value="2" />
                  <Picker.Item label="3 - Sausage-like with cracks" value="3" />
                  <Picker.Item label="4 - Smooth and soft" value="4" />
                  <Picker.Item label="5 - Soft blobs with clear edges" value="5" />
                  <Picker.Item label="6 - Mushy consistency" value="6" />
                  <Picker.Item label="7 - Entirely liquid" value="7" />
                </Picker>
              </View>
            </View>
            
            <TextInput
              label="Urgency Level (0-10)"
              value={formData.urgency_level}
              onChangeText={(text) => setFormData({...formData, urgency_level: text})}
              mode="outlined"
              keyboardType="numeric"
              style={styles.input}
            />
            
            <View style={styles.pickerContainer}>
              <Text style={styles.label}>Blood Present</Text>
              <View style={styles.pickerWrapper}>
                <Picker
                  selectedValue={formData.blood_present}
                  onValueChange={(value) => setFormData({...formData, blood_present: value})}
                  style={styles.picker}
                >
                  <Picker.Item label="Select..." value="" />
                  <Picker.Item label="Yes" value="yes" />
                  <Picker.Item label="No" value="no" />
                </Picker>
              </View>
            </View>
          </View>
        );

      case 'pain':
        return (
          <View style={styles.formContent}>
            <Title style={styles.formTitle}>
              {isEditMode ? 'Edit Pain & Discomfort Log' : 'Pain & Discomfort Log'}
            </Title>
            
            {/* Date */}
            <TextInput
              label="Date"
              value={formData.entry_date}
              onChangeText={(text) => setFormData({...formData, entry_date: text})}
              mode="outlined"
              style={styles.input}
            />
            
            <View style={styles.pickerContainer}>
              <Text style={styles.label}>Pain Location</Text>
              <View style={styles.pickerWrapper}>
                <Picker
                  selectedValue={formData.pain_location}
                  onValueChange={(value) => setFormData({...formData, pain_location: value})}
                  style={styles.picker}
                >
                  <Picker.Item label="Select..." value="" />
                  <Picker.Item label="None" value="None" />
                  <Picker.Item label="Full Abdomen" value="full_abdomen" />
                  <Picker.Item label="Lower Abdomen" value="lower_abdomen" />
                  <Picker.Item label="Upper Abdomen" value="upper_abdomen" />
                </Picker>
              </View>
            </View>
            
            <TextInput
              label="Pain Severity (0-10)"
              value={formData.pain_severity}
              onChangeText={(text) => setFormData({...formData, pain_severity: text})}
              mode="outlined"
              keyboardType="numeric"
              style={styles.input}
            />
            
            <View style={styles.pickerContainer}>
              <Text style={styles.label}>Pain Time</Text>
              <View style={styles.pickerWrapper}>
                <Picker
                  selectedValue={formData.pain_time}
                  onValueChange={(value) => setFormData({...formData, pain_time: value})}
                  style={styles.picker}
                >
                  <Picker.Item label="Select..." value="" />
                  <Picker.Item label="None" value="None" />
                  <Picker.Item label="Morning" value="morning" />
                  <Picker.Item label="Afternoon" value="afternoon" />
                  <Picker.Item label="Evening" value="evening" />
                  <Picker.Item label="Night" value="night" />
                  <Picker.Item label="Variable" value="variable" />
                </Picker>
              </View>
            </View>
          </View>
        );

      case 'medication':
        return (
          <View style={styles.formContent}>
            <Title style={styles.formTitle}>
              {isEditMode ? 'Edit Medication Log' : 'Medication Log'}
            </Title>
            
            {/* Date */}
            <TextInput
              label="Date"
              value={formData.entry_date}
              onChangeText={(text) => setFormData({...formData, entry_date: text})}
              mode="outlined"
              style={styles.input}
            />
            
            <View style={styles.pickerContainer}>
              <Text style={styles.label}>Medication Taken</Text>
              <View style={styles.pickerWrapper}>
                <Picker
                  selectedValue={formData.medication_taken}
                  onValueChange={(value) => setFormData({...formData, medication_taken: value})}
                  style={styles.picker}
                >
                  <Picker.Item label="Select..." value="" />
                  <Picker.Item label="Yes" value="yes" />
                  <Picker.Item label="No" value="no" />
                </Picker>
              </View>
            </View>
            
            <View style={styles.pickerContainer}>
              <Text style={styles.label}>Medication Type</Text>
              <View style={styles.pickerWrapper}>
                <Picker
                  selectedValue={formData.medication_type}
                  onValueChange={(value) => {
                    setFormData({...formData, medication_type: value});
                    // Reset dosage level when medication type changes
                    const medicationType = medicationTypeOptions.find(opt => opt.value === value);
                    const defaultDosage = medicationType?.dosageOptions[0]?.value || '';
                    setFormData(prev => ({
                      ...prev,
                      medication_type: value,
                      dosage_level: defaultDosage
                    }));
                  }}
                  style={styles.picker}
                >
                  <Picker.Item label="Select..." value="" />
                  <Picker.Item label="None" value="None" />
                  <Picker.Item label="Biologic" value="biologic" />
                  <Picker.Item label="Immunosuppressant" value="immunosuppressant" />
                  <Picker.Item label="Steroid" value="steroid" />
                </Picker>
              </View>
            </View>
            
            {/* Dynamic Dosage Options based on Medication Type */}
            {formData.medication_type && formData.medication_type !== 'None' && (
              <View style={styles.pickerContainer}>
                <Text style={styles.label}>Dosage Level</Text>
                <View style={styles.pickerWrapper}>
                  <Picker
                    selectedValue={formData.dosage_level}
                    onValueChange={(value) => setFormData({...formData, dosage_level: value})}
                    style={styles.picker}
                  >
                    <Picker.Item label="Select..." value="" />
                    {getDosageOptions(formData.medication_type).map((option) => (
                      <Picker.Item 
                        key={option.value} 
                        label={option.label} 
                        value={option.value} 
                      />
                    ))}
                  </Picker>
                </View>
              </View>
            )}
          </View>
        );

      case 'lifestyle':
        return (
          <View style={styles.formContent}>
            <Title style={styles.formTitle}>
              {isEditMode ? 'Edit Lifestyle Log' : 'Lifestyle Log'}
            </Title>
            
            {/* Date */}
            <TextInput
              label="Date"
              value={formData.entry_date}
              onChangeText={(text) => setFormData({...formData, entry_date: text})}
              mode="outlined"
              style={styles.input}
            />
            
            <TextInput
              label="Sleep Hours"
              value={formData.sleep_hours}
              onChangeText={(text) => setFormData({...formData, sleep_hours: text})}
              mode="outlined"
              keyboardType="numeric"
              style={styles.input}
            />
            
            <TextInput
              label="Stress Level (0-10)"
              value={formData.stress_level}
              onChangeText={(text) => setFormData({...formData, stress_level: text})}
              mode="outlined"
              keyboardType="numeric"
              style={styles.input}
            />
            
            <View style={styles.pickerContainer}>
              <Text style={styles.label}>Menstruation</Text>
              <View style={styles.pickerWrapper}>
                <Picker
                  selectedValue={formData.menstruation}
                  onValueChange={(value) => setFormData({...formData, menstruation: value})}
                  style={styles.picker}
                >
                  <Picker.Item label="Select..." value="" />
                  <Picker.Item label="Yes" value="yes" />
                  <Picker.Item label="No" value="no" />
                  <Picker.Item label="Not Applicable" value="not_applicable" />
                </Picker>
              </View>
            </View>
            
            <TextInput
              label="Fatigue Level (0-10)"
              value={formData.fatigue_level}
              onChangeText={(text) => setFormData({...formData, fatigue_level: text})}
              mode="outlined"
              keyboardType="numeric"
              style={styles.input}
            />
          </View>
        );

      default:
        return null;
    }
  };

  return (
    <KeyboardAvoidingView
      style={styles.container}
      behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
    >
      <ScrollView contentContainerStyle={styles.scrollContainer}>
        <Surface style={styles.surface}>
          <View style={styles.header}>
            <Title style={styles.title}>Daily Log</Title>
            <Paragraph style={styles.subtitle}>
              Track your daily health metrics and symptoms
            </Paragraph>
            
            {/* Date Picker */}
            <View style={styles.datePickerContainer}>
              <Text style={styles.dateLabel}>Date:</Text>
              <TextInput
                label="Select Date"
                value={formData.entry_date}
                onChangeText={(text) => setFormData({...formData, entry_date: text})}
                mode="outlined"
                style={styles.dateInput}
                placeholder="YYYY-MM-DD"
                keyboardType="numeric"
              />
              <Button
                mode="text"
                onPress={() => setFormData({...formData, entry_date: new Date().toISOString().split('T')[0]})}
                icon="calendar-today"
                compact
              >
                Today
              </Button>
            </View>
          </View>

          <View style={styles.content}>
            {/* Icon Grid */}
            <View style={styles.iconGrid}>
              {logCategories.map((category) => {
                const existingEntry = checkExistingEntry(formData.entry_date, category.id);
                const isCompleted = existingEntry !== null;
                
                return (
                  <Card
                    key={category.id}
                    style={[
                      styles.iconCard, 
                      { 
                        borderLeftColor: category.color,
                        backgroundColor: isCompleted ? `${category.color}10` : 'white'
                      }
                    ]}
                    onPress={() => openFormModal(category.id)}
                  >
                    <Card.Content style={styles.iconCardContent}>
                      <IconButton
                        icon={isCompleted ? 'check-circle' : category.icon}
                        size={32}
                        iconColor={isCompleted ? colors.success : category.color}
                        style={styles.categoryIcon}
                      />
                      <View style={styles.categoryText}>
                        <Title style={styles.categoryTitle}>{category.title}</Title>
                        <Paragraph style={styles.categoryDescription}>
                          {isCompleted ? 'Completed' : category.description}
                        </Paragraph>
                      </View>
                      {isCompleted && (
                        <IconButton
                          icon="pencil"
                          size={20}
                          iconColor={category.color}
                          onPress={() => openFormModal(category.id)}
                        />
                      )}
                    </Card.Content>
                  </Card>
                );
              })}
            </View>

            {/* Quick Stats */}
            <Card style={styles.card}>
              <Card.Content>
                <Title style={styles.cardTitle}>Today's Summary</Title>
                <View style={styles.statsGrid}>
                  <View style={styles.statItem}>
                    <Text style={styles.statNumber}>{existingEntries.length}</Text>
                    <Text style={styles.statLabel}>Entries</Text>
                  </View>
                  <View style={styles.statItem}>
                    <Text style={styles.statNumber}>
                      {existingEntries.filter(entry => 
                        entry.bowel_frequency > 0 || entry.pain_severity > 0
                      ).length}
                    </Text>
                    <Text style={styles.statLabel}>Symptoms</Text>
                  </View>
                  <View style={styles.statItem}>
                    <Text style={styles.statNumber}>
                      {existingEntries.filter(entry => 
                        entry.medication_taken || entry.medication_type
                      ).length}
                    </Text>
                    <Text style={styles.statLabel}>Medications</Text>
                  </View>
                </View>
              </Card.Content>
            </Card>

            {/* Existing Entries List */}
            {existingEntries.length > 0 && (
              <Card style={styles.card}>
                <Card.Content>
                  <Title style={styles.cardTitle}>Today's Entries</Title>
                  <Text style={styles.subtitle}>
                    Tap on an entry to edit it
                  </Text>
                  
                  {existingEntries.map((entry, index) => {
                    const entryType = getEntryType(entry);
                    const category = logCategories.find(cat => cat.id === entryType);
                    
                    return (
                      <List.Item
                        key={entry.entry_id || index}
                        title={category?.title || 'Log Entry'}
                        description={`${entry.entry_date} - ${getEntryDescription(entry, entryType)}`}
                        left={props => (
                          <List.Icon 
                            {...props} 
                            icon={category?.icon || 'file-document'} 
                            color={category?.color || colors.primary}
                          />
                        )}
                        right={props => (
                          <IconButton
                            {...props}
                            icon="pencil"
                            size={20}
                            onPress={() => loadEntryForEditing(entry)}
                          />
                        )}
                        onPress={() => loadEntryForEditing(entry)}
                        style={styles.entryItem}
                      />
                    );
                  })}
                </Card.Content>
              </Card>
            )}
          </View>
        </Surface>
      </ScrollView>

      {/* Form Modal */}
      <CustomModal
        visible={showFormModal}
        onClose={() => setShowFormModal(false)}
        title=""
        message=""
        customContent={
          <>
            {renderFormFields()}
            <View style={styles.modalButtons}>
              <Button
                mode="outlined"
                onPress={() => setShowFormModal(false)}
                style={styles.modalButton}
              >
                Cancel
              </Button>
              <Button
                mode="contained"
                onPress={handleSave}
                loading={isLoading}
                style={styles.modalButton}
              >
                {isEditMode ? 'Update' : 'Save'}
              </Button>
            </View>
          </>
        }
      />

      {/* Success Modal */}
      <CustomModal
        visible={showSuccessModal}
        onClose={() => setShowSuccessModal(false)}
        title="Success"
        message={`Your log entry has been ${isEditMode ? 'updated' : 'saved'} successfully!`}
      />

      {/* Food Search Modal */}
      <CustomModal
        visible={showFoodSearch}
        onClose={() => setShowFoodSearch(false)}
        title="Search Foods"
        message=""
        customContent={
          <View style={styles.modalContent}>
            <FoodSearch
              onFoodSelect={handleFoodSelect}
              selectedFoods={[]}
              onFoodsChange={() => {}}
            />
          </View>
        }
      />

      {/* Existing Entries Modal */}
      <CustomModal
        visible={showExistingEntriesModal}
        onClose={() => setShowExistingEntriesModal(false)}
        title="Entry Already Exists"
        message="An entry for this category already exists for today. What would you like to do?"
        customContent={
          <View style={styles.modalContent}>
            <Text style={styles.modalText}>
              You already have a {formType} entry for {formData.entry_date}. 
              You can edit the existing entry or create a new one.
            </Text>
            
            <View style={styles.modalButtons}>
              <Button
                mode="outlined"
                onPress={() => {
                  setShowExistingEntriesModal(false);
                  // Load existing entry for editing
                  const existingEntry = checkExistingEntry(formData.entry_date, formType);
                  if (existingEntry) {
                    loadEntryForEditing(existingEntry);
                    setShowFormModal(true);
                  }
                }}
                style={styles.modalButton}
              >
                Edit Existing
              </Button>
              <Button
                mode="contained"
                onPress={() => {
                  setShowExistingEntriesModal(false);
                  // Reset form for new entry
                  setFormData({
                    entry_date: new Date().toISOString().split('T')[0],
                    calories: '',
                    protein: '',
                    carbs: '',
                    fiber: '',
                    has_allergens: '',
                    meals_per_day: '',
                    hydration_level: '',
                    breakfast: '',
                    lunch: '',
                    dinner: '',
                    snacks: '',
                    bowel_frequency: '',
                    bristol_scale: '',
                    urgency_level: '',
                    blood_present: '',
                    pain_location: '',
                    pain_severity: '',
                    pain_time: '',
                    medication_taken: '',
                    medication_type: '',
                    dosage_level: '',
                    sleep_hours: '',
                    stress_level: '',
                    menstruation: '',
                    fatigue_level: '',
                    notes: '',
                  });
                  setIsEditMode(false);
                  setEditingEntryId(null);
                  setShowFormModal(true);
                }}
                style={styles.modalButton}
              >
                Create New
              </Button>
            </View>
          </View>
        }
      />

      {/* Error Modal */}
      <CustomModal
        visible={showErrorModal}
        onClose={() => setShowErrorModal(false)}
        title="Error"
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
  },
  subtitle: {
    fontSize: 16,
    color: colors.placeholder,
    textAlign: 'center',
  },
  content: {
    flex: 1,
  },
  iconGrid: {
    marginBottom: 24,
  },
  iconCard: {
    marginBottom: 12,
    borderLeftWidth: 4,
    elevation: 2,
  },
  iconCardContent: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: 8,
  },
  categoryIcon: {
    marginRight: 16,
  },
  categoryText: {
    flex: 1,
  },
  categoryTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    marginBottom: 4,
  },
  categoryDescription: {
    fontSize: 14,
    color: colors.placeholder,
  },
  card: {
    marginBottom: 16,
  },
  cardTitle: {
    fontSize: 20,
    fontWeight: 'bold',
    marginBottom: 16,
  },
  statsGrid: {
    flexDirection: 'row',
    justifyContent: 'space-around',
  },
  statItem: {
    alignItems: 'center',
  },
  statNumber: {
    fontSize: 24,
    fontWeight: 'bold',
    color: colors.primary,
  },
  statLabel: {
    fontSize: 14,
    color: colors.placeholder,
    marginTop: 4,
  },
  formContent: {
    marginBottom: 20,
  },
  formTitle: {
    fontSize: 20,
    fontWeight: 'bold',
    marginBottom: 16,
    textAlign: 'center',
  },
  sectionTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    marginTop: 16,
    marginBottom: 12,
    color: colors.primary,
  },
  input: {
    marginBottom: 16,
  },
  pickerContainer: {
    marginBottom: 16,
  },
  label: {
    fontSize: 16,
    fontWeight: '500',
    marginBottom: 8,
    color: colors.text,
  },
  pickerWrapper: {
    borderWidth: 1,
    borderColor: colors.placeholder,
    borderRadius: 4,
  },
  picker: {
    height: 50,
  },
  modalButtons: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    gap: 12,
  },
  modalButton: {
    flex: 1,
  },
  mealInputSection: {
    marginBottom: 16,
  },
  mealLabel: {
    fontSize: 16,
    fontWeight: 'bold',
    color: colors.primary,
    marginBottom: 8,
  },
  mealButtons: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginTop: 8,
  },
  nutritionSummaryContainer: {
    backgroundColor: colors.surface,
    padding: 16,
    borderRadius: 8,
    marginBottom: 16,
  },
  nutritionItem: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 8,
  },
  nutritionLabel: {
    fontSize: 14,
    color: colors.text,
    fontWeight: '500',
  },
  nutritionValue: {
    fontSize: 16,
    fontWeight: 'bold',
    color: colors.primary,
  },
  nutritionSource: {
    fontSize: 12,
    color: colors.placeholder,
    fontStyle: 'italic',
  },
  modalContent: {
    padding: 20,
    height: 500,
  },
  modalText: {
    fontSize: 16,
    color: colors.text,
    marginBottom: 20,
    textAlign: 'center',
  },
  entryItem: {
    marginBottom: 8,
    borderRadius: 8,
    elevation: 1,
  },
  datePickerContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    marginTop: 16,
    marginBottom: 20,
  },
  dateLabel: {
    fontSize: 16,
    fontWeight: '500',
    marginRight: 10,
    color: colors.text,
  },
  dateInput: {
    flex: 1,
    marginRight: 10,
  },
});

export default DailyLogScreen; 