-- Fix the user_diagnosis foreign key constraint
-- This script fixes the constraint to reference user_id instead of username

-- Step 1: Drop the existing foreign key constraint
ALTER TABLE user_diagnosis DROP CONSTRAINT IF EXISTS user_diagnosis_username_fkey;

-- Step 2: Add a new column for user_id if it doesn't exist
ALTER TABLE user_diagnosis ADD COLUMN IF NOT EXISTS user_id TEXT;

-- Step 3: Update existing records to use user_id instead of username
-- This maps username to user_id from the users table
UPDATE user_diagnosis 
SET user_id = (
    SELECT u.user_id 
    FROM users u 
    WHERE u.username = user_diagnosis.username
)
WHERE user_id IS NULL;

-- Step 4: Make user_id NOT NULL and add the correct foreign key constraint
ALTER TABLE user_diagnosis ALTER COLUMN user_id SET NOT NULL;

-- Step 5: Add the correct foreign key constraint
ALTER TABLE user_diagnosis 
ADD CONSTRAINT user_diagnosis_user_id_fkey 
FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE;

-- Step 6: Create index for better performance
CREATE INDEX IF NOT EXISTS idx_user_diagnosis_user_id ON user_diagnosis(user_id);

-- Step 7: Optionally drop the username column if no longer needed
-- ALTER TABLE user_diagnosis DROP COLUMN IF EXISTS username;

-- Step 8: Update the API routes to use user_id instead of username
-- (This will be done in the server code)









