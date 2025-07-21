const https = require('https');
const { exec } = require('child_process');

console.log('🧪 Testing Railway connection through Charles Proxy...');
console.log('🔗 Target URL: https://ibdpal-server-production.up.railway.app');
console.log('🔧 Proxy: 127.0.0.1:8888');

// Test with curl through Charles proxy
console.log('\n📡 Testing with curl through Charles proxy...');
const curlCommand = `curl -x 127.0.0.1:8888 -k https://ibdpal-server-production.up.railway.app/api/health`;
exec(curlCommand, (error, stdout, stderr) => {
    if (error) {
        console.log(`❌ Curl through Charles failed: ${error.message}`);
        console.log('\n💡 Instructions:');
        console.log('1. Make sure Charles is running');
        console.log('2. In Charles, go to Proxy → SSL Proxying Settings');
        console.log('3. Check "Enable SSL Proxying"');
        console.log('4. Add location: *.up.railway.app with port 443');
        console.log('5. Try again');
        return;
    }
    if (stderr) {
        console.log(`⚠️  Curl stderr: ${stderr}`);
    }
    console.log(`✅ Charles proxy working!`);
    console.log(`📄 Response: ${stdout}`);
});

// Test direct connection for comparison
console.log('\n📡 Testing direct connection...');
const directCommand = `curl -k https://ibdpal-server-production.up.railway.app/api/health`;
exec(directCommand, (error, stdout, stderr) => {
    if (error) {
        console.log(`❌ Direct connection failed: ${error.message}`);
    } else {
        console.log(`✅ Direct connection working`);
        console.log(`📄 Response: ${stdout}`);
    }
}); 