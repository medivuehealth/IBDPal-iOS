const { Client } = require('pg');
const fs = require('fs');
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, 'config.env') });

console.log('🚀 Starting Email Verification Database Migration...');

const runMigration = async () => {
  // Use DATABASE_URL if available, otherwise fall back to individual variables
  const connectionString = process.env.DATABASE_URL || 
    `postgresql://${process.env.DB_USER}:${process.env.DB_PASSWORD}@${process.env.DB_HOST}:${process.env.DB_PORT}/medivue`;
  
  const client = new Client({
    connectionString: connectionString,
    ssl: process.env.NODE_ENV === 'production' ? { rejectUnauthorized: false } : false
  });

  try {
    await client.connect();
    console.log('✅ Connected to database');

    // Read the migration file
    const migrationPath = path.join(__dirname, 'database', 'migration_add_email_verification_simple.sql');
    const migrationSQL = fs.readFileSync(migrationPath, 'utf8');

    console.log('📝 Executing email verification migration...');
    
    // Execute the migration
    await client.query(migrationSQL);
    
    console.log('✅ Email verification migration completed successfully!');
    console.log('📊 Added fields:');
    console.log('   - email_verified (BOOLEAN)');
    console.log('   - verification_code (VARCHAR(6))');
    console.log('   - verification_code_expires (TIMESTAMP)');
    console.log('   - verification_attempts (INTEGER)');
    console.log('   - last_verification_attempt (TIMESTAMP)');
    console.log('🔧 Added functions:');
    console.log('   - generate_verification_code()');
    console.log('   - is_verification_code_expired()');
    console.log('📈 Added indexes for performance');
    console.log('🔒 Added constraints for data integrity');

  } catch (error) {
    console.error('❌ Migration failed:', error.message);
    process.exit(1);
  } finally {
    await client.end();
    console.log('🔌 Database connection closed');
  }
};

runMigration(); 