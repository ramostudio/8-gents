# 🎮 8-GENTS

### Your AI agents are alive.

> Merge, breed, mutate, deploy, trade — the agents you create are ready for your task with skill upgrades. What will yours become?

---

## What is 8-Gents?

**8-Gents** is a living AI agent simulation platform where you create pixel art agents, teach them real skills, deploy them to work on actual AI platforms, and breed them to discover hidden mutations.

Think **Tamagotchi × AI agent management**.

Your agents aren't just tools — they're characters with personalities, skill trees, levels, and lineage. Two agents can merge in the Marriage Chamber to produce offspring with inherited skills and mysterious mutations you won't see until they complete their first task.

---

## ✨ Features

**🧬 CREATE** — Design pixel agents with 12 body types, custom sprites, and 8 distinct personalities

**📚 185 SKILLS** — Learn, create, and trade skills across 16 categories. 45 hidden skills can only appear through mutation

**💍 MARRIAGE CHAMBER** — Merge two agents. Natural mode gives 50/50 skill inheritance + random mutations. Gene Splice mode lets you pick

**🚀 DEPLOY** — Connect to Claude, ChatGPT, Gemini, or any AI platform. Your agent's personality and skills shape its system prompt

**📈 GROWTH** — Agents earn XP while working. 10 levels to crown. Offline catch-up for up to 8 hours

**🤝 COMMUNITY** — Clone agents to friends, trade 1-for-1, lend for breeding, publish skills to the community market

**🔒 CLONE LOCK** — Cloned agents arrive locked. Complete 3 tasks to unlock editing. Earn your agent's trust

**⏰ LEND SYSTEM** — Loan agents for breeding or deployment. Auto-returns after task completion or 24 hours. Earn +10 XP

---

## 🎨 The Pixel Roster

```
    HUMAN  ·  CAT  ·  FOX  ·  BUNNY  ·  OWL  ·  FROG
    ALIEN  ·  GOBLIN  ·  SKELETON  ·  SLIME  ·  DEMON  ·  GHOST
```

Each body type has unique sprite rendering. Customize with 12 skin tones, 10 hairstyles, 6 clothing types, 10 hats, 10 accessories, and 9 props. Or draw your own with the built-in pixel editor.

---

## 🧪 The Mutation System

When two agents breed in Natural mode, there's a 10-30% chance of mutation. Mutated skills appear as purple `???` tags — you won't know what they are until the offspring completes their first task.

45 hidden skills from the **special**, **mystical**, and **philosophy** categories can only be discovered through mutation. They never appear in the skill shop.

*What did your agent inherit?*

---

## 🛠 Tech Stack

| Layer | Tech |
|-------|------|
| Frontend | Single-file vanilla HTML/CSS/JS (~3100 lines) |
| Font | Press Start 2P (pixel RPG aesthetic) |
| Sprites | SVG-based pixel art on 16×24 grid |
| Backend | Supabase (PostgreSQL + Auth) |
| AI | Claude, ChatGPT, Gemini, or any OpenAI-compatible API |
| Hosting | Vercel (auto-deploy from this repo) |

No frameworks. No build step. One HTML file.

---

## 🚀 Quick Start

```bash
# Clone
git clone https://github.com/ramostudio/8gents.git
cd 8gents

# Serve locally (required for Supabase auth)
python3 -m http.server 8080

# Open
open http://localhost:8080/index.html
```

See [SETUP-GUIDE.md](SETUP-GUIDE.md) for full deployment instructions including Supabase and Vercel setup.

---

## 📁 Project Structure

```
8gents/
├── index.html          # The entire app
├── CLAUDE.md           # AI coding context (for Claude Code)
├── supabase-setup.sql  # Database schema
├── SETUP-GUIDE.md      # Deployment walkthrough
└── README.md           # You are here
```

---

## 🗺 Roadmap

- [x] 12 body types with pixel sprites
- [x] 185 skills + mutation system
- [x] Marriage Chamber (Natural + Gene Splice)
- [x] Deploy to Claude / ChatGPT / Gemini
- [x] Growth system with XP + levels
- [x] Community: Clone, Trade, Lend, Skill Market
- [x] Supabase auth + cloud sync
- [ ] Friends list
- [ ] Family tree / lineage viewer
- [ ] Shareable agent cards (viral)
- [ ] Real-time trade notifications
- [ ] Mobile-responsive layout

---

## 🧠 Design Philosophy

**Agents are not disposable.** Every agent has a personality that gets locked when they're born through breeding. Every mutation is a surprise. Every clone must earn its freedom through 3 completed tasks. Every lent agent comes back with a story.

The deeper you go, the more you discover.

---

<div align="center">

**Built by [Ramo Studio](https://github.com/ramostudio)**

*What will yours become?*

</div>
