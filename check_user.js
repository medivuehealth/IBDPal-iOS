const { Client } = require('pg');
const bcrypt = require('bcryptjs');
require('dotenv').config({ path: './config.env' });

async function checkUser() {
  const client = new Client({
    host: process.env.DB_HOST,
    port: process.env.DB_PORT,
    database: 'medivue',
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
  });

  try {
    await client.connect();
    console.log('Connected to database');
    
    const email = 'aryan.skumar17@gmail.com';
    
    // Check if user exists
    const userResult = await client.query(
      'SELECT user_id, email, first_name, last_name, password_hash, created_at FROM users WHERE email = $1',
      [email]
    );
    
    if (userResult.rows.length === 0) {
      console.log('❌ User not found in database');
      return;
    }
    
    const user = userResult.rows[0];
    console.log('✅ User found in database:');
    console.log('User ID:', user.user_id);
    console.log('Email:', user.email);
    console.log('First Name:', user.first_name);
    console.log('Last Name:', user.last_name);
    console.log('Created At:', user.created_at);
    console.log('Password Hash:', user.password_hash ? 'Present' : 'Missing');
    
    if (user.password_hash) {
      console.log('Password Hash Length:', user.password_hash.length);
      console.log('Password Hash Starts with:', user.password_hash.substring(0, 10) + '...');
    }
    
    // Test password reset
    console.log('\n' + '='.repeat(50));
    console.log('Testing password reset...');
    
    const newPassword = 'password123';
    const saltRounds = 12;
    const newPasswordHash = await bcrypt.hash(newPassword, saltRounds);
    
    await client.query(
      'UPDATE users SET password_hash = $1, password_last_changed = CURRENT_TIMESTAMP WHERE user_id = $2',
      [newPasswordHash, user.user_id]
    );
    
    console.log('✅ Password updated successfully');
    console.log('New password:', newPassword);
    console.log('You can now login with:');
    console.log('Email:', email);
    console.log('Password:', newPassword);
    
  } catch (error) {
    console.error('❌ Error:', error.message);
  } finally {
    await client.end();
  }
}

checkUser(); 