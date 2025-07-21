const fetch = require('node-fetch').default;

async function testLogin() {
  const API_BASE_URL = 'http://localhost:3004/api';
  const testEmail = 'aryan.skumar17@gmail.com';
  
  console.log('Testing IBDPal Login for:', testEmail);
  console.log('='.repeat(50));
  
  // Test 1: Try to login with the email
  console.log('\nTest 1: Attempting login...');
  try {
    const response = await fetch(`${API_BASE_URL}/auth/login`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        email: testEmail,
        password: 'password123', // Common test password
      }),
    });

    const data = await response.json();
    
    console.log('Response Status:', response.status);
    console.log('Response Data:', JSON.stringify(data, null, 2));
    
    if (response.status === 200) {
      console.log('✅ SUCCESS: Login successful');
      console.log('User ID:', data.user.id);
      console.log('Token received:', data.token ? 'Yes' : 'No');
    } else if (response.status === 401) {
      console.log('❌ FAILED: Authentication failed');
      console.log('Error:', data.message);
    } else {
      console.log('❌ UNEXPECTED: Unexpected response');
    }
    
  } catch (error) {
    console.error('❌ ERROR:', error.message);
  }
  
  console.log('\n' + '='.repeat(50) + '\n');
  
  // Test 2: Try to register the user if login fails
  console.log('Test 2: Attempting registration if user doesn\'t exist...');
  try {
    const response = await fetch(`${API_BASE_URL}/auth/register`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        email: testEmail,
        password: 'password123',
        confirmPassword: 'password123',
        firstName: 'Aryan',
        lastName: 'Kumar',
        agreeToTerms: true,
      }),
    });

    const data = await response.json();
    
    console.log('Registration Response Status:', response.status);
    console.log('Registration Response Data:', JSON.stringify(data, null, 2));
    
    if (response.status === 201) {
      console.log('✅ SUCCESS: User registered successfully');
    } else if (response.status === 409) {
      console.log('ℹ️ INFO: User already exists');
    } else {
      console.log('❌ FAILED: Registration failed');
    }
    
  } catch (error) {
    console.error('❌ ERROR:', error.message);
  }
}

testLogin(); 