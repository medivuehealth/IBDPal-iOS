const { Client } = require('pg');
const fs = require('fs');
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '..', 'config.env') });

const runMigration = async () => {
  console.log('🚀 Starting database migration for meal nutrition columns...');
  
  // Use DATABASE_URL if available, otherwise fall back to individual env vars
  const client = new Client(
    process.env.DATABASE_URL ? {
      connectionString: process.env.DATABASE_URL,
      ssl: {
        rejectUnauthorized: false
      }
    } : {
      host: process.env.DB_HOST || 'localhost',
      port: parseInt(process.env.DB_PORT) || 5432,
      database: process.env.DB_NAME || 'medivue',
      user: process.env.DB_USER || 'postgres',
      password: process.env.DB_PASSWORD || 'postgres',
    }
  );

  try {
    await client.connect();
    console.log('✅ Connected to database');

    // Run the migration to add meal nutrition columns
    const migrationPath = path.join(__dirname, 'migration_add_meal_nutrition.sql');
    if (fs.existsSync(migrationPath)) {
      const migrationSQL = fs.readFileSync(migrationPath, 'utf8');
      
      console.log('📝 Adding meal nutrition columns to existing journal_entries table...');
      await client.query(migrationSQL);
      
      console.log('✅ Migration completed successfully!');
      console.log('📊 Added individual meal nutrition columns to journal_entries table');
      console.log('🔍 Added performance indexes for meal queries');
      
      // Verify the migration
      const verifyQuery = `
        SELECT column_name, data_type, column_default 
        FROM information_schema.columns 
        WHERE table_name = 'journal_entries' 
        AND column_name LIKE '%_calories' 
        ORDER BY column_name;
      `;
      
      const verifyResult = await client.query(verifyQuery);
      console.log('📋 Verification - Added columns:');
      verifyResult.rows.forEach(row => {
        console.log(`   - ${row.column_name}: ${row.data_type} (default: ${row.column_default})`);
      });
      
    } else {
      console.error('❌ Migration file not found:', migrationPath);
      process.exit(1);
    }

  } catch (error) {
    console.error('❌ Migration failed:', error);
    process.exit(1);
  } finally {
    await client.end();
    console.log('🔌 Database connection closed');
  }
};

runMigration(); 