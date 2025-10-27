import Foundation

// Test the Swift email regex for info@ibdpal.org
let testEmail = "info@ibdpal.org"
let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
let isValid = emailPredicate.evaluate(with: testEmail)

print("🧪 Testing Swift Email Regex for info@ibdpal.org")
print("📧 Test Results:")
print("  Email: \(testEmail)")
print("  Regex: \(emailRegex)")
print("  Is valid: \(isValid)")

// Test with some other emails
let testCases = [
    "info@ibdpal.org",
    "test@example.com",
    "user@domain.co.uk",
    "admin@sub.domain.com"
]

print("\n🧪 Testing Multiple Email Cases:")
for email in testCases {
    let predicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
    let result = predicate.evaluate(with: email)
    print("  \(email): \(result ? "✅" : "❌")")
}
