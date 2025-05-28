import Foundation

// ┌────────────────────────────────────────────────────────────────────┐
// │                     SUPABASE SETUP INSTRUCTIONS                     │
// │                                                                    │
// │ 1. Create a new Supabase project at https://supabase.com           │
// │                                                                    │
// │ 2. Create the following tables in your database:                   │
// │    - users                                                         │
// │      • id (uuid, PK)                                               │
// │      • name (text)                                                 │
// │      • email (text)                                                │
// │      • role (text)                                                 │
// │      • cq_score (float)                                            │
// │      • profile_image_url (text, nullable)                          │
// │      • created_at (timestamp with timezone)                         │
// │      • is_active (boolean)                                         │
// │      • meals_saved (integer)                                       │
// │      • meals_swapped (integer)                                     │
// │      • meals_distributed (integer)                                 │
// │                                                                    │
// │    - meals                                                         │
// │      • id (uuid, PK)                                               │
// │      • name (text)                                                 │
// │      • description (text)                                          │
// │      • image_url (text, nullable)                                  │
// │      • type (text)                                                 │
// │      • status (text)                                               │
// │      • date (timestamp with timezone)                               │
// │      • location (text)                                             │
// │      • offered_by (uuid, nullable, FK to users.id)                 │
// │      • claimed_by (uuid, nullable, FK to users.id)                 │
// │      • offer_expiry_time (timestamp with timezone, nullable)        │
// │      • claim_deadline_time (timestamp with timezone, nullable)      │
// │      • actually_consumed (boolean, nullable)                       │
// │      • is_feedback_provided (boolean)                              │
// │      • calories (integer, nullable)                                │
// │      • protein (float, nullable)                                   │
// │      • carbs (float, nullable)                                     │
// │      • fat (float, nullable)                                       │
// │      • allergens (text[], nullable)                                │
// │      • dietary_info (text[], nullable)                             │
// │                                                                    │
// │    - meal_swaps                                                    │
// │      • id (uuid, PK)                                               │
// │      • meal_id (uuid, FK to meals.id)                              │
// │      • offered_by (uuid, FK to users.id)                           │
// │      • claimed_by (uuid, nullable, FK to users.id)                 │
// │      • claimed_at (timestamp with timezone, nullable)               │
// │      • expires_at (timestamp with timezone)                         │
// │      • status (text)                                               │
// │      • cq_points_earned (float, nullable)                          │
// │                                                                    │
// │    - meal_predictions                                              │
// │      • id (uuid, PK)                                               │
// │      • date (timestamp with timezone)                               │
// │      • meal_type (text)                                            │
// │      • location (text)                                             │
// │      • predicted_attendance (integer)                              │
// │      • weather_condition (text)                                     │
// │      • is_exam_day (boolean)                                       │
// │      • is_holiday (boolean)                                        │
// │      • is_event_day (boolean)                                      │
// │      • confidence_score (float)                                    │
// │      • factors (jsonb, nullable)                                   │
// │      • adjusted_preparation_level (integer)                        │
// │      • waste_reduction (integer)                                   │
// │                                                                    │
// │ 3. Create storage buckets in Storage section:                      │
// │    - profile_images                                                │
// │    - meal_images                                                   │
// │                                                                    │
// │ 4. Enable Row Level Security and configure policies as needed      │
// │                                                                    │
// │ 5. Add your credentials below                                      │
// └────────────────────────────────────────────────────────────────────┘

struct SupabaseConfig {
    // ⚠️ IMPORTANT: Replace these with your actual Supabase credentials from your project dashboard ⚠️
    // Your Supabase URL looks like: https://abcdefghijklm.supabase.co
    static let supabaseURL = "https://rkfxfoyarguyqckpasjn.supabase.co"
    
    // Your anon key can be found in Project Settings > API
    static let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJrZnhmb3lhcmd1eXFja3Bhc2puIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDgwNzgzMzcsImV4cCI6MjA2MzY1NDMzN30.uaB6v-N4xMtmfJfVLF-vypkP1b75gTxCJUpY1hvDiQQ"
    
    // Storage bucket names - make sure these buckets exist in your Supabase project
    static let profileImagesBucket = "profile_images"
    static let mealImagesBucket = "meal_images"
} 