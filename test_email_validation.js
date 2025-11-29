// Test email validation for App Store review issue
console.log('🧪 Testing Email Validation for info@ibdpal.org');

const testEmail = 'info@ibdpal.org';

// Test the regex pattern used in LoginScreen.js
const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
const isValid = emailRegex.test(testEmail);

console.log('📧 Test Results:');
console.log('  Email:', testEmail);
console.log('  Regex pattern:', emailRegex.toString());
console.log('  Is valid:', isValid);
console.log('  Email length:', testEmail.length);
console.log('  Email char codes:', testEmail.split('').map(c => c.charCodeAt(0)));

// Test with trimmed version
const trimmedEmail = testEmail.trim();
const isTrimmedValid = emailRegex.test(trimmedEmail);
console.log('  Trimmed email:', trimmedEmail);
console.log('  Trimmed is valid:', isTrimmedValid);

// Test the old regex pattern for comparison
const oldRegex = /\S+@\S+\.\S+/;
const isOldValid = oldRegex.test(testEmail);
console.log('  Old regex result:', isOldValid);

if (isValid) {
  console.log('✅ Email validation should work correctly');
} else {
  console.log('❌ Email validation is failing - this is the issue!');
}









