const { Client } = require('pg');

const client = new Client({
  host: 'localhost',
  port: 5432,
  database: 'medivue',
  user: 'postgres',
  password: 'postgres'
});

async function fixLoginHistory() {
  try {
    console.log('Connecting to database...');
    await client.connect();
    console.log('Connected to database');

    // Check current login_history table structure
    console.log('Checking current login_history table structure...');
    const tableInfo = await client.query(`
      SELECT column_name, data_type, is_nullable
      FROM information_schema.columns 
      WHERE table_name = 'login_history'
      ORDER BY ordinal_position
    `);
    
    console.log('Current login_history columns:');
    tableInfo.rows.forEach(row => {
      console.log(`- ${row.column_name}: ${row.data_type} (nullable: ${row.is_nullable})`);
    });

    // Add missing columns to login_history table
    console.log('Adding missing columns to login_history table...');
    const alterQueries = [
      'ALTER TABLE login_history ADD COLUMN IF NOT EXISTS success BOOLEAN',
      'ALTER TABLE login_history ADD COLUMN IF NOT EXISTS failure_reason VARCHAR(255)',
      'ALTER TABLE login_history ADD COLUMN IF NOT EXISTS user_agent TEXT'
    ];

    for (const query of alterQueries) {
      try {
        await client.query(query);
        console.log('Executed:', query);
      } catch (error) {
        console.log('Query failed:', query, error.message);
      }
    }

    // Check final table structure
    console.log('Checking final login_history table structure...');
    const finalTableInfo = await client.query(`
      SELECT column_name, data_type, is_nullable
      FROM information_schema.columns 
      WHERE table_name = 'login_history'
      ORDER BY ordinal_position
    `);
    
    console.log('Final login_history columns:');
    finalTableInfo.rows.forEach(row => {
      console.log(`- ${row.column_name}: ${row.data_type} (nullable: ${row.is_nullable})`);
    });

    console.log('Login history table fix completed!');

  } catch (error) {
    console.error('Login history fix failed:', error);
  } finally {
    await client.end();
    console.log('Database connection closed');
  }
}

fixLoginHistory(); 