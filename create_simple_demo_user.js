const { Client } = require('pg');
const bcrypt = require('bcrypt');
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '../IBDPal-Server/config.env') });

const createSimpleDemoUser = async () => {
  const client = new Client({
    connectionString: process.env.DATABASE_URL || 'postgresql://neondb_owner:npg_ILP7Oz0VhYKj@ep-lucky-wildflower-ae5uww1l-pooler.c-2.us-east-2.aws.neon.tech/medivue?sslmode=require&channel_binding=require',
    ssl: {
      rejectUnauthorized: false
    }
  });

  try {
    await client.connect();
    console.log('Connected to database');

    // Generate user ID
    const userId = 'demo3_' + Date.now();
    const email = 'demo3@ibdpal.org';
    const password = 'demo789';
    const hashedPassword = await bcrypt.hash(password, 10);

    console.log('Creating simple demo user:', email);
    console.log('='.repeat(50));

    // Create demo user with email verification complete
    await client.query(`
      INSERT INTO users (
        user_id, username, email, password_hash, first_name, last_name, 
        date_of_birth, gender, phone_number, address, city, 
        state, country, postal_code, emergency_contact_name, 
        emergency_contact_phone, created_at, updated_at, email_verified, account_status
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20)
      ON CONFLICT (email) DO UPDATE SET
        password_hash = $4,
        updated_at = $18,
        email_verified = $19,
        account_status = $20
    `, [
      userId, email, email, hashedPassword, 'Demo', 'User3',
      '1990-01-15', 'Other', '+1-555-0789', '789 Health Blvd', 'Austin',
      'TX', 'USA', '73301', 'Emergency Contact', '+1-555-0790',
      new Date(), new Date(), true, 'active'
    ]);

    console.log('✅ Demo user created/updated');
    console.log('✅ Email verification: COMPLETE');
    console.log('✅ Account status: ACTIVE');

    // Create a login session
    const sessionToken = 'demo3_session_' + Date.now();
    const sessionHash = await bcrypt.hash(sessionToken, 10);
    const expiresAt = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000); // 30 days

    await client.query(`
      INSERT INTO user_sessions (
        user_id, token_hash, device_info, ip_address, created_at, expires_at, is_active
      ) VALUES ($1, $2, $3, $4, $5, $6, $7)
    `, [userId, sessionHash, 'Demo Device 3', '127.0.0.1', new Date(), expiresAt, true]);

    console.log('✅ Demo session created');

    // Add login history
    await client.query(`
      INSERT INTO login_history (
        user_id, login_timestamp, ip_address, user_agent, success, failure_reason
      ) VALUES ($1, $2, $3, $4, $5, $6)
    `, [userId, new Date(), '127.0.0.1', 'Demo Browser 3', true, null]);

    console.log('✅ Login history added');

    console.log('\n' + '='.repeat(50));
    console.log('🎉 SIMPLE DEMO USER CREATED!');
    console.log('='.repeat(50));
    console.log('Email: demo3@ibdpal.org');
    console.log('Password: demo789');
    console.log('User ID:', userId);
    console.log('Email Verified: ✅ YES');
    console.log('Account Status: ✅ ACTIVE');
    console.log('\nReady for you to add data! 🚀');

  } catch (error) {
    console.error('❌ Error creating demo user:', error);
  } finally {
    await client.end();
  }
};

createSimpleDemoUser();





