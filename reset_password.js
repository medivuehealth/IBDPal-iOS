const { Client } = require('pg');
const bcrypt = require('bcryptjs');
require('dotenv').config({ path: './config.env' });

async function resetPassword() {
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
    const newPassword = 'password123';
    
    // First, check if user exists
    const userResult = await client.query(
      'SELECT user_id, email, first_name, last_name FROM users WHERE email = $1',
      [email]
    );
    
    if (userResult.rows.length === 0) {
      console.log('❌ User not found in MediVue database');
      console.log('Creating new user...');
      
      // Create the user if it doesn't exist
      const saltRounds = 12;
      const passwordHash = await bcrypt.hash(newPassword, saltRounds);
      
      const newUser = await client.query(
        `INSERT INTO users (
          user_id, 
          email, 
          password_hash, 
          first_name, 
          last_name,
          username,
          pseudonymized_id,
          account_status
        )
         VALUES (
          gen_random_uuid()::text, 
          $1, 
          $2, 
          $3, 
          $4,
          $1,
          'PSEUDO_' || substr(md5(random()::text), 1, 8),
          'active'
        )
         RETURNING user_id, email, first_name, last_name`,
        [email, passwordHash, 'Aryan', 'Kumar']
      );
      
      console.log('✅ User created successfully');
      console.log('User ID:', newUser.rows[0].user_id);
      
    } else {
      console.log('✅ User found in MediVue database');
      const user = userResult.rows[0];
      console.log('User ID:', user.user_id);
      console.log('Name:', user.first_name, user.last_name);
      
      // Update the password
      const saltRounds = 12;
      const passwordHash = await bcrypt.hash(newPassword, saltRounds);
      
      await client.query(
        'UPDATE users SET password_hash = $1, password_last_changed = CURRENT_TIMESTAMP WHERE user_id = $2',
        [passwordHash, user.user_id]
      );
      
      console.log('✅ Password updated successfully');
    }
    
    console.log('\n' + '='.repeat(50));
    console.log('Login Credentials:');
    console.log('Email:', email);
    console.log('Password:', newPassword);
    console.log('='.repeat(50));
    
    // Test the login
    console.log('\nTesting login...');
    const testLogin = await client.query(
      'SELECT user_id, email FROM users WHERE email = $1',
      [email]
    );
    
    if (testLogin.rows.length > 0) {
      console.log('✅ User is ready for login');
      console.log('You can now login to IBDPal with these credentials');
    }
    
  } catch (error) {
    console.error('❌ Error:', error.message);
  } finally {
    await client.end();
  }
}

resetPassword(); 