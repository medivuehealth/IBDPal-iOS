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

const MedicationScreen = () => {
  const [formData, setFormData] = useState({
    medicationName: '',
    dosage: '',
    frequency: '',
    timeTaken: '',
    taken: false,
    sideEffects: '',
    effectiveness: '',
    notes: '',
  });

  const [showPicker, setShowPicker] = useState(false);
  const [activeField, setActiveField] = useState('');

  const medicationOptions = [
    { label: 'Mesalamine (Asacol, Pentasa)', value: 'mesalamine' },
    { label: 'Azathioprine (Imuran)', value: 'azathioprine' },
    { label: 'Mercaptopurine (6-MP)', value: 'mercaptopurine' },
    { label: 'Methotrexate', value: 'methotrexate' },
    { label: 'Infliximab (Remicade)', value: 'infliximab' },
    { label: 'Adalimumab (Humira)', value: 'adalimumab' },
    { label: 'Vedolizumab (Entyvio)', value: 'vedolizumab' },
    { label: 'Ustekinumab (Stelara)', value: 'ustekinumab' },
    { label: 'Prednisone', value: 'prednisone' },
    { label: 'Budesonide (Entocort)', value: 'budesonide' },
    { label: 'Iron supplements', value: 'iron' },
    { label: 'Vitamin D', value: 'vitamin_d' },
    { label: 'Other', value: 'other' },
  ];

  const dosageOptions = [
    { label: '5mg', value: '5mg' },
    { label: '10mg', value: '10mg' },
    { label: '15mg', value: '15mg' },
    { label: '20mg', value: '20mg' },
    { label: '25mg', value: '25mg' },
    { label: '30mg', value: '30mg' },
    { label: '40mg', value: '40mg' },
    { label: '50mg', value: '50mg' },
    { label: '100mg', value: '100mg' },
    { label: '200mg', value: '200mg' },
    { label: '400mg', value: '400mg' },
    { label: '500mg', value: '500mg' },
    { label: '1000mg', value: '1000mg' },
    { label: 'Other', value: 'other' },
  ];

  const frequencyOptions = [
    { label: 'Once daily', value: 'once_daily' },
    { label: 'Twice daily', value: 'twice_daily' },
    { label: 'Three times daily', value: 'three_daily' },
    { label: 'Every 6 hours', value: 'every_6h' },
    { label: 'Every 8 hours', value: 'every_8h' },
    { label: 'Every 12 hours', value: 'every_12h' },
    { label: 'Weekly', value: 'weekly' },
    { label: 'Every 2 weeks', value: 'every_2weeks' },
    { label: 'Every 4 weeks', value: 'every_4weeks' },
    { label: 'Every 8 weeks', value: 'every_8weeks' },
    { label: 'As needed', value: 'as_needed' },
  ];

  const timeOptions = [
    { label: 'Morning (6-9 AM)', value: 'morning' },
    { label: 'Mid-morning (9-12 PM)', value: 'mid_morning' },
    { label: 'Afternoon (12-3 PM)', value: 'afternoon' },
    { label: 'Mid-afternoon (3-6 PM)', value: 'mid_afternoon' },
    { label: 'Evening (6-9 PM)', value: 'evening' },
    { label: 'Night (9 PM-12 AM)', value: 'night' },
    { label: 'Late night (12-3 AM)', value: 'late_night' },
    { label: 'With meals', value: 'with_meals' },
    { label: 'Before meals', value: 'before_meals' },
    { label: 'After meals', value: 'after_meals' },
  ];

  const sideEffectsOptions = [
    { label: 'None', value: 'none' },
    { label: 'Nausea', value: 'nausea' },
    { label: 'Headache', value: 'headache' },
    { label: 'Fatigue', value: 'fatigue' },
    { label: 'Dizziness', value: 'dizziness' },
    { label: 'Rash', value: 'rash' },
    { label: 'Joint pain', value: 'joint_pain' },
    { label: 'Stomach upset', value: 'stomach_upset' },
    { label: 'Diarrhea', value: 'diarrhea' },
    { label: 'Constipation', value: 'constipation' },
    { label: 'Mood changes', value: 'mood_changes' },
    { label: 'Multiple', value: 'multiple' },
    { label: 'Other', value: 'other' },
  ];

  const effectivenessOptions = [
    { label: 'Very effective', value: 'very_effective' },
    { label: 'Effective', value: 'effective' },
    { label: 'Somewhat effective', value: 'somewhat_effective' },
    { label: 'Not very effective', value: 'not_very_effective' },
    { label: 'Not effective', value: 'not_effective' },
    { label: 'Worse symptoms', value: 'worse' },
    { label: 'Too early to tell', value: 'too_early' },
  ];

  const getOptions = () => {
    switch (activeField) {
      case 'medicationName':
        return medicationOptions;
      case 'dosage':
        return dosageOptions;
      case 'frequency':
        return frequencyOptions;
      case 'timeTaken':
        return timeOptions;
      case 'sideEffects':
        return sideEffectsOptions;
      case 'effectiveness':
        return effectivenessOptions;
      default:
        return [];
    }
  };

  const getFieldLabel = () => {
    switch (activeField) {
      case 'medicationName':
        return 'Medication Name';
      case 'dosage':
        return 'Dosage';
      case 'frequency':
        return 'Frequency';
      case 'timeTaken':
        return 'Time Taken';
      case 'sideEffects':
        return 'Side Effects';
      case 'effectiveness':
        return 'Effectiveness';
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

  const saveMedication = async () => {
    try {
      // TODO: Implement API call to save medication data
      Alert.alert('Success', 'Medication data saved successfully!');
      // Reset form
      setFormData({
        medicationName: '',
        dosage: '',
        frequency: '',
        timeTaken: '',
        taken: false,
        sideEffects: '',
        effectiveness: '',
        notes: '',
      });
    } catch (error) {
      Alert.alert('Error', 'Failed to save medication data');
    }
  };

  return (
    <ScrollView style={styles.container}>
      <Text style={styles.title}>Medication Log</Text>
      
      <View style={styles.formSection}>
        <Text style={styles.sectionTitle}>Medication Name</Text>
        <TouchableOpacity
          style={styles.pickerContainer}
          onPress={() => openPicker('medicationName')}
        >
          <Text style={styles.pickerText}>{getFieldDisplayValue()}</Text>
          <Text style={styles.pickerArrow}>▼</Text>
        </TouchableOpacity>
      </View>

      <View style={styles.formSection}>
        <Text style={styles.sectionTitle}>Dosage</Text>
        <TouchableOpacity
          style={styles.pickerContainer}
          onPress={() => openPicker('dosage')}
        >
          <Text style={styles.pickerText}>{getFieldDisplayValue()}</Text>
          <Text style={styles.pickerArrow}>▼</Text>
        </TouchableOpacity>
      </View>

      <View style={styles.formSection}>
        <Text style={styles.sectionTitle}>Frequency</Text>
        <TouchableOpacity
          style={styles.pickerContainer}
          onPress={() => openPicker('frequency')}
        >
          <Text style={styles.pickerText}>{getFieldDisplayValue()}</Text>
          <Text style={styles.pickerArrow}>▼</Text>
        </TouchableOpacity>
      </View>

      <View style={styles.formSection}>
        <Text style={styles.sectionTitle}>Time Taken</Text>
        <TouchableOpacity
          style={styles.pickerContainer}
          onPress={() => openPicker('timeTaken')}
        >
          <Text style={styles.pickerText}>{getFieldDisplayValue()}</Text>
          <Text style={styles.pickerArrow}>▼</Text>
        </TouchableOpacity>
      </View>

      <View style={styles.formSection}>
        <Text style={styles.sectionTitle}>Medication Taken</Text>
        <TouchableOpacity
          style={styles.checkboxContainer}
          onPress={() => setFormData({...formData, taken: !formData.taken})}
        >
          <View style={[styles.checkbox, formData.taken && styles.checkboxChecked]}>
            {formData.taken && <Text style={styles.checkmark}>✓</Text>}
          </View>
          <Text style={styles.checkboxLabel}>I took this medication as prescribed</Text>
        </TouchableOpacity>
      </View>

      <View style={styles.formSection}>
        <Text style={styles.sectionTitle}>Side Effects</Text>
        <TouchableOpacity
          style={styles.pickerContainer}
          onPress={() => openPicker('sideEffects')}
        >
          <Text style={styles.pickerText}>{getFieldDisplayValue()}</Text>
          <Text style={styles.pickerArrow}>▼</Text>
        </TouchableOpacity>
      </View>

      <View style={styles.formSection}>
        <Text style={styles.sectionTitle}>Effectiveness</Text>
        <TouchableOpacity
          style={styles.pickerContainer}
          onPress={() => openPicker('effectiveness')}
        >
          <Text style={styles.pickerText}>{getFieldDisplayValue()}</Text>
          <Text style={styles.pickerArrow}>▼</Text>
        </TouchableOpacity>
      </View>

      <View style={styles.formSection}>
        <Text style={styles.sectionTitle}>Notes (Optional)</Text>
        <Text style={styles.notesPlaceholder}>
          Add any additional notes about your medication...
        </Text>
      </View>

      <TouchableOpacity style={styles.saveButton} onPress={saveMedication}>
        <Text style={styles.saveButtonText}>Save Medication Data</Text>
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
  checkboxContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 10,
  },
  checkbox: {
    width: 24,
    height: 24,
    borderWidth: 2,
    borderColor: '#3498db',
    borderRadius: 4,
    marginRight: 10,
    justifyContent: 'center',
    alignItems: 'center',
  },
  checkboxChecked: {
    backgroundColor: '#3498db',
  },
  checkmark: {
    color: 'white',
    fontSize: 16,
    fontWeight: 'bold',
  },
  checkboxLabel: {
    fontSize: 16,
    color: '#2c3e50',
    flex: 1,
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
    backgroundColor: '#9b59b6',
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

export default MedicationScreen; 