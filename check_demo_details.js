const { Client } = require('pg');
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '../IBDPal-Server/config.env') });

const checkDemoDetails = async () => {
  const client = new Client({
    connectionString: process.env.DATABASE_URL || 'postgresql://neondb_owner:npg_ILP7Oz0VhYKj@ep-lucky-wildflower-ae5uww1l-pooler.c-2.us-east-2.aws.neon.tech/medivue?sslmode=require&channel_binding=require',
    ssl: {
      rejectUnauthorized: false
    }
  });

  try {
    await client.connect();
    console.log('Connected to database');

    const email = 'info@ibdpal.org';
    
    // Get user
    const userResult = await client.query(
      'SELECT user_id, email, first_name, last_name, created_at FROM users WHERE email = $1',
      [email]
    );
    
    if (userResult.rows.length === 0) {
      console.log('❌ Demo user not found');
      return;
    }
    
    const user = userResult.rows[0];
    console.log('✅ Demo user:', user.user_id, user.email);
    
    // Check all tables for this user
    console.log('\n=== CHECKING ALL TABLES ===');
    
    // Micronutrient profiles
    const profilesResult = await client.query(
      'SELECT * FROM micronutrient_profiles WHERE user_id = $1',
      [user.user_id]
    );
    console.log(`Micronutrient profiles: ${profilesResult.rows.length}`);
    if (profilesResult.rows.length > 0) {
      console.log('Profile:', profilesResult.rows[0]);
    }
    
    // Journal entries
    const journalResult = await client.query(
      'SELECT entry_date, breakfast, lunch, dinner, calories FROM journal_entries WHERE user_id = $1 ORDER BY entry_date DESC LIMIT 3',
      [user.user_id]
    );
    console.log(`\nJournal entries: ${journalResult.rows.length}`);
    journalResult.rows.forEach(entry => {
      console.log(`- ${entry.entry_date}: ${entry.breakfast} | ${entry.lunch} | ${entry.dinner} (${entry.calories} cal)`);
    });
    
    // Check if there are any micronutrient profiles at all
    const allProfilesResult = await client.query('SELECT COUNT(*) as count FROM micronutrient_profiles');
    console.log(`\nTotal micronutrient profiles in database: ${allProfilesResult.rows[0].count}`);
    
    // Check if there are any supplements at all
    const allSupplementsResult = await client.query('SELECT COUNT(*) as count FROM micronutrient_supplements');
    console.log(`Total supplements in database: ${allSupplementsResult.rows[0].count}`);
    
    // Check users table structure
    const usersStructureResult = await client.query(`
      SELECT column_name, data_type, is_nullable 
      FROM information_schema.columns 
      WHERE table_name = 'users' 
      ORDER BY ordinal_position
    `);
    console.log('\nUsers table structure:');
    usersStructureResult.rows.forEach(col => {
      console.log(`- ${col.column_name}: ${col.data_type} (${col.is_nullable === 'YES' ? 'nullable' : 'not null'})`);
    });
    
  } catch (error) {
    console.error('❌ Error:', error.message);
  } finally {
    await client.end();
  }
};

checkDemoDetails();







