const { Client } = require('pg');
const bcrypt = require('bcrypt');
const fs = require('fs');
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '../IBDPal-Server/config.env') });

const setupDemoUser = async () => {
  const client = new Client({
    connectionString: process.env.DATABASE_URL || 'postgresql://neondb_owner:npg_ILP7Oz0VhYKj@ep-lucky-wildflower-ae5uww1l-pooler.c-2.us-east-2.aws.neon.tech/medivue?sslmode=require&channel_binding=require',
    ssl: {
      rejectUnauthorized: false
    }
  });

  try {
    await client.connect();
    console.log('Connected to database');

    // Generate user ID
    const userId = 'demo_' + Date.now();
    const email = 'info@ibdpal.org';
    const password = 'demo123';
    const hashedPassword = await bcrypt.hash(password, 10);

    console.log('Setting up demo user:', email);
    console.log('='.repeat(50));

    // 1. Create demo user
    await client.query(`
      INSERT INTO users (
        user_id, username, email, password_hash, first_name, last_name, 
        date_of_birth, gender, phone_number, address, city, 
        state, country, postal_code, emergency_contact_name, 
        emergency_contact_phone, created_at, updated_at
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18)
      ON CONFLICT (email) DO UPDATE SET
        password_hash = $4,
        updated_at = $18
    `, [
      userId, 'demo_user', email, hashedPassword, 'Demo', 'User',
      '1985-06-15', 'Female', '+1-555-0123', '123 Health St', 'Raleigh',
      'NC', 'USA', '27601', 'Emergency Contact', '+1-555-0124',
      new Date(), new Date()
    ]);

    console.log('✅ Demo user created/updated');

    // 2. Create micronutrient profile
    await client.query(`
      INSERT INTO micronutrient_profiles (
        user_id, age, weight, height, gender, created_at, updated_at
      ) VALUES ($1, $2, $3, $4, $5, $6, $7)
      ON CONFLICT (user_id) DO UPDATE SET
        age = $2, weight = $3, height = $4, gender = $5, updated_at = $7
    `, [userId, 38, 65.5, 165.0, 'Female', new Date(), new Date()]);

    console.log('✅ Micronutrient profile created');

    // 3. Add sample supplements
    const supplements = [
      ['Vitamin D3', 'Vitamins', '2000', 'IU', 'Daily', '2024-01-01', 'Essential for IBD patients'],
      ['Iron', 'Minerals', '18', 'mg', 'Daily', '2024-01-01', 'Prevents anemia common in IBD'],
      ['Probiotics', 'Probiotics', '50', 'mg', 'Daily', '2024-01-01', 'Gut health support'],
      ['Omega-3', 'Omega-3', '1000', 'mg', 'Daily', '2024-01-01', 'Anti-inflammatory support'],
      ['B12', 'Vitamins', '1000', 'mcg', 'Daily', '2024-01-01', 'Energy and nerve function']
    ];

    // Get profile ID
    const profileResult = await client.query('SELECT id FROM micronutrient_profiles WHERE user_id = $1', [userId]);
    const profileId = profileResult.rows[0].id;

    // Clear existing supplements
    await client.query('DELETE FROM micronutrient_supplements WHERE profile_id = $1', [profileId]);

    // Add supplements
    for (const [name, category, dosage, unit, frequency, startDate, notes] of supplements) {
      await client.query(`
        INSERT INTO micronutrient_supplements (
          profile_id, name, category, dosage, unit, frequency, start_date, notes, is_active, created_at, updated_at
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
      `, [profileId, name, category, dosage, unit, frequency, startDate, notes, true, new Date(), new Date()]);
    }

    console.log('✅ Sample supplements added');

    // 4. Create sample journal entries for the last 7 days
    const today = new Date();
    const sampleEntries = [
      {
        date: new Date(today.getTime() - 6 * 24 * 60 * 60 * 1000),
        breakfast: 'Oatmeal with banana and almond milk',
        lunch: 'Grilled chicken salad with quinoa',
        dinner: 'Baked salmon with steamed vegetables',
        snacks: 'Greek yogurt with berries',
        calories: 1850, protein: 95, carbs: 180, fiber: 25, fat: 65,
        bowel_frequency: 2, bristol_scale: 4, pain_severity: 2, sleep_hours: 8,
        stress_level: 3, mood_level: 7, water_intake: 2.5
      },
      {
        date: new Date(today.getTime() - 5 * 24 * 60 * 60 * 1000),
        breakfast: 'Scrambled eggs with spinach',
        lunch: 'Turkey and avocado wrap',
        dinner: 'Lentil soup with brown rice',
        snacks: 'Apple slices with almond butter',
        calories: 1920, protein: 88, carbs: 195, fiber: 28, fat: 72,
        bowel_frequency: 1, bristol_scale: 3, pain_severity: 1, sleep_hours: 8.0,
        stress_level: 2, mood_level: 8, water_intake: 2.8
      },
      {
        date: new Date(today.getTime() - 4 * 24 * 60 * 60 * 1000),
        breakfast: 'Smoothie bowl with berries and granola',
        lunch: 'Grilled fish with sweet potato',
        dinner: 'Vegetable stir-fry with tofu',
        snacks: 'Mixed nuts and dried fruit',
        calories: 1780, protein: 82, carbs: 165, fiber: 22, fat: 68,
        bowel_frequency: 3, bristol_scale: 5, pain_severity: 3,         sleep_hours: 7,
        stress_level: 4, mood_level: 6, water_intake: 2.2
      },
      {
        date: new Date(today.getTime() - 3 * 24 * 60 * 60 * 1000),
        breakfast: 'Greek yogurt parfait with granola',
        lunch: 'Chicken and vegetable soup',
        dinner: 'Baked cod with roasted vegetables',
        snacks: 'Rice cakes with hummus',
        calories: 1650, protein: 78, carbs: 155, fiber: 20, fat: 58,
        bowel_frequency: 2, bristol_scale: 4, pain_severity: 2, sleep_hours: 7.0,
        stress_level: 3, mood_level: 7, water_intake: 2.6
      },
      {
        date: new Date(today.getTime() - 2 * 24 * 60 * 60 * 1000),
        breakfast: 'Oatmeal with berries and nuts',
        lunch: 'Quinoa salad with chickpeas',
        dinner: 'Grilled chicken with steamed broccoli',
        snacks: 'Banana with peanut butter',
        calories: 1890, protein: 92, carbs: 175, fiber: 26, fat: 70,
        bowel_frequency: 1, bristol_scale: 3, pain_severity: 1, sleep_hours: 8.5,
        stress_level: 2, mood_level: 8, water_intake: 3.0
      },
      {
        date: new Date(today.getTime() - 1 * 24 * 60 * 60 * 1000),
        breakfast: 'Avocado toast with eggs',
        lunch: 'Salmon salad with mixed greens',
        dinner: 'Turkey meatballs with zucchini noodles',
        snacks: 'Cottage cheese with fruit',
        calories: 1820, protein: 89, carbs: 170, fiber: 24, fat: 66,
        bowel_frequency: 2, bristol_scale: 4, pain_severity: 2, sleep_hours: 7.5,
        stress_level: 3, mood_level: 7, water_intake: 2.7
      },
      {
        date: today,
        breakfast: 'Protein smoothie with spinach',
        lunch: 'Grilled chicken wrap with vegetables',
        dinner: 'Baked salmon with quinoa',
        snacks: 'Trail mix with nuts and seeds',
        calories: 1950, protein: 96, carbs: 185, fiber: 27, fat: 74,
        bowel_frequency: 1, bristol_scale: 3, pain_severity: 1, sleep_hours: 8.0,
        stress_level: 2, mood_level: 8, water_intake: 2.9
      }
    ];

    // Clear existing journal entries
    await client.query('DELETE FROM journal_entries WHERE user_id = $1', [userId]);

    // Add sample journal entries
    for (const entry of sampleEntries) {
      await client.query(`
        INSERT INTO journal_entries (
          user_id, entry_date, calories, protein, carbs, fiber,
          breakfast, lunch, dinner, snacks,
          bowel_frequency, bristol_scale, pain_severity, sleep_hours,
          stress_level, mood_level, water_intake, created_at, updated_at
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19)
      `, [
        userId, entry.date, entry.calories, entry.protein, entry.carbs, entry.fiber,
        entry.breakfast, entry.lunch, entry.dinner, entry.snacks,
        entry.bowel_frequency, entry.bristol_scale, entry.pain_severity, entry.sleep_hours,
        entry.stress_level, entry.mood_level, entry.water_intake, new Date(), new Date()
      ]);
    }

    console.log('✅ Sample journal entries created (7 days)');

    // 5. Create a login session for the demo user
    const sessionToken = 'demo_session_' + Date.now();
    const sessionHash = await bcrypt.hash(sessionToken, 10);
    const expiresAt = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000); // 30 days

    await client.query(`
      INSERT INTO user_sessions (
        user_id, token_hash, device_info, ip_address, created_at, expires_at, is_active
      ) VALUES ($1, $2, $3, $4, $5, $6, $7)
    `, [userId, sessionHash, 'Demo Device', '127.0.0.1', new Date(), expiresAt, true]);

    console.log('✅ Demo session created');

    // 6. Add login history
    await client.query(`
      INSERT INTO login_history (
        user_id, login_timestamp, ip_address, user_agent, success, failure_reason
      ) VALUES ($1, $2, $3, $4, $5, $6)
    `, [userId, new Date(), '127.0.0.1', 'Demo Browser', true, null]);

    console.log('✅ Login history added');

    console.log('\n' + '='.repeat(50));
    console.log('🎉 DEMO USER SETUP COMPLETE!');
    console.log('='.repeat(50));
    console.log('Email: info@ibdpal.org');
    console.log('Password: demo123');
    console.log('User ID:', userId);
    console.log('\nSample data includes:');
    console.log('- 7 days of nutrition tracking');
    console.log('- Micronutrient profile (38-year-old female, 65.5kg)');
    console.log('- 5 sample supplements');
    console.log('- Health metrics and trends');
    console.log('- Bowel health tracking');
    console.log('- Sleep and stress monitoring');
    console.log('\nReady for App Store review! 🚀');

  } catch (error) {
    console.error('❌ Error setting up demo user:', error);
  } finally {
    await client.end();
  }
};

setupDemoUser();
