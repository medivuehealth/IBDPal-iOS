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

const BowelHealthScreen = () => {
  const [formData, setFormData] = useState({
    frequency: '',
    consistency: '',
    color: '',
    urgency: '',
    incomplete: false,
    blood: false,
    mucus: false,
    notes: '',
  });

  const [showPicker, setShowPicker] = useState(false);
  const [activeField, setActiveField] = useState('');

  const frequencyOptions = [
    { label: '0 times', value: '0' },
    { label: '1 time', value: '1' },
    { label: '2 times', value: '2' },
    { label: '3 times', value: '3' },
    { label: '4 times', value: '4' },
    { label: '5+ times', value: '5+' },
  ];

  const consistencyOptions = [
    { label: 'Type 1: Hard, separate lumps', value: '1' },
    { label: 'Type 2: Sausage-like but lumpy', value: '2' },
    { label: 'Type 3: Sausage-like with cracks', value: '3' },
    { label: 'Type 4: Smooth, soft sausage', value: '4' },
    { label: 'Type 5: Soft blobs with clear edges', value: '5' },
    { label: 'Type 6: Mushy consistency', value: '6' },
    { label: 'Type 7: Entirely liquid', value: '7' },
  ];

  const colorOptions = [
    { label: 'Brown', value: 'brown' },
    { label: 'Dark brown', value: 'dark_brown' },
    { label: 'Light brown', value: 'light_brown' },
    { label: 'Yellow', value: 'yellow' },
    { label: 'Green', value: 'green' },
    { label: 'Black', value: 'black' },
    { label: 'Red', value: 'red' },
    { label: 'White/Clay', value: 'white' },
  ];

  const urgencyOptions = [
    { label: 'No urgency', value: 'none' },
    { label: 'Mild urgency', value: 'mild' },
    { label: 'Moderate urgency', value: 'moderate' },
    { label: 'Severe urgency', value: 'severe' },
    { label: 'Incontinence', value: 'incontinence' },
  ];

  const getOptions = () => {
    switch (activeField) {
      case 'frequency':
        return frequencyOptions;
      case 'consistency':
        return consistencyOptions;
      case 'color':
        return colorOptions;
      case 'urgency':
        return urgencyOptions;
      default:
        return [];
    }
  };

  const getFieldLabel = () => {
    switch (activeField) {
      case 'frequency':
        return 'Frequency';
      case 'consistency':
        return 'Consistency (Bristol Stool Scale)';
      case 'color':
        return 'Color';
      case 'urgency':
        return 'Urgency Level';
      default:
        return '';
    }
  };

  const getFieldValue = () => {
    return formData[activeField] || '';
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

  const saveBowelHealth = async () => {
    try {
      // TODO: Implement API call to save bowel health data
      Alert.alert('Success', 'Bowel health data saved successfully!');
      // Reset form
      setFormData({
        frequency: '',
        consistency: '',
        color: '',
        urgency: '',
        incomplete: false,
        blood: false,
        mucus: false,
        notes: '',
      });
    } catch (error) {
      Alert.alert('Error', 'Failed to save bowel health data');
    }
  };

  return (
    <ScrollView style={styles.container}>
      <Text style={styles.title}>Bowel Health Log</Text>
      
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
        <Text style={styles.sectionTitle}>Consistency (Bristol Stool Scale)</Text>
        <TouchableOpacity
          style={styles.pickerContainer}
          onPress={() => openPicker('consistency')}
        >
          <Text style={styles.pickerText}>{getFieldDisplayValue()}</Text>
          <Text style={styles.pickerArrow}>▼</Text>
        </TouchableOpacity>
      </View>

      <View style={styles.formSection}>
        <Text style={styles.sectionTitle}>Color</Text>
        <TouchableOpacity
          style={styles.pickerContainer}
          onPress={() => openPicker('color')}
        >
          <Text style={styles.pickerText}>{getFieldDisplayValue()}</Text>
          <Text style={styles.pickerArrow}>▼</Text>
        </TouchableOpacity>
      </View>

      <View style={styles.formSection}>
        <Text style={styles.sectionTitle}>Urgency Level</Text>
        <TouchableOpacity
          style={styles.pickerContainer}
          onPress={() => openPicker('urgency')}
        >
          <Text style={styles.pickerText}>{getFieldDisplayValue()}</Text>
          <Text style={styles.pickerArrow}>▼</Text>
        </TouchableOpacity>
      </View>

      <View style={styles.formSection}>
        <Text style={styles.sectionTitle}>Additional Symptoms</Text>
        
        <TouchableOpacity
          style={styles.checkboxContainer}
          onPress={() => setFormData({...formData, incomplete: !formData.incomplete})}
        >
          <View style={[styles.checkbox, formData.incomplete && styles.checkboxChecked]}>
            {formData.incomplete && <Text style={styles.checkmark}>✓</Text>}
          </View>
          <Text style={styles.checkboxLabel}>Feeling of incomplete evacuation</Text>
        </TouchableOpacity>

        <TouchableOpacity
          style={styles.checkboxContainer}
          onPress={() => setFormData({...formData, blood: !formData.blood})}
        >
          <View style={[styles.checkbox, formData.blood && styles.checkboxChecked]}>
            {formData.blood && <Text style={styles.checkmark}>✓</Text>}
          </View>
          <Text style={styles.checkboxLabel}>Blood in stool</Text>
        </TouchableOpacity>

        <TouchableOpacity
          style={styles.checkboxContainer}
          onPress={() => setFormData({...formData, mucus: !formData.mucus})}
        >
          <View style={[styles.checkbox, formData.mucus && styles.checkboxChecked]}>
            {formData.mucus && <Text style={styles.checkmark}>✓</Text>}
          </View>
          <Text style={styles.checkboxLabel}>Mucus in stool</Text>
        </TouchableOpacity>
      </View>

      <View style={styles.formSection}>
        <Text style={styles.sectionTitle}>Notes (Optional)</Text>
        <Text style={styles.notesPlaceholder}>
          Add any additional observations or symptoms...
        </Text>
      </View>

      <TouchableOpacity style={styles.saveButton} onPress={saveBowelHealth}>
        <Text style={styles.saveButtonText}>Save Bowel Health Data</Text>
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

export default BowelHealthScreen; 