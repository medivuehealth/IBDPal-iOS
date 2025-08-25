-- Migration: Add Email Verification Fields to Users Table
-- This migration adds fields needed for email verification functionality

-- Add email verification fields to users table
DO $$ 
BEGIN
    -- Add email_verified column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'email_verified') THEN
        ALTER TABLE users ADD COLUMN email_verified BOOLEAN DEFAULT FALSE;
    END IF;
    
    -- Add verification_code column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'verification_code') THEN
        ALTER TABLE users ADD COLUMN verification_code VARCHAR(6);
    END IF;
    
    -- Add verification_code_expires column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'verification_code_expires') THEN
        ALTER TABLE users ADD COLUMN verification_code_expires TIMESTAMP;
    END IF;
    
    -- Add verification_attempts column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'verification_attempts') THEN
        ALTER TABLE users ADD COLUMN verification_attempts INTEGER DEFAULT 0;
    END IF;
    
    -- Add last_verification_attempt column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'last_verification_attempt') THEN
        ALTER TABLE users ADD COLUMN last_verification_attempt TIMESTAMP;
    END IF;
END $$;

-- Create index for faster verification code lookups
CREATE INDEX IF NOT EXISTS idx_users_verification_code ON users(verification_code) WHERE verification_code IS NOT NULL;

-- Create index for email verification status
CREATE INDEX IF NOT EXISTS idx_users_email_verified ON users(email_verified);

-- Add constraint to ensure verification code is exactly 6 digits
ALTER TABLE users 
ADD CONSTRAINT IF NOT EXISTS check_verification_code_length 
CHECK (verification_code IS NULL OR (LENGTH(verification_code) = 6 AND verification_code ~ '^[0-9]{6}$'));

-- Add constraint to ensure verification attempts is non-negative
ALTER TABLE users 
ADD CONSTRAINT IF NOT EXISTS check_verification_attempts 
CHECK (verification_attempts >= 0);

-- Create a function to generate verification codes
CREATE OR REPLACE FUNCTION generate_verification_code()
RETURNS VARCHAR(6) AS $$
BEGIN
    -- Generate a random 6-digit code
    RETURN LPAD(FLOOR(RANDOM() * 1000000)::TEXT, 6, '0');
END;
$$ LANGUAGE plpgsql;

-- Create a function to check if verification code is expired
CREATE OR REPLACE FUNCTION is_verification_code_expired(expires_at TIMESTAMP)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN expires_at IS NULL OR expires_at < CURRENT_TIMESTAMP;
END;
$$ LANGUAGE plpgsql;

-- Add comments to document the new fields
COMMENT ON COLUMN users.email_verified IS 'Whether the user has verified their email address';
COMMENT ON COLUMN users.verification_code IS '6-digit verification code sent to user email';
COMMENT ON COLUMN users.verification_code_expires IS 'Timestamp when verification code expires (15 minutes from generation)';
COMMENT ON COLUMN users.verification_attempts IS 'Number of failed verification attempts';
COMMENT ON COLUMN users.last_verification_attempt IS 'Timestamp of last verification attempt';

-- Update existing users to have verified email (for backward compatibility)
-- Only update users who don't have email_verified set
UPDATE users 
SET email_verified = TRUE 
WHERE email_verified IS NULL;

-- Migration completed successfully
-- Note: Migration logging removed to avoid dependency on migration_log table 