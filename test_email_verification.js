const axios = require('axios');

// Configuration
const BASE_URL = process.env.API_BASE_URL || 'http://localhost:3004/api';
const TEST_EMAIL = `test_${Date.now()}@example.com`;
const TEST_PASSWORD = 'TestPassword123!';

console.log('🧪 Testing Email Verification System...');
console.log(`📧 Test Email: ${TEST_EMAIL}`);
console.log(`🔗 Base URL: ${BASE_URL}`);

let userId = null;
let verificationCode = null;

async function testRegistration() {
    console.log('\n📝 Step 1: Testing Registration...');
    
    try {
        const response = await axios.post(`${BASE_URL}/auth/register`, {
            email: TEST_EMAIL,
            password: TEST_PASSWORD,
            confirmPassword: TEST_PASSWORD,
            firstName: 'Test',
            lastName: 'User',
            agreeToTerms: true
        });

        console.log('✅ Registration successful!');
        console.log('📊 Response:', {
            message: response.data.message,
            requiresVerification: response.data.requiresVerification,
            userId: response.data.user.id
        });

        userId = response.data.user.id;
        
        // Check if verification is required
        if (response.data.requiresVerification) {
            console.log('📧 Email verification required - this is expected!');
        } else {
            console.log('⚠️  No verification required - this might be unexpected');
        }

        return true;
    } catch (error) {
        console.error('❌ Registration failed:', error.response?.data || error.message);
        return false;
    }
}

async function testLoginWithoutVerification() {
    console.log('\n🔐 Step 2: Testing Login Without Verification...');
    
    try {
        const response = await axios.post(`${BASE_URL}/auth/login`, {
            email: TEST_EMAIL,
            password: TEST_PASSWORD
        });

        console.log('❌ Login succeeded without verification - this should not happen!');
        return false;
    } catch (error) {
        if (error.response?.status === 401 && error.response?.data?.requiresVerification) {
            console.log('✅ Login correctly blocked - verification required');
            console.log('📊 Error response:', error.response.data);
            return true;
        } else {
            console.error('❌ Unexpected error during login test:', error.response?.data || error.message);
            return false;
        }
    }
}

async function testResendVerification() {
    console.log('\n📧 Step 3: Testing Resend Verification...');
    
    try {
        const response = await axios.post(`${BASE_URL}/auth/resend-verification`, {
            email: TEST_EMAIL
        });

        console.log('✅ Resend verification successful!');
        console.log('📊 Response:', response.data);
        return true;
    } catch (error) {
        console.error('❌ Resend verification failed:', error.response?.data || error.message);
        return false;
    }
}

async function testInvalidVerification() {
    console.log('\n❌ Step 4: Testing Invalid Verification Code...');
    
    try {
        const response = await axios.post(`${BASE_URL}/auth/verify-email`, {
            email: TEST_EMAIL,
            verificationCode: '000000',
            userData: {}
        });

        console.log('❌ Invalid verification succeeded - this should not happen!');
        return false;
    } catch (error) {
        if (error.response?.status === 400) {
            console.log('✅ Invalid verification correctly rejected');
            console.log('📊 Error response:', error.response.data);
            return true;
        } else {
            console.error('❌ Unexpected error during invalid verification test:', error.response?.data || error.message);
            return false;
        }
    }
}

async function cleanup() {
    console.log('\n🧹 Step 5: Cleanup...');
    
    // Note: In a real scenario, you might want to delete the test user
    // For now, we'll just log that cleanup is needed
    console.log('⚠️  Test user created for testing. Consider cleaning up manually if needed.');
    console.log(`📧 Test email: ${TEST_EMAIL}`);
}

async function runTests() {
    console.log('🚀 Starting Email Verification Tests...\n');
    
    const results = {
        registration: await testRegistration(),
        loginWithoutVerification: await testLoginWithoutVerification(),
        resendVerification: await testResendVerification(),
        invalidVerification: await testInvalidVerification()
    };

    console.log('\n📊 Test Results Summary:');
    console.log('========================');
    Object.entries(results).forEach(([test, passed]) => {
        console.log(`${passed ? '✅' : '❌'} ${test}: ${passed ? 'PASSED' : 'FAILED'}`);
    });

    const allPassed = Object.values(results).every(result => result);
    
    if (allPassed) {
        console.log('\n🎉 All tests passed! Email verification system is working correctly.');
    } else {
        console.log('\n⚠️  Some tests failed. Please check the implementation.');
    }

    await cleanup();
    
    return allPassed;
}

// Run the tests
runTests().catch(error => {
    console.error('💥 Test runner failed:', error);
    process.exit(1);
}); 