// Test simplified email validation for App Store review issue
console.log('🧪 Testing Simplified Email Validation for info@ibdpal.org');

const testEmail = 'info@ibdpal.org';

// Clean the email input thoroughly
const cleanEmail = testEmail.trim().replace(/[\u200B-\u200D\uFEFF]/g, '');

console.log('📧 Test Results:');
console.log('  Raw email:', `"${testEmail}"`);
console.log('  Cleaned email:', `"${cleanEmail}"`);
console.log('  Email length:', testEmail.length);
console.log('  Cleaned length:', cleanEmail.length);

// Use the most permissive email validation for App Store compatibility
const hasAtSymbol = cleanEmail.includes('@');
const hasDotAfterAt = cleanEmail.indexOf('@') > 0 && cleanEmail.indexOf('.', cleanEmail.indexOf('@')) > cleanEmail.indexOf('@');
const hasTextBeforeAt = cleanEmail.indexOf('@') > 0;
const hasTextAfterDot = cleanEmail.lastIndexOf('.') < cleanEmail.length - 1;

console.log('  Has @ symbol:', hasAtSymbol);
console.log('  Has dot after @:', hasDotAfterAt);
console.log('  Has text before @:', hasTextBeforeAt);
console.log('  Has text after dot:', hasTextAfterDot);

const isValidEmail = hasAtSymbol && hasDotAfterAt && hasTextBeforeAt && hasTextAfterDot;
console.log('  Final validation result:', isValidEmail);

if (isValidEmail) {
  console.log('✅ Simplified email validation should work correctly');
} else {
  console.log('❌ Simplified email validation is still failing!');
}

// Test with some edge cases
const testCases = [
  'info@ibdpal.org',
  'test@example.com',
  'user@domain.co.uk',
  'admin@sub.domain.com'
];

console.log('\n🧪 Testing Multiple Email Cases:');
testCases.forEach(email => {
  const clean = email.trim().replace(/[\u200B-\u200D\uFEFF]/g, '');
  const hasAt = clean.includes('@');
  const hasDotAfter = clean.indexOf('@') > 0 && clean.indexOf('.', clean.indexOf('@')) > clean.indexOf('@');
  const hasTextBefore = clean.indexOf('@') > 0;
  const hasTextAfter = clean.lastIndexOf('.') < clean.length - 1;
  const isValid = hasAt && hasDotAfter && hasTextBefore && hasTextAfter;
  
  console.log(`  ${email}: ${isValid ? '✅' : '❌'}`);
});



