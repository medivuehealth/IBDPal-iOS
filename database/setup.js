const { Client } = require('pg');
const fs = require('fs');
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '..', 'config.env') });

console.log('DEBUG: DB_PASSWORD type:', typeof process.env.DB_PASSWORD, 'value:', process.env.DB_PASSWORD);
console.log('DEBUG: Config file path:', path.join(__dirname, '..', 'config.env'));
console.log('DEBUG: Config file exists:', fs.existsSync(path.join(__dirname, '..', 'config.env')));

const setupDatabase = async () => {
  // Connect to default postgres database to create/verify shared medivue database
  const defaultClient = new Client({
    host: process.env.DB_HOST,
    port: process.env.DB_PORT,
    database: 'postgres',
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
  });

  try {
    await defaultClient.connect();
    console.log('Connected to PostgreSQL');

    // Check if shared medivue database exists
    const dbExists = await defaultClient.query(
      "SELECT 1 FROM pg_database WHERE datname = 'medivue'"
    );

    if (dbExists.rows.length === 0) {
      // Create shared medivue database for both MediVue website and IBDPal app
      await defaultClient.query('CREATE DATABASE medivue');
      console.log('Created shared medivue database for MediVue website and IBDPal app');
    } else {
      console.log('Shared medivue database already exists');
    }

    await defaultClient.end();

    // Connect to shared medivue database to create/verify schema
    const medivueClient = new Client({
      host: process.env.DB_HOST,
      port: process.env.DB_PORT,
      database: 'medivue',
      user: process.env.DB_USER,
      password: process.env.DB_PASSWORD,
    });

    await medivueClient.connect();
    console.log('Connected to shared medivue database');

    // Read and execute the main schema file
    const schemaPath = path.join(__dirname, '..', '..', 'database', 'schema.sql');
    if (fs.existsSync(schemaPath)) {
      const schemaSQL = fs.readFileSync(schemaPath, 'utf8');
      await medivueClient.query(schemaSQL);
      console.log('Shared MediVue database schema created/verified successfully');
      console.log('This database is shared between MediVue website and IBDPal iOS app');
    } else {
      console.log('Schema file not found, creating basic tables...');
      
      // Create basic users table with email as primary identifier
      await medivueClient.query(`
        CREATE TABLE IF NOT EXISTS users (
          user_id TEXT PRIMARY KEY,
          email TEXT UNIQUE NOT NULL,
          password_hash TEXT,
          first_name TEXT NOT NULL,
          last_name TEXT NOT NULL,
          display_name TEXT,
          date_of_birth DATE NOT NULL,
          gender TEXT NOT NULL CHECK (gender IN ('male', 'female', 'other', 'prefer_not_to_say')),
          phone_number TEXT NOT NULL,
          address TEXT,
          city TEXT,
          state TEXT,
          country TEXT,
          postal_code TEXT,
          emergency_contact_name TEXT,
          emergency_contact_phone TEXT,
          mfa_secret TEXT,
          password_last_changed TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          account_locked BOOLEAN DEFAULT FALSE,
          failed_login_attempts INTEGER DEFAULT 0,
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
      `);

      // Create user_sessions table
      await medivueClient.query(`
        CREATE TABLE IF NOT EXISTS user_sessions (
          id SERIAL PRIMARY KEY,
          user_id TEXT REFERENCES users(user_id) ON DELETE CASCADE,
          token_hash VARCHAR(255) NOT NULL,
          device_info TEXT,
          ip_address VARCHAR(45),
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          expires_at TIMESTAMP NOT NULL,
          is_active BOOLEAN DEFAULT TRUE
        )
      `);

      // Create login_history table
      await medivueClient.query(`
        CREATE TABLE IF NOT EXISTS login_history (
          id SERIAL PRIMARY KEY,
          user_id TEXT REFERENCES users(user_id) ON DELETE CASCADE,
          login_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          logout_timestamp TIMESTAMP,
          ip_address VARCHAR(45),
          user_agent TEXT,
          success BOOLEAN NOT NULL,
          failure_reason VARCHAR(255)
        )
      `);

      // Create indexes for better performance
      await medivueClient.query(`
        CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
        CREATE INDEX IF NOT EXISTS idx_user_sessions_user_id ON user_sessions(user_id);
        CREATE INDEX IF NOT EXISTS idx_user_sessions_token_hash ON user_sessions(token_hash);
        CREATE INDEX IF NOT EXISTS idx_login_history_user_id ON login_history(user_id);
      `);
    }

    console.log('IBDPal iOS app database setup completed successfully');
    console.log('Database is shared with MediVue website application');

    await medivueClient.end();
  } catch (error) {
    console.error('Database setup error:', error);
    process.exit(1);
  }
};

setupDatabase(); 