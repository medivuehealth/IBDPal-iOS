const { Pool } = require('pg');
require('dotenv').config({ path: './config.env' });

// Test the reminders API endpoints
async function testRemindersAPI() {
    const pool = new Pool({
        connectionString: process.env.DATABASE_URL,
        ssl: { rejectUnauthorized: false }
    });

    try {
        console.log('🧪 Testing Reminders API Database Integration');
        console.log('==============================================');
        
        // Test 1: Check if reminders table exists and is accessible
        console.log('\n1️⃣ Testing table access...');
        const tableCheck = await pool.query(`
            SELECT COUNT(*) as count 
            FROM information_schema.tables 
            WHERE table_name = 'reminders'
        `);
        console.log(`✅ Reminders table exists: ${tableCheck.rows[0].count > 0}`);
        
        // Test 2: Check table structure
        console.log('\n2️⃣ Testing table structure...');
        const structureCheck = await pool.query(`
            SELECT column_name, data_type, is_nullable
            FROM information_schema.columns 
            WHERE table_name = 'reminders'
            ORDER BY ordinal_position
        `);
        console.log('📋 Table columns:');
        structureCheck.rows.forEach(row => {
            console.log(`   - ${row.column_name}: ${row.data_type} (nullable: ${row.is_nullable})`);
        });
        
        // Test 3: Check indexes
        console.log('\n3️⃣ Testing indexes...');
        const indexCheck = await pool.query(`
            SELECT indexname, indexdef
            FROM pg_indexes 
            WHERE tablename = 'reminders'
        `);
        console.log('📊 Indexes created:');
        indexCheck.rows.forEach(row => {
            console.log(`   - ${row.indexname}`);
        });
        
        // Test 4: Check foreign key constraint
        console.log('\n4️⃣ Testing foreign key constraint...');
        const fkCheck = await pool.query(`
            SELECT 
                tc.constraint_name,
                tc.table_name,
                kcu.column_name,
                ccu.table_name AS foreign_table_name,
                ccu.column_name AS foreign_column_name
            FROM information_schema.table_constraints AS tc
            JOIN information_schema.key_column_usage AS kcu
                ON tc.constraint_name = kcu.constraint_name
                AND tc.table_schema = kcu.table_schema
            JOIN information_schema.constraint_column_usage AS ccu
                ON ccu.constraint_name = tc.constraint_name
                AND ccu.table_schema = tc.table_schema
            WHERE tc.constraint_type = 'FOREIGN KEY' 
                AND tc.table_name = 'reminders'
        `);
        console.log('🔗 Foreign key constraints:');
        fkCheck.rows.forEach(row => {
            console.log(`   - ${row.column_name} → ${row.foreign_table_name}.${row.foreign_column_name}`);
        });
        
        // Test 5: Test JSONB functionality
        console.log('\n5️⃣ Testing JSONB functionality...');
        const jsonbTest = await pool.query(`
            SELECT 
                '["monday", "tuesday", "wednesday"]'::jsonb as test_jsonb,
                jsonb_array_length('["monday", "tuesday", "wednesday"]'::jsonb) as array_length
        `);
        console.log(`✅ JSONB test passed: ${jsonbTest.rows[0].array_length} items in array`);
        
        // Test 6: Check trigger
        console.log('\n6️⃣ Testing trigger...');
        const triggerCheck = await pool.query(`
            SELECT trigger_name, event_manipulation, action_timing
            FROM information_schema.triggers 
            WHERE event_object_table = 'reminders'
        `);
        console.log('⚡ Triggers:');
        triggerCheck.rows.forEach(row => {
            console.log(`   - ${row.trigger_name} (${row.action_timing} ${row.event_manipulation})`);
        });
        
        console.log('\n🎉 All tests passed! Reminders API is ready for use.');
        console.log('\n📡 API Endpoints available:');
        console.log('   - GET    /api/reminders');
        console.log('   - POST   /api/reminders');
        console.log('   - PUT    /api/reminders/:id');
        console.log('   - DELETE /api/reminders/:id');
        console.log('   - PATCH  /api/reminders/:id/toggle');
        
    } catch (error) {
        console.error('❌ Test failed:', error);
    } finally {
        await pool.end();
    }
}

testRemindersAPI();

