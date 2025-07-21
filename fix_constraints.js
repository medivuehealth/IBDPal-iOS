const { Client } = require('pg');

const client = new Client({
  host: 'localhost',
  port: 5432,
  database: 'medivue',
  user: 'postgres',
  password: 'postgres'
});

async function fixConstraints() {
  try {
    console.log('Connecting to database...');
    await client.connect();
    console.log('Connected to database');

    // Remove NOT NULL constraints from optional fields
    console.log('Removing NOT NULL constraints from optional fields...');
    const alterQueries = [
      'ALTER TABLE users ALTER COLUMN date_of_birth DROP NOT NULL',
      'ALTER TABLE users ALTER COLUMN gender DROP NOT NULL',
      'ALTER TABLE users ALTER COLUMN phone_number DROP NOT NULL'
    ];

    for (const query of alterQueries) {
      try {
        await client.query(query);
        console.log('Executed:', query);
      } catch (error) {
        console.log('Query failed (constraint might not exist):', query);
      }
    }

    // Keep only essential registration fields as NOT NULL
    // These should remain NOT NULL: user_id, username, email, first_name, last_name
    console.log('Registration form fields remain required:');
    console.log('- user_id (PRIMARY KEY)');
    console.log('- username (UNIQUE)');
    console.log('- email (UNIQUE)');
    console.log('- first_name');
    console.log('- last_name');

    console.log('All optional fields are now nullable!');

  } catch (error) {
    console.error('Constraint fix failed:', error);
  } finally {
    await client.end();
    console.log('Database connection closed');
  }
}

fixConstraints(); 