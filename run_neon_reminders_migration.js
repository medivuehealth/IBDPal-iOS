const { Pool } = require('pg');
const fs = require('fs');
const path = require('path');
require('dotenv').config({ path: './config.env' });

// Neon database connection
const pool = new Pool({
    connectionString: process.env.DATABASE_URL,
    ssl: { rejectUnauthorized: false }
});

async function runRemindersMigration() {
    let client;
    try {
        console.log('🔄 Starting reminders table migration on Neon database...');
        console.log('🔗 Connecting to Neon database...');
        
        // Test connection
        client = await pool.connect();
        console.log('✅ Connected to Neon database successfully!');
        
        // Read the SQL file
        const sqlPath = path.join(__dirname, 'database', 'create_reminders_table_simple.sql');
        const sql = fs.readFileSync(sqlPath, 'utf8');
        
        console.log('📄 SQL migration file loaded');
        console.log('🚀 Executing migration...');
        
        // Execute the migration
        await client.query(sql);
        
        console.log('✅ Reminders table migration completed successfully on Neon!');
        console.log('📋 Created table: reminders');
        console.log('📋 Created indexes: user_id, type, is_enabled');
        console.log('📋 Created trigger: update_updated_at_column');
        
        // Verify the table was created
        const verifyResult = await client.query(`
            SELECT table_name, column_name, data_type 
            FROM information_schema.columns 
            WHERE table_name = 'reminders' 
            ORDER BY ordinal_position;
        `);
        
        console.log('\n📊 Verification - Reminders table structure:');
        verifyResult.rows.forEach(row => {
            console.log(`  - ${row.column_name} (${row.data_type})`);
        });
        
        // Check if there are any existing reminders
        const countResult = await client.query('SELECT COUNT(*) as count FROM reminders');
        console.log(`\n📈 Current reminders count: ${countResult.rows[0].count}`);
        
    } catch (error) {
        console.error('❌ Migration failed:', error);
        
        if (error.code === '42P07') {
            console.log('ℹ️  Table already exists - this is normal if migration was run before');
        } else if (error.code === '23503') {
            console.log('ℹ️  Foreign key constraint error - users table might not exist');
        } else {
            console.log('💡 Error details:', {
                code: error.code,
                detail: error.detail,
                hint: error.hint
            });
        }
        
        process.exit(1);
    } finally {
        if (client) {
            client.release();
        }
        await pool.end();
        console.log('🔌 Database connection closed');
    }
}

// Add some helpful information
console.log('🌐 Neon Database Migration Script');
console.log('================================');
console.log('This script will create the reminders table on your Neon database');
console.log('Make sure your DATABASE_URL is set in config.env\n');

runRemindersMigration();

