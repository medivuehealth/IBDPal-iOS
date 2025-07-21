const fs = require('fs');
const path = require('path');

console.log('IBDPal Build 18 Configuration Test');
console.log('===================================');

// Test 1: Check app.json configuration
console.log('\n1. Checking app.json...');
try {
  const appJson = JSON.parse(fs.readFileSync('app.json', 'utf8'));
  const iosConfig = appJson.expo.ios;
  
  if (iosConfig.buildNumber === '18') {
    console.log('✅ Build number is correctly set to 18');
  } else {
    console.log('❌ Build number is not set to 18');
  }
  
  if (iosConfig.bundleIdentifier) {
    console.log('✅ Bundle identifier is set:', iosConfig.bundleIdentifier);
  } else {
    console.log('❌ Bundle identifier is missing');
  }
  
  if (iosConfig.infoPlist && iosConfig.infoPlist.ITSAppUsesNonExemptEncryption === false) {
    console.log('✅ Encryption configuration is correct');
  } else {
    console.log('❌ Encryption configuration is missing or incorrect');
  }
} catch (error) {
  console.log('❌ Error reading app.json:', error.message);
}

// Test 2: Check package.json
console.log('\n2. Checking package.json...');
try {
  const packageJson = JSON.parse(fs.readFileSync('package.json', 'utf8'));
  
  if (packageJson.name === 'ibdpal') {
    console.log('✅ Package name is correct');
  } else {
    console.log('❌ Package name is incorrect');
  }
  
  if (packageJson.version === '1.0.0') {
    console.log('✅ Version is correct');
  } else {
    console.log('❌ Version is incorrect');
  }
  
  const requiredDeps = ['expo', 'react', 'react-native', '@react-navigation/native'];
  const missingDeps = requiredDeps.filter(dep => !packageJson.dependencies[dep]);
  
  if (missingDeps.length === 0) {
    console.log('✅ All required dependencies are present');
  } else {
    console.log('❌ Missing dependencies:', missingDeps.join(', '));
  }
} catch (error) {
  console.log('❌ Error reading package.json:', error.message);
}

// Test 3: Check critical files exist
console.log('\n3. Checking critical files...');
const criticalFiles = [
  'App.js',
  'src/screens/LoginScreen.js',
  'src/screens/HomeScreen.js',
  'src/theme.js',
  'src/config.js',
  'assets/icon.png'
];

criticalFiles.forEach(file => {
  if (fs.existsSync(file)) {
    console.log(`✅ ${file} exists`);
  } else {
    console.log(`❌ ${file} is missing`);
  }
});

// Test 4: Check EAS configuration
console.log('\n4. Checking EAS configuration...');
try {
  const easJson = JSON.parse(fs.readFileSync('eas.json', 'utf8'));
  
  if (easJson.build && easJson.build.preview) {
    console.log('✅ EAS preview build configuration exists');
  } else {
    console.log('❌ EAS preview build configuration is missing');
  }
  
  if (easJson.build && easJson.build.production) {
    console.log('✅ EAS production build configuration exists');
  } else {
    console.log('❌ EAS production build configuration is missing');
  }
} catch (error) {
  console.log('❌ Error reading eas.json:', error.message);
}

console.log('\n===================================');
console.log('Build 18 Configuration Test Complete');
console.log('==================================='); 