const https = require('https');
const http = require('http');

// Railway server URL
const RAILWAY_URL = 'https://ibdpal-server-production.up.railway.app';

// Test data
const testUser = {
    username: 'testuser_' + Date.now(),
    email: `test${Date.now()}@example.com`,
    password: 'testpass123',
    confirmPassword: 'testpass123',
    firstName: 'Test',
    lastName: 'User',
    agreeToTerms: true
};

// Helper function to make HTTPS requests
function makeRequest(url, options = {}) {
    return new Promise((resolve, reject) => {
        const urlObj = new URL(url);
        
        const requestOptions = {
            hostname: urlObj.hostname,
            port: urlObj.port || 443,
            path: urlObj.pathname + urlObj.search,
            method: options.method || 'GET',
            headers: {
                'Content-Type': 'application/json',
                ...options.headers
            }
        };

        const client = urlObj.protocol === 'https:' ? https : http;
        
        const req = client.request(requestOptions, (res) => {
            let data = '';
            
            res.on('data', (chunk) => {
                data += chunk;
            });
            
            res.on('end', () => {
                try {
                    const jsonData = JSON.parse(data);
                    resolve({
                        statusCode: res.statusCode,
                        headers: res.headers,
                        data: jsonData
                    });
                } catch (error) {
                    resolve({
                        statusCode: res.statusCode,
                        headers: res.headers,
                        data: data
                    });
                }
            });
        });

        req.on('error', (error) => {
            reject(error);
        });

        if (options.body) {
            req.write(JSON.stringify(options.body));
        }

        req.end();
    });
}

// Test functions
async function testHealthCheck() {
    console.log('🏥 Testing Health Check...');
    try {
        const response = await makeRequest(`${RAILWAY_URL}/api/health`);
        console.log('✅ Health Check Response:', response);
        return response.statusCode === 200;
    } catch (error) {
        console.log('❌ Health Check Failed:', error.message);
        return false;
    }
}

async function testRegistration() {
    console.log('📝 Testing User Registration...');
    try {
        const response = await makeRequest(`${RAILWAY_URL}/api/auth/register`, {
            method: 'POST',
            body: testUser
        });
        console.log('✅ Registration Response:', response);
        return response.statusCode === 200 || response.statusCode === 201;
    } catch (error) {
        console.log('❌ Registration Failed:', error.message);
        return false;
    }
}

async function testLogin() {
    console.log('🔐 Testing User Login...');
    try {
        const response = await makeRequest(`${RAILWAY_URL}/api/auth/login`, {
            method: 'POST',
            body: {
                email: testUser.email,
                password: testUser.password
            }
        });
        console.log('✅ Login Response:', response);
        return response.statusCode === 200;
    } catch (error) {
        console.log('❌ Login Failed:', error.message);
        return false;
    }
}

async function testSSLConnection() {
    console.log('🔒 Testing SSL Connection...');
    try {
        const url = new URL(RAILWAY_URL);
        const options = {
            hostname: url.hostname,
            port: 443,
            path: '/api/health',
            method: 'GET'
        };

        return new Promise((resolve) => {
            const req = https.request(options, (res) => {
                console.log('✅ SSL Connection Successful');
                console.log('Status Code:', res.statusCode);
                console.log('Headers:', res.headers);
                resolve(true);
            });

            req.on('error', (error) => {
                console.log('❌ SSL Connection Failed:', error.message);
                resolve(false);
            });

            req.end();
        });
    } catch (error) {
        console.log('❌ SSL Test Failed:', error.message);
        return false;
    }
}

// Main test function
async function runTests() {
    console.log('🚀 Starting Railway Server Tests...\n');
    
    // Test 1: SSL Connection
    const sslTest = await testSSLConnection();
    console.log('');
    
    // Test 2: Health Check
    const healthTest = await testHealthCheck();
    console.log('');
    
    // Test 3: Registration
    const registrationTest = await testRegistration();
    console.log('');
    
    // Test 4: Login
    const loginTest = await testLogin();
    console.log('');
    
    // Summary
    console.log('📊 Test Results Summary:');
    console.log('SSL Connection:', sslTest ? '✅ PASS' : '❌ FAIL');
    console.log('Health Check:', healthTest ? '✅ PASS' : '❌ FAIL');
    console.log('Registration:', registrationTest ? '✅ PASS' : '❌ FAIL');
    console.log('Login:', loginTest ? '✅ PASS' : '❌ FAIL');
    
    if (sslTest && healthTest && registrationTest && loginTest) {
        console.log('\n🎉 All tests passed! Railway server is working correctly.');
    } else {
        console.log('\n⚠️  Some tests failed. Check the errors above.');
    }
}

// Run the tests
runTests().catch(console.error); 