-- Create journal_entries table with comprehensive meal nutrition tracking
CREATE TABLE IF NOT EXISTS journal_entries (
    entry_id SERIAL PRIMARY KEY,
    user_id TEXT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    entry_date DATE NOT NULL,
    entry_type TEXT NOT NULL,
    
    -- Basic nutrition (cumulative totals)
    calories DECIMAL(8,2) DEFAULT 0,
    protein DECIMAL(8,2) DEFAULT 0,
    carbs DECIMAL(8,2) DEFAULT 0,
    fiber DECIMAL(8,2) DEFAULT 0,
    fat DECIMAL(8,2) DEFAULT 0,
    
    -- Meal descriptions
    breakfast TEXT DEFAULT '',
    lunch TEXT DEFAULT '',
    dinner TEXT DEFAULT '',
    snacks TEXT DEFAULT '',
    
    -- Individual meal nutrition tracking
    breakfast_calories DECIMAL(8,2) DEFAULT 0,
    breakfast_protein DECIMAL(8,2) DEFAULT 0,
    breakfast_carbs DECIMAL(8,2) DEFAULT 0,
    breakfast_fiber DECIMAL(8,2) DEFAULT 0,
    breakfast_fat DECIMAL(8,2) DEFAULT 0,
    
    lunch_calories DECIMAL(8,2) DEFAULT 0,
    lunch_protein DECIMAL(8,2) DEFAULT 0,
    lunch_carbs DECIMAL(8,2) DEFAULT 0,
    lunch_fiber DECIMAL(8,2) DEFAULT 0,
    lunch_fat DECIMAL(8,2) DEFAULT 0,
    
    dinner_calories DECIMAL(8,2) DEFAULT 0,
    dinner_protein DECIMAL(8,2) DEFAULT 0,
    dinner_carbs DECIMAL(8,2) DEFAULT 0,
    dinner_fiber DECIMAL(8,2) DEFAULT 0,
    dinner_fat DECIMAL(8,2) DEFAULT 0,
    
    snack_calories DECIMAL(8,2) DEFAULT 0,
    snack_protein DECIMAL(8,2) DEFAULT 0,
    snack_carbs DECIMAL(8,2) DEFAULT 0,
    snack_fiber DECIMAL(8,2) DEFAULT 0,
    snack_fat DECIMAL(8,2) DEFAULT 0,
    
    -- Bowel health
    bowel_frequency INTEGER DEFAULT 0,
    bristol_scale INTEGER DEFAULT 4 CHECK (bristol_scale >= 1 AND bristol_scale <= 7),
    urgency_level INTEGER DEFAULT 0,
    blood_present BOOLEAN DEFAULT FALSE,
    mucus_present BOOLEAN DEFAULT FALSE,
    
    -- Pain tracking
    pain_location TEXT DEFAULT 'None' CHECK (pain_location IN ('None', 'full_abdomen', 'lower_abdomen', 'upper_abdomen')),
    pain_severity INTEGER DEFAULT 0,
    pain_time TEXT DEFAULT 'None' CHECK (pain_time IN ('None', 'morning', 'afternoon', 'evening', 'night', 'variable')),
    
    -- Medication
    medication_taken BOOLEAN DEFAULT FALSE,
    medication_type TEXT DEFAULT 'None' CHECK (medication_type IN ('None', 'biologic', 'immunosuppressant', 'steroid')),
    dosage_level TEXT DEFAULT '0',
    
    -- Sleep
    sleep_hours DECIMAL(4,2) DEFAULT 0,
    sleep_quality INTEGER DEFAULT 5,
    bedtime TIME,
    wake_time TIME,
    sleep_interruptions INTEGER DEFAULT 0,
    
    -- Stress and mood
    stress_level INTEGER DEFAULT 5,
    stress_source TEXT DEFAULT '',
    coping_strategies TEXT DEFAULT '',
    mood_level INTEGER DEFAULT 5,
    
    -- Hydration
    water_intake DECIMAL(6,2) DEFAULT 0,
    other_fluids DECIMAL(6,2) DEFAULT 0,
    fluid_type TEXT DEFAULT 'Water',
    hydration_level INTEGER DEFAULT 5,
    
    -- Other health factors
    has_allergens BOOLEAN DEFAULT FALSE,
    meals_per_day INTEGER DEFAULT 0,
    menstruation TEXT DEFAULT 'not_applicable',
    fatigue_level INTEGER DEFAULT 5,
    
    -- General notes
    notes TEXT DEFAULT '',
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints
    UNIQUE(user_id, entry_date, entry_type)
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_journal_entries_user_date ON journal_entries(user_id, entry_date);
CREATE INDEX IF NOT EXISTS idx_journal_entries_entry_type ON journal_entries(entry_type);
CREATE INDEX IF NOT EXISTS idx_journal_entries_meal_nutrition ON journal_entries(breakfast_calories, lunch_calories, dinner_calories, snack_calories);

-- Create trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_journal_entries_updated_at 
    BEFORE UPDATE ON journal_entries 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column(); 