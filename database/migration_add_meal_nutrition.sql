-- Migration: Add individual meal nutrition columns to journal_entries table
-- This migration adds separate nutrition tracking for each meal type

-- Add breakfast nutrition columns
ALTER TABLE journal_entries ADD COLUMN IF NOT EXISTS breakfast_calories DECIMAL(8,2) DEFAULT 0;
ALTER TABLE journal_entries ADD COLUMN IF NOT EXISTS breakfast_protein DECIMAL(8,2) DEFAULT 0;
ALTER TABLE journal_entries ADD COLUMN IF NOT EXISTS breakfast_carbs DECIMAL(8,2) DEFAULT 0;
ALTER TABLE journal_entries ADD COLUMN IF NOT EXISTS breakfast_fiber DECIMAL(8,2) DEFAULT 0;
ALTER TABLE journal_entries ADD COLUMN IF NOT EXISTS breakfast_fat DECIMAL(8,2) DEFAULT 0;

-- Add lunch nutrition columns
ALTER TABLE journal_entries ADD COLUMN IF NOT EXISTS lunch_calories DECIMAL(8,2) DEFAULT 0;
ALTER TABLE journal_entries ADD COLUMN IF NOT EXISTS lunch_protein DECIMAL(8,2) DEFAULT 0;
ALTER TABLE journal_entries ADD COLUMN IF NOT EXISTS lunch_carbs DECIMAL(8,2) DEFAULT 0;
ALTER TABLE journal_entries ADD COLUMN IF NOT EXISTS lunch_fiber DECIMAL(8,2) DEFAULT 0;
ALTER TABLE journal_entries ADD COLUMN IF NOT EXISTS lunch_fat DECIMAL(8,2) DEFAULT 0;

-- Add dinner nutrition columns
ALTER TABLE journal_entries ADD COLUMN IF NOT EXISTS dinner_calories DECIMAL(8,2) DEFAULT 0;
ALTER TABLE journal_entries ADD COLUMN IF NOT EXISTS dinner_protein DECIMAL(8,2) DEFAULT 0;
ALTER TABLE journal_entries ADD COLUMN IF NOT EXISTS dinner_carbs DECIMAL(8,2) DEFAULT 0;
ALTER TABLE journal_entries ADD COLUMN IF NOT EXISTS dinner_fiber DECIMAL(8,2) DEFAULT 0;
ALTER TABLE journal_entries ADD COLUMN IF NOT EXISTS dinner_fat DECIMAL(8,2) DEFAULT 0;

-- Add snack nutrition columns
ALTER TABLE journal_entries ADD COLUMN IF NOT EXISTS snack_calories DECIMAL(8,2) DEFAULT 0;
ALTER TABLE journal_entries ADD COLUMN IF NOT EXISTS snack_protein DECIMAL(8,2) DEFAULT 0;
ALTER TABLE journal_entries ADD COLUMN IF NOT EXISTS snack_carbs DECIMAL(8,2) DEFAULT 0;
ALTER TABLE journal_entries ADD COLUMN IF NOT EXISTS snack_fiber DECIMAL(8,2) DEFAULT 0;
ALTER TABLE journal_entries ADD COLUMN IF NOT EXISTS snack_fat DECIMAL(8,2) DEFAULT 0;

-- Add indexes for better performance on meal queries
CREATE INDEX IF NOT EXISTS idx_journal_entries_user_date ON journal_entries(user_id, entry_date);
CREATE INDEX IF NOT EXISTS idx_journal_entries_meal_nutrition ON journal_entries(breakfast_calories, lunch_calories, dinner_calories, snack_calories);

-- Verify the migration
SELECT column_name, data_type, column_default 
FROM information_schema.columns 
WHERE table_name = 'journal_entries' 
AND column_name LIKE '%_calories' 
ORDER BY column_name; 