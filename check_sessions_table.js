const { Client } = require('pg');
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '../IBDPal-Server/config.env') });

const checkSessionsTable = async () => {
  const client = new Client({
    connectionString: process.env.DATABASE_URL || 'postgresql://neondb_owner:npg_ILP7Oz0VhYKj@ep-lucky-wildflower-ae5uww1l-pooler.c-2.us-east-2.aws.neon.tech/medivue?sslmode=require&channel_binding=require',
    ssl: {
      rejectUnauthorized: false
    }
  });

  try {
    await client.connect();
    console.log('Connected to database');

    // Check user_sessions table structure
    const sessionsStructureResult = await client.query(`
      SELECT column_name, data_type, is_nullable 
      FROM information_schema.columns 
      WHERE table_name = 'user_sessions' 
      ORDER BY ordinal_position
    `);
    
    console.log('User sessions table structure:');
    sessionsStructureResult.rows.forEach(col => {
      console.log(`- ${col.column_name}: ${col.data_type} (${col.is_nullable === 'YES' ? 'nullable' : 'not null'})`);
    });

    // Check if demo user was created
    const userResult = await client.query(
      'SELECT user_id, email, first_name, last_name, email_verified, account_status FROM users WHERE email = $1',
      ['demo3@ibdpal.org']
    );
    
    if (userResult.rows.length > 0) {
      const user = userResult.rows[0];
      console.log('\n✅ Demo user found:');
      console.log('User ID:', user.user_id);
      console.log('Email:', user.email);
      console.log('Name:', user.first_name, user.last_name);
      console.log('Email Verified:', user.email_verified);
      console.log('Account Status:', user.account_status);
    } else {
      console.log('\n❌ Demo user not found');
    }
    
  } catch (error) {
    console.error('❌ Error:', error.message);
  } finally {
    await client.end();
  }
};

checkSessionsTable();





