const { Client } = require('pg');
require('dotenv').config({ path: './config.env' });

async function checkPassword() {
  const client = new Client({
    host: process.env.DB_HOST,
    port: process.env.DB_PORT,
    database: 'medivue', // Using the shared MediVue database
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
  });

  try {
    await client.connect();
    console.log('Connected to MediVue database');
    
    const email = 'aryan.skumar17@gmail.com';
    
    // Check user details including password hash
    const userResult = await client.query(
      `SELECT 
        user_id, 
        email, 
        first_name, 
        last_name, 
        password_hash,
        username,
        account_status,
        created_at,
        password_last_changed,
        failed_login_attempts,
        account_locked
       FROM users WHERE email = $1`,
      [email]
    );
    
    if (userResult.rows.length === 0) {
      console.log('❌ User not found in MediVue database');
      console.log('Email:', email);
      return;
    }
    
    const user = userResult.rows[0];
    console.log('✅ User found in MediVue database:');
    console.log('='.repeat(50));
    console.log('User ID:', user.user_id);
    console.log('Email:', user.email);
    console.log('First Name:', user.first_name);
    console.log('Last Name:', user.last_name);
    console.log('Username:', user.username);
    console.log('Account Status:', user.account_status);
    console.log('Created At:', user.created_at);
    console.log('Password Last Changed:', user.password_last_changed);
    console.log('Failed Login Attempts:', user.failed_login_attempts);
    console.log('Account Locked:', user.account_locked);
    
    console.log('\n' + '='.repeat(50));
    console.log('Password Information:');
    if (user.password_hash) {
      console.log('✅ Password hash exists');
      console.log('Password Hash Length:', user.password_hash.length);
      console.log('Password Hash Starts with:', user.password_hash.substring(0, 10) + '...');
      console.log('Password Hash Ends with:', '...' + user.password_hash.substring(user.password_hash.length - 10));
      
      // Check if it's a bcrypt hash (should start with $2a$, $2b$, or $2y$)
      if (user.password_hash.startsWith('$2')) {
        console.log('✅ Password hash appears to be bcrypt format');
      } else {
        console.log('⚠️ Password hash may not be in bcrypt format');
      }
    } else {
      console.log('❌ No password hash found');
    }
    
    console.log('\n' + '='.repeat(50));
    console.log('Login Status:');
    if (user.account_locked) {
      console.log('❌ Account is locked');
    } else {
      console.log('✅ Account is not locked');
    }
    
    if (user.failed_login_attempts > 0) {
      console.log('⚠️ Failed login attempts:', user.failed_login_attempts);
    } else {
      console.log('✅ No failed login attempts');
    }
    
  } catch (error) {
    console.error('❌ Error:', error.message);
  } finally {
    await client.end();
  }
}

checkPassword(); 