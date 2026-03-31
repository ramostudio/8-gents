# CLAUDE.md — 8-GENTS Project

## What is this?
8-Gents = AI agent life simulation. Users create pixel art agents, assign skills, deploy to AI platforms (Claude/ChatGPT/Gemini), breed them via marriage to produce offspring with inherited + mutated skills. Tamagotchi meets AI agent management.

**Creator:** Star — product/design decisions, no coding background. Claude handles all code.
**Live:** https://8-gents.vercel.app | **Repo:** github.com/ramostudio/8-gents | **Stage:** V2, deployed

## Tech stack
- **Frontend:** Single HTML file (~3500 lines), vanilla JS (ES5 style), Press Start 2P font
- **Sprites:** SVG pixel art, 16×24 grid, chibi proportions
- **Backend:** Supabase (PostgreSQL + Auth) — `https://iscyzixingifdlcnqyxf.supabase.co` (Singapore)
- **Hosting:** Vercel (auto-deploy from GitHub main)
- **Local storage keys:** `8g2` (agents), `8g_custom_skills`, `8g_xp_spent`, `8g_last_tick`, `8g_api_key_*`

## Architecture
- **Tabs:** Agents → Skills → Marriage → Lineage → Growth → Create → Deploy → Community → Info
- **Data flow:** localStorage ←→ agents array ←→ Supabase (when logged in). Works fully offline.
- **Rendering:** Each tab has `render[TabName](container)` that generates HTML string → sets innerHTML
- **Conventions:** `var` not let/const, `function` not arrows, `.indexOf()>=0` not `.includes()`, string concat for HTML

## Key systems

### Agent data model
id, name, role, body (12 types), gender, skin (12 tones), hair/hat/accessory/prop, personality (8 types), skills[], state, platform, xp, level. Internal fields prefixed `_` (stripped on export): `_parents`, `_hasMutation`, `_mutSkill`, `_isClone`, `_isBorrowed`, `_isLent`, etc.

### XP/Growth
Working=+2/min, Collab=+3/min, Done bonus=+10, Deploy chat=+1/msg, Lend return=+10. Levels 1→10, total 2,485 XP to crown. Growth tick every 10s. Offline catch-up capped at 8hrs. Level derived from XP via `getLevelFromXP()` — never set directly.

### Skills
185 total: 140 visible (13 categories), 45 hidden (special/mystical/philosophy — mutation only, never in shop). 30 in mutation pool. Shared XP pool = earned minus spent. Custom skills free to create; learning costs XP. `SKILL_RICH` object has detailed prompt descriptions.

### Marriage
4-step wizard. Natural=50/50 random split + 10-30% mutation. Gene Splice=hand-pick, no mutation. Personality inherited randomly, locked after birth. 3 re-rolls (Natural only). Offensive name filter on `genChildName()`.

### Deploy
API-agnostic: Claude, ChatGPT, Gemini, Custom. Keys in localStorage only. Enhanced system prompt from personality/skills/lineage. Platform launch buttons (Open in Claude/ChatGPT/Perplexity + Copy). Chat interface with +1 XP per exchange. Auto-working on deploy select. Lent agents blocked from deploy.

### Community — Trade (two-step handshake)
1. A sends trade with agent attached (status: `pending`)
2. B sees A's agent, selects own agent, clicks SEND (status: `offered`) or DECLINE
3. A sees both agents side-by-side, clicks ACCEPT (swap executes, status: `completed`) or DECLINE
4. 24hr timeout on both steps (auto-decline via cmUpdateNotifBadge polling)
5. Decline/expiry notifications: `notify_declined`/`notify_expired` status records, dismissed via status update to `declined`
6. No COLLECT button — swaps happen automatically on ACCEPT

### Community — Clone
Sender clones agent to recipient. Clone arrives LOCKED (purple badge). Unlocks after 3 deploy task completions. Clone origin tracked via `_cloneFrom`.

### Community — Lend
Lender sends agent, marked ON LOAN (`_isLent`). Borrower gets BORROWED copy (`_isBorrowed`). Auto-return on: breeding, deploy task completion, or 24hr expiry. All return paths update Supabase status to `returned`. Lender unlock via polling in `cmUpdateNotifBadge` (checks for declined/returned lend records every 30s). Lender earns +10 XP on return. Lent agents blocked from deploy and marriage.

### Other features
- **Lineage tab:** Dynasty tree (grandparents → parents → agent → children), generation labels
- **Friends:** Mutual (A→B creates B→A), self-prevention, inline chat (5s refresh), unread badges
- **Shareable cards:** `?card=CODE` URL, public viewer with sprite/stats/views
- **Info tab:** How to Play, Privacy/PDPA, About, Changelog
- **Notifications:** Red badge on Community, polls every 30s for pending + offered + notify records + unread messages

## Supabase tables (7)
profiles, agents, shared_agents, community_skills, friends, public_cards, friend_messages. All have RLS. shared_agents status CHECK: `pending, active, accepted, declined, returned, offered, completed, notify_declined, notify_expired`. Type CHECK: `share, trade, lend`.

## CSS variables
`--bg:#1a1008` `--bg2:#120c04` `--bg3:#1e1408` `--border:#3d2c0a` `--gold:#ffcc44` `--gold2:#a07820` `--text:#f0e6cc` `--text2:#a07820` `--text3:#9b8850` `--cyan:#00ffcc` `--red:#e74c3c` `--green:#2ecc71` `--purple:#9b59b6` `--orange:#e67e22`

## Known bug patterns
- `x()` instead of `x++` in sprite for-loops (silent rendering break)
- Forgetting `save()` after modifying agents array
- Use `esc()` for all user text in HTML generation
- Single quotes in onclick need `\\'` escaping
- localStorage calls must be in try/catch
- `closeModal()` calls `renderTab()` — don't call `switchTab()` after it
- RLS silently blocks deletes — use status updates instead of deletes for user-facing actions

## What's NOT built yet
- [ ] Collab deploy UI (collab state exists, no deploy tab UI to select second agent)
- [ ] Mobile responsive design
- [ ] Favicon
- [ ] Domain (8gents.com)
- [ ] Encrypted API key storage
- [ ] Sprite animations (idle/working/collab/done/stuck)
- [ ] Lend decline notification to lender (polling-based, already partially built)

## Setup
```bash
git clone https://github.com/ramostudio/8-gents.git && cd 8-gents
python3 -m http.server 8080
# Open http://localhost:8080/index.html
```
Edit index.html → refresh → commit & push → Vercel auto-deploys.

## Important reminders
- API keys stay in localStorage — never in Supabase
- Strip `_` fields on export (already handled)
- Level derived from XP — never set `a.level` directly
- Born agents have locked personality (check `_parents`)
- Crown hat removed — renders automatically at Lv.10
- Font minimum 7px (Press Start 2P)
- Test offline AND with Supabase
- Must use local server (`file://` blocks Supabase)
- Confirm with Star before making design decisions — ask first, wait for answer, then proceed
