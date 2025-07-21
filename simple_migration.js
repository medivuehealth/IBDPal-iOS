const { Client } = require('pg');

const client = new Client({
  host: 'localhost',
  port: 5432,
  database: 'medivue',
  user: 'postgres',
  password: 'postgres'
});

async function runSimpleMigration() {
  try {
    console.log('Connecting to database...');
    await client.connect();
    console.log('Connected to database');

    // Step 1: Create the function first
    console.log('Creating generate_pseudonymized_id function...');
    await client.query(`
      CREATE OR REPLACE FUNCTION generate_pseudonymized_id()
      RETURNS TEXT AS $$
      BEGIN
          RETURN 'P' || substr(md5(random()::text), 1, 8) || substr(md5(clock_timestamp()::text), 1, 8);
      END;
      $$ language 'plpgsql';
    `);
    console.log('Function created successfully');

    // Step 2: Add new columns to users table
    console.log('Adding new columns to users table...');
    const alterQueries = [
      'ALTER TABLE users ADD COLUMN IF NOT EXISTS mrn TEXT UNIQUE',
      'ALTER TABLE users ADD COLUMN IF NOT EXISTS pseudonymized_id TEXT UNIQUE',
      'ALTER TABLE users ADD COLUMN IF NOT EXISTS patient_type TEXT CHECK (patient_type IN (\'pediatric\', \'adult\', \'transitional\'))',
      'ALTER TABLE users ADD COLUMN IF NOT EXISTS diagnosis_date DATE',
      'ALTER TABLE users ADD COLUMN IF NOT EXISTS ibd_type TEXT CHECK (ibd_type IN (\'crohns\', \'ulcerative_colitis\', \'indeterminate_colitis\', \'ibd_unspecified\'))',
      'ALTER TABLE users ADD COLUMN IF NOT EXISTS disease_location TEXT',
      'ALTER TABLE users ADD COLUMN IF NOT EXISTS disease_behavior TEXT',
      'ALTER TABLE users ADD COLUMN IF NOT EXISTS current_medications TEXT',
      'ALTER TABLE users ADD COLUMN IF NOT EXISTS allergies TEXT',
      'ALTER TABLE users ADD COLUMN IF NOT EXISTS comorbidities TEXT',
      'ALTER TABLE users ADD COLUMN IF NOT EXISTS family_history TEXT',
      'ALTER TABLE users ADD COLUMN IF NOT EXISTS disease_activity TEXT CHECK (disease_activity IN (\'remission\', \'mild\', \'moderate\', \'severe\'))',
      'ALTER TABLE users ADD COLUMN IF NOT EXISTS last_flare_date DATE',
      'ALTER TABLE users ADD COLUMN IF NOT EXISTS flare_frequency INTEGER',
      'ALTER TABLE users ADD COLUMN IF NOT EXISTS hospitalizations_count INTEGER DEFAULT 0',
      'ALTER TABLE users ADD COLUMN IF NOT EXISTS surgeries_count INTEGER DEFAULT 0',
      'ALTER TABLE users ADD COLUMN IF NOT EXISTS insurance_provider TEXT',
      'ALTER TABLE users ADD COLUMN IF NOT EXISTS insurance_id TEXT',
      'ALTER TABLE users ADD COLUMN IF NOT EXISTS primary_care_physician TEXT',
      'ALTER TABLE users ADD COLUMN IF NOT EXISTS gastroenterologist TEXT',
      'ALTER TABLE users ADD COLUMN IF NOT EXISTS care_coordinator TEXT',
      'ALTER TABLE users ADD COLUMN IF NOT EXISTS data_sharing_consent BOOLEAN DEFAULT FALSE',
      'ALTER TABLE users ADD COLUMN IF NOT EXISTS ai_model_consent BOOLEAN DEFAULT FALSE',
      'ALTER TABLE users ADD COLUMN IF NOT EXISTS research_consent BOOLEAN DEFAULT FALSE',
      'ALTER TABLE users ADD COLUMN IF NOT EXISTS consent_date DATE',
      'ALTER TABLE users ADD COLUMN IF NOT EXISTS account_status TEXT CHECK (account_status IN (\'active\', \'inactive\', \'suspended\', \'pending_verification\')) DEFAULT \'pending_verification\'',
      'ALTER TABLE users ADD COLUMN IF NOT EXISTS email_verified BOOLEAN DEFAULT FALSE',
      'ALTER TABLE users ADD COLUMN IF NOT EXISTS phone_verified BOOLEAN DEFAULT FALSE',
      'ALTER TABLE users ADD COLUMN IF NOT EXISTS last_login TIMESTAMP',
      'ALTER TABLE users ADD COLUMN IF NOT EXISTS last_activity TIMESTAMP'
    ];

    for (const query of alterQueries) {
      await client.query(query);
    }
    console.log('All columns added successfully');

    // Step 3: Generate pseudonymized IDs for existing users
    console.log('Generating pseudonymized IDs for existing users...');
    await client.query(`
      UPDATE users 
      SET pseudonymized_id = generate_pseudonymized_id()
      WHERE pseudonymized_id IS NULL
    `);
    console.log('Pseudonymized IDs generated');

    // Step 4: Set default values for existing users
    console.log('Setting default values for existing users...');
    await client.query(`
      UPDATE users 
      SET patient_type = 'pediatric',
          account_status = 'active',
          data_sharing_consent = true,
          ai_model_consent = true
      WHERE patient_type IS NULL
    `);
    console.log('Default values set');

    // Step 5: Update existing users to have username if not set
    console.log('Updating usernames for existing users...');
    await client.query(`
      UPDATE users 
      SET username = email 
      WHERE username IS NULL
    `);
    console.log('Usernames updated');

    console.log('Migration completed successfully!');

  } catch (error) {
    console.error('Migration failed:', error);
  } finally {
    await client.end();
    console.log('Database connection closed');
  }
}

runSimpleMigration(); 