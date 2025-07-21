const https = require('https');
const http = require('http');

// Test configuration
const RAILWAY_URL = 'https://ibdpal-server-production.up.railway.app';
const PROXY_HOST = '127.0.0.1';
const PROXY_PORT = 9090;

console.log('🧪 Testing Railway connection through Proxyman...');
console.log(`🔗 Target URL: ${RAILWAY_URL}`);
console.log(`🔧 Proxy: ${PROXY_HOST}:${PROXY_PORT}`);

// Test 1: Direct HTTPS connection (should fail with SSL)
console.log('\n📡 Test 1: Direct HTTPS connection (should fail with SSL)');
const directRequest = https.get(RAILWAY_URL, (res) => {
    console.log(`✅ Direct connection successful! Status: ${res.statusCode}`);
    let data = '';
    res.on('data', chunk => data += chunk);
    res.on('end', () => {
        console.log('📄 Response:', data.substring(0, 200) + '...');
    });
}).on('error', (err) => {
    console.log(`❌ Direct connection failed: ${err.message}`);
});

// Test 2: HTTP connection (should redirect to HTTPS)
console.log('\n📡 Test 2: HTTP connection (should redirect)');
const httpUrl = RAILWAY_URL.replace('https://', 'http://');
const httpRequest = http.get(httpUrl, (res) => {
    console.log(`✅ HTTP connection successful! Status: ${res.statusCode}`);
    console.log(`📍 Redirected to: ${res.headers.location || 'No redirect'}`);
}).on('error', (err) => {
    console.log(`❌ HTTP connection failed: ${err.message}`);
});

// Test 3: Test with curl through proxy
console.log('\n📡 Test 3: Testing with curl through proxy...');
const { exec } = require('child_process');

const curlCommand = `curl -x ${PROXY_HOST}:${PROXY_PORT} -k ${RAILWAY_URL}/api/health`;
exec(curlCommand, (error, stdout, stderr) => {
    if (error) {
        console.log(`❌ Curl through proxy failed: ${error.message}`);
        return;
    }
    if (stderr) {
        console.log(`⚠️  Curl stderr: ${stderr}`);
    }
    console.log(`✅ Curl through proxy successful!`);
    console.log(`📄 Response: ${stdout}`);
});

// Test 4: Test with curl without proxy (for comparison)
console.log('\n📡 Test 4: Testing with curl without proxy...');
const curlDirectCommand = `curl -k ${RAILWAY_URL}/api/health`;
exec(curlDirectCommand, (error, stdout, stderr) => {
    if (error) {
        console.log(`❌ Direct curl failed: ${error.message}`);
        return;
    }
    if (stderr) {
        console.log(`⚠️  Direct curl stderr: ${stderr}`);
    }
    console.log(`✅ Direct curl successful!`);
    console.log(`📄 Response: ${stdout}`);
});

console.log('\n🔍 Instructions:');
console.log('1. Make sure Proxyman is running and listening on port 9090');
console.log('2. Check Proxyman interface for captured requests');
console.log('3. If you see SSL errors, Proxyman should handle them automatically');
console.log('4. The iOS app should now work through Proxyman proxy'); 