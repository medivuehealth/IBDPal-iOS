const { Pool } = require('pg');
const fs = require('fs');
const path = require('path');
require('dotenv').config({ path: './config.env' });

const pool = new Pool({
    connectionString: process.env.DATABASE_URL,
    ssl: process.env.NODE_ENV === 'production' ? { rejectUnauthorized: false } : false
});

async function runRemindersMigration() {
    try {
        console.log('🔄 Starting reminders table migration...');
        
        // Read the SQL file
        const sqlPath = path.join(__dirname, 'database', 'create_reminders_table_simple.sql');
        const sql = fs.readFileSync(sqlPath, 'utf8');
        
        // Execute the migration
        await pool.query(sql);
        
        console.log('✅ Reminders table migration completed successfully!');
        console.log('📋 Created table: reminders');
        console.log('📋 Created indexes: user_id, type, is_enabled');
        console.log('📋 Created trigger: update_updated_at_column');
        
    } catch (error) {
        console.error('❌ Migration failed:', error);
        process.exit(1);
    } finally {
        await pool.end();
    }
}

runRemindersMigration();
