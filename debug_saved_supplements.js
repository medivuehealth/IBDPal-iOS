const { Pool } = require('pg');
const path = require('path');

// Load environment variables
require('dotenv').config({ path: path.join(__dirname, 'config.env') });

// Database configuration
const pool = new Pool({
    connectionString: process.env.DATABASE_URL,
    ssl: {
        rejectUnauthorized: false
    }
});

async function debugSavedSupplements() {
    const client = await pool.connect();
    
    try {
        console.log('🔍 Debugging saved supplements for demo@ibdpal.org...');
        
        // Get user ID
        const userResult = await client.query(
            `SELECT user_id FROM users WHERE email = 'demo@ibdpal.org'`
        );
        
        if (userResult.rows.length === 0) {
            console.log('❌ User not found');
            return;
        }
        
        const userId = userResult.rows[0].user_id;
        console.log(`📊 User ID: ${userId}`);
        
        // Check micronutrient profile supplements
        console.log('\n📊 Micronutrient Profile Supplements:');
        const profileResult = await client.query(
            `SELECT name, category, dosage, unit, frequency, created_at
             FROM micronutrient_supplements 
             WHERE user_id = $1
             ORDER BY created_at DESC`,
            [userId]
        );
        
        console.log(`Found ${profileResult.rows.length} saved supplements:`);
        for (const supplement of profileResult.rows) {
            console.log(`  📝 ${supplement.name}: ${supplement.dosage} ${supplement.unit} (${supplement.frequency}) - ${supplement.created_at}`);
            
            // Calculate what this would convert to
            if (supplement.name.toLowerCase().includes('vitamin d') && supplement.unit === 'IU') {
                const mcgEquivalent = supplement.dosage * 0.025;
                const displayIU = mcgEquivalent * 40;
                console.log(`    💡 IU conversion: ${supplement.dosage} IU → ${mcgEquivalent} mcg → ${displayIU} IU (for display)`);
            }
        }
        
        // Check if there are any Vitamin D supplements that might be causing the issue
        const vitaminDSupplements = profileResult.rows.filter(s => 
            s.name.toLowerCase().includes('vitamin d') || s.name.toLowerCase().includes('d3')
        );
        
        if (vitaminDSupplements.length > 0) {
            console.log('\n🔍 Vitamin D Supplements Analysis:');
            let totalMcg = 0;
            
            for (const supplement of vitaminDSupplements) {
                let mcgValue;
                if (supplement.unit === 'IU') {
                    mcgValue = supplement.dosage * 0.025;
                } else if (supplement.unit === 'mcg') {
                    mcgValue = supplement.dosage;
                } else if (supplement.unit === 'mg') {
                    mcgValue = supplement.dosage * 1000;
                } else {
                    mcgValue = 0;
                }
                
                totalMcg += mcgValue;
                console.log(`  📝 ${supplement.name}: ${supplement.dosage} ${supplement.unit} → ${mcgValue} mcg`);
            }
            
            const displayIU = totalMcg * 40;
            console.log(`\n  🎯 Total Vitamin D: ${totalMcg} mcg → ${displayIU} IU (for display)`);
            
            if (Math.abs(displayIU - 80008) < 1000) {
                console.log(`  ✅ This matches the 80,008 IU issue!`);
            }
        }
        
        // Check journal entries for comparison
        console.log('\n📊 Journal Entries (Last 7 days):');
        const journalResult = await client.query(
            `SELECT entry_id, entry_date, supplement_details
             FROM journal_entries 
             WHERE user_id = $1 AND entry_date >= CURRENT_DATE - INTERVAL '7 days'
             ORDER BY entry_date DESC`,
            [userId]
        );
        
        console.log(`Found ${journalResult.rows.length} journal entries:`);
        for (const entry of journalResult.rows) {
            if (entry.supplement_details) {
                try {
                    const supplementDetails = typeof entry.supplement_details === 'string' 
                        ? JSON.parse(entry.supplement_details) 
                        : entry.supplement_details;
                    
                    if (Array.isArray(supplementDetails)) {
                        for (const supplement of supplementDetails) {
                            if (supplement.supplement_name && supplement.supplement_name.toLowerCase().includes('vitamin d')) {
                                console.log(`  📅 ${entry.entry_date}: ${supplement.supplement_name} - ${supplement.dosage} ${supplement.unit}`);
                            }
                        }
                    }
                } catch (error) {
                    // Skip parsing errors
                }
            }
        }
        
    } catch (error) {
        console.error('❌ Error debugging saved supplements:', error);
    } finally {
        client.release();
        await pool.end();
    }
}

// Run the debug
debugSavedSupplements().catch(console.error);





