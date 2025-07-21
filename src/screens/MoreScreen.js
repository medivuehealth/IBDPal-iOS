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
  Card,
  List,
} from 'react-native-paper';
import { Picker } from '@react-native-picker/picker';
import { colors } from '../theme';
import CustomModal from '../components/CustomModal';
import { API_BASE_URL } from '../config';

const MoreScreen = ({ navigation, route }) => {
  const [showLogoutModal, setShowLogoutModal] = useState(false);
  const [showAssessmentForm, setShowAssessmentForm] = useState(false);

  const { userData, authContext } = route.params;

  const handleLogout = async () => {
    await authContext.signOut();
  };

  const [showFeatureModal, setShowFeatureModal] = useState(false);
  const [featureMessage, setFeatureMessage] = useState('');

  const handleFeaturePress = (title) => {
    setFeatureMessage(`${title} feature is coming soon! This will be available in a future update.`);
    setShowFeatureModal(true);
  };

  // Assessment Form State
  const [diagnosis, setDiagnosis] = useState('');
  const [diagnosisYear, setDiagnosisYear] = useState('');
  const [diagnosisMonth, setDiagnosisMonth] = useState('');
  const [diseaseLocation, setDiseaseLocation] = useState('');
  const [diseaseBehavior, setDiseaseBehavior] = useState('');
  const [diseaseSeverity, setDiseaseSeverity] = useState('');
  const [takingMedications, setTakingMedications] = useState('');
  const [currentMedications, setCurrentMedications] = useState([]);
  const [selectedMedication, setSelectedMedication] = useState('');
  const [medicationComplications, setMedicationComplications] = useState([]);
  const [selectedComplication, setSelectedComplication] = useState('');
  const [isAnemic, setIsAnemic] = useState('');
  const [anemiaSeverity, setAnemiaSeverity] = useState('');
  const [giSpecialistFrequency, setGiSpecialistFrequency] = useState('');
  const [lastGiVisit, setLastGiVisit] = useState('');
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
  const [isLoading, setIsLoading] = useState(false);
  const [showSuccessModal, setShowSuccessModal] = useState(false);
  const [showErrorModal, setShowErrorModal] = useState(false);
  const [errorMessage, setErrorMessage] = useState('');
  const [currentStep, setCurrentStep] = useState(1);
  const [totalSteps] = useState(4);

  // Assessment Form Options
  const diagnosisOptions = [
    { label: 'Select your diagnosis', value: '' },
    { label: 'Crohn\'s Disease', value: 'crohns' },
    { label: 'Ulcerative Colitis', value: 'ulcerative_colitis' },
    { label: 'Indeterminate Colitis', value: 'indeterminate_colitis' },
    { label: 'Microscopic Colitis', value: 'microscopic_colitis' },
    { label: 'IBS (Irritable Bowel Syndrome)', value: 'ibs' },
    { label: 'Other IBD', value: 'other_ibd' },
  ];

  const yearOptions = [
    { label: 'Select year', value: '' },
    ...Array.from({ length: 50 }, (_, i) => {
      const year = new Date().getFullYear() - i;
      return { label: year.toString(), value: year.toString() };
    }),
  ];

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

  const behaviorOptions = [
    { label: 'Select behavior', value: '' },
    { label: 'Inflammatory', value: 'inflammatory' },
    { label: 'Stricturing', value: 'stricturing' },
    { label: 'Penetrating', value: 'penetrating' },
    { label: 'Mixed', value: 'mixed' },
    { label: 'Unknown', value: 'unknown' },
  ];

  const severityOptions = [
    { label: 'Select severity', value: '' },
    { label: 'Mild', value: 'mild' },
    { label: 'Moderate', value: 'moderate' },
    { label: 'Severe', value: 'severe' },
    { label: 'Varies', value: 'varies' },
  ];

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

  const anemiaOptions = [
    { label: 'Select severity', value: '' },
    { label: 'Mild', value: 'mild' },
    { label: 'Moderate', value: 'moderate' },
    { label: 'Severe', value: 'severe' },
  ];

  const giFrequencyOptions = [
    { label: 'Select frequency', value: '' },
    { label: 'Every 3 months', value: 'every_3_months' },
    { label: 'Every 6 months', value: 'every_6_months' },
    { label: 'Once a year', value: 'once_a_year' },
    { label: 'As needed', value: 'as_needed' },
    { label: 'I don\'t see a GI specialist', value: 'none' },
  ];

  const lastVisitOptions = [
    { label: 'Select timeframe', value: '' },
    { label: 'Within last month', value: 'last_month' },
    { label: '1-3 months ago', value: '1_3_months' },
    { label: '3-6 months ago', value: '3_6_months' },
    { label: '6-12 months ago', value: '6_12_months' },
    { label: 'More than a year ago', value: 'over_year' },
    { label: 'Never', value: 'never' },
  ];

  const flareFrequencyOptions = [
    { label: 'Select frequency', value: '' },
    { label: 'Never', value: 'never' },
    { label: 'Rarely (once a year)', value: 'rarely' },
    { label: 'Occasionally (2-3 times a year)', value: 'occasionally' },
    { label: 'Frequently (monthly)', value: 'frequently' },
    { label: 'Very frequently (weekly)', value: 'very_frequently' },
  ];

  const symptomOptions = [
    { label: 'Select symptom', value: '' },
    { label: 'Abdominal pain', value: 'abdominal_pain' },
    { label: 'Diarrhea', value: 'diarrhea' },
    { label: 'Constipation', value: 'constipation' },
    { label: 'Blood in stool', value: 'blood_in_stool' },
    { label: 'Fatigue', value: 'fatigue' },
    { label: 'Weight loss', value: 'weight_loss' },
    { label: 'Fever', value: 'fever' },
    { label: 'Joint pain', value: 'joint_pain' },
    { label: 'Skin problems', value: 'skin_problems' },
    { label: 'Eye problems', value: 'eye_problems' },
    { label: 'None', value: 'none' },
  ];

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
    { label: 'None', value: 'none' },
  ];

  const comorbidityOptions = [
    { label: 'Select comorbidity', value: '' },
    { label: 'Arthritis', value: 'arthritis' },
    { label: 'Diabetes', value: 'diabetes' },
    { label: 'Hypertension', value: 'hypertension' },
    { label: 'Asthma', value: 'asthma' },
    { label: 'Depression/Anxiety', value: 'depression_anxiety' },
    { label: 'Osteoporosis', value: 'osteoporosis' },
    { label: 'Liver disease', value: 'liver_disease' },
    { label: 'Kidney disease', value: 'kidney_disease' },
    { label: 'Heart disease', value: 'heart_disease' },
    { label: 'None', value: 'none' },
  ];

  // Assessment Form Helper Functions
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
        return diagnosis && diagnosisYear && diagnosisMonth;
      case 2:
        return takingMedications !== '';
      case 3:
        return isAnemic !== '' && giSpecialistFrequency !== '';
      case 4:
        return familyHistory !== '' && surgeryHistory !== '';
      default:
        return false;
    }
  };

  const nextStep = () => {
    if (validateStep(currentStep) && currentStep < totalSteps) {
      setCurrentStep(currentStep + 1);
    }
  };

  const prevStep = () => {
    if (currentStep > 1) {
      setCurrentStep(currentStep - 1);
    }
  };

  const handleSave = async () => {
    setIsLoading(true);
    try {
      const formData = {
        diagnosis,
        diagnosisYear,
        diagnosisMonth,
        diseaseLocation,
        diseaseBehavior,
        diseaseSeverity,
        takingMedications,
        currentMedications,
        medicationComplications,
        isAnemic,
        anemiaSeverity,
        giSpecialistFrequency,
        lastGiVisit,
        familyHistory,
        surgeryHistory,
        hospitalizations,
        flareFrequency,
        currentSymptoms,
        dietaryRestrictions,
        comorbidities,
      };

      const response = await fetch(`${API_BASE_URL}/diagnosis/${userData.username}`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(formData),
      });

      if (response.ok) {
        setShowSuccessModal(true);
        setTimeout(() => {
          setShowSuccessModal(false);
          setShowAssessmentForm(false);
          setCurrentStep(1);
        }, 2000);
      } else {
        const errorData = await response.json();
        setErrorMessage(errorData.message || 'Failed to save diagnosis information');
        setShowErrorModal(true);
      }
    } catch (error) {
      setErrorMessage('Network error. Please try again.');
      setShowErrorModal(true);
    } finally {
      setIsLoading(false);
    }
  };

  const handleCancel = () => {
    setShowAssessmentForm(false);
    setCurrentStep(1);
  };

  const renderStep1 = () => (
    <View style={styles.stepContainer}>
      <Title style={styles.stepTitle}>Basic Diagnosis Information</Title>
      
      <View style={styles.inputGroup}>
        <Text style={styles.label}>Primary Diagnosis *</Text>
        <View style={styles.pickerContainer}>
          <Picker
            selectedValue={diagnosis}
            onValueChange={setDiagnosis}
            style={styles.picker}
          >
            {diagnosisOptions.map((option) => (
              <Picker.Item key={option.value} label={option.label} value={option.value} />
            ))}
          </Picker>
        </View>
      </View>

      <View style={styles.row}>
        <View style={[styles.inputGroup, styles.halfWidth]}>
          <Text style={styles.label}>Diagnosis Year *</Text>
          <View style={styles.pickerContainer}>
            <Picker
              selectedValue={diagnosisYear}
              onValueChange={setDiagnosisYear}
              style={styles.picker}
            >
              {yearOptions.map((option) => (
                <Picker.Item key={option.value} label={option.label} value={option.value} />
              ))}
            </Picker>
          </View>
        </View>

        <View style={[styles.inputGroup, styles.halfWidth]}>
          <Text style={styles.label}>Diagnosis Month *</Text>
          <View style={styles.pickerContainer}>
            <Picker
              selectedValue={diagnosisMonth}
              onValueChange={setDiagnosisMonth}
              style={styles.picker}
            >
              {monthOptions.map((option) => (
                <Picker.Item key={option.value} label={option.label} value={option.value} />
              ))}
            </Picker>
          </View>
        </View>
      </View>

      <View style={styles.inputGroup}>
        <Text style={styles.label}>Disease Location</Text>
        <View style={styles.pickerContainer}>
          <Picker
            selectedValue={diseaseLocation}
            onValueChange={setDiseaseLocation}
            style={styles.picker}
          >
            {locationOptions.map((option) => (
              <Picker.Item key={option.value} label={option.label} value={option.value} />
            ))}
          </Picker>
        </View>
      </View>

      <View style={styles.row}>
        <View style={[styles.inputGroup, styles.halfWidth]}>
          <Text style={styles.label}>Disease Behavior</Text>
          <View style={styles.pickerContainer}>
            <Picker
              selectedValue={diseaseBehavior}
              onValueChange={setDiseaseBehavior}
              style={styles.picker}
            >
              {behaviorOptions.map((option) => (
                <Picker.Item key={option.value} label={option.label} value={option.value} />
              ))}
            </Picker>
          </View>
        </View>

        <View style={[styles.inputGroup, styles.halfWidth]}>
          <Text style={styles.label}>Disease Severity</Text>
          <View style={styles.pickerContainer}>
            <Picker
              selectedValue={diseaseSeverity}
              onValueChange={setDiseaseSeverity}
              style={styles.picker}
            >
              {severityOptions.map((option) => (
                <Picker.Item key={option.value} label={option.label} value={option.value} />
              ))}
            </Picker>
          </View>
        </View>
      </View>
    </View>
  );

  const renderStep2 = () => (
    <View style={styles.stepContainer}>
      <Title style={styles.stepTitle}>Medication Information</Title>
      
      <View style={styles.inputGroup}>
        <Text style={styles.label}>Are you currently taking medications? *</Text>
        <RadioButton.Group onValueChange={setTakingMedications} value={takingMedications}>
          <View style={styles.radioGroup}>
            <RadioButton.Item label="Yes" value="yes" />
            <RadioButton.Item label="No" value="no" />
            <RadioButton.Item label="Sometimes" value="sometimes" />
          </View>
        </RadioButton.Group>
      </View>

      {takingMedications === 'yes' && (
        <>
          <View style={styles.inputGroup}>
            <Text style={styles.label}>Current Medications</Text>
            <View style={styles.row}>
              <View style={styles.pickerContainer}>
                <Picker
                  selectedValue={selectedMedication}
                  onValueChange={setSelectedMedication}
                  style={styles.picker}
                >
                  {medicationOptions.map((option) => (
                    <Picker.Item key={option.value} label={option.label} value={option.value} />
                  ))}
                </Picker>
              </View>
              <Button mode="contained" onPress={addMedication} style={styles.addButton}>
                Add
              </Button>
            </View>
            {currentMedications.length > 0 && (
              <View style={styles.chipContainer}>
                {currentMedications.map((medication, index) => (
                  <Chip
                    key={index}
                    onClose={() => removeMedication(medication)}
                    style={styles.chip}
                  >
                    {medication}
                  </Chip>
                ))}
              </View>
            )}
          </View>

          <View style={styles.inputGroup}>
            <Text style={styles.label}>Medication Complications</Text>
            <View style={styles.row}>
              <View style={styles.pickerContainer}>
                <Picker
                  selectedValue={selectedComplication}
                  onValueChange={setSelectedComplication}
                  style={styles.picker}
                >
                  {complicationOptions.map((option) => (
                    <Picker.Item key={option.value} label={option.label} value={option.value} />
                  ))}
                </Picker>
              </View>
              <Button mode="contained" onPress={addComplication} style={styles.addButton}>
                Add
              </Button>
            </View>
            {medicationComplications.length > 0 && (
              <View style={styles.chipContainer}>
                {medicationComplications.map((complication, index) => (
                  <Chip
                    key={index}
                    onClose={() => removeComplication(complication)}
                    style={styles.chip}
                  >
                    {complication}
                  </Chip>
                ))}
              </View>
            )}
          </View>
        </>
      )}
    </View>
  );

  const renderStep3 = () => (
    <View style={styles.stepContainer}>
      <Title style={styles.stepTitle}>Health Status</Title>
      
      <View style={styles.inputGroup}>
        <Text style={styles.label}>Are you anemic? *</Text>
        <RadioButton.Group onValueChange={setIsAnemic} value={isAnemic}>
          <View style={styles.radioGroup}>
            <RadioButton.Item label="Yes" value="yes" />
            <RadioButton.Item label="No" value="no" />
            <RadioButton.Item label="Unknown" value="unknown" />
          </View>
        </RadioButton.Group>
      </View>

      {isAnemic === 'yes' && (
        <View style={styles.inputGroup}>
          <Text style={styles.label}>Anemia Severity</Text>
          <View style={styles.pickerContainer}>
            <Picker
              selectedValue={anemiaSeverity}
              onValueChange={setAnemiaSeverity}
              style={styles.picker}
            >
              {anemiaOptions.map((option) => (
                <Picker.Item key={option.value} label={option.label} value={option.value} />
              ))}
            </Picker>
          </View>
        </View>
      )}

      <View style={styles.inputGroup}>
        <Text style={styles.label}>How often do you see a GI specialist? *</Text>
        <View style={styles.pickerContainer}>
          <Picker
            selectedValue={giSpecialistFrequency}
            onValueChange={setGiSpecialistFrequency}
            style={styles.picker}
          >
            {giFrequencyOptions.map((option) => (
              <Picker.Item key={option.value} label={option.label} value={option.value} />
            ))}
          </Picker>
        </View>
      </View>

      <View style={styles.inputGroup}>
        <Text style={styles.label}>When was your last GI visit?</Text>
        <View style={styles.pickerContainer}>
          <Picker
            selectedValue={lastGiVisit}
            onValueChange={setLastGiVisit}
            style={styles.picker}
          >
            {lastVisitOptions.map((option) => (
              <Picker.Item key={option.value} label={option.label} value={option.value} />
            ))}
          </Picker>
        </View>
      </View>
    </View>
  );

  const renderStep4 = () => (
    <View style={styles.stepContainer}>
      <Title style={styles.stepTitle}>Additional Information</Title>
      
      <View style={styles.inputGroup}>
        <Text style={styles.label}>Family History of IBD *</Text>
        <RadioButton.Group onValueChange={setFamilyHistory} value={familyHistory}>
          <View style={styles.radioGroup}>
            <RadioButton.Item label="Yes" value="yes" />
            <RadioButton.Item label="No" value="no" />
            <RadioButton.Item label="Unknown" value="unknown" />
          </View>
        </RadioButton.Group>
      </View>

      <View style={styles.inputGroup}>
        <Text style={styles.label}>Previous IBD Surgery *</Text>
        <RadioButton.Group onValueChange={setSurgeryHistory} value={surgeryHistory}>
          <View style={styles.radioGroup}>
            <RadioButton.Item label="Yes" value="yes" />
            <RadioButton.Item label="No" value="no" />
            <RadioButton.Item label="Unknown" value="unknown" />
          </View>
        </RadioButton.Group>
      </View>

      <View style={styles.inputGroup}>
        <Text style={styles.label}>Hospitalizations for IBD</Text>
        <RadioButton.Group onValueChange={setHospitalizations} value={hospitalizations}>
          <View style={styles.radioGroup}>
            <RadioButton.Item label="Yes" value="yes" />
            <RadioButton.Item label="No" value="no" />
            <RadioButton.Item label="Unknown" value="unknown" />
          </View>
        </RadioButton.Group>
      </View>

      <View style={styles.inputGroup}>
        <Text style={styles.label}>Flare Frequency</Text>
        <View style={styles.pickerContainer}>
          <Picker
            selectedValue={flareFrequency}
            onValueChange={setFlareFrequency}
            style={styles.picker}
          >
            {flareFrequencyOptions.map((option) => (
              <Picker.Item key={option.value} label={option.label} value={option.value} />
            ))}
          </Picker>
        </View>
      </View>

      <View style={styles.inputGroup}>
        <Text style={styles.label}>Current Symptoms</Text>
        <View style={styles.row}>
          <View style={styles.pickerContainer}>
            <Picker
              selectedValue={selectedSymptom}
              onValueChange={setSelectedSymptom}
              style={styles.picker}
            >
              {symptomOptions.map((option) => (
                <Picker.Item key={option.value} label={option.label} value={option.value} />
              ))}
            </Picker>
          </View>
          <Button mode="contained" onPress={addSymptom} style={styles.addButton}>
            Add
          </Button>
        </View>
        {currentSymptoms.length > 0 && (
          <View style={styles.chipContainer}>
            {currentSymptoms.map((symptom, index) => (
              <Chip
                key={index}
                onClose={() => removeSymptom(symptom)}
                style={styles.chip}
              >
                {symptom}
              </Chip>
            ))}
          </View>
        )}
      </View>

      <View style={styles.inputGroup}>
        <Text style={styles.label}>Dietary Restrictions</Text>
        <View style={styles.row}>
          <View style={styles.pickerContainer}>
            <Picker
              selectedValue={selectedRestriction}
              onValueChange={setSelectedRestriction}
              style={styles.picker}
            >
              {restrictionOptions.map((option) => (
                <Picker.Item key={option.value} label={option.label} value={option.value} />
              ))}
            </Picker>
          </View>
          <Button mode="contained" onPress={addRestriction} style={styles.addButton}>
            Add
          </Button>
        </View>
        {dietaryRestrictions.length > 0 && (
          <View style={styles.chipContainer}>
            {dietaryRestrictions.map((restriction, index) => (
              <Chip
                key={index}
                onClose={() => removeRestriction(restriction)}
                style={styles.chip}
              >
                {restriction}
              </Chip>
            ))}
          </View>
        )}
      </View>

      <View style={styles.inputGroup}>
        <Text style={styles.label}>Comorbidities</Text>
        <View style={styles.row}>
          <View style={styles.pickerContainer}>
            <Picker
              selectedValue={selectedComorbidity}
              onValueChange={setSelectedComorbidity}
              style={styles.picker}
            >
              {comorbidityOptions.map((option) => (
                <Picker.Item key={option.value} label={option.label} value={option.value} />
              ))}
            </Picker>
          </View>
          <Button mode="contained" onPress={addComorbidity} style={styles.addButton}>
            Add
          </Button>
        </View>
        {comorbidities.length > 0 && (
          <View style={styles.chipContainer}>
            {comorbidities.map((comorbidity, index) => (
              <Chip
                key={index}
                onClose={() => removeComorbidity(comorbidity)}
                style={styles.chip}
              >
                {comorbidity}
              </Chip>
            ))}
          </View>
        )}
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

  const menuItems = [
    {
      title: 'My Diagnosis',
      description: 'Update your IBD diagnosis information',
      icon: 'medical-bag',
      onPress: () => setShowAssessmentForm(true),
    },
    {
      title: 'Profile Settings',
      description: 'Manage your account and preferences',
      icon: 'account-cog',
      onPress: () => handleFeaturePress('Profile Settings'),
    },
    {
      title: 'Data & Privacy',
      description: 'Manage your data and privacy settings',
      icon: 'shield-account',
      onPress: () => handleFeaturePress('Data & Privacy'),
    },
    {
      title: 'Notifications',
      description: 'Configure app notifications',
      icon: 'bell',
      onPress: () => handleFeaturePress('Notifications'),
    },
    {
      title: 'Help & Support',
      description: 'Get help and contact support',
      icon: 'help-circle',
      onPress: () => handleFeaturePress('Help & Support'),
    },
    {
      title: 'About IBDPal',
      description: 'Learn more about the app',
      icon: 'information',
      onPress: () => handleFeaturePress('About IBDPal'),
    },
  ];

  // Render Assessment Form
  if (showAssessmentForm) {
    return (
      <KeyboardAvoidingView 
        style={styles.container} 
        behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
      >
        <ScrollView 
          contentContainerStyle={styles.scrollContainer}
          showsVerticalScrollIndicator={false}
          keyboardShouldPersistTaps="handled"
        >
          <Surface style={styles.surface}>
            <View style={styles.header}>
              <Title style={styles.title}>My Diagnosis Assessment</Title>
              <Paragraph style={styles.subtitle}>
                Step {currentStep} of {totalSteps}
              </Paragraph>
            </View>

            {/* Progress Bar */}
            <View style={styles.progressContainer}>
              <View style={styles.progressBar}>
                <View 
                  style={[
                    styles.progressFill, 
                    { width: `${(currentStep / totalSteps) * 100}%` }
                  ]} 
                />
              </View>
            </View>

            <View style={styles.content}>
              {renderCurrentStep()}
            </View>

            {/* Navigation Buttons */}
            <View style={styles.navigationContainer}>
              <View style={styles.buttonRow}>
                <Button
                  mode="outlined"
                  onPress={handleCancel}
                  style={styles.navButton}
                  textColor={colors.error}
                >
                  Cancel
                </Button>
                
                {currentStep > 1 && (
                  <Button
                    mode="outlined"
                    onPress={prevStep}
                    style={styles.navButton}
                  >
                    Back
                  </Button>
                )}
                
                {currentStep < totalSteps ? (
                  <Button
                    mode="contained"
                    onPress={nextStep}
                    style={styles.navButton}
                    disabled={!validateStep(currentStep)}
                  >
                    Next
                  </Button>
                ) : (
                  <Button
                    mode="contained"
                    onPress={handleSave}
                    style={styles.navButton}
                    disabled={!validateStep(currentStep) || isLoading}
                    loading={isLoading}
                  >
                    Save
                  </Button>
                )}
              </View>
            </View>
          </Surface>
        </ScrollView>

        {/* Success Modal */}
        <CustomModal
          visible={showSuccessModal}
          onClose={() => setShowSuccessModal(false)}
          title="Success"
          message="Your diagnosis information has been saved successfully!"
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
  }

  // Render Regular More Screen
  return (
    <View style={styles.container}>
      <ScrollView contentContainerStyle={styles.scrollContainer}>
        <Surface style={styles.surface}>
          <View style={styles.header}>
            <Title style={styles.title}>More</Title>
            <Paragraph style={styles.subtitle}>
              Settings and additional features
            </Paragraph>
          </View>

          <View style={styles.content}>
            {/* User Profile Card */}
            <Card style={styles.card}>
              <Card.Content>
                <View style={styles.profileSection}>
                  <View style={styles.profileInfo}>
                    <Title style={styles.userName}>
                      {userData?.firstName} {userData?.lastName}
                    </Title>
                    <Paragraph style={styles.userEmail}>
                      {userData?.email}
                    </Paragraph>
                  </View>
                  <Button
                    mode="outlined"
                    onPress={() => handleFeaturePress('Profile Settings')}
                    compact
                  >
                    Edit
                  </Button>
                </View>
              </Card.Content>
            </Card>

            {/* Menu Items */}
            <Card style={styles.card}>
              <Card.Content>
                {menuItems.map((item, index) => (
                  <React.Fragment key={index}>
                    <List.Item
                      title={item.title}
                      description={item.description}
                      left={(props) => <List.Icon {...props} icon={item.icon} />}
                      right={(props) => <List.Icon {...props} icon="chevron-right" />}
                      onPress={item.onPress}
                      style={styles.menuItem}
                    />
                    {index < menuItems.length - 1 && (
                      <Divider style={styles.divider} />
                    )}
                  </React.Fragment>
                ))}
              </Card.Content>
            </Card>

            {/* App Information */}
            <Card style={styles.card}>
              <Card.Content>
                <Title style={styles.cardTitle}>App Information</Title>
                <View style={styles.infoItem}>
                  <Text style={styles.infoLabel}>Version:</Text>
                  <Text style={styles.infoValue}>1.0.0</Text>
                </View>
                <View style={styles.infoItem}>
                  <Text style={styles.infoLabel}>Last Updated:</Text>
                  <Text style={styles.infoValue}>July 2024</Text>
                </View>
                <View style={styles.infoItem}>
                  <Text style={styles.infoLabel}>Developer:</Text>
                  <Text style={styles.infoValue}>IBDPal Team</Text>
                </View>
              </Card.Content>
            </Card>

            {/* Logout Button */}
            <Button
              mode="outlined"
              onPress={() => setShowLogoutModal(true)}
              style={styles.logoutButton}
              textColor={colors.error}
              icon="logout"
            >
              Sign Out
            </Button>
          </View>
        </Surface>
      </ScrollView>

      {/* Logout Confirmation Modal */}
      <CustomModal
        visible={showLogoutModal}
        onClose={() => setShowLogoutModal(false)}
        title="Sign Out"
        message="Are you sure you want to sign out? You'll need to sign in again to access your data."
        buttonText="Sign Out"
        onButtonPress={handleLogout}
      />

      {/* Feature Coming Soon Modal */}
      <CustomModal
        visible={showFeatureModal}
        onClose={() => setShowFeatureModal(false)}
        title="Coming Soon"
        message={featureMessage}
      />
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
  profileSection: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  profileInfo: {
    flex: 1,
  },
  userName: {
    fontSize: 20,
    fontWeight: 'bold',
    color: colors.primary,
    marginBottom: 4,
  },
  userEmail: {
    fontSize: 14,
    color: colors.placeholder,
  },
  menuItem: {
    paddingVertical: 8,
  },
  divider: {
    marginVertical: 4,
  },
  cardTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    color: colors.primary,
    marginBottom: 16,
  },
  infoItem: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: 8,
  },
  infoLabel: {
    fontSize: 16,
    color: colors.text,
  },
  infoValue: {
    fontSize: 16,
    color: colors.primary,
    fontWeight: 'bold',
  },
  logoutButton: {
    marginTop: 24,
    borderColor: colors.error,
  },
  // Assessment Form Styles
  stepContainer: {
    marginBottom: 24,
  },
  stepTitle: {
    fontSize: 20,
    fontWeight: 'bold',
    color: colors.primary,
    marginBottom: 16,
  },
  inputGroup: {
    marginBottom: 20,
  },
  label: {
    fontSize: 16,
    fontWeight: '600',
    color: colors.text,
    marginBottom: 8,
  },
  pickerContainer: {
    borderWidth: 1,
    borderColor: colors.border,
    borderRadius: 8,
    backgroundColor: colors.surface,
  },
  picker: {
    height: 50,
  },
  row: {
    flexDirection: 'row',
    justifyContent: 'space-between',
  },
  halfWidth: {
    width: '48%',
  },
  radioGroup: {
    marginTop: 8,
  },
  chipContainer: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    marginTop: 8,
  },
  chip: {
    margin: 4,
  },
  addButton: {
    marginLeft: 8,
    height: 50,
    justifyContent: 'center',
  },
  progressContainer: {
    marginBottom: 24,
  },
  progressBar: {
    height: 8,
    backgroundColor: colors.border,
    borderRadius: 4,
    overflow: 'hidden',
  },
  progressFill: {
    height: '100%',
    backgroundColor: colors.primary,
    borderRadius: 4,
  },
  navigationContainer: {
    marginTop: 24,
  },
  buttonRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  navButton: {
    flex: 1,
    marginHorizontal: 4,
  },
});

export default MoreScreen; 