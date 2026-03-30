# CLAUDE.md — 8-GENTS Project

## What is this project?

8-Gents ("8-bit" + "agents") is an AI agent life simulation platform. Users create pixel art AI agents, assign them skills, deploy them to real AI platforms (Claude, ChatGPT, Gemini), and breed them through a marriage system to produce offspring with inherited and mutated skills. Think Tamagotchi meets AI agent management.

**Creator:** Star — handles product and design decisions. No coding background. Claude handles all code.
**Stage:** V2, Supabase connected, preparing for Vercel deployment.

## Tech stack

- **Frontend:** Single-file vanilla HTML/CSS/JS (~3100 lines). No frameworks, no build step.
- **Font:** Press Start 2P (Google Fonts) — pixel RPG aesthetic
- **Sprites:** SVG-based pixel characters on 16x24 grid, chibi proportions
- **Local storage:** `8g2` (agents), `8g_custom_skills` (custom skills), `8g_xp_spent` (XP spent), `8g_last_tick` (growth timer), `8g_api_key_*` (API keys per provider)
- **Backend:** Supabase (PostgreSQL + auth + realtime) — CONNECTED
  - Project: `https://iscyzixingifdlcnqyxf.supabase.co`
  - Region: Southeast Asia (Singapore)
  - Auth: Email + password (email confirmation OFF for dev)
- **Hosting target:** Vercel (auto-deploy from GitHub)
- **AI providers:** API-agnostic — Claude, ChatGPT, Gemini, or any OpenAI-compatible endpoint. Keys stored locally only, sent directly from browser to provider.

## File structure

```
8gents/
├── index.html          # Main app (rename from 8gentsv1.html for Vercel)
├── supabase-setup.sql  # Database schema — already run in Supabase
├── SETUP-GUIDE.md      # Step-by-step deployment walkthrough
└── CLAUDE.md           # This file
```

The app is a single HTML file. All CSS is in a `<style>` block, all JS in `<script>` blocks. There are three script blocks:
1. Supabase JS client library (CDN)
2. Supabase config (URL + anon key — CONFIGURED)
3. Main application code (~3100 lines)

## Architecture

### Tab system
Menu order: Agents → Skills → Marriage → Growth → Create → Deploy → Community

Each tab has a `render[TabName](container)` function that generates HTML and sets `container.innerHTML`. Tab state is managed through global variables (e.g., `curTab`, `skSubTab`, `wedStep`).

### Data flow
```
localStorage (offline) ←→ agents array (in memory) ←→ Supabase (cloud, when logged in)
```
Every `save()` call writes to localStorage AND syncs to Supabase if authenticated. The app works fully offline — cloud is optional.

### Agent data model
```javascript
{
  id: 'agent_01',
  name: 'Researcher',
  role: 'Data Analyst',
  body: 'human',           // 12 types: human, cat, fox, bunny, owl, frog, alien, goblin, skeleton, slime, demon, ghost
  gender: 'male',           // neutral, male, female
  skin: '#E8A87C',          // 12 skin tones (6 natural + 6 colorful)
  hair: 'short',            // 10 styles
  hairColor: '#8B4513',     // 12 colors
  top: 'shirt',             // 6 types
  bottom: 'pants',          // 3 types
  topColor: '#4A90D9',
  bottomColor: '#95a5a6',
  hat: 'none',              // 10 types (banana replaced crown — crown is Lv.10 only)
  hatColor: '#e74c3c',
  accessory: 'none',        // 10 types
  accColor: '#ffcc44',
  prop: 'none',             // 9 types
  personality: 'methodical', // 8 types — locked on born agents, changeable on created agents
  skills: ['web search', 'summarisation'],
  state: 'idle',            // idle, working, collab, stuck, waiting, done
  task: '',
  output: '',
  platform: 'claude',       // claude, chatgpt, gemini, local
  xp: 0,                    // Total accumulated XP
  level: 1,                 // Derived from XP via getLevelFromXP()
  customSprite: null,        // Array of {x,y,c} or null
  pinned: false,
  // Internal fields (prefixed with _, stripped on export):
  _parents: ['Parent1', 'Parent2'],  // null for created agents
  _hasMutation: true,
  _mutSkill: 'quantum logic',
  _mutRevealed: false,       // Reveals on first task completion (done bonus)
  _workStart: 1711800000000, // Timestamp when started working
  _doneClaimed: false,       // Prevents double-claiming done bonus
  // Clone fields (set when received via Clone/Share):
  _isClone: true,            // Agent is a clone from another user
  _cloneFrom: 'username',    // Who cloned it
  _cloneTasksDone: 0,        // Unlocks editing at 3
  // Lend fields (set when lending/borrowing):
  _isLent: true,             // Agent is currently lent out
  _lentTo: 'username',       // Who borrowed it
  _lentExpiry: 1711886400000, // 24hr auto-return timestamp
  _isBorrowed: true,         // Agent is borrowed from someone
  _borrowExpiry: 1711886400000, // 24hr auto-return timestamp
  _lentBy: 'username'        // Who lent it
}
```

### Progressive XP curve
```
Level 1→2:   10 XP  (5 min at 2 XP/min)
Level 2→3:   25 XP
Level 3→4:   50 XP
Level 4→5:  100 XP
Level 5→6:  150 XP
Level 6→7:  250 XP
Level 7→8:  400 XP
Level 8→9:  600 XP
Level 9→10: 900 XP  (~7.5 hr working time)
```
Total to crown: 2,485 XP. Level is always derived from XP via `getLevelFromXP()`, never set directly.

### XP earning
- Working: +2 XP/min
- Collab: +3 XP/min (1.5x)
- Done bonus: +10 XP (requires 5 min working time, one claim per done cycle)
- Deploy chat: +1 XP per message exchange
- Lending reward: +10 XP when lent agent returns
- Catch-up on load: retroactive XP for time away, capped at 8 hours
- Growth tick: every 10 seconds via setInterval

### Skill system
- 185 total skills across 16 categories
- 140 visible (13 categories: research, writing, coding, analysis, design, document, strategy, communication, marketing, operations, ai, personal)
- 45 hidden (3 categories: special, mystical, philosophy) — mutation-only, never shown in library
- 30 skills in the mutation pool (drawn from hidden categories)
- Shared XP pool: total XP earned across all agents minus XP spent on skills
- Custom skills: stored in localStorage key `8g_custom_skills`, free to create
- Rich descriptions: `SKILL_RICH` object maps skill names to detailed prompt-style descriptions
- Skill Tree: clickable nodes with prerequisite logic (must learn earlier skills in path first)
- MY SKILLS tab: shows custom skills (expandable with detail, assign, publish, delete) + all agent skills (expandable)
- PUBLISH: custom skills publish directly to Supabase community market

### Marriage system
- 4-step wizard: select parents → choose mode → preview → name & confirm
- Natural mode: 50/50 random skill split, random personality from either parent, 10-30% mutation chance
- Gene Splice (GMO) mode: user picks skills via checkboxes, no mutation, personality still randomly inherited
- Re-roll: 3 attempts max (Natural only, disabled for Gene Splice)
- Offspring get `_parents` array and locked personality
- Name auto-generated from parent skills, user can rename

### Clone (Share) system
- Sender clones agent to recipient via username lookup
- Clone arrives LOCKED — recipient cannot edit name, role, personality, skills, or appearance
- Clone unlocks after 3 completed task deployments (tracked via `_cloneTasksDone`)
- CLONE badge (purple) shown on agent card
- LOCKED badge (red) shown until unlocked
- Clone origin shown in modal (`_cloneFrom` username)

### Lend system
- Lender sends agent to borrower via username lookup
- Lender's agent marked ON LOAN (`_isLent`) — cannot edit while lent
- Borrower receives agent as BORROWED (`_isBorrowed`) — can only breed or deploy, no editing
- Auto-return triggers on whichever comes first: breeding completes, task deployment completes, or 24 hours expire
- Lender earns +10 XP when agent returns
- Growth tick checks expiry every 10 seconds; expired borrowed agents auto-removed, expired lent agents auto-unlocked
- ON LOAN badge (gold) on lender's card, BORROWED badge (cyan) on borrower's card

### Deploy system
- API-agnostic: Claude, ChatGPT, Gemini, Custom (OpenAI-compatible)
- Keys stored in localStorage per provider (`8g_api_key_claude`, etc.)
- System prompt auto-generated from agent name, role, personality behavior, skills, and lineage
- Chat interface with message history
- Stats tracking: messages sent, responses, tasks done
- On response: increments clone task counter if clone, triggers auto-return if borrowed

### Auth + Community (Supabase)
- Email + password authentication (email confirmation OFF for dev)
- Cloud sync: agent data auto-syncs on every save when logged in
- Community sub-tabs: Clone, Trade, Lend, Skill Market, Friends (coming soon), Profile
- Clone: sends locked duplicate to another user (unlocks after 3 tasks)
- Trade: 1-for-1 swap with acceptance flow
- Lend: temporary loan with 24hr timer and auto-return
- Skill Market: publish custom skills to community, import from others
- Friends: coming soon placeholder
- Profile: username, agent count, copyable ID, delete account (PDPA compliance)
- All community actions require login — app works fully offline without it

### Supabase tables (already created)
- `profiles`: id (UUID), username (unique), created_at
- `agents`: id, user_id, agent_data (JSONB), updated_at
- `shared_agents`: id, from_user, to_user, agent_data (JSONB), from_agent_idx, type (share/trade/lend), status (pending/active/accepted/declined/returned), created_at
- `community_skills`: id, user_id, username, skill_data (JSONB), downloads, created_at
- RLS policies on all tables — users can only access their own data
- Trigger: `handle_new_user()` auto-creates profile on signup (with EXCEPTION handler for resilience)

## Coding conventions

### JavaScript style
- Use `var` (not `let`/`const`) — the codebase is ES5-compatible
- Use `function` declarations (not arrow functions)
- Use `.forEach(function(item){...})` (not `.forEach(item => {...})`)
- Use `.indexOf(x) >= 0` (not `.includes()`)
- String concatenation with `+` for HTML generation (not template literals)
- `async function` is OK for Supabase/API calls

### HTML generation pattern
All tabs generate HTML as string concatenation into a variable `h`, then set `container.innerHTML = h`. Example:
```javascript
function renderMyTab(c) {
  var h = '';
  h += '<div>content</div>';
  c.innerHTML = h;
}
```

### Naming conventions
- Tab render functions: `render[TabName]` (e.g., `renderAgents`, `renderGrowth`)
- Sub-tab renders: `renderCm[SubTab]` for Community, `renderSk[SubTab]` for Skills
- Marriage functions: `wed[Action]` (e.g., `wedPickParent`, `wedDoPreview`)
- Deploy functions: `dp[Action]` (e.g., `dpSend`, `dpSelectAgent`)
- Community functions: `cm[Action]` (e.g., `cmShareAgent`, `cmProposeTrade`)
- Auth functions: `auth[Action]` (e.g., `authSubmit`, `authLogout`)
- Helper functions: short names (`dk` = darken, `lt` = lighten, `esc` = escape HTML, `pick` = random from array)

### Internal fields
Fields prefixed with `_` (e.g., `_parents`, `_hasMutation`, `_isClone`, `_isBorrowed`) are internal metadata. They are:
- Stripped on export (both exportAll and doExportSelected)
- Not shown in UI unless specifically handled
- Used for game mechanics (mutation tracking, work timing, clone locking, lend timing)

### CSS conventions
- CSS variables defined in `:root` (--bg, --gold, --cyan, --text, --border, etc.)
- Component-specific classes prefixed by section: `.ag-` (agents), `.sk-` (skills), `.wed-` (marriage), `.dp-` (deploy), `.cm-` (community)
- Badge classes: `.ag-badge.clone` (purple), `.ag-badge.lent` (gold), `.ag-badge.borrowed` (cyan), `.ag-badge.locked` (red)
- Minimum font size: 7px (Press Start 2P pixel font)

## Known bug patterns

**WATCH FOR THESE — they've happened multiple times:**
- `x()` instead of `x++` in for loops (breaks sprite rendering silently)
- Forgetting to call `save()` after modifying agents array
- HTML string escaping: use `esc()` for all user-provided text in HTML generation
- Single quotes inside onclick handlers need `\\'` escaping in string concatenation
- `localStorage` calls should always be wrapped in try/catch
- `closeModal()` calls `renderTab()` which re-renders the current tab — don't call `switchTab()` after `closeModal()` if you need to pass data (use direct DOM manipulation like `editLook()` does)
- Supabase `sb_publishable_` keys work with supabase-js v2 (drop-in replacement for old `eyJ` anon keys)

## What's built (complete)

- [x] 12 body types with full sprite rendering
- [x] SVG pixel sprites (16x24 grid, chibi proportions)
- [x] Agent cards with modal detail view + lock state for clones/borrowed
- [x] Agent card badges: CLONE, ON LOAN, BORROWED, LOCKED
- [x] Pin, sort (8 options incl. clone/lent/borrowed), search, import/export
- [x] 185 skills (140 visible + 45 hidden), 16 categories
- [x] Merged Library with rich descriptions + teach-from-expanded-card
- [x] Skill Tree with clickable-to-learn nodes + prerequisite logic
- [x] MY SKILLS tab with expandable custom skills + agent skills
- [x] Create Skill with assign-to-agent
- [x] Publish custom skills directly to Supabase community market
- [x] Marriage Chamber (Natural + Gene Splice modes)
- [x] 3x re-roll limit, personality inheritance, mutation system
- [x] Progressive XP curve (10/25/50/100/150/250/400/600/900)
- [x] Growth dashboard with live XP ticking
- [x] Offline catch-up (8hr cap)
- [x] Done bonus with 5-min working guard + mutation reveal
- [x] Deploy tab (4 providers, chat interface, system prompt generator)
- [x] Clone task counter in deploy (increments on response, unlocks at 3)
- [x] Borrowed auto-return on deploy task completion
- [x] Personality behavior system (8 types with rich prompts)
- [x] Personality lock on born agents
- [x] Edit Look bug fixed (loads agent data into Create form correctly)
- [x] Auth system (email login/signup) — CONNECTED to Supabase
- [x] Cloud sync via Supabase
- [x] Community: Clone (locked 3 tasks), Trade, Lend (24hr timer + auto-return + 10 XP reward), Skill Market, Friends (coming soon), Profile
- [x] Lend/borrow expiry auto-checked every 10 seconds in growth tick
- [x] Enhanced import with preview + select (Agents tab + Deploy tab)
- [x] Safety notice on API keys
- [x] Export sanitization (strips internal fields)
- [x] Supabase SQL schema with RLS policies — DEPLOYED
- [x] Setup guide for deployment

## What's NOT built yet

- [ ] Vercel deployment
- [ ] Friends list (community tab — coming soon placeholder exists)
- [ ] Privacy policy page
- [ ] Real-time notifications for trade/share/lend requests
- [ ] Family tree / lineage viewer
- [ ] Shareable agent card URLs (viral hook)
- [ ] Lend return notification to lender (currently silent)
- [ ] VS Code extension (Phase 2)

## Design principles

1. **Ship fast, differentiate:** Marriage/breeding mechanic is the key differentiator from other agent tools.
2. **Surgical fixes over rewrites:** Prefer targeted corrections rather than full rebuilds.
3. **Visual-first decisions:** Star describes what they SEE. Live rendered comparisons before decisions.
4. **Phased feature gating:** Core loop ships first, community/social deferred to backend.
5. **Mutation as delight:** Hidden skills that reveal through play add discovery value.
6. **Create = free, Learn = costs XP:** Encourages exploration while giving XP pool purpose.
7. **Personality matters:** Born agents have locked personality — makes breeding decisions meaningful.
8. **API keys stay local:** Never stored on our servers. PDPA compliance by design.
9. **Clone = locked gift:** Clones must earn their freedom through 3 task deployments.
10. **Lend = community mechanic:** Encourages sharing via XP reward, protected by 24hr timer and auto-return.

## How to work on this project

### Setup
```bash
# Clone the repo
git clone https://github.com/daraproud/8gents.git
cd 8gents

# Serve locally (required for Supabase — can't use file:// protocol)
python3 -m http.server 8080

# Open in browser
open http://localhost:8080/index.html
```

### Making changes
1. Edit `index.html` directly
2. Test in browser (refresh to see changes)
3. Check browser console (F12) for errors
4. Commit and push — Vercel auto-deploys

### Supabase (already configured)
- Project URL: `https://iscyzixingifdlcnqyxf.supabase.co`
- Tables: profiles, agents, shared_agents, community_skills
- Auth: Email provider, confirmation OFF for dev
- Trigger: handle_new_user() with EXCEPTION handler

## Important reminders

- **Never store API keys in Supabase or any backend.** They stay in localStorage.
- **Always strip `_` fields on export.** The export functions already do this — don't bypass them.
- **Level is derived from XP.** Never set `a.level` directly — use `awardXP()` which calls `getLevelFromXP()`.
- **Born agents have locked personality.** Check for `_parents` before allowing personality changes.
- **Locked agents cannot be edited.** Check `_isClone` + `_cloneTasksDone < 3`, `_isBorrowed`, or `_isLent` before allowing edits.
- **The crown hat was intentionally removed.** Crown renders automatically at Lv.10 on the sprite — it's an achievement, not a cosmetic choice.
- **Font minimum is 7px.** The Press Start 2P pixel font is hard to read below this size.
- **Test offline AND with Supabase.** The app must work both ways.
- **Must use local server for testing.** `file://` protocol blocks Supabase API calls. Use `python3 -m http.server 8080`.
- **Supabase uses new key format.** `sb_publishable_` keys work with supabase-js v2 — no migration needed.
