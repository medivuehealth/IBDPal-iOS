const { Client } = require('pg');
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '../IBDPal-Server/config.env') });

const checkDemoUser = async () => {
  const client = new Client({
    connectionString: process.env.DATABASE_URL || 'postgresql://neondb_owner:npg_ILP7Oz0VhYKj@ep-lucky-wildflower-ae5uww1l-pooler.c-2.us-east-2.aws.neon.tech/medivue?sslmode=require&channel_binding=require',
    ssl: {
      rejectUnauthorized: false
    }
  });

  try {
    await client.connect();
    console.log('Connected to database');

    // Check if demo user exists
    const userResult = await client.query(
      'SELECT user_id, email, first_name, last_name, created_at FROM users WHERE email = $1',
      ['info@ibdpal.org']
    );
    
    if (userResult.rows.length === 0) {
      console.log('❌ Demo user not found');
      return;
    }
    
    const user = userResult.rows[0];
    console.log('✅ Demo user found:');
    console.log('User ID:', user.user_id);
    console.log('Email:', user.email);
    console.log('Name:', user.first_name, user.last_name);
    console.log('Created:', user.created_at);
    
    // Check micronutrient profile
    const profileResult = await client.query(
      'SELECT * FROM micronutrient_profiles WHERE user_id = $1',
      [user.user_id]
    );
    
    if (profileResult.rows.length > 0) {
      console.log('✅ Micronutrient profile found');
      console.log('Profile:', profileResult.rows[0]);
    } else {
      console.log('❌ No micronutrient profile found');
    }
    
    // Check supplements
    const supplementsResult = await client.query(`
      SELECT ms.* FROM micronutrient_supplements ms
      JOIN micronutrient_profiles mp ON ms.profile_id = mp.id
      WHERE mp.user_id = $1
    `, [user.user_id]);
    
    console.log(`✅ Found ${supplementsResult.rows.length} supplements:`);
    supplementsResult.rows.forEach(supplement => {
      console.log(`- ${supplement.name}: ${supplement.dosage} ${supplement.unit} (${supplement.frequency})`);
    });
    
    // Check journal entries
    const journalResult = await client.query(
      'SELECT COUNT(*) as count FROM journal_entries WHERE user_id = $1',
      [user.user_id]
    );
    
    console.log(`✅ Found ${journalResult.rows[0].count} journal entries`);
    
  } catch (error) {
    console.error('❌ Error:', error.message);
  } finally {
    await client.end();
  }
};

checkDemoUser();
