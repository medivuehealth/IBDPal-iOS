const { Client } = require('pg');
const bcrypt = require('bcrypt');
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '../IBDPal-Server/config.env') });

const updateDemoUser = async () => {
  const client = new Client({
    connectionString: process.env.DATABASE_URL || 'postgresql://neondb_owner:npg_ILP7Oz0VhYKj@ep-lucky-wildflower-ae5uww1l-pooler.c-2.us-east-2.aws.neon.tech/medivue?sslmode=require&channel_binding=require',
    ssl: {
      rejectUnauthorized: false
    }
  });

  try {
    await client.connect();
    console.log('Connected to database');

    const oldEmail = 'demo3@ibdpal.org'; // Only updating demo3, not info@ibdpal.org
    const newEmail = 'demo@ibdpal.org';
    const newPassword = 'demo123';
    const hashedPassword = await bcrypt.hash(newPassword, 10);

    console.log('Updating demo user credentials...');
    console.log('='.repeat(50));

    // First, check if the old user exists
    const oldUserResult = await client.query(
      'SELECT user_id FROM users WHERE email = $1',
      [oldEmail]
    );

    if (oldUserResult.rows.length === 0) {
      console.log('❌ Old demo user not found:', oldEmail);
      return;
    }

    const userId = oldUserResult.rows[0].user_id;
    console.log('✅ Found old demo user with ID:', userId);

    // Check if new email already exists
    const existingUserResult = await client.query(
      'SELECT user_id FROM users WHERE email = $1',
      [newEmail]
    );

    if (existingUserResult.rows.length > 0) {
      console.log('❌ Email already exists:', newEmail);
      return;
    }

    // Update the user with new email and password
    await client.query(`
      UPDATE users SET 
        email = $1,
        username = $1,
        password_hash = $2,
        updated_at = $3
      WHERE user_id = $4
    `, [newEmail, hashedPassword, new Date(), userId]);

    console.log('✅ Demo user updated successfully');
    console.log('✅ New email:', newEmail);
    console.log('✅ New password:', newPassword);
    console.log('✅ User ID:', userId);

    // Verify the update
    const updatedUserResult = await client.query(
      'SELECT user_id, email, username, email_verified, account_status FROM users WHERE user_id = $1',
      [userId]
    );

    if (updatedUserResult.rows.length > 0) {
      const user = updatedUserResult.rows[0];
      console.log('\n' + '='.repeat(50));
      console.log('🎉 DEMO USER UPDATED SUCCESSFULLY!');
      console.log('='.repeat(50));
      console.log('Email:', user.email);
      console.log('Username:', user.username);
      console.log('Password:', newPassword);
      console.log('User ID:', user.user_id);
      console.log('Email Verified:', user.email_verified);
      console.log('Account Status:', user.account_status);
      console.log('\nReady for testing! 🚀');
    }

  } catch (error) {
    console.error('❌ Error updating demo user:', error);
  } finally {
    await client.end();
  }
};

updateDemoUser();
