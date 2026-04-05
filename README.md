# Obsidian Second Brain — Vault Template

A personal knowledge management vault powered by Obsidian, Claude AI agents, and GitHub. Captures daily life, work, people, places, media, and goals — with scheduled AI agents that process notes, extract people and places, generate todos, and surface curated content.

---

## How It Works

```
You write daily notes on iPhone/desktop
        ↓
Obsidian Git auto-pushes to GitHub
        ↓
Hourly CCR agent clones vault, processes notes,
creates people/place/media notes, updates Now.md, pushes back
        ↓
Daily CCR agent resolves Open Questions,
runs Weekly Review (Saturdays), appends curated content
        ↓
Obsidian Git auto-pulls agent changes on startup
```

---

## Prerequisites

- [Obsidian](https://obsidian.md) (desktop + mobile)
- GitHub account + private repo
- [Claude](https://claude.ai) account (Pro or higher for CCR triggers)
- Obsidian plugins:
  - **Obsidian Git** — sync to GitHub
  - **Dataview** — social tracker heatmap
  - **Heatmap Calendar** — renders the social heatmap
  - **Calendar** — sidebar date nav, daily note creation
  - **Advanced Progress Bars** — sprint + goal progress bars

---

## Setup

### 1. Create your GitHub repo

Create a **private** repo on GitHub (e.g. `obsidian-vault`). Do not initialize with a README.

### 2. Clone this template

```bash
git clone https://github.com/LuisFTE/obsidian-vault-template.git obsidian-vault
cd obsidian-vault
```

Remove the template remote and add yours:

```bash
git remote remove origin
git remote add origin https://github.com/YOUR_USERNAME/obsidian-vault.git
git branch -M main
git push -u origin main
```

### 3. Open in Obsidian

Open the `obsidian-vault` folder as a vault in Obsidian. Install the plugins listed above.

### 4. Configure Obsidian Git

In Obsidian settings → Obsidian Git:
- **Sync method:** Rebase
- **Merge strategy (pull):** Theirs  
- **Auto pull interval:** 15 minutes
- **Auto push interval:** 30 minutes
- **Pull on startup:** On

On **mobile** (iPhone/Android):
- Same settings; syncMethod defaults to merge — that's fine, theirs covers conflicts

### 5. Generate a GitHub PAT

GitHub → Settings → Developer settings → Personal access tokens → Fine-grained tokens.  
Grant **Read and write** access to your vault repo under **Contents**.  
Copy the token — you'll use it in the agent prompts.

### 6. Fill in Now.md

Open `_Index/Now.md` and fill in your details — who you are, current sprint, work/life status. This is the AI agent's entry point every session.

### 7. Set up CCR agents

Go to [claude.ai/code](https://claude.ai/code) → **Triggers** → **New trigger**.

Create both agents from the prompts in [AGENTS.md](./AGENTS.md). Replace:
- `YOUR_GITHUB_PAT` — your token from step 5
- `YOUR_USERNAME` — your GitHub username
- `YOUR_REPO` — your repo name

See [AGENTS.md](./AGENTS.md) for full prompts and a local cron alternative.

---

## Folder Structure

```
vault/
├── _Index/              # Entry points and indexes
│   ├── Now.md           # ← AI reads this first every session
│   ├── Dashboard.md     # Progress bars, project status, social heatmap
│   ├── Open Questions.md# Async queue for questions the agent needs answered
│   ├── Content Queue.md # Daily curated content (5 categories, auto-refreshed)
│   └── Content Queue Log.md  # URL dedup log
│
├── _Templates/          # Note templates (used by agent and Calendar plugin)
│
├── Daily/
│   ├── Life/Notes/      # YYYY-MM-DD.md — daily journal entries
│   └── Todo/            # YYYY-MM-DD.md — daily todos
│
├── Life/
│   ├── People/          # Personal contacts (friends, family, colleagues)
│   ├── Physical/        # Active life projects (relationship, health, etc.)
│   ├── Ephemeral/       # Feelings, desires, transient states
│   └── Fact/            # Static reference (values, thinking style, etc.)
│
├── Career/
│   ├── People/          # Work contacts
│   └── Physical/        # Work projects, sprint notes, WP log
│
├── Places/              # Location notes with people, memories, media links
│
├── Media/
│   ├── People/          # Public creators — artists, directors, musicians
│   ├── Channels/        # YouTube channels
│   └── *.md             # Individual media notes (photos, movies, albums, etc.)
│
├── Projects/
│   ├── Physical/        # Active personal projects
│   └── Ephemeral/       # Dormant/exploratory project ideas
│
├── Finance/             # Financial notes and operating system
├── Learning/            # Language, skills, courses
├── Reviews/             # Weekly/monthly review notes
├── Music/               # Music notes
└── Cooking/             # Recipes and techniques
```

---

## Note Types

| Type | Purpose | Location |
|---|---|---|
| Physical | Active projects, events | `Category/Physical/` |
| Ephemeral | Feelings, desires, states | `Category/Ephemeral/` |
| Fact | Static reference, benchmarks | `Category/Fact/` |
| Daily | Day-to-day life log | `Daily/Life/Notes/` |
| Todo | Work + life tasks | `Daily/Todo/` |
| Person | Personal contacts | `Life/People/` or `Career/People/` |
| Creator | Public figures (artists, directors) | `Media/People/` |
| Place | Locations with hierarchy + people | `Places/` |
| Media | Photos, videos, movies, albums, etc. | `Media/` |
| Review | Weekly/monthly synthesis | `Reviews/` |

---

## Linking Philosophy

**Use wikilinks** when a person/place is **central** to the note — artist, director, subject of a photo, the place a memory is about.

**Use plain text** when someone was just **present** — e.g. `with: Miki` in frontmatter, not `[[Life/People/Miki]]`. This keeps the graph clean and prevents context overload when querying about a person.

---

## Templates

| Template | Use For |
|---|---|
| `Daily Life Note.md` | Daily journal entry |
| `Todo.md` | Daily task list |
| `Place.md` | Location note |
| `Person - Creator.md` | Public figure (artist, director, musician) |
| `Personal Project.md` | Personal project arc tracking |
| `Work Project.md` | Work project arc tracking |
| `Media - Photo.md` | Photo taken by you |
| `Media - Video (Personal).md` | Video taken by you |
| `Media - YouTube.md` | YouTube video watched |
| `Media - Movie.md` | Movie (with director + cast) |
| `Media - Show.md` | TV show (with director/creator + cast) |
| `Media - Album.md` | Music album |
| `Media - Channel.md` | YouTube channel |

---

## Multiple Writers

The vault supports multiple simultaneous writers without conflicts:

| Writer | Role |
|---|---|
| iPhone Obsidian Git | Primary raw writing |
| Desktop Obsidian Git | Local editing |
| Hourly CCR agent | Digest processing |
| Daily CCR agent | Questions, review, content |
| Manual Claude Code | Structural vault work |

All writers use **pull-rebase** with **theirs** conflict resolution. The CCR agent retries with `git pull --rebase` on push failure.

---

## Tips

- Write messy daily notes — the agent cleans up structure, extracts people/places, updates links
- Answer questions in `_Index/Open Questions.md` inline — check the box and write your answer on the next line
- `_Index/Now.md` is your single source of truth for the AI — keep it current
- The social heatmap tracks how connected vs. isolated you've been; score is set automatically by the agent
