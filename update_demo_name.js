const { Client } = require('pg');
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '../IBDPal-Server/config.env') });

const updateDemoName = async () => {
  const client = new Client({
    connectionString: process.env.DATABASE_URL || 'postgresql://neondb_owner:npg_ILP7Oz0VhYKj@ep-lucky-wildflower-ae5uww1l-pooler.c-2.us-east-2.aws.neon.tech/medivue?sslmode=require&channel_binding=require',
    ssl: {
      rejectUnauthorized: false
    }
  });

  try {
    await client.connect();
    console.log('Connected to database');

    const email = 'demo@ibdpal.org';
    const newFirstName = 'Alex';
    const newLastName = 'Chen';

    console.log('Updating demo user name...');
    console.log('='.repeat(50));

    // Update the user's first and last name
    await client.query(`
      UPDATE users SET 
        first_name = $1,
        last_name = $2,
        updated_at = $3
      WHERE email = $4
    `, [newFirstName, newLastName, new Date(), email]);

    console.log('✅ Demo user name updated successfully');
    console.log('✅ New name:', newFirstName, newLastName);

    // Verify the update
    const updatedUserResult = await client.query(
      'SELECT user_id, email, first_name, last_name, email_verified, account_status FROM users WHERE email = $1',
      [email]
    );

    if (updatedUserResult.rows.length > 0) {
      const user = updatedUserResult.rows[0];
      console.log('\n' + '='.repeat(50));
      console.log('🎉 DEMO USER NAME UPDATED!');
      console.log('='.repeat(50));
      console.log('Email:', user.email);
      console.log('Name:', user.first_name, user.last_name);
      console.log('User ID:', user.user_id);
      console.log('Email Verified:', user.email_verified);
      console.log('Account Status:', user.account_status);
      console.log('\nReady for testing! 🚀');
    }

  } catch (error) {
    console.error('❌ Error updating demo user name:', error);
  } finally {
    await client.end();
  }
};

updateDemoName();





