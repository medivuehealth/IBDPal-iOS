import React, { useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  Alert,
  Modal,
} from 'react-native';

const HydrationScreen = () => {
  const [formData, setFormData] = useState({
    fluidType: '',
    amount: '',
    timeOfDay: '',
    container: '',
    temperature: '',
    flavor: '',
    notes: '',
  });

  const [showPicker, setShowPicker] = useState(false);
  const [activeField, setActiveField] = useState('');

  const fluidTypeOptions = [
    { label: 'Water', value: 'water' },
    { label: 'Filtered water', value: 'filtered_water' },
    { label: 'Sparkling water', value: 'sparkling_water' },
    { label: 'Herbal tea', value: 'herbal_tea' },
    { label: 'Green tea', value: 'green_tea' },
    { label: 'Black tea', value: 'black_tea' },
    { label: 'Coffee', value: 'coffee' },
    { label: 'Decaf coffee', value: 'decaf_coffee' },
    { label: 'Milk', value: 'milk' },
    { label: 'Almond milk', value: 'almond_milk' },
    { label: 'Soy milk', value: 'soy_milk' },
    { label: 'Coconut water', value: 'coconut_water' },
    { label: 'Sports drink', value: 'sports_drink' },
    { label: 'Electrolyte solution', value: 'electrolyte' },
    { label: 'Juice', value: 'juice' },
    { label: 'Smoothie', value: 'smoothie' },
    { label: 'Broth', value: 'broth' },
    { label: 'Other', value: 'other' },
  ];

  const amountOptions = [
    { label: '1/4 cup (60ml)', value: '60ml' },
    { label: '1/2 cup (120ml)', value: '120ml' },
    { label: '3/4 cup (180ml)', value: '180ml' },
    { label: '1 cup (240ml)', value: '240ml' },
    { label: '1.5 cups (360ml)', value: '360ml' },
    { label: '2 cups (480ml)', value: '480ml' },
    { label: '2.5 cups (600ml)', value: '600ml' },
    { label: '3 cups (720ml)', value: '720ml' },
    { label: '4 cups (960ml)', value: '960ml' },
    { label: 'Small bottle (500ml)', value: '500ml' },
    { label: 'Large bottle (1L)', value: '1000ml' },
    { label: 'Other', value: 'other' },
  ];

  const timeOfDayOptions = [
    { label: 'Early morning (5-7 AM)', value: 'early_morning' },
    { label: 'Morning (7-9 AM)', value: 'morning' },
    { label: 'Mid-morning (9-11 AM)', value: 'mid_morning' },
    { label: 'Lunch time (11 AM-1 PM)', value: 'lunch' },
    { label: 'Afternoon (1-3 PM)', value: 'afternoon' },
    { label: 'Mid-afternoon (3-5 PM)', value: 'mid_afternoon' },
    { label: 'Evening (5-7 PM)', value: 'evening' },
    { label: 'Dinner time (7-9 PM)', value: 'dinner' },
    { label: 'Night (9-11 PM)', value: 'night' },
    { label: 'Late night (11 PM-1 AM)', value: 'late_night' },
    { label: 'Throughout the day', value: 'throughout' },
  ];

  const containerOptions = [
    { label: 'Glass', value: 'glass' },
    { label: 'Plastic cup', value: 'plastic_cup' },
    { label: 'Stainless steel bottle', value: 'stainless_bottle' },
    { label: 'Plastic bottle', value: 'plastic_bottle' },
    { label: 'Ceramic mug', value: 'ceramic_mug' },
    { label: 'Travel mug', value: 'travel_mug' },
    { label: 'Straw', value: 'straw' },
    { label: 'Other', value: 'other' },
  ];

  const temperatureOptions = [
    { label: 'Hot', value: 'hot' },
    { label: 'Warm', value: 'warm' },
    { label: 'Room temperature', value: 'room_temp' },
    { label: 'Cool', value: 'cool' },
    { label: 'Cold', value: 'cold' },
    { label: 'Iced', value: 'iced' },
  ];

  const flavorOptions = [
    { label: 'Plain', value: 'plain' },
    { label: 'Lemon', value: 'lemon' },
    { label: 'Lime', value: 'lime' },
    { label: 'Orange', value: 'orange' },
    { label: 'Cucumber', value: 'cucumber' },
    { label: 'Mint', value: 'mint' },
    { label: 'Ginger', value: 'ginger' },
    { label: 'Honey', value: 'honey' },
    { label: 'Vanilla', value: 'vanilla' },
    { label: 'Chocolate', value: 'chocolate' },
    { label: 'Strawberry', value: 'strawberry' },
    { label: 'Mixed berries', value: 'mixed_berries' },
    { label: 'Other', value: 'other' },
  ];

  const getOptions = () => {
    switch (activeField) {
      case 'fluidType':
        return fluidTypeOptions;
      case 'amount':
        return amountOptions;
      case 'timeOfDay':
        return timeOfDayOptions;
      case 'container':
        return containerOptions;
      case 'temperature':
        return temperatureOptions;
      case 'flavor':
        return flavorOptions;
      default:
        return [];
    }
  };

  const getFieldLabel = () => {
    switch (activeField) {
      case 'fluidType':
        return 'Type of Fluid';
      case 'amount':
        return 'Amount';
      case 'timeOfDay':
        return 'Time of Day';
      case 'container':
        return 'Container';
      case 'temperature':
        return 'Temperature';
      case 'flavor':
        return 'Flavor (if applicable)';
      default:
        return '';
    }
  };

  const getFieldDisplayValue = () => {
    const value = formData[activeField];
    if (!value) return 'Select option';
    
    const options = getOptions();
    const option = options.find(opt => opt.value === value);
    return option ? option.label : 'Select option';
  };

  const openPicker = (field) => {
    setActiveField(field);
    setShowPicker(true);
  };

  const selectOption = (value) => {
    setFormData({ ...formData, [activeField]: value });
    setShowPicker(false);
  };

  const saveHydration = async () => {
    try {
      // TODO: Implement API call to save hydration data
      Alert.alert('Success', 'Hydration data saved successfully!');
      // Reset form
      setFormData({
        fluidType: '',
        amount: '',
        timeOfDay: '',
        container: '',
        temperature: '',
        flavor: '',
        notes: '',
      });
    } catch (error) {
      Alert.alert('Error', 'Failed to save hydration data');
    }
  };

  return (
    <ScrollView style={styles.container}>
      <Text style={styles.title}>Hydration Log</Text>
      
      <View style={styles.formSection}>
        <Text style={styles.sectionTitle}>Type of Fluid</Text>
        <TouchableOpacity
          style={styles.pickerContainer}
          onPress={() => openPicker('fluidType')}
        >
          <Text style={styles.pickerText}>{getFieldDisplayValue()}</Text>
          <Text style={styles.pickerArrow}>▼</Text>
        </TouchableOpacity>
      </View>

      <View style={styles.formSection}>
        <Text style={styles.sectionTitle}>Amount</Text>
        <TouchableOpacity
          style={styles.pickerContainer}
          onPress={() => openPicker('amount')}
        >
          <Text style={styles.pickerText}>{getFieldDisplayValue()}</Text>
          <Text style={styles.pickerArrow}>▼</Text>
        </TouchableOpacity>
      </View>

      <View style={styles.formSection}>
        <Text style={styles.sectionTitle}>Time of Day</Text>
        <TouchableOpacity
          style={styles.pickerContainer}
          onPress={() => openPicker('timeOfDay')}
        >
          <Text style={styles.pickerText}>{getFieldDisplayValue()}</Text>
          <Text style={styles.pickerArrow}>▼</Text>
        </TouchableOpacity>
      </View>

      <View style={styles.formSection}>
        <Text style={styles.sectionTitle}>Container</Text>
        <TouchableOpacity
          style={styles.pickerContainer}
          onPress={() => openPicker('container')}
        >
          <Text style={styles.pickerText}>{getFieldDisplayValue()}</Text>
          <Text style={styles.pickerArrow}>▼</Text>
        </TouchableOpacity>
      </View>

      <View style={styles.formSection}>
        <Text style={styles.sectionTitle}>Temperature</Text>
        <TouchableOpacity
          style={styles.pickerContainer}
          onPress={() => openPicker('temperature')}
        >
          <Text style={styles.pickerText}>{getFieldDisplayValue()}</Text>
          <Text style={styles.pickerArrow}>▼</Text>
        </TouchableOpacity>
      </View>

      <View style={styles.formSection}>
        <Text style={styles.sectionTitle}>Flavor (if applicable)</Text>
        <TouchableOpacity
          style={styles.pickerContainer}
          onPress={() => openPicker('flavor')}
        >
          <Text style={styles.pickerText}>{getFieldDisplayValue()}</Text>
          <Text style={styles.pickerArrow}>▼</Text>
        </TouchableOpacity>
      </View>

      <View style={styles.formSection}>
        <Text style={styles.sectionTitle}>Notes (Optional)</Text>
        <Text style={styles.notesPlaceholder}>
          Add any additional notes about your hydration...
        </Text>
      </View>

      <View style={styles.hydrationGoal}>
        <Text style={styles.goalTitle}>Daily Hydration Goal</Text>
        <Text style={styles.goalText}>Recommended: 6-8 cups (1.5-2L) of water per day</Text>
        <Text style={styles.goalText}>Current: [Will be calculated from your logs]</Text>
      </View>

      <TouchableOpacity style={styles.saveButton} onPress={saveHydration}>
        <Text style={styles.saveButtonText}>Save Hydration Data</Text>
      </TouchableOpacity>

      {/* Custom Picker Modal */}
      <Modal
        visible={showPicker}
        transparent={true}
        animationType="slide"
        onRequestClose={() => setShowPicker(false)}
      >
        <View style={styles.modalOverlay}>
          <View style={styles.modalContent}>
            <View style={styles.modalHeader}>
              <Text style={styles.modalTitle}>{getFieldLabel()}</Text>
              <TouchableOpacity onPress={() => setShowPicker(false)}>
                <Text style={styles.modalClose}>✕</Text>
              </TouchableOpacity>
            </View>
            <ScrollView style={styles.modalBody}>
              {getOptions().map((option) => (
                <TouchableOpacity
                  key={option.value}
                  style={styles.modalOption}
                  onPress={() => selectOption(option.value)}
                >
                  <Text style={styles.modalOptionText}>{option.label}</Text>
                </TouchableOpacity>
              ))}
            </ScrollView>
          </View>
        </View>
      </Modal>
    </ScrollView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f5f5f5',
    padding: 20,
  },
  title: {
    fontSize: 24,
    fontWeight: 'bold',
    color: '#2c3e50',
    marginBottom: 20,
    textAlign: 'center',
  },
  formSection: {
    backgroundColor: 'white',
    padding: 15,
    borderRadius: 10,
    marginBottom: 15,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 3,
  },
  sectionTitle: {
    fontSize: 16,
    fontWeight: '600',
    color: '#34495e',
    marginBottom: 10,
  },
  pickerContainer: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    borderWidth: 1,
    borderColor: '#ddd',
    borderRadius: 8,
    backgroundColor: '#f9f9f9',
    padding: 15,
  },
  pickerText: {
    fontSize: 16,
    color: '#2c3e50',
    flex: 1,
  },
  pickerArrow: {
    fontSize: 16,
    color: '#6c757d',
  },
  notesPlaceholder: {
    fontSize: 16,
    color: '#95a5a6',
    fontStyle: 'italic',
    padding: 15,
    backgroundColor: '#f9f9f9',
    borderRadius: 8,
    borderWidth: 1,
    borderColor: '#ddd',
  },
  hydrationGoal: {
    backgroundColor: '#e8f4fd',
    padding: 15,
    borderRadius: 10,
    marginBottom: 15,
    borderLeftWidth: 4,
    borderLeftColor: '#3498db',
  },
  goalTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    color: '#2c3e50',
    marginBottom: 10,
  },
  goalText: {
    fontSize: 14,
    color: '#34495e',
    marginBottom: 5,
  },
  saveButton: {
    backgroundColor: '#3498db',
    padding: 15,
    borderRadius: 10,
    marginTop: 20,
    marginBottom: 30,
  },
  saveButtonText: {
    color: 'white',
    fontSize: 18,
    fontWeight: 'bold',
    textAlign: 'center',
  },
  modalOverlay: {
    flex: 1,
    backgroundColor: 'rgba(0, 0, 0, 0.5)',
    justifyContent: 'flex-end',
  },
  modalContent: {
    backgroundColor: 'white',
    borderTopLeftRadius: 20,
    borderTopRightRadius: 20,
    maxHeight: '70%',
  },
  modalHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    padding: 20,
    borderBottomWidth: 1,
    borderBottomColor: '#eee',
  },
  modalTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    color: '#2c3e50',
  },
  modalClose: {
    fontSize: 20,
    color: '#6c757d',
  },
  modalBody: {
    padding: 20,
  },
  modalOption: {
    paddingVertical: 15,
    borderBottomWidth: 1,
    borderBottomColor: '#eee',
  },
  modalOptionText: {
    fontSize: 16,
    color: '#2c3e50',
  },
});

export default HydrationScreen; 