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

async function add7DayEntries() {
    const client = await pool.connect();
    
    try {
        console.log('🔍 Adding 7-day meal entries for demo@ibdpal.org...');
        
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
        
        // Create entries for the last 7 days
        const today = new Date();
        const entries = [];
        
        // Sample meal combinations with nutrient-dense foods for demo
        const mealCombinations = [
            {
                breakfast: "Oatmeal with blueberries, walnuts, and chia seeds",
                lunch: "Grilled salmon with quinoa, spinach, and roasted sweet potato",
                dinner: "Chicken breast with brown rice, broccoli, and bell peppers",
                snacks: "Greek yogurt with mixed berries and almonds"
            },
            {
                breakfast: "Scrambled eggs with spinach, tomatoes, and whole grain toast",
                lunch: "Turkey and avocado wrap with kale salad and chickpeas",
                dinner: "Baked cod with jasmine rice, asparagus, and carrots",
                snacks: "Apple slices with peanut butter and dark chocolate"
            },
            {
                breakfast: "Smoothie bowl with banana, strawberries, spinach, and protein powder",
                lunch: "Lentil curry with brown rice and steamed vegetables",
                dinner: "Beef stir-fry with mixed vegetables and jasmine rice",
                snacks: "Mixed nuts, dried cranberries, and dark chocolate"
            },
            {
                breakfast: "Greek yogurt parfait with granola, berries, and flax seeds",
                lunch: "Grilled chicken salad with mixed greens, tomatoes, and olive oil",
                dinner: "Pasta with marinara sauce, steamed broccoli, and parmesan cheese",
                snacks: "Carrot sticks with hummus and whole grain crackers"
            },
            {
                breakfast: "Whole grain pancakes with maple syrup and fresh fruit",
                lunch: "Tuna salad sandwich with avocado and side of mixed fruit",
                dinner: "Baked chicken with roasted vegetables and mashed sweet potato",
                snacks: "Cheese and whole grain crackers with grapes"
            },
            {
                breakfast: "Avocado toast with poached egg and cherry tomatoes",
                lunch: "Quinoa bowl with black beans, corn, and fresh vegetables",
                dinner: "Grilled fish with rice and steamed asparagus and green beans",
                snacks: "Trail mix with nuts, seeds, and dried fruit"
            },
            {
                breakfast: "Fortified cereal with milk, banana, and berries",
                lunch: "Vegetable soup with whole grain roll and side salad",
                dinner: "Pork tenderloin with mashed potatoes, peas, and green beans",
                snacks: "Orange slices and mixed nuts"
            }
        ];
        
        // Sample supplement combinations (varied for demo testing)
        const supplementCombinations = [
            [
                { supplement_id: 1, supplement_name: "Vitamin D3 (Cholecalciferol)", dosage: 2000, unit: "IU", category: "Vitamins", time_taken: "08:00" },
                { supplement_id: 2, supplement_name: "Vitamin B12 (Methylcobalamin)", dosage: 1000, unit: "mcg", category: "Vitamins", time_taken: "08:00" },
                { supplement_id: 3, supplement_name: "Iron (Ferrous Sulfate)", dosage: 18, unit: "mg", category: "Minerals", time_taken: "14:00" },
                { supplement_id: 4, supplement_name: "Omega-3 Fish Oil", dosage: 1000, unit: "mg", category: "Other", time_taken: "12:00" }
            ],
            [
                { supplement_id: 1, supplement_name: "Vitamin D3 (Cholecalciferol)", dosage: 2000, unit: "IU", category: "Vitamins", time_taken: "08:00" },
                { supplement_id: 5, supplement_name: "Multivitamin", dosage: 1, unit: "tablets", category: "Vitamins", time_taken: "08:00" },
                { supplement_id: 6, supplement_name: "Calcium", dosage: 600, unit: "mg", category: "Minerals", time_taken: "20:00" }
            ],
            [
                { supplement_id: 1, supplement_name: "Vitamin D3 (Cholecalciferol)", dosage: 2000, unit: "IU", category: "Vitamins", time_taken: "08:00" },
                { supplement_id: 2, supplement_name: "Vitamin B12 (Methylcobalamin)", dosage: 1000, unit: "mcg", category: "Vitamins", time_taken: "08:00" },
                { supplement_id: 7, supplement_name: "Zinc", dosage: 15, unit: "mg", category: "Minerals", time_taken: "20:00" }
            ],
            [
                { supplement_id: 1, supplement_name: "Vitamin D3 (Cholecalciferol)", dosage: 2000, unit: "IU", category: "Vitamins", time_taken: "08:00" },
                { supplement_id: 3, supplement_name: "Iron (Ferrous Sulfate)", dosage: 18, unit: "mg", category: "Minerals", time_taken: "14:00" },
                { supplement_id: 4, supplement_name: "Omega-3 Fish Oil", dosage: 1000, unit: "mg", category: "Other", time_taken: "12:00" }
            ],
            [
                { supplement_id: 1, supplement_name: "Vitamin D3 (Cholecalciferol)", dosage: 2000, unit: "IU", category: "Vitamins", time_taken: "08:00" },
                { supplement_id: 8, supplement_name: "Vitamin C", dosage: 500, unit: "mg", category: "Vitamins", time_taken: "08:00" },
                { supplement_id: 9, supplement_name: "Magnesium", dosage: 200, unit: "mg", category: "Minerals", time_taken: "20:00" }
            ],
            [
                { supplement_id: 1, supplement_name: "Vitamin D3 (Cholecalciferol)", dosage: 2000, unit: "IU", category: "Vitamins", time_taken: "08:00" },
                { supplement_id: 5, supplement_name: "Multivitamin", dosage: 1, unit: "tablets", category: "Vitamins", time_taken: "08:00" },
                { supplement_id: 10, supplement_name: "Probiotics", dosage: 10, unit: "billion CFU", category: "Probiotics", time_taken: "20:00" }
            ],
            [
                { supplement_id: 1, supplement_name: "Vitamin D3 (Cholecalciferol)", dosage: 2000, unit: "IU", category: "Vitamins", time_taken: "08:00" },
                { supplement_id: 2, supplement_name: "Vitamin B12 (Methylcobalamin)", dosage: 1000, unit: "mcg", category: "Vitamins", time_taken: "08:00" },
                { supplement_id: 11, supplement_name: "Folate", dosage: 400, unit: "mcg", category: "Vitamins", time_taken: "08:00" }
            ]
        ];
        
        // Create entries for the last 7 days
        for (let i = 0; i < 7; i++) {
            const entryDate = new Date(today);
            entryDate.setDate(today.getDate() - i);
            
            const mealCombo = mealCombinations[i];
            const supplementCombo = supplementCombinations[i];
            
            const entry = {
                user_id: userId,
                entry_date: entryDate.toISOString().split('T')[0],
                breakfast: mealCombo.breakfast,
                lunch: mealCombo.lunch,
                dinner: mealCombo.dinner,
                snacks: mealCombo.snacks,
                supplements_taken: true,
                supplements_count: supplementCombo.length,
                supplement_details: JSON.stringify(supplementCombo),
                calories: Math.floor(Math.random() * 400) + 1800, // 1800-2200 calories
                protein: Math.floor(Math.random() * 20) + 60, // 60-80g protein
                carbs: Math.floor(Math.random() * 50) + 200, // 200-250g carbs
                fiber: Math.floor(Math.random() * 10) + 20, // 20-30g fiber
                has_allergens: false,
                meals_per_day: 3,
                hydration_level: Math.floor(Math.random() * 3) + 6, // 6-8 glasses
                bowel_frequency: Math.floor(Math.random() * 2) + 1, // 1-2 times
                bristol_scale: Math.floor(Math.random() * 2) + 3, // 3-4 (normal)
                urgency_level: Math.floor(Math.random() * 2), // 0-1 (low)
                blood_present: false,
                pain_location: "None",
                pain_severity: Math.floor(Math.random() * 2), // 0-1 (low)
                pain_time: "None",
                medication_taken: false,
                medication_type: "None",
                dosage_level: "0",
                sleep_hours: Math.floor(Math.random() * 2) + 7, // 7-8 hours
                stress_level: Math.floor(Math.random() * 3) + 3, // 3-5 (moderate)
                fatigue_level: Math.floor(Math.random() * 3) + 3, // 3-5 (moderate)
                notes: "",
                created_at: new Date().toISOString(),
                menstruation: "not_applicable",
                mood_level: Math.floor(Math.random() * 2) + 4, // 4-5 (good)
                sleep_quality: Math.floor(Math.random() * 2) + 4, // 4-5 (good)
                sleep_notes: "",
                water_intake: Math.floor(Math.random() * 500) + 2000, // 2000-2500ml
                other_fluids: Math.floor(Math.random() * 200) + 200, // 200-400ml
                fluid_type: "Water",
                stress_source: "",
                coping_strategies: "",
                updated_at: new Date().toISOString()
            };
            
            entries.push(entry);
        }
        
        // Insert entries
        console.log('\n📝 Adding 7 journal entries...');
        for (const entry of entries) {
            const result = await client.query(
                `INSERT INTO journal_entries (
                    user_id, entry_date, breakfast, lunch, dinner, snacks,
                    supplements_taken, supplements_count, supplement_details,
                    calories, protein, carbs, fiber, has_allergens, meals_per_day,
                    hydration_level, bowel_frequency, bristol_scale, urgency_level,
                    blood_present, pain_location, pain_severity, pain_time,
                    medication_taken, medication_type, dosage_level, sleep_hours,
                    stress_level, fatigue_level, notes, created_at, menstruation,
                    mood_level, sleep_quality, sleep_notes, water_intake,
                    other_fluids, fluid_type, stress_source, coping_strategies, updated_at
                ) VALUES (
                    $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15,
                    $16, $17, $18, $19, $20, $21, $22, $23, $24, $25, $26, $27, $28,
                    $29, $30, $31, $32, $33, $34, $35, $36, $37, $38, $39, $40, $41
                )`,
                [
                    entry.user_id, entry.entry_date, entry.breakfast, entry.lunch, entry.dinner, entry.snacks,
                    entry.supplements_taken, entry.supplements_count, entry.supplement_details,
                    entry.calories, entry.protein, entry.carbs, entry.fiber, entry.has_allergens, entry.meals_per_day,
                    entry.hydration_level, entry.bowel_frequency, entry.bristol_scale, entry.urgency_level,
                    entry.blood_present, entry.pain_location, entry.pain_severity, entry.pain_time,
                    entry.medication_taken, entry.medication_type, entry.dosage_level, entry.sleep_hours,
                    entry.stress_level, entry.fatigue_level, entry.notes, entry.created_at, entry.menstruation,
                    entry.mood_level, entry.sleep_quality, entry.sleep_notes, entry.water_intake,
                    entry.other_fluids, entry.fluid_type, entry.stress_source, entry.coping_strategies, entry.updated_at
                ]
            );
            console.log(`✅ Added entry for ${entry.entry_date}`);
        }
        
        console.log('\n🎉 Successfully added 7 daily log entries!');
        console.log('\n📊 Demo-Ready Summary:');
        console.log('  🍽️  Nutrient-dense foods: Salmon, quinoa, spinach, sweet potato, berries');
        console.log('  🥗 Rich in micronutrients: Dark leafy greens, colorful vegetables, nuts, seeds');
        console.log('  🐟 High-quality proteins: Fish, chicken, eggs, legumes, Greek yogurt');
        console.log('  💊 Varied supplements: Vitamin D (IU), B12, Iron, Omega-3, Multivitamins');
        console.log('  📈 Realistic macronutrient profiles: 1800-2200 calories, 60-80g protein');
        console.log('  🏥 IBD-relevant health metrics: Bowel frequency, pain levels, sleep quality');
        console.log('  🔬 Perfect for showcasing micronutrient analysis and unit conversions!');
        
        // Show what was added
        console.log('\n📋 Sample entries added:');
        for (let i = 0; i < 3; i++) {
            const entry = entries[i];
            console.log(`\n📅 ${entry.entry_date}:`);
            console.log(`  🍽️  Breakfast: ${entry.breakfast}`);
            console.log(`  🍽️  Lunch: ${entry.lunch}`);
            console.log(`  🍽️  Dinner: ${entry.dinner}`);
            console.log(`  💊 Supplements: ${JSON.parse(entry.supplement_details).length} items`);
        }
        
    } catch (error) {
        console.error('❌ Error adding 7-day entries:', error);
    } finally {
        client.release();
        await pool.end();
    }
}

// Run the script
add7DayEntries().catch(console.error);
