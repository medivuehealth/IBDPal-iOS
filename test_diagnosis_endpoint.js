const fetch = require('node-fetch');

const API_BASE_URL = 'http://localhost:3001/api';

// Test diagnosis data
const testDiagnosisData = {
  user_id: 'test_user_123',
  diagnosis_date: '2020-03-15',
  ibd_type: 'crohns',
  disease_location: 'small_intestine',
  disease_behavior: 'inflammatory',
  disease_activity: 'moderate',
  current_medications: 'biologics,steroids',
  medication_complications: 'fatigue,headaches',
  is_anemic: true,
  anemia_severity: 'mild',
  gi_specialist_frequency: 'every_6_months',
  last_gi_visit: '3_6_months',
  family_history: 'yes',
  surgery_history: 'no',
  hospitalizations_count: 2,
  flare_frequency: 'occasionally',
  current_symptoms: 'abdominal_pain,diarrhea,fatigue',
  dietary_restrictions: 'gluten_free,low_fodmap',
  comorbidities: 'arthritis,depression_anxiety',
  created_at: new Date().toISOString(),
  updated_at: new Date().toISOString()
};

async function testDiagnosisEndpoint() {
  try {
    console.log('Testing diagnosis endpoint...');
    
    // First, we need to authenticate (this would normally be done through login)
    // For testing purposes, we'll assume we have a valid token
    const authToken = 'test_token'; // In real app, this would come from login
    
    const response = await fetch(`${API_BASE_URL}/users/diagnosis`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${authToken}`
      },
      body: JSON.stringify(testDiagnosisData)
    });

    if (response.ok) {
      const result = await response.json();
      console.log('✅ Diagnosis saved successfully:', result);
    } else {
      const error = await response.json();
      console.log('❌ Error saving diagnosis:', error);
    }
  } catch (error) {
    console.error('❌ Test failed:', error.message);
  }
}

// Test GET diagnosis endpoint
async function testGetDiagnosis() {
  try {
    console.log('\nTesting GET diagnosis endpoint...');
    
    const authToken = 'test_token';
    
    const response = await fetch(`${API_BASE_URL}/users/diagnosis`, {
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${authToken}`
      }
    });

    if (response.ok) {
      const result = await response.json();
      console.log('✅ Diagnosis retrieved successfully:', result);
    } else {
      const error = await response.json();
      console.log('❌ Error retrieving diagnosis:', error);
    }
  } catch (error) {
    console.error('❌ Test failed:', error.message);
  }
}

// Run tests
async function runTests() {
  console.log('🧪 Testing IBDPal Diagnosis Endpoints\n');
  
  await testDiagnosisEndpoint();
  await testGetDiagnosis();
  
  console.log('\n✅ Tests completed!');
}

runTests(); 