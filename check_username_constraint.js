const { Client } = require('pg');

const client = new Client({
  host: 'localhost',
  port: 5432,
  database: 'medivue',
  user: 'postgres',
  password: 'postgres'
});

async function checkAndFixUsernameConstraint() {
  try {
    console.log('Connecting to database...');
    await client.connect();
    console.log('Connected to database');

    // Check the current username constraint
    console.log('Checking current username constraint...');
    const constraintResult = await client.query(`
      SELECT conname, pg_get_constraintdef(oid) as definition
      FROM pg_constraint 
      WHERE conrelid = 'users'::regclass 
      AND conname LIKE '%username%'
    `);
    
    console.log('Current username constraints:');
    constraintResult.rows.forEach(row => {
      console.log(`- ${row.conname}: ${row.definition}`);
    });

    // Drop the problematic username constraint
    console.log('Dropping username check constraint...');
    await client.query(`
      ALTER TABLE users DROP CONSTRAINT IF EXISTS users_username_check
    `);
    console.log('Username check constraint dropped');

    // Add a simpler username constraint that allows email addresses
    console.log('Adding new username constraint...');
    await client.query(`
      ALTER TABLE users ADD CONSTRAINT users_username_check 
      CHECK (username ~ '^[a-zA-Z0-9@._-]+$' AND length(username) <= 100)
    `);
    console.log('New username constraint added');

    // Test with a sample email
    console.log('Testing username constraint with email format...');
    const testResult = await client.query(`
      SELECT 'test@example.com' ~ '^[a-zA-Z0-9@._-]+$' as is_valid
    `);
    console.log('Email format test result:', testResult.rows[0]);

    console.log('Username constraint fix completed!');

  } catch (error) {
    console.error('Username constraint fix failed:', error);
  } finally {
    await client.end();
    console.log('Database connection closed');
  }
}

checkAndFixUsernameConstraint(); 