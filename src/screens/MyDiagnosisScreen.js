import React, { useState } from 'react';
import {
  View,
  StyleSheet,
  ScrollView,
  KeyboardAvoidingView,
  Platform,
  Alert,
} from 'react-native';
import {
  TextInput,
  Button,
  Text,
  Surface,
  Title,
  Paragraph,
  HelperText,
  Chip,
  Divider,
  RadioButton,
  Checkbox,
} from 'react-native-paper';
import { Picker } from '@react-native-picker/picker';
import { colors } from '../theme';
import CustomModal from '../components/CustomModal';
import { API_BASE_URL } from '../config';

const MyDiagnosisScreen = ({ navigation, route }) => {
  const { userData } = route.params;
  
  // Basic Diagnosis Information
  const [diagnosis, setDiagnosis] = useState('');
  const [diagnosisYear, setDiagnosisYear] = useState('');
  const [diagnosisMonth, setDiagnosisMonth] = useState('');
  const [diseaseLocation, setDiseaseLocation] = useState('');
  const [diseaseBehavior, setDiseaseBehavior] = useState('');
  const [diseaseSeverity, setDiseaseSeverity] = useState('');
  
  // Medication Information
  const [takingMedications, setTakingMedications] = useState('');
  const [currentMedications, setCurrentMedications] = useState([]);
  const [selectedMedication, setSelectedMedication] = useState('');
  const [medicationComplications, setMedicationComplications] = useState([]);
  const [selectedComplication, setSelectedComplication] = useState('');
  
  // Health Status
  const [isAnemic, setIsAnemic] = useState('');
  const [anemiaSeverity, setAnemiaSeverity] = useState('');
  const [giSpecialistFrequency, setGiSpecialistFrequency] = useState('');
  const [lastGiVisit, setLastGiVisit] = useState('');
  
  // Additional IBD Questions
  const [familyHistory, setFamilyHistory] = useState('');
  const [surgeryHistory, setSurgeryHistory] = useState('');
  const [hospitalizations, setHospitalizations] = useState('');
  const [flareFrequency, setFlareFrequency] = useState('');
  const [currentSymptoms, setCurrentSymptoms] = useState([]);
  const [selectedSymptom, setSelectedSymptom] = useState('');
  const [dietaryRestrictions, setDietaryRestrictions] = useState([]);
  const [selectedRestriction, setSelectedRestriction] = useState('');
  const [comorbidities, setComorbidities] = useState([]);
  const [selectedComorbidity, setSelectedComorbidity] = useState('');
  
  // Form State
  const [isLoading, setIsLoading] = useState(false);
  const [showSuccessModal, setShowSuccessModal] = useState(false);
  const [showErrorModal, setShowErrorModal] = useState(false);
  const [errorMessage, setErrorMessage] = useState('');
  const [currentStep, setCurrentStep] = useState(1);
  const [totalSteps] = useState(4);

  // Diagnosis options
  const diagnosisOptions = [
    { label: 'Select your diagnosis', value: '' },
    { label: 'Crohn\'s Disease', value: 'crohns' },
    { label: 'Ulcerative Colitis', value: 'ulcerative_colitis' },
    { label: 'Indeterminate Colitis', value: 'indeterminate_colitis' },
    { label: 'Microscopic Colitis', value: 'microscopic_colitis' },
    { label: 'IBS (Irritable Bowel Syndrome)', value: 'ibs' },
    { label: 'Other IBD', value: 'other_ibd' },
  ];

  // Year options (last 50 years)
  const yearOptions = [
    { label: 'Select year', value: '' },
    ...Array.from({ length: 50 }, (_, i) => {
      const year = new Date().getFullYear() - i;
      return { label: year.toString(), value: year.toString() };
    }),
  ];

  // Month options
  const monthOptions = [
    { label: 'Select month', value: '' },
    { label: 'January', value: '01' },
    { label: 'February', value: '02' },
    { label: 'March', value: '03' },
    { label: 'April', value: '04' },
    { label: 'May', value: '05' },
    { label: 'June', value: '06' },
    { label: 'July', value: '07' },
    { label: 'August', value: '08' },
    { label: 'September', value: '09' },
    { label: 'October', value: '10' },
    { label: 'November', value: '11' },
    { label: 'December', value: '12' },
  ];

  // Disease location options
  const locationOptions = [
    { label: 'Select location', value: '' },
    { label: 'Small Intestine', value: 'small_intestine' },
    { label: 'Large Intestine', value: 'large_intestine' },
    { label: 'Colon', value: 'colon' },
    { label: 'Rectum', value: 'rectum' },
    { label: 'Ileum', value: 'ileum' },
    { label: 'Multiple Locations', value: 'multiple' },
    { label: 'Unknown', value: 'unknown' },
  ];

  // Disease behavior options
  const behaviorOptions = [
    { label: 'Select behavior', value: '' },
    { label: 'Inflammatory', value: 'inflammatory' },
    { label: 'Stricturing', value: 'stricturing' },
    { label: 'Penetrating', value: 'penetrating' },
    { label: 'Mixed', value: 'mixed' },
    { label: 'Unknown', value: 'unknown' },
  ];

  // Severity options
  const severityOptions = [
    { label: 'Select severity', value: '' },
    { label: 'Mild', value: 'mild' },
    { label: 'Moderate', value: 'moderate' },
    { label: 'Severe', value: 'severe' },
    { label: 'Varies', value: 'varies' },
  ];

  // Medication options
  const medicationOptions = [
    { label: 'Select medication type', value: '' },
    { label: 'Biologics (Humira, Remicade, Stelara, Entyvio)', value: 'biologics' },
    { label: 'Immunosuppressants (Azathioprine, Methotrexate, 6-MP)', value: 'immunosuppressants' },
    { label: 'Steroids (Prednisone, Budesonide)', value: 'steroids' },
    { label: '5-ASA (Mesalamine, Sulfasalazine)', value: 'asa' },
    { label: 'JAK Inhibitors (Xeljanz, Rinvoq)', value: 'jak_inhibitors' },
    { label: 'Antibiotics (Metronidazole, Ciprofloxacin)', value: 'antibiotics' },
    { label: 'Pain Medications', value: 'pain_medications' },
    { label: 'Other', value: 'other' },
  ];

  // Medication complication options
  const complicationOptions = [
    { label: 'Select complication', value: '' },
    { label: 'Infections', value: 'infections' },
    { label: 'Liver problems', value: 'liver_problems' },
    { label: 'Bone loss', value: 'bone_loss' },
    { label: 'Skin reactions', value: 'skin_reactions' },
    { label: 'Fatigue', value: 'fatigue' },
    { label: 'Nausea', value: 'nausea' },
    { label: 'Headaches', value: 'headaches' },
    { label: 'Joint pain', value: 'joint_pain' },
    { label: 'None', value: 'none' },
  ];

  // Anemia severity options
  const anemiaOptions = [
    { label: 'Select severity', value: '' },
    { label: 'Mild', value: 'mild' },
    { label: 'Moderate', value: 'moderate' },
    { label: 'Severe', value: 'severe' },
  ];

  // GI specialist frequency options
  const giFrequencyOptions = [
    { label: 'Select frequency', value: '' },
    { label: 'Every 3 months', value: 'every_3_months' },
    { label: 'Every 6 months', value: 'every_6_months' },
    { label: 'Once a year', value: 'once_a_year' },
    { label: 'As needed', value: 'as_needed' },
    { label: 'I don\'t see a GI specialist', value: 'none' },
  ];

  // Last GI visit options
  const lastVisitOptions = [
    { label: 'Select timeframe', value: '' },
    { label: 'Within last month', value: 'last_month' },
    { label: '1-3 months ago', value: '1_3_months' },
    { label: '3-6 months ago', value: '3_6_months' },
    { label: '6-12 months ago', value: '6_12_months' },
    { label: 'More than a year ago', value: 'over_year' },
    { label: 'Never', value: 'never' },
  ];

  // Flare frequency options
  const flareFrequencyOptions = [
    { label: 'Select frequency', value: '' },
    { label: 'Never', value: 'never' },
    { label: 'Rarely (once a year)', value: 'rarely' },
    { label: 'Occasionally (2-4 times a year)', value: 'occasionally' },
    { label: 'Frequently (monthly)', value: 'frequently' },
    { label: 'Very frequently (weekly)', value: 'very_frequently' },
  ];

  // Symptom options
  const symptomOptions = [
    { label: 'Select symptom', value: '' },
    { label: 'Abdominal Pain', value: 'abdominal_pain' },
    { label: 'Diarrhea', value: 'diarrhea' },
    { label: 'Constipation', value: 'constipation' },
    { label: 'Blood in Stool', value: 'blood_in_stool' },
    { label: 'Fatigue', value: 'fatigue' },
    { label: 'Weight Loss', value: 'weight_loss' },
    { label: 'Fever', value: 'fever' },
    { label: 'Joint Pain', value: 'joint_pain' },
    { label: 'Skin Problems', value: 'skin_problems' },
    { label: 'Eye Problems', value: 'eye_problems' },
    { label: 'Nausea', value: 'nausea' },
    { label: 'Loss of Appetite', value: 'loss_of_appetite' },
    { label: 'Bloating', value: 'bloating' },
    { label: 'Urgency', value: 'urgency' },
  ];

  // Dietary restriction options
  const restrictionOptions = [
    { label: 'Select restriction', value: '' },
    { label: 'Gluten-free', value: 'gluten_free' },
    { label: 'Dairy-free', value: 'dairy_free' },
    { label: 'Low FODMAP', value: 'low_fodmap' },
    { label: 'Low fiber', value: 'low_fiber' },
    { label: 'Low fat', value: 'low_fat' },
    { label: 'No raw vegetables', value: 'no_raw_vegetables' },
    { label: 'No spicy foods', value: 'no_spicy_foods' },
    { label: 'No caffeine', value: 'no_caffeine' },
    { label: 'No alcohol', value: 'no_alcohol' },
    { label: 'Other', value: 'other' },
  ];

  // Comorbidity options
  const comorbidityOptions = [
    { label: 'Select condition', value: '' },
    { label: 'Arthritis', value: 'arthritis' },
    { label: 'Diabetes', value: 'diabetes' },
    { label: 'Hypertension', value: 'hypertension' },
    { label: 'Asthma', value: 'asthma' },
    { label: 'Depression/Anxiety', value: 'depression_anxiety' },
    { label: 'Osteoporosis', value: 'osteoporosis' },
    { label: 'Liver disease', value: 'liver_disease' },
    { label: 'Kidney disease', value: 'kidney_disease' },
    { label: 'Heart disease', value: 'heart_disease' },
    { label: 'Cancer', value: 'cancer' },
    { label: 'None', value: 'none' },
  ];

  // Helper functions
  const addMedication = () => {
    if (selectedMedication && !currentMedications.includes(selectedMedication)) {
      setCurrentMedications([...currentMedications, selectedMedication]);
      setSelectedMedication('');
    }
  };

  const removeMedication = (medication) => {
    setCurrentMedications(currentMedications.filter(m => m !== medication));
  };

  const addComplication = () => {
    if (selectedComplication && !medicationComplications.includes(selectedComplication)) {
      setMedicationComplications([...medicationComplications, selectedComplication]);
      setSelectedComplication('');
    }
  };

  const removeComplication = (complication) => {
    setMedicationComplications(medicationComplications.filter(c => c !== complication));
  };

  const addSymptom = () => {
    if (selectedSymptom && !currentSymptoms.includes(selectedSymptom)) {
      setCurrentSymptoms([...currentSymptoms, selectedSymptom]);
      setSelectedSymptom('');
    }
  };

  const removeSymptom = (symptom) => {
    setCurrentSymptoms(currentSymptoms.filter(s => s !== symptom));
  };

  const addRestriction = () => {
    if (selectedRestriction && !dietaryRestrictions.includes(selectedRestriction)) {
      setDietaryRestrictions([...dietaryRestrictions, selectedRestriction]);
      setSelectedRestriction('');
    }
  };

  const removeRestriction = (restriction) => {
    setDietaryRestrictions(dietaryRestrictions.filter(r => r !== restriction));
  };

  const addComorbidity = () => {
    if (selectedComorbidity && !comorbidities.includes(selectedComorbidity)) {
      setComorbidities([...comorbidities, selectedComorbidity]);
      setSelectedComorbidity('');
    }
  };

  const removeComorbidity = (comorbidity) => {
    setComorbidities(comorbidities.filter(c => c !== comorbidity));
  };

  const validateStep = (step) => {
    switch (step) {
      case 1:
        if (!diagnosis) {
          setErrorMessage('Please select your IBD diagnosis');
          setShowErrorModal(true);
          return false;
        }
        if (!diagnosisYear) {
          setErrorMessage('Please select the year of your diagnosis');
          setShowErrorModal(true);
          return false;
        }
        break;
      case 2:
        if (!takingMedications) {
          setErrorMessage('Please indicate if you are taking medications');
          setShowErrorModal(true);
          return false;
        }
        if (takingMedications === 'yes' && currentMedications.length === 0) {
          setErrorMessage('Please select at least one medication type');
          setShowErrorModal(true);
          return false;
        }
        break;
      case 3:
        if (!isAnemic) {
          setErrorMessage('Please indicate if you are anemic');
          setShowErrorModal(true);
          return false;
        }
        if (!giSpecialistFrequency) {
          setErrorMessage('Please select how often you see your GI specialist');
          setShowErrorModal(true);
          return false;
        }
        break;
    }
    return true;
  };

  const nextStep = () => {
    console.log('Next button pressed, current step:', currentStep);
    if (validateStep(currentStep)) {
      setCurrentStep(Math.min(currentStep + 1, totalSteps));
    }
  };

  const prevStep = () => {
    console.log('Previous button pressed, current step:', currentStep);
    setCurrentStep(Math.max(currentStep - 1, 1));
  };

  const handleSave = async () => {
    if (!validateStep(currentStep)) {
      return;
    }

    setIsLoading(true);

    try {
      const diagnosisData = {
        username: userData?.username,
        diagnosis_date: diagnosisYear && diagnosisMonth ? `${diagnosisYear}-${diagnosisMonth}-01` : null,
        ibd_type: diagnosis,
        disease_location: diseaseLocation,
        disease_behavior: diseaseBehavior,
        disease_activity: diseaseSeverity,
        current_medications: currentMedications.join(','),
        medication_complications: medicationComplications.join(','),
        is_anemic: isAnemic === 'yes',
        anemia_severity: isAnemic === 'yes' ? anemiaSeverity : null,
        gi_specialist_frequency: giSpecialistFrequency,
        last_gi_visit: lastGiVisit,
        family_history: familyHistory,
        surgery_history: surgeryHistory,
        hospitalizations_count: hospitalizations ? parseInt(hospitalizations) : 0,
        flare_frequency: flareFrequency,
        current_symptoms: currentSymptoms.join(','),
        dietary_restrictions: dietaryRestrictions.join(','),
        comorbidities: comorbidities.join(','),
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString()
      };

      const response = await fetch(`${API_BASE_URL}/users/diagnosis`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(diagnosisData),
      });

      if (response.ok) {
        setShowSuccessModal(true);
      } else {
        const errorData = await response.json();
        throw new Error(errorData.message || 'Failed to save diagnosis');
      }
    } catch (error) {
      console.error('Error saving diagnosis:', error);
      setErrorMessage(error.message || 'Failed to save diagnosis. Please try again.');
      setShowErrorModal(true);
    } finally {
      setIsLoading(false);
    }
  };

  const renderStep1 = () => (
    <View>
      <Title style={styles.stepTitle}>Step 1: Basic Diagnosis Information</Title>
      
      {/* Diagnosis */}
      <View style={styles.pickerContainer}>
        <Text style={styles.label}>What is your IBD diagnosis? *</Text>
        <View style={styles.pickerWrapper}>
          <Picker
            selectedValue={diagnosis}
            onValueChange={setDiagnosis}
            style={styles.picker}
          >
            {diagnosisOptions.map((option) => (
              <Picker.Item
                key={option.value}
                label={option.label}
                value={option.value}
              />
            ))}
          </Picker>
        </View>
      </View>

      {/* Diagnosis Year */}
      <View style={styles.pickerContainer}>
        <Text style={styles.label}>When were you first diagnosed? *</Text>
        <View style={styles.rowContainer}>
          <View style={[styles.pickerWrapper, { flex: 1, marginRight: 10 }]}>
            <Picker
              selectedValue={diagnosisYear}
              onValueChange={setDiagnosisYear}
              style={styles.picker}
            >
              {yearOptions.map((option) => (
                <Picker.Item
                  key={option.value}
                  label={option.label}
                  value={option.value}
                />
              ))}
            </Picker>
          </View>
          <View style={[styles.pickerWrapper, { flex: 1 }]}>
            <Picker
              selectedValue={diagnosisMonth}
              onValueChange={setDiagnosisMonth}
              style={styles.picker}
            >
              {monthOptions.map((option) => (
                <Picker.Item
                  key={option.value}
                  label={option.label}
                  value={option.value}
                />
              ))}
            </Picker>
          </View>
        </View>
      </View>

      {/* Disease Location */}
      <View style={styles.pickerContainer}>
        <Text style={styles.label}>Where is your disease located?</Text>
        <View style={styles.pickerWrapper}>
          <Picker
            selectedValue={diseaseLocation}
            onValueChange={setDiseaseLocation}
            style={styles.picker}
          >
            {locationOptions.map((option) => (
              <Picker.Item
                key={option.value}
                label={option.label}
                value={option.value}
              />
            ))}
          </Picker>
        </View>
      </View>

      {/* Disease Behavior */}
      <View style={styles.pickerContainer}>
        <Text style={styles.label}>What is your disease behavior?</Text>
        <View style={styles.pickerWrapper}>
          <Picker
            selectedValue={diseaseBehavior}
            onValueChange={setDiseaseBehavior}
            style={styles.picker}
          >
            {behaviorOptions.map((option) => (
              <Picker.Item
                key={option.value}
                label={option.label}
                value={option.value}
              />
            ))}
          </Picker>
        </View>
      </View>

      {/* Disease Severity */}
      <View style={styles.pickerContainer}>
        <Text style={styles.label}>What is your disease severity?</Text>
        <View style={styles.pickerWrapper}>
          <Picker
            selectedValue={diseaseSeverity}
            onValueChange={setDiseaseSeverity}
            style={styles.picker}
          >
            {severityOptions.map((option) => (
              <Picker.Item
                key={option.value}
                label={option.label}
                value={option.value}
              />
            ))}
          </Picker>
        </View>
      </View>
    </View>
  );

  const renderStep2 = () => (
    <View>
      <Title style={styles.stepTitle}>Step 2: Medication Information</Title>
      
      {/* Taking Medications */}
      <View style={styles.radioContainer}>
        <Text style={styles.label}>Are you currently taking medications? *</Text>
        <RadioButton.Group onValueChange={setTakingMedications} value={takingMedications}>
          <View style={styles.radioItem}>
            <RadioButton value="yes" />
            <Text style={styles.radioLabel}>Yes</Text>
          </View>
          <View style={styles.radioItem}>
            <RadioButton value="no" />
            <Text style={styles.radioLabel}>No</Text>
          </View>
        </RadioButton.Group>
      </View>

      {takingMedications === 'yes' && (
        <>
          {/* Current Medications */}
          <Text style={styles.sectionTitle}>What types of medications are you taking?</Text>
          <View style={styles.addItemContainer}>
            <View style={styles.pickerWrapper}>
              <Picker
                selectedValue={selectedMedication}
                onValueChange={setSelectedMedication}
                style={styles.picker}
              >
                {medicationOptions.map((option) => (
                  <Picker.Item
                    key={option.value}
                    label={option.label}
                    value={option.value}
                  />
                ))}
              </Picker>
            </View>
            <Button
              mode="outlined"
              onPress={addMedication}
              disabled={!selectedMedication}
              style={styles.addButton}
            >
              Add
            </Button>
          </View>

          {/* Selected Medications */}
          <View style={styles.chipContainer}>
            {currentMedications.map((medication, index) => (
              <Chip
                key={index}
                onClose={() => removeMedication(medication)}
                style={styles.chip}
              >
                {medicationOptions.find(m => m.value === medication)?.label || medication}
              </Chip>
            ))}
          </View>

          {/* Medication Complications */}
          <Text style={styles.sectionTitle}>What complications have you experienced from medications in the last 3 months?</Text>
          <View style={styles.addItemContainer}>
            <View style={styles.pickerWrapper}>
              <Picker
                selectedValue={selectedComplication}
                onValueChange={setSelectedComplication}
                style={styles.picker}
              >
                {complicationOptions.map((option) => (
                  <Picker.Item
                    key={option.value}
                    label={option.label}
                    value={option.value}
                  />
                ))}
              </Picker>
            </View>
            <Button
              mode="outlined"
              onPress={addComplication}
              disabled={!selectedComplication}
              style={styles.addButton}
            >
              Add
            </Button>
          </View>

          {/* Selected Complications */}
          <View style={styles.chipContainer}>
            {medicationComplications.map((complication, index) => (
              <Chip
                key={index}
                onClose={() => removeComplication(complication)}
                style={styles.chip}
              >
                {complicationOptions.find(c => c.value === complication)?.label || complication}
              </Chip>
            ))}
          </View>
        </>
      )}
    </View>
  );

  const renderStep3 = () => (
    <View>
      <Title style={styles.stepTitle}>Step 3: Health Status</Title>
      
      {/* Anemia */}
      <View style={styles.radioContainer}>
        <Text style={styles.label}>Are you anemic? *</Text>
        <RadioButton.Group onValueChange={setIsAnemic} value={isAnemic}>
          <View style={styles.radioItem}>
            <RadioButton value="yes" />
            <Text style={styles.radioLabel}>Yes</Text>
          </View>
          <View style={styles.radioItem}>
            <RadioButton value="no" />
            <Text style={styles.radioLabel}>No</Text>
          </View>
        </RadioButton.Group>
      </View>

      {isAnemic === 'yes' && (
        <View style={styles.pickerContainer}>
          <Text style={styles.label}>How severe is your anemia?</Text>
          <View style={styles.pickerWrapper}>
            <Picker
              selectedValue={anemiaSeverity}
              onValueChange={setAnemiaSeverity}
              style={styles.picker}
            >
              {anemiaOptions.map((option) => (
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

      {/* GI Specialist Frequency */}
      <View style={styles.pickerContainer}>
        <Text style={styles.label}>How often do you see your GI specialist? *</Text>
        <View style={styles.pickerWrapper}>
          <Picker
            selectedValue={giSpecialistFrequency}
            onValueChange={setGiSpecialistFrequency}
            style={styles.picker}
          >
            {giFrequencyOptions.map((option) => (
              <Picker.Item
                key={option.value}
                label={option.label}
                value={option.value}
              />
            ))}
          </Picker>
        </View>
      </View>

      {/* Last GI Visit */}
      <View style={styles.pickerContainer}>
        <Text style={styles.label}>When was your last GI specialist visit?</Text>
        <View style={styles.pickerWrapper}>
          <Picker
            selectedValue={lastGiVisit}
            onValueChange={setLastGiVisit}
            style={styles.picker}
          >
            {lastVisitOptions.map((option) => (
              <Picker.Item
                key={option.value}
                label={option.label}
                value={option.value}
              />
            ))}
          </Picker>
        </View>
      </View>
    </View>
  );

  const renderStep4 = () => (
    <View>
      <Title style={styles.stepTitle}>Step 4: Additional Information</Title>
      
      {/* Family History */}
      <View style={styles.radioContainer}>
        <Text style={styles.label}>Do you have a family history of IBD?</Text>
        <RadioButton.Group onValueChange={setFamilyHistory} value={familyHistory}>
          <View style={styles.radioItem}>
            <RadioButton value="yes" />
            <Text style={styles.radioLabel}>Yes</Text>
          </View>
          <View style={styles.radioItem}>
            <RadioButton value="no" />
            <Text style={styles.radioLabel}>No</Text>
          </View>
          <View style={styles.radioItem}>
            <RadioButton value="unknown" />
            <Text style={styles.radioLabel}>Unknown</Text>
          </View>
        </RadioButton.Group>
      </View>

      {/* Surgery History */}
      <View style={styles.radioContainer}>
        <Text style={styles.label}>Have you had any IBD-related surgeries?</Text>
        <RadioButton.Group onValueChange={setSurgeryHistory} value={surgeryHistory}>
          <View style={styles.radioItem}>
            <RadioButton value="yes" />
            <Text style={styles.radioLabel}>Yes</Text>
          </View>
          <View style={styles.radioItem}>
            <RadioButton value="no" />
            <Text style={styles.radioLabel}>No</Text>
          </View>
        </RadioButton.Group>
      </View>

      {/* Hospitalizations */}
      <View style={styles.inputContainer}>
        <Text style={styles.label}>How many times have you been hospitalized for IBD?</Text>
        <TextInput
          style={styles.textInput}
          value={hospitalizations}
          onChangeText={setHospitalizations}
          keyboardType="numeric"
          placeholder="Enter number"
        />
      </View>

      {/* Flare Frequency */}
      <View style={styles.pickerContainer}>
        <Text style={styles.label}>How often do you experience flares?</Text>
        <View style={styles.pickerWrapper}>
          <Picker
            selectedValue={flareFrequency}
            onValueChange={setFlareFrequency}
            style={styles.picker}
          >
            {flareFrequencyOptions.map((option) => (
              <Picker.Item
                key={option.value}
                label={option.label}
                value={option.value}
              />
            ))}
          </Picker>
        </View>
      </View>

      {/* Current Symptoms */}
      <Text style={styles.sectionTitle}>What symptoms are you currently experiencing?</Text>
      <View style={styles.addItemContainer}>
        <View style={styles.pickerWrapper}>
          <Picker
            selectedValue={selectedSymptom}
            onValueChange={setSelectedSymptom}
            style={styles.picker}
          >
            {symptomOptions.map((option) => (
              <Picker.Item
                key={option.value}
                label={option.label}
                value={option.value}
              />
            ))}
          </Picker>
        </View>
        <Button
          mode="outlined"
          onPress={addSymptom}
          disabled={!selectedSymptom}
          style={styles.addButton}
        >
          Add
        </Button>
      </View>

      {/* Selected Symptoms */}
      <View style={styles.chipContainer}>
        {currentSymptoms.map((symptom, index) => (
          <Chip
            key={index}
            onClose={() => removeSymptom(symptom)}
            style={styles.chip}
          >
            {symptomOptions.find(s => s.value === symptom)?.label || symptom}
          </Chip>
        ))}
      </View>

      {/* Dietary Restrictions */}
      <Text style={styles.sectionTitle}>Do you follow any dietary restrictions?</Text>
      <View style={styles.addItemContainer}>
        <View style={styles.pickerWrapper}>
          <Picker
            selectedValue={selectedRestriction}
            onValueChange={setSelectedRestriction}
            style={styles.picker}
          >
            {restrictionOptions.map((option) => (
              <Picker.Item
                key={option.value}
                label={option.label}
                value={option.value}
              />
            ))}
          </Picker>
        </View>
        <Button
          mode="outlined"
          onPress={addRestriction}
          disabled={!selectedRestriction}
          style={styles.addButton}
        >
          Add
        </Button>
      </View>

      {/* Selected Restrictions */}
      <View style={styles.chipContainer}>
        {dietaryRestrictions.map((restriction, index) => (
          <Chip
            key={index}
            onClose={() => removeRestriction(restriction)}
            style={styles.chip}
          >
            {restrictionOptions.find(r => r.value === restriction)?.label || restriction}
          </Chip>
        ))}
      </View>

      {/* Comorbidities */}
      <Text style={styles.sectionTitle}>Do you have any other medical conditions?</Text>
      <View style={styles.addItemContainer}>
        <View style={styles.pickerWrapper}>
          <Picker
            selectedValue={selectedComorbidity}
            onValueChange={setSelectedComorbidity}
            style={styles.picker}
          >
            {comorbidityOptions.map((option) => (
              <Picker.Item
                key={option.value}
                label={option.label}
                value={option.value}
              />
            ))}
          </Picker>
        </View>
        <Button
          mode="outlined"
          onPress={addComorbidity}
          disabled={!selectedComorbidity}
          style={styles.addButton}
        >
          Add
        </Button>
      </View>

      {/* Selected Comorbidities */}
      <View style={styles.chipContainer}>
        {comorbidities.map((comorbidity, index) => (
          <Chip
            key={index}
            onClose={() => removeComorbidity(comorbidity)}
            style={styles.chip}
          >
            {comorbidityOptions.find(c => c.value === comorbidity)?.label || comorbidity}
          </Chip>
        ))}
      </View>
    </View>
  );

  const renderCurrentStep = () => {
    switch (currentStep) {
      case 1:
        return renderStep1();
      case 2:
        return renderStep2();
      case 3:
        return renderStep3();
      case 4:
        return renderStep4();
      default:
        return renderStep1();
    }
  };

  return (
    <KeyboardAvoidingView
      style={styles.container}
      behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
    >
      <ScrollView 
        style={styles.scrollView}
        contentContainerStyle={styles.scrollContainer}
        showsVerticalScrollIndicator={true}
        bounces={true}
        alwaysBounceVertical={false}
      >
        <View style={styles.content}>
          {/* Header */}
          <View style={styles.header}>
            <View style={styles.headerTop}>
              <Button
                mode="outlined"
                onPress={() => navigation.goBack()}
                style={styles.backButton}
                icon="arrow-left"
              >
                Back
              </Button>
            </View>
            <Title style={styles.title}>My Diagnosis Assessment</Title>
            <Paragraph style={styles.subtitle}>
              Help us understand your IBD journey for personalized care
            </Paragraph>
            
            {/* Progress Indicator */}
            <View style={styles.progressContainer}>
              <View style={styles.progressBar}>
                <View 
                  style={[
                    styles.progressFill, 
                    { width: `${(currentStep / totalSteps) * 100}%` }
                  ]} 
                />
              </View>
              <Text style={styles.progressText}>
                Step {currentStep} of {totalSteps}
              </Text>
            </View>
          </View>

          {/* Navigation Buttons */}
          <View style={styles.navigationContainer}>
            {currentStep > 1 ? (
              <Button
                mode="contained"
                onPress={prevStep}
                style={[styles.navButton, styles.prevButton]}
                labelStyle={styles.navButtonLabel}
              >
                ← Previous
              </Button>
            ) : (
              <View style={styles.navButton} />
            )}
            
            {currentStep < totalSteps ? (
              <Button
                mode="contained"
                onPress={nextStep}
                style={[styles.navButton, styles.nextButton]}
                labelStyle={styles.navButtonLabel}
              >
                Next →
              </Button>
            ) : (
              <Button
                mode="contained"
                onPress={handleSave}
                style={[styles.navButton, styles.saveButton]}
                loading={isLoading}
                disabled={isLoading}
                labelStyle={styles.navButtonLabel}
              >
                Save Diagnosis
              </Button>
            )}
          </View>

          {/* Form Content */}
          <View style={styles.form}>
            {renderCurrentStep()}
          </View>
        </View>
      </ScrollView>

      {/* Success Modal */}
      <CustomModal
        visible={showSuccessModal}
        onClose={() => {
          setShowSuccessModal(false);
          navigation.navigate('Home');
        }}
        title="Diagnosis Saved Successfully"
        message="Your diagnosis information has been saved. This helps us provide personalized insights and recommendations for your IBD management."
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
    minHeight: '100%',
  },
  scrollView: {
    flex: 1,
  },
  scrollContainer: {
    flexGrow: 1,
    padding: 20,
    minHeight: '100%',
  },
  content: {
    flex: 1,
    padding: 24,
  },
  header: {
    alignItems: 'center',
    marginBottom: 32,
  },
  headerTop: {
    width: '100%',
    alignItems: 'flex-start',
    marginBottom: 16,
  },
  backButton: {
    borderColor: colors.primary,
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
    marginBottom: 20,
  },
  progressContainer: {
    width: '100%',
    alignItems: 'center',
  },
  progressBar: {
    width: '100%',
    height: 8,
    backgroundColor: colors.placeholder,
    borderRadius: 4,
    marginBottom: 8,
  },
  progressFill: {
    height: '100%',
    backgroundColor: colors.primary,
    borderRadius: 4,
  },
  progressText: {
    fontSize: 14,
    color: colors.primary,
    fontWeight: '600',
  },
  navigationContainer: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 32,
    paddingHorizontal: 16,
  },
  navButton: {
    flex: 1,
    marginHorizontal: 8,
    minHeight: 50,
    borderRadius: 8,
  },
  navButtonLabel: {
    fontSize: 16,
    fontWeight: 'bold',
  },
  prevButton: {
    backgroundColor: colors.placeholder,
  },
  nextButton: {
    backgroundColor: colors.primary,
  },
  saveButton: {
    backgroundColor: colors.success || '#4CAF50',
  },
  form: {
    width: '100%',
  },
  stepTitle: {
    fontSize: 20,
    fontWeight: 'bold',
    color: colors.primary,
    marginBottom: 20,
  },
  pickerContainer: {
    marginBottom: 20,
  },
  rowContainer: {
    flexDirection: 'row',
    alignItems: 'center',
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
  radioContainer: {
    marginBottom: 20,
  },
  radioItem: {
    flexDirection: 'row',
    alignItems: 'center',
    marginVertical: 4,
  },
  radioLabel: {
    fontSize: 16,
    color: colors.text,
    marginLeft: 8,
  },
  inputContainer: {
    marginBottom: 20,
  },
  textInput: {
    borderWidth: 1,
    borderColor: colors.placeholder,
    borderRadius: 8,
    paddingHorizontal: 12,
    paddingVertical: 8,
    backgroundColor: 'white',
    fontSize: 16,
  },
  sectionTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    color: colors.primary,
    marginBottom: 16,
    marginTop: 8,
  },
  addItemContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 16,
  },
  addButton: {
    marginLeft: 12,
    minWidth: 80,
  },
  chipContainer: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    marginBottom: 20,
  },
  chip: {
    margin: 4,
  },
});

export default MyDiagnosisScreen; 