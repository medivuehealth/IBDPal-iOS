const fetch = require('node-fetch').default;

async function createUser() {
  const API_BASE_URL = 'http://localhost:3004/api';
  const email = 'aryan.skumar17@gmail.com';
  
  console.log('Creating user:', email);
  console.log('='.repeat(50));
  
  try {
    const response = await fetch(`${API_BASE_URL}/auth/register`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        email: email,
        password: 'password123',
        confirmPassword: 'password123',
        firstName: 'Aryan',
        lastName: 'Kumar',
        agreeToTerms: true,
      }),
    });

    const data = await response.json();
    
    console.log('Response Status:', response.status);
    console.log('Response Data:', JSON.stringify(data, null, 2));
    
    if (response.status === 201) {
      console.log('✅ SUCCESS: User created successfully');
      console.log('User ID:', data.user.id);
      console.log('Token:', data.token ? 'Received' : 'Not received');
      
      console.log('\n' + '='.repeat(50));
      console.log('Now testing login...');
      
      // Test login immediately
      const loginResponse = await fetch(`${API_BASE_URL}/auth/login`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          email: email,
          password: 'password123',
        }),
      });

      const loginData = await loginResponse.json();
      
      console.log('Login Response Status:', loginResponse.status);
      console.log('Login Response Data:', JSON.stringify(loginData, null, 2));
      
      if (loginResponse.status === 200) {
        console.log('✅ SUCCESS: Login works after registration');
      } else {
        console.log('❌ FAILED: Login failed after registration');
      }
      
    } else if (response.status === 409) {
      console.log('ℹ️ INFO: User already exists, trying to login...');
      
      // Try login with the existing user
      const loginResponse = await fetch(`${API_BASE_URL}/auth/login`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          email: email,
          password: 'password123',
        }),
      });

      const loginData = await loginResponse.json();
      
      console.log('Login Response Status:', loginResponse.status);
      console.log('Login Response Data:', JSON.stringify(loginData, null, 2));
      
      if (loginResponse.status === 200) {
        console.log('✅ SUCCESS: Login successful with existing user');
      } else {
        console.log('❌ FAILED: Login failed with existing user');
        console.log('You may need to reset the password or use a different password');
      }
      
    } else {
      console.log('❌ FAILED: Registration failed');
    }
    
  } catch (error) {
    console.error('❌ ERROR:', error.message);
  }
}

createUser(); 