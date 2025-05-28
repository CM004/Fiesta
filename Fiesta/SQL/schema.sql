-- Create the extension for UUID generation if it doesn't exist
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create the tables

-- Users Table
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY REFERENCES auth.users ON DELETE CASCADE,
  name TEXT NOT NULL,
  email TEXT NOT NULL UNIQUE,
  role TEXT NOT NULL DEFAULT 'student', -- 'student', 'cafeteriaStaff', 'admin'
  cq_score FLOAT NOT NULL DEFAULT 0,
  leaderboard_rank INTEGER,
  profile_image_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  is_active BOOLEAN NOT NULL DEFAULT true,
  meals_saved INTEGER NOT NULL DEFAULT 0,
  meals_swapped INTEGER NOT NULL DEFAULT 0,
  meals_distributed INTEGER NOT NULL DEFAULT 0,
  
  -- Add any additional fields here
  CONSTRAINT valid_role CHECK (role IN ('student', 'cafeteriaStaff', 'admin'))
);

-- Meals Table
CREATE TABLE IF NOT EXISTS meals (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  description TEXT NOT NULL,
  image_url TEXT,
  type TEXT NOT NULL, -- 'breakfast', 'lunch', 'dinner', 'snack'
  status TEXT NOT NULL, -- 'available', 'offered', 'claimed', 'consumed', 'unclaimed'
  date TIMESTAMP WITH TIME ZONE NOT NULL,
  location TEXT NOT NULL,
  
  -- Nutrition info
  calories INTEGER,
  protein FLOAT,
  carbs FLOAT,
  fat FLOAT,
  allergens TEXT[], -- Array of allergen strings
  dietary_info TEXT[], -- Array of dietary info strings
  
  -- Swap-related fields
  offered_by UUID REFERENCES users(id) ON DELETE SET NULL,
  claimed_by UUID REFERENCES users(id) ON DELETE SET NULL,
  offer_expiry_time TIMESTAMP WITH TIME ZONE,
  claim_deadline_time TIMESTAMP WITH TIME ZONE,
  actually_consumed BOOLEAN,
  is_feedback_provided BOOLEAN DEFAULT false,
  
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  CONSTRAINT valid_type CHECK (type IN ('breakfast', 'lunch', 'dinner', 'snack')),
  CONSTRAINT valid_status CHECK (status IN ('available', 'offered', 'claimed', 'consumed', 'unclaimed'))
);

-- Meal Swaps Table
CREATE TABLE IF NOT EXISTS meal_swaps (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  meal_id UUID NOT NULL REFERENCES meals(id) ON DELETE CASCADE,
  offered_by UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  claimed_by UUID REFERENCES users(id) ON DELETE SET NULL,
  claimed_at TIMESTAMP WITH TIME ZONE,
  expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending', -- 'pending', 'completed', 'expired'
  cq_points_earned FLOAT,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  CONSTRAINT valid_status CHECK (status IN ('pending', 'completed', 'expired'))
);

-- Meal Predictions Table
CREATE TABLE IF NOT EXISTS meal_predictions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  date TIMESTAMP WITH TIME ZONE NOT NULL,
  meal_type TEXT NOT NULL, -- 'breakfast', 'lunch', 'dinner', 'snack'
  location TEXT NOT NULL,
  predicted_attendance INTEGER NOT NULL,
  weather_condition TEXT,
  is_exam_day BOOLEAN DEFAULT false,
  is_holiday BOOLEAN DEFAULT false,
  is_event_day BOOLEAN DEFAULT false,
  confidence_score FLOAT NOT NULL,
  factors JSONB, -- Array of factors affecting the prediction
  adjusted_preparation_level INTEGER,
  waste_reduction INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  CONSTRAINT valid_meal_type CHECK (meal_type IN ('breakfast', 'lunch', 'dinner', 'snack'))
);

-- User Preferences
CREATE TABLE IF NOT EXISTS user_preferences (
  user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  notification_enabled BOOLEAN DEFAULT true,
  location_services_enabled BOOLEAN DEFAULT true,
  dark_mode_enabled BOOLEAN DEFAULT false,
  dietary_preferences JSONB DEFAULT '{}',
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Storage Buckets
INSERT INTO storage.buckets (id, name) VALUES ('profile_images', 'Profile Images')
ON CONFLICT (id) DO NOTHING;

INSERT INTO storage.buckets (id, name) VALUES ('meal_images', 'Meal Images')
ON CONFLICT (id) DO NOTHING;

-- Row Level Security Policies

-- Users policies
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Everyone can read users
CREATE POLICY users_read_policy ON users
  FOR SELECT USING (true);

-- Users can update their own data
CREATE POLICY users_update_policy ON users
  FOR UPDATE USING (auth.uid() = id);

-- Only admins can create users (Supabase Auth will handle this)
CREATE POLICY users_insert_policy ON users
  FOR INSERT WITH CHECK (auth.uid() = id OR auth.jwt() ->> 'role' = 'admin');

-- Meals policies
ALTER TABLE meals ENABLE ROW LEVEL SECURITY;

-- Everyone can read meals
CREATE POLICY meals_read_policy ON meals
  FOR SELECT USING (true);

-- Users can create meals
CREATE POLICY meals_insert_policy ON meals
  FOR INSERT WITH CHECK (auth.uid()::text = offered_by::text OR status = 'available');

-- Users can update their own offered meals
CREATE POLICY meals_update_policy ON meals
  FOR UPDATE USING (
    auth.uid()::text = offered_by::text OR -- can update own meal
    auth.uid()::text = claimed_by::text OR -- can update claimed meal
    auth.jwt() ->> 'role' = 'admin' OR     -- admin can update any meal
    status = 'available'                   -- anyone can claim available meals
  );

-- Meal Swaps policies
ALTER TABLE meal_swaps ENABLE ROW LEVEL SECURITY;

-- Everyone can read meal swaps
CREATE POLICY meal_swaps_read_policy ON meal_swaps
  FOR SELECT USING (true);

-- Users can insert swaps for their meals
CREATE POLICY meal_swaps_insert_policy ON meal_swaps
  FOR INSERT WITH CHECK (auth.uid()::text = offered_by::text OR auth.jwt() ->> 'role' = 'admin');

-- Users can update their own swaps or swaps they have claimed
CREATE POLICY meal_swaps_update_policy ON meal_swaps
  FOR UPDATE USING (
    auth.uid()::text = offered_by::text OR 
    auth.uid()::text = claimed_by::text OR 
    auth.jwt() ->> 'role' = 'admin'
  );

-- Predictions policies (admin only)
ALTER TABLE meal_predictions ENABLE ROW LEVEL SECURITY;

-- Everyone can read predictions
CREATE POLICY predictions_read_policy ON meal_predictions
  FOR SELECT USING (true);

-- Only admins and cafeteria staff can modify predictions
CREATE POLICY predictions_insert_policy ON meal_predictions
  FOR INSERT WITH CHECK (auth.jwt() ->> 'role' IN ('admin', 'cafeteriaStaff'));

CREATE POLICY predictions_update_policy ON meal_predictions
  FOR UPDATE USING (auth.jwt() ->> 'role' IN ('admin', 'cafeteriaStaff'));

-- User Preferences policies
ALTER TABLE user_preferences ENABLE ROW LEVEL SECURITY;

-- Users can read their own preferences
CREATE POLICY user_prefs_read_policy ON user_preferences
  FOR SELECT USING (auth.uid()::text = user_id::text OR auth.jwt() ->> 'role' = 'admin');

-- Users can update their own preferences
CREATE POLICY user_prefs_update_policy ON user_preferences
  FOR UPDATE USING (auth.uid()::text = user_id::text OR auth.jwt() ->> 'role' = 'admin');

-- Users can insert their own preferences
CREATE POLICY user_prefs_insert_policy ON user_preferences
  FOR INSERT WITH CHECK (auth.uid()::text = user_id::text OR auth.jwt() ->> 'role' = 'admin');

-- Storage policies
CREATE POLICY profile_image_select ON storage.objects 
  FOR SELECT USING (bucket_id = 'profile_images');

CREATE POLICY profile_image_insert ON storage.objects 
  FOR INSERT WITH CHECK (
    bucket_id = 'profile_images' AND 
    (auth.uid()::text = (storage.foldername(name))[1] OR auth.jwt() ->> 'role' = 'admin')
  );

CREATE POLICY meal_image_select ON storage.objects 
  FOR SELECT USING (bucket_id = 'meal_images');

CREATE POLICY meal_image_insert ON storage.objects 
  FOR INSERT WITH CHECK (
    bucket_id = 'meal_images' AND 
    (auth.uid()::text IS NOT NULL)
  );

-- Create a trigger to update the leaderboard_rank
CREATE OR REPLACE FUNCTION update_leaderboard_ranks()
RETURNS TRIGGER AS $$
BEGIN
  -- Update the ranks of all users based on cq_score
  UPDATE users
  SET leaderboard_rank = ranks.rank
  FROM (
    SELECT 
      id,
      RANK() OVER (ORDER BY cq_score DESC) as rank
    FROM users
  ) ranks
  WHERE users.id = ranks.id;
  
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Create the trigger for any changes to users table
CREATE TRIGGER trigger_update_leaderboard
AFTER INSERT OR UPDATE OF cq_score ON users
FOR EACH STATEMENT
EXECUTE PROCEDURE update_leaderboard_ranks();

-- Create a function to initialize the leaderboard ranks
CREATE OR REPLACE FUNCTION initialize_leaderboard_ranks()
RETURNS VOID AS $$
BEGIN
  -- Initialize the ranks of all users based on cq_score
  UPDATE users
  SET leaderboard_rank = ranks.rank
  FROM (
    SELECT 
      id,
      RANK() OVER (ORDER BY cq_score DESC) as rank
    FROM users
  ) ranks
  WHERE users.id = ranks.id;
END;
$$ LANGUAGE plpgsql;

-- Run this once to initialize ranks
SELECT initialize_leaderboard_ranks(); 