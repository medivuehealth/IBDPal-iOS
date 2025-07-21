const fetch = require('node-fetch').default;

async function testRegistration() {
  const API_BASE_URL = 'http://localhost:3004/api';
  
  console.log('Testing IBDPal Registration Endpoint...\n');
  
  // Test 1: Try to register with a duplicate email
  console.log('Test 1: Registering with duplicate email...');
  try {
    const response = await fetch(`${API_BASE_URL}/auth/register`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        email: 'test@example.com',
        password: 'password123',
        confirmPassword: 'password123',
        firstName: 'Test',
        lastName: 'User',
        agreeToTerms: true,
      }),
    });

    const data = await response.json();
    
    console.log('Response Status:', response.status);
    console.log('Response Data:', JSON.stringify(data, null, 2));
    
    if (response.status === 409) {
      console.log('✅ SUCCESS: Backend correctly returns 409 for duplicate email');
    } else {
      console.log('❌ FAILED: Backend should return 409 for duplicate email');
    }
    
  } catch (error) {
    console.error('❌ ERROR:', error.message);
  }
  
  console.log('\n' + '='.repeat(50) + '\n');
  
  // Test 2: Try to register with a new email
  console.log('Test 2: Registering with new email...');
  try {
    const newEmail = `test${Date.now()}@example.com`;
    const response = await fetch(`${API_BASE_URL}/auth/register`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        email: newEmail,
        password: 'password123',
        confirmPassword: 'password123',
        firstName: 'Test',
        lastName: 'User',
        agreeToTerms: true,
      }),
    });

    const data = await response.json();
    
    console.log('Response Status:', response.status);
    console.log('Response Data:', JSON.stringify(data, null, 2));
    
    if (response.status === 201) {
      console.log('✅ SUCCESS: Backend correctly creates new user');
    } else {
      console.log('❌ FAILED: Backend should return 201 for new user');
    }
    
  } catch (error) {
    console.error('❌ ERROR:', error.message);
  }
}

testRegistration(); 