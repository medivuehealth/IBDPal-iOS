const { Client } = require('pg');
const bcrypt = require('bcrypt');
const fs = require('fs');
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '../IBDPal-Server/config.env') });

const setupDemoUser2 = async () => {
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
    const userId = 'demo2_' + Date.now();
    const email = 'demo2@ibdpal.org';
    const password = 'demo456';
    const hashedPassword = await bcrypt.hash(password, 10);

    console.log('Setting up demo user 2:', email);
    console.log('='.repeat(50));

    // 1. Create demo user 2
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
      userId, email, email, hashedPassword, 'Alex', 'Johnson',
      '1992-03-22', 'Male', '+1-555-0456', '456 Wellness Ave', 'San Francisco',
      'CA', 'USA', '94102', 'Sarah Johnson', '+1-555-0457',
      new Date(), new Date()
    ]);

    console.log('✅ Demo user 2 created/updated');

    // 2. Create micronutrient profile
    await client.query(`
      INSERT INTO micronutrient_profiles (
        user_id, age, weight, height, gender, created_at, updated_at
      ) VALUES ($1, $2, $3, $4, $5, $6, $7)
      ON CONFLICT (user_id) DO UPDATE SET
        age = $2, weight = $3, height = $4, gender = $5, updated_at = $7
    `, [userId, 32, 78.2, 180.0, 'Male', new Date(), new Date()]);

    console.log('✅ Micronutrient profile created');

    // 3. Add sample supplements
    const supplements = [
      ['Vitamin D3', 'Vitamins', '4000', 'IU', 'Daily', '2024-01-01', 'Higher dose for male IBD patient'],
      ['Magnesium', 'Minerals', '400', 'mg', 'Daily', '2024-01-01', 'Muscle and nerve function support'],
      ['Probiotics', 'Probiotics', '100', 'mg', 'Daily', '2024-01-01', 'Multi-strain gut health support'],
      ['Omega-3', 'Omega-3', '2000', 'mg', 'Daily', '2024-01-01', 'High-dose anti-inflammatory'],
      ['B12', 'Vitamins', '2500', 'mcg', 'Daily', '2024-01-01', 'High-dose for energy and nerve function'],
      ['Zinc', 'Minerals', '15', 'mg', 'Daily', '2024-01-01', 'Immune system support'],
      ['Curcumin', 'Antioxidants', '1000', 'mg', 'Daily', '2024-01-01', 'Anti-inflammatory turmeric extract']
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
        breakfast: 'Protein smoothie with spinach and berries',
        lunch: 'Grilled chicken with quinoa and roasted vegetables',
        dinner: 'Baked salmon with sweet potato and asparagus',
        snacks: 'Mixed nuts and Greek yogurt',
        calories: 2150, protein: 120, carbs: 195, fiber: 28, fat: 85,
        bowel_frequency: 1, bristol_scale: 3, pain_severity: 1, sleep_hours: 8,
        stress_level: 2, mood_level: 8, water_intake: 3.2
      },
      {
        date: new Date(today.getTime() - 5 * 24 * 60 * 60 * 1000),
        breakfast: 'Oatmeal with banana, nuts, and protein powder',
        lunch: 'Turkey and avocado wrap with side salad',
        dinner: 'Lentil curry with brown rice and vegetables',
        snacks: 'Apple slices with almond butter',
        calories: 2280, protein: 125, carbs: 210, fiber: 32, fat: 92,
        bowel_frequency: 2, bristol_scale: 4, pain_severity: 2, sleep_hours: 8,
        stress_level: 3, mood_level: 7, water_intake: 3.5
      },
      {
        date: new Date(today.getTime() - 4 * 24 * 60 * 60 * 1000),
        breakfast: 'Scrambled eggs with spinach and whole grain toast',
        lunch: 'Grilled fish with roasted vegetables and quinoa',
        dinner: 'Vegetable stir-fry with tofu and brown rice',
        snacks: 'Trail mix with dried fruit',
        calories: 2020, protein: 110, carbs: 185, fiber: 26, fat: 78,
        bowel_frequency: 1, bristol_scale: 3, pain_severity: 1, sleep_hours: 9.0,
        stress_level: 1, mood_level: 9, water_intake: 3.8
      },
      {
        date: new Date(today.getTime() - 3 * 24 * 60 * 60 * 1000),
        breakfast: 'Greek yogurt parfait with granola and berries',
        lunch: 'Chicken and vegetable soup with whole grain bread',
        dinner: 'Baked cod with roasted vegetables and wild rice',
        snacks: 'Rice cakes with hummus',
        calories: 1950, protein: 105, carbs: 175, fiber: 24, fat: 72,
        bowel_frequency: 2, bristol_scale: 4, pain_severity: 2, sleep_hours: 7.5,
        stress_level: 4, mood_level: 6, water_intake: 3.0
      },
      {
        date: new Date(today.getTime() - 2 * 24 * 60 * 60 * 1000),
        breakfast: 'Protein pancakes with berries and maple syrup',
        lunch: 'Quinoa salad with chickpeas and vegetables',
        dinner: 'Grilled chicken with steamed broccoli and sweet potato',
        snacks: 'Banana with peanut butter',
        calories: 2120, protein: 115, carbs: 200, fiber: 30, fat: 88,
        bowel_frequency: 1, bristol_scale: 3, pain_severity: 1, sleep_hours: 8,
        stress_level: 2, mood_level: 8, water_intake: 3.6
      },
      {
        date: new Date(today.getTime() - 1 * 24 * 60 * 60 * 1000),
        breakfast: 'Avocado toast with eggs and spinach',
        lunch: 'Salmon salad with mixed greens and olive oil dressing',
        dinner: 'Turkey meatballs with zucchini noodles and marinara',
        snacks: 'Cottage cheese with fruit',
        calories: 2080, protein: 118, carbs: 185, fiber: 28, fat: 82,
        bowel_frequency: 2, bristol_scale: 4, pain_severity: 2, sleep_hours: 8,
        stress_level: 3, mood_level: 7, water_intake: 3.4
      },
      {
        date: today,
        breakfast: 'Green smoothie with protein powder and chia seeds',
        lunch: 'Grilled chicken wrap with vegetables and hummus',
        dinner: 'Baked salmon with quinoa and roasted vegetables',
        snacks: 'Mixed nuts and dark chocolate',
        calories: 2200, protein: 128, carbs: 195, fiber: 32, fat: 95,
        bowel_frequency: 1, bristol_scale: 3, pain_severity: 1, sleep_hours: 8,
        stress_level: 2, mood_level: 8, water_intake: 3.7
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
    const sessionToken = 'demo2_session_' + Date.now();
    const sessionHash = await bcrypt.hash(sessionToken, 10);
    const expiresAt = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000); // 30 days

    await client.query(`
      INSERT INTO user_sessions (
        user_id, token_hash, device_info, ip_address, created_at, expires_at, is_active
      ) VALUES ($1, $2, $3, $4, $5, $6, $7)
    `, [userId, sessionHash, 'Demo Device 2', '127.0.0.1', new Date(), expiresAt, true]);

    console.log('✅ Demo session created');

    // 6. Add login history
    await client.query(`
      INSERT INTO login_history (
        user_id, login_timestamp, ip_address, user_agent, success, failure_reason
      ) VALUES ($1, $2, $3, $4, $5, $6)
    `, [userId, new Date(), '127.0.0.1', 'Demo Browser 2', true, null]);

    console.log('✅ Login history added');

    console.log('\n' + '='.repeat(50));
    console.log('🎉 DEMO USER 2 SETUP COMPLETE!');
    console.log('='.repeat(50));
    console.log('Email: demo2@ibdpal.org');
    console.log('Password: demo456');
    console.log('User ID:', userId);
    console.log('\nSample data includes:');
    console.log('- 7 days of nutrition tracking');
    console.log('- Micronutrient profile (32-year-old male, 78.2kg)');
    console.log('- 7 sample supplements');
    console.log('- Health metrics and trends');
    console.log('- Bowel health tracking');
    console.log('- Sleep and stress monitoring');
    console.log('\nReady for testing! 🚀');

  } catch (error) {
    console.error('❌ Error setting up demo user 2:', error);
  } finally {
    await client.end();
  }
};

setupDemoUser2();
