-- ═══════════════════════════════════════════════════
-- 8-GENTS Supabase Database Setup
-- Run this in Supabase SQL Editor (Dashboard → SQL Editor → New Query)
-- ═══════════════════════════════════════════════════

-- 1. PROFILES TABLE
-- Stores username for user lookup (supplements Supabase auth.users)
CREATE TABLE IF NOT EXISTS profiles (
  id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  username TEXT UNIQUE NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Auto-create profile when user signs up
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO profiles (id, username)
  VALUES (NEW.id, COALESCE(NEW.raw_user_meta_data->>'username', split_part(NEW.email, '@', 1)));
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop trigger if exists, then create
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- 2. AGENTS TABLE
-- Stores all agent data as JSON per user
CREATE TABLE IF NOT EXISTS agents (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE NOT NULL,
  agent_data JSONB NOT NULL DEFAULT '[]',
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- 3. SHARED AGENTS TABLE
-- Handles share, trade, and lend transactions
CREATE TABLE IF NOT EXISTS shared_agents (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  from_user UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  to_user UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  agent_data JSONB NOT NULL,
  from_agent_idx INTEGER,
  type TEXT NOT NULL CHECK (type IN ('share', 'trade', 'lend')),
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'active', 'accepted', 'declined', 'returned')),
  created_at TIMESTAMPTZ DEFAULT now()
);

-- 4. COMMUNITY SKILLS TABLE
-- Skills shared by users for the community market
CREATE TABLE IF NOT EXISTS community_skills (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  username TEXT NOT NULL,
  skill_data JSONB NOT NULL,
  downloads INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- ═══════════════════════════════════════════════════
-- ROW LEVEL SECURITY (RLS)
-- This ensures users can only access their own data
-- ═══════════════════════════════════════════════════

-- Enable RLS on all tables
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE agents ENABLE ROW LEVEL SECURITY;
ALTER TABLE shared_agents ENABLE ROW LEVEL SECURITY;
ALTER TABLE community_skills ENABLE ROW LEVEL SECURITY;

-- PROFILES: anyone can read (needed for username lookup), only own user can update
CREATE POLICY "Profiles are viewable by everyone" ON profiles FOR SELECT USING (true);
CREATE POLICY "Users can update own profile" ON profiles FOR UPDATE USING (auth.uid() = id);

-- AGENTS: only own user can read/write
CREATE POLICY "Users can view own agents" ON agents FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own agents" ON agents FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own agents" ON agents FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own agents" ON agents FOR DELETE USING (auth.uid() = user_id);

-- SHARED AGENTS: can see if you're sender or receiver
CREATE POLICY "Users can view their shared agents" ON shared_agents FOR SELECT USING (auth.uid() = from_user OR auth.uid() = to_user);
CREATE POLICY "Users can create shares" ON shared_agents FOR INSERT WITH CHECK (auth.uid() = from_user);
CREATE POLICY "Users can update shares they received" ON shared_agents FOR UPDATE USING (auth.uid() = to_user OR auth.uid() = from_user);
CREATE POLICY "Users can delete own shares" ON shared_agents FOR DELETE USING (auth.uid() = from_user);

-- COMMUNITY SKILLS: anyone can read, only owner can write/delete
CREATE POLICY "Community skills are viewable by everyone" ON community_skills FOR SELECT USING (true);
CREATE POLICY "Users can publish skills" ON community_skills FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can delete own skills" ON community_skills FOR DELETE USING (auth.uid() = user_id);

-- ═══════════════════════════════════════════════════
-- INDEXES for performance
-- ═══════════════════════════════════════════════════
CREATE INDEX IF NOT EXISTS idx_profiles_username ON profiles(username);
CREATE INDEX IF NOT EXISTS idx_agents_user_id ON agents(user_id);
CREATE INDEX IF NOT EXISTS idx_shared_to_user ON shared_agents(to_user, status);
CREATE INDEX IF NOT EXISTS idx_shared_from_user ON shared_agents(from_user);
CREATE INDEX IF NOT EXISTS idx_community_skills_created ON community_skills(created_at DESC);
