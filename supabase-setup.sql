-- ═══════════════════════════════════════════════════
-- 8-GENTS Supabase Database Setup (COMPLETE)
-- Run this in Supabase SQL Editor (Dashboard → SQL Editor → New Query)
-- Last updated: March 31, 2026
-- ═══════════════════════════════════════════════════

-- 1. PROFILES TABLE
CREATE TABLE IF NOT EXISTS profiles (
  id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  username TEXT UNIQUE NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO profiles (id, username)
  VALUES (NEW.id, COALESCE(NEW.raw_user_meta_data->>'username', split_part(NEW.email, '@', 1)));
  RETURN NEW;
EXCEPTION WHEN OTHERS THEN
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- 2. AGENTS TABLE
CREATE TABLE IF NOT EXISTS agents (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE NOT NULL,
  agent_data JSONB NOT NULL DEFAULT '[]',
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- 3. SHARED AGENTS TABLE
CREATE TABLE IF NOT EXISTS shared_agents (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  from_user UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  to_user UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  agent_data JSONB NOT NULL,
  from_agent_idx INTEGER,
  type TEXT NOT NULL CHECK (type IN ('share', 'trade', 'lend')),
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'active', 'accepted', 'declined', 'returned', 'offered', 'completed', 'notify_declined', 'notify_expired')),
  created_at TIMESTAMPTZ DEFAULT now()
);

-- 4. COMMUNITY SKILLS TABLE
CREATE TABLE IF NOT EXISTS community_skills (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  username TEXT NOT NULL,
  skill_data JSONB NOT NULL,
  downloads INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- 5. FRIENDS TABLE
CREATE TABLE IF NOT EXISTS friends (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  friend_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  friend_username TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(user_id, friend_id)
);

-- 6. PUBLIC AGENT CARDS TABLE
CREATE TABLE IF NOT EXISTS public_cards (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  username TEXT NOT NULL,
  share_code TEXT UNIQUE NOT NULL,
  agent_data JSONB NOT NULL,
  views INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- 7. FRIEND MESSAGES TABLE
CREATE TABLE IF NOT EXISTS friend_messages (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  from_user UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  to_user UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  message TEXT NOT NULL,
  read BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- ═══════════════════════════════════════════════════
-- ROW LEVEL SECURITY (RLS)
-- ═══════════════════════════════════════════════════

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE agents ENABLE ROW LEVEL SECURITY;
ALTER TABLE shared_agents ENABLE ROW LEVEL SECURITY;
ALTER TABLE community_skills ENABLE ROW LEVEL SECURITY;
ALTER TABLE friends ENABLE ROW LEVEL SECURITY;
ALTER TABLE public_cards ENABLE ROW LEVEL SECURITY;
ALTER TABLE friend_messages ENABLE ROW LEVEL SECURITY;

-- PROFILES
CREATE POLICY "Profiles are viewable by everyone" ON profiles FOR SELECT USING (true);
CREATE POLICY "Users can update own profile" ON profiles FOR UPDATE USING (auth.uid() = id);

-- AGENTS
CREATE POLICY "Users can view own agents" ON agents FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own agents" ON agents FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own agents" ON agents FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own agents" ON agents FOR DELETE USING (auth.uid() = user_id);

-- SHARED AGENTS
CREATE POLICY "Users can view their shared agents" ON shared_agents FOR SELECT USING (auth.uid() = from_user OR auth.uid() = to_user);
CREATE POLICY "Users can create shares" ON shared_agents FOR INSERT WITH CHECK (auth.uid() = from_user);
CREATE POLICY "Users can update shares they received or sent" ON shared_agents FOR UPDATE USING (auth.uid() = to_user OR auth.uid() = from_user);
CREATE POLICY "Users can delete own shares" ON shared_agents FOR DELETE USING (auth.uid() = from_user OR auth.uid() = to_user);

-- COMMUNITY SKILLS
CREATE POLICY "Community skills are viewable by everyone" ON community_skills FOR SELECT USING (true);
CREATE POLICY "Users can publish skills" ON community_skills FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can delete own skills" ON community_skills FOR DELETE USING (auth.uid() = user_id);

-- FRIENDS
CREATE POLICY "Users can view own friends" ON friends FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can add friends" ON friends FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can remove friends" ON friends FOR DELETE USING (auth.uid() = user_id);

-- PUBLIC CARDS
CREATE POLICY "Public cards are viewable by everyone" ON public_cards FOR SELECT USING (true);
CREATE POLICY "Users can create public cards" ON public_cards FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can delete own cards" ON public_cards FOR DELETE USING (auth.uid() = user_id);
CREATE POLICY "Anyone can update view count" ON public_cards FOR UPDATE USING (true);

-- FRIEND MESSAGES
CREATE POLICY "Users can view own messages" ON friend_messages FOR SELECT USING (auth.uid() = from_user OR auth.uid() = to_user);
CREATE POLICY "Users can send messages" ON friend_messages FOR INSERT WITH CHECK (auth.uid() = from_user);
CREATE POLICY "Users can mark messages read" ON friend_messages FOR UPDATE USING (auth.uid() = to_user);

-- ═══════════════════════════════════════════════════
-- INDEXES
-- ═══════════════════════════════════════════════════
CREATE INDEX IF NOT EXISTS idx_profiles_username ON profiles(username);
CREATE INDEX IF NOT EXISTS idx_agents_user_id ON agents(user_id);
CREATE INDEX IF NOT EXISTS idx_shared_to_user ON shared_agents(to_user, status);
CREATE INDEX IF NOT EXISTS idx_shared_from_user ON shared_agents(from_user);
CREATE INDEX IF NOT EXISTS idx_community_skills_created ON community_skills(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_friends_user_id ON friends(user_id);
CREATE INDEX IF NOT EXISTS idx_friends_friend_id ON friends(friend_id);
CREATE INDEX IF NOT EXISTS idx_public_cards_code ON public_cards(share_code);
CREATE INDEX IF NOT EXISTS idx_public_cards_user ON public_cards(user_id);
CREATE INDEX IF NOT EXISTS idx_messages_to_user ON friend_messages(to_user, read);
CREATE INDEX IF NOT EXISTS idx_messages_conversation ON friend_messages(from_user, to_user, created_at DESC);
