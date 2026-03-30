# 8-GENTS — Setup Guide
## From zero to live in 5 steps

---

## STEP 1: Create Supabase Project (5 minutes)

1. Go to **https://supabase.com** → click **Start your project** → sign up with GitHub
2. Click **New project**
3. Fill in:
   - **Name:** `8gents`
   - **Database Password:** pick something strong, save it somewhere safe
   - **Region:** choose closest to your users (Singapore for SE Asia)
4. Click **Create new project** — wait ~2 minutes for it to provision
5. Once ready, go to **Settings → API** (left sidebar)
6. Copy two values:
   - **Project URL** — looks like `https://xxxxxxxxxxxx.supabase.co`
   - **anon public key** — starts with `eyJ...` (this is safe to put in frontend code)

**Paste these into your 8gents-v2.html file:**
Find these lines near the top:
```
var SUPABASE_URL='YOUR_SUPABASE_URL';
var SUPABASE_ANON_KEY='YOUR_SUPABASE_ANON_KEY';
```
Replace with your actual values.

---

## STEP 2: Create Database Tables (2 minutes)

1. In Supabase dashboard → click **SQL Editor** (left sidebar)
2. Click **New query**
3. Open the file `supabase-setup.sql` and copy ALL the contents
4. Paste into the SQL editor
5. Click **Run** (or Ctrl+Enter)
6. You should see "Success. No rows returned" — this means all tables and security rules are created

**To verify:** Go to **Table Editor** (left sidebar) — you should see 4 tables: profiles, agents, shared_agents, community_skills

---

## STEP 3: Configure Auth (2 minutes)

1. In Supabase dashboard → **Authentication → Providers**
2. **Email** should already be enabled by default
3. Optional: under **Authentication → URL Configuration**:
   - Set **Site URL** to your Vercel URL (you'll get this in Step 4)
   - Set **Redirect URLs** to the same URL

That's it for auth. Email + password works out of the box.

---

## STEP 4: Deploy to Vercel (5 minutes)

1. Go to **https://github.com** → click **+** → **New repository**
   - Name: `8gents`
   - Keep it **Public** (free hosting) or **Private** (your choice)
   - Click **Create repository**
2. Upload your `8gents-v2.html` file:
   - On the repo page, click **uploading an existing file**
   - Rename the file to `index.html` before uploading (Vercel needs this name)
   - Drag your file in → click **Commit changes**
3. Go to **https://vercel.com** → sign up with GitHub
4. Click **Add New → Project**
5. Find your `8gents` repo → click **Import**
6. Leave all settings as default → click **Deploy**
7. Wait ~30 seconds — Vercel gives you a URL like `8gents-xxxx.vercel.app`
8. Click the URL — your app is live!

**Every time you update the file on GitHub, Vercel auto-deploys the new version.**

---

## STEP 5: Connect Domain (optional, when you buy 8gents.com)

1. Buy domain from any registrar (Namecheap, Cloudflare, Google Domains)
2. In Vercel dashboard → your project → **Settings → Domains**
3. Click **Add** → type `8gents.com` → click **Add**
4. Vercel shows you DNS records to add
5. Go to your domain registrar → DNS settings → add the records Vercel shows
6. Wait 5-30 minutes for DNS to propagate
7. Done — `8gents.com` now serves your app with automatic HTTPS

---

## UPDATING YOUR APP

When you make changes:

**Option A — Through GitHub (recommended):**
1. Go to your repo on GitHub
2. Click on `index.html`
3. Click the pencil icon (edit)
4. Make changes or paste new content
5. Click **Commit changes**
6. Vercel auto-deploys in ~30 seconds

**Option B — Through Vercel CLI (advanced):**
```
npm i -g vercel
vercel login
vercel --prod
```

---

## TROUBLESHOOTING

**"Supabase not configured"** → You haven't replaced YOUR_SUPABASE_URL and YOUR_SUPABASE_ANON_KEY in the HTML file

**Auth not working** → Check that Email provider is enabled in Supabase Authentication → Providers

**Tables not found** → Re-run the supabase-setup.sql in SQL Editor. Make sure you ran ALL of it, not just part

**Community features show "login required"** → You need to create an account first. Click LOGIN in the top bar.

**Agent data not syncing** → Check browser console (F12 → Console) for errors. Most common: wrong Supabase URL

**CORS errors** → Make sure your Vercel URL is added to Supabase → Authentication → URL Configuration → Redirect URLs

---

## SECURITY CHECKLIST

- [x] API keys stored in localStorage only (never sent to our backend)
- [x] Supabase anon key is safe to expose (it's designed for frontend use)
- [x] Row Level Security (RLS) enabled on all tables
- [x] Users can only read/write their own data
- [x] Passwords hashed by Supabase (bcrypt)
- [x] HTTPS automatic on both Vercel and Supabase
- [x] Export functions strip internal metadata
- [x] Delete account feature removes all cloud data (PDPA compliance)
- [ ] Privacy policy page (you need to write this — template available online)

---

## DATABASE SCHEMA REFERENCE

**profiles**
| Column | Type | Notes |
|--------|------|-------|
| id | UUID | Links to auth.users |
| username | TEXT | Unique, used for community lookups |
| created_at | TIMESTAMP | Auto-set |

**agents**
| Column | Type | Notes |
|--------|------|-------|
| user_id | UUID | One row per user |
| agent_data | JSONB | Full agent array as JSON |
| updated_at | TIMESTAMP | Auto-set |

**shared_agents**
| Column | Type | Notes |
|--------|------|-------|
| from_user | UUID | Sender |
| to_user | UUID | Receiver |
| agent_data | JSONB | Agent snapshot |
| type | TEXT | share / trade / lend |
| status | TEXT | pending / active / accepted / declined |

**community_skills**
| Column | Type | Notes |
|--------|------|-------|
| user_id | UUID | Creator |
| username | TEXT | For display |
| skill_data | JSONB | Skill object |
| downloads | INTEGER | Popularity counter |
