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

const PainSymptomsScreen = () => {
  const [formData, setFormData] = useState({
    painLevel: '',
    location: '',
    duration: '',
    type: '',
    triggers: '',
    relievedBy: '',
    interferesWith: '',
    notes: '',
  });

  const [showPicker, setShowPicker] = useState(false);
  const [activeField, setActiveField] = useState('');

  const painLevelOptions = [
    { label: '0 - No pain', value: '0' },
    { label: '1 - Very mild', value: '1' },
    { label: '2 - Mild', value: '2' },
    { label: '3 - Mild to moderate', value: '3' },
    { label: '4 - Moderate', value: '4' },
    { label: '5 - Moderate to severe', value: '5' },
    { label: '6 - Severe', value: '6' },
    { label: '7 - Very severe', value: '7' },
    { label: '8 - Extremely severe', value: '8' },
    { label: '9 - Worst possible', value: '9' },
    { label: '10 - Unbearable', value: '10' },
  ];

  const locationOptions = [
    { label: 'Upper abdomen', value: 'upper_abdomen' },
    { label: 'Lower abdomen', value: 'lower_abdomen' },
    { label: 'Right side', value: 'right_side' },
    { label: 'Left side', value: 'left_side' },
    { label: 'Center abdomen', value: 'center_abdomen' },
    { label: 'Back', value: 'back' },
    { label: 'Joints', value: 'joints' },
    { label: 'Head', value: 'head' },
    { label: 'Multiple areas', value: 'multiple' },
    { label: 'Other', value: 'other' },
  ];

  const durationOptions = [
    { label: 'Less than 1 hour', value: '<1h' },
    { label: '1-2 hours', value: '1-2h' },
    { label: '2-4 hours', value: '2-4h' },
    { label: '4-8 hours', value: '4-8h' },
    { label: '8-12 hours', value: '8-12h' },
    { label: '12-24 hours', value: '12-24h' },
    { label: 'More than 24 hours', value: '>24h' },
    { label: 'Constant', value: 'constant' },
  ];

  const typeOptions = [
    { label: 'Cramping', value: 'cramping' },
    { label: 'Sharp', value: 'sharp' },
    { label: 'Dull', value: 'dull' },
    { label: 'Aching', value: 'aching' },
    { label: 'Burning', value: 'burning' },
    { label: 'Stabbing', value: 'stabbing' },
    { label: 'Throbbing', value: 'throbbing' },
    { label: 'Pressure', value: 'pressure' },
    { label: 'Mixed', value: 'mixed' },
  ];

  const triggersOptions = [
    { label: 'Food', value: 'food' },
    { label: 'Stress', value: 'stress' },
    { label: 'Exercise', value: 'exercise' },
    { label: 'Medication', value: 'medication' },
    { label: 'Menstruation', value: 'menstruation' },
    { label: 'Sleep', value: 'sleep' },
    { label: 'Unknown', value: 'unknown' },
    { label: 'None', value: 'none' },
  ];

  const relievedByOptions = [
    { label: 'Rest', value: 'rest' },
    { label: 'Heat', value: 'heat' },
    { label: 'Cold', value: 'cold' },
    { label: 'Medication', value: 'medication' },
    { label: 'Bathroom', value: 'bathroom' },
    { label: 'Eating', value: 'eating' },
    { label: 'Not eating', value: 'not_eating' },
    { label: 'Nothing', value: 'nothing' },
  ];

  const interferesWithOptions = [
    { label: 'Daily activities', value: 'daily_activities' },
    { label: 'School', value: 'school' },
    { label: 'Sleep', value: 'sleep' },
    { label: 'Exercise', value: 'exercise' },
    { label: 'Social activities', value: 'social' },
    { label: 'Eating', value: 'eating' },
    { label: 'Nothing', value: 'nothing' },
  ];

  const getOptions = () => {
    switch (activeField) {
      case 'painLevel':
        return painLevelOptions;
      case 'location':
        return locationOptions;
      case 'duration':
        return durationOptions;
      case 'type':
        return typeOptions;
      case 'triggers':
        return triggersOptions;
      case 'relievedBy':
        return relievedByOptions;
      case 'interferesWith':
        return interferesWithOptions;
      default:
        return [];
    }
  };

  const getFieldLabel = () => {
    switch (activeField) {
      case 'painLevel':
        return 'Pain Level (0-10)';
      case 'location':
        return 'Pain Location';
      case 'duration':
        return 'Duration';
      case 'type':
        return 'Type of Pain';
      case 'triggers':
        return 'Triggers';
      case 'relievedBy':
        return 'Relieved By';
      case 'interferesWith':
        return 'Interferes With';
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

  const savePainSymptoms = async () => {
    try {
      // TODO: Implement API call to save pain symptoms data
      Alert.alert('Success', 'Pain symptoms data saved successfully!');
      // Reset form
      setFormData({
        painLevel: '',
        location: '',
        duration: '',
        type: '',
        triggers: '',
        relievedBy: '',
        interferesWith: '',
        notes: '',
      });
    } catch (error) {
      Alert.alert('Error', 'Failed to save pain symptoms data');
    }
  };

  return (
    <ScrollView style={styles.container}>
      <Text style={styles.title}>Pain Symptoms Log</Text>
      
      <View style={styles.formSection}>
        <Text style={styles.sectionTitle}>Pain Level (0-10)</Text>
        <TouchableOpacity
          style={styles.pickerContainer}
          onPress={() => openPicker('painLevel')}
        >
          <Text style={styles.pickerText}>{getFieldDisplayValue()}</Text>
          <Text style={styles.pickerArrow}>▼</Text>
        </TouchableOpacity>
      </View>

      <View style={styles.formSection}>
        <Text style={styles.sectionTitle}>Pain Location</Text>
        <TouchableOpacity
          style={styles.pickerContainer}
          onPress={() => openPicker('location')}
        >
          <Text style={styles.pickerText}>{getFieldDisplayValue()}</Text>
          <Text style={styles.pickerArrow}>▼</Text>
        </TouchableOpacity>
      </View>

      <View style={styles.formSection}>
        <Text style={styles.sectionTitle}>Duration</Text>
        <TouchableOpacity
          style={styles.pickerContainer}
          onPress={() => openPicker('duration')}
        >
          <Text style={styles.pickerText}>{getFieldDisplayValue()}</Text>
          <Text style={styles.pickerArrow}>▼</Text>
        </TouchableOpacity>
      </View>

      <View style={styles.formSection}>
        <Text style={styles.sectionTitle}>Type of Pain</Text>
        <TouchableOpacity
          style={styles.pickerContainer}
          onPress={() => openPicker('type')}
        >
          <Text style={styles.pickerText}>{getFieldDisplayValue()}</Text>
          <Text style={styles.pickerArrow}>▼</Text>
        </TouchableOpacity>
      </View>

      <View style={styles.formSection}>
        <Text style={styles.sectionTitle}>Triggers</Text>
        <TouchableOpacity
          style={styles.pickerContainer}
          onPress={() => openPicker('triggers')}
        >
          <Text style={styles.pickerText}>{getFieldDisplayValue()}</Text>
          <Text style={styles.pickerArrow}>▼</Text>
        </TouchableOpacity>
      </View>

      <View style={styles.formSection}>
        <Text style={styles.sectionTitle}>Relieved By</Text>
        <TouchableOpacity
          style={styles.pickerContainer}
          onPress={() => openPicker('relievedBy')}
        >
          <Text style={styles.pickerText}>{getFieldDisplayValue()}</Text>
          <Text style={styles.pickerArrow}>▼</Text>
        </TouchableOpacity>
      </View>

      <View style={styles.formSection}>
        <Text style={styles.sectionTitle}>Interferes With</Text>
        <TouchableOpacity
          style={styles.pickerContainer}
          onPress={() => openPicker('interferesWith')}
        >
          <Text style={styles.pickerText}>{getFieldDisplayValue()}</Text>
          <Text style={styles.pickerArrow}>▼</Text>
        </TouchableOpacity>
      </View>

      <View style={styles.formSection}>
        <Text style={styles.sectionTitle}>Notes (Optional)</Text>
        <Text style={styles.notesPlaceholder}>
          Add any additional details about your pain...
        </Text>
      </View>

      <TouchableOpacity style={styles.saveButton} onPress={savePainSymptoms}>
        <Text style={styles.saveButtonText}>Save Pain Symptoms</Text>
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
  saveButton: {
    backgroundColor: '#e74c3c',
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

export default PainSymptomsScreen; 