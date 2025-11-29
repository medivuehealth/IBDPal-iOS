// Email service for sending verification codes and password reset codes
// Supports multiple email providers via environment variables

/**
 * Send verification email
 * @param {string} email - Recipient email address
 * @param {string} verificationCode - 6-digit verification code
 * @param {string} firstName - User's first name
 * @returns {Promise<boolean>} - Returns true if email was sent successfully
 */
async function sendVerificationEmail(email, verificationCode, firstName = '') {
  try {
    // For now, log the email (can be configured with actual email service later)
    console.log(`📧 [Email Service] Verification email for ${email}:`);
    console.log(`   Code: ${verificationCode}`);
    console.log(`   Subject: Verify your IBDPal account`);
    console.log(`   Body: Hello ${firstName || 'there'},\n\nYour verification code is: ${verificationCode}\n\nThis code will expire in 15 minutes.\n\nIf you didn't create an account, please ignore this email.\n\nBest regards,\nIBDPal Team`);
    
    // TODO: Configure actual email service (nodemailer, SendGrid, AWS SES, etc.)
    // Example with nodemailer:
    // const nodemailer = require('nodemailer');
    // const transporter = nodemailer.createTransport({
    //   host: process.env.SMTP_HOST,
    //   port: process.env.SMTP_PORT,
    //   secure: true,
    //   auth: {
    //     user: process.env.SMTP_USER,
    //     pass: process.env.SMTP_PASS
    //   }
    // });
    // 
    // await transporter.sendMail({
    //   from: process.env.FROM_EMAIL,
    //   to: email,
    //   subject: 'Verify your IBDPal account',
    //   html: `...`
    // });
    
    return true;
  } catch (error) {
    console.error('Error sending verification email:', error);
    return false;
  }
}

/**
 * Send password reset email
 * @param {string} email - Recipient email address
 * @param {string} resetCode - 6-digit reset code
 * @param {string} firstName - User's first name
 * @returns {Promise<boolean>} - Returns true if email was sent successfully
 */
async function sendPasswordResetEmail(email, resetCode, firstName = '') {
  try {
    // For now, log the email (can be configured with actual email service later)
    console.log(`📧 [Email Service] Password reset email for ${email}:`);
    console.log(`   Code: ${resetCode}`);
    console.log(`   Subject: Reset your IBDPal password`);
    console.log(`   Body: Hello ${firstName || 'there'},\n\nYour password reset code is: ${resetCode}\n\nThis code will expire in 15 minutes.\n\nIf you didn't request a password reset, please ignore this email.\n\nBest regards,\nIBDPal Team`);
    
    // TODO: Configure actual email service (same as above)
    
    return true;
  } catch (error) {
    console.error('Error sending password reset email:', error);
    return false;
  }
}

module.exports = {
  sendVerificationEmail,
  sendPasswordResetEmail
};







