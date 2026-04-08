# Obsidian Second Brain

> A personal knowledge management vault powered by Obsidian + Claude AI agents. Captures daily life, work, people, places, and media — with scheduled agents that auto-process your notes, surface connections, and keep everything linked.

---

## What It Does

You write daily notes. The agents do the rest.

```
You write a daily note on your phone
        ↓
Obsidian Git auto-pushes to GitHub
        ↓
Hourly agent clones vault, processes notes:
  → creates People notes for anyone mentioned
  → creates Place notes for any location
  → creates Media notes (photos, movies, albums)
  → updates links, fills frontmatter, sets social score
  → pushes back to GitHub
        ↓
Daily agent runs at noon:
  → resolves Open Questions you've answered
  → writes Weekly Review (Saturdays)
  → surfaces 5 categories of curated content
        ↓
Obsidian pulls changes automatically
```

Everything links together. Ask Claude about a person, a place, a project — it reads the right notes, not everything.

---

## Screenshots

> *Coming soon — vault graph, daily note, dashboard*

---

## Prerequisites

| Tool | Purpose |
|---|---|
| [Obsidian](https://obsidian.md) | Note editor (desktop + mobile) |
| GitHub account | Sync source of truth |
| [Claude Pro](https://claude.ai) | Powers the scheduled agents |
| Obsidian Git plugin | Auto push/pull |
| Dataview plugin | Social heatmap queries |
| Heatmap Calendar plugin | Renders the social heatmap |
| Calendar plugin | Sidebar date nav, daily note creation |
| Advanced Progress Bars plugin | Sprint + goal progress bars |

---

## Quick Start

### Option A — Install Script (recommended)

**Windows** — open PowerShell as Administrator and run:
```powershell
irm https://raw.githubusercontent.com/LuisFTE/obsidian-vault-template/main/install.ps1 | iex
```
Installs WSL2 + Ubuntu if needed, restarts if required, then hands off to the bash script automatically.

**Linux / macOS / WSL2 already set up:**
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/LuisFTE/obsidian-vault-template/main/install.sh)
```

Both paths handle everything: installs dependencies (Node, Claude Code, gh), authenticates GitHub and Claude, creates your private repo from this template, sets up the ChatGPT Chats folder, creates both scheduled agents, and walks you through filling in Now.md interactively. Then install Obsidian on your phone and/or PC and follow OBSIDIAN_SETUP.md — that's it.

---

### Option B — Manual Setup

**1. Use this template**

Click **Use this template** on GitHub, create a private repo named `obsidian-vault`.

**2. Clone and open in Obsidian**

```bash
git clone https://github.com/YOUR_USERNAME/obsidian-vault.git
```

Open the folder as a vault in Obsidian. Install the plugins listed in Prerequisites above.

**3. Configure plugins**

Follow [OBSIDIAN_SETUP.md](./OBSIDIAN_SETUP.md) for exact plugin settings.

**4. Fill in `_Index/Now.md`**

The AI's entry point every session. Fill in your name, role, current sprint, goals. Keep it current.

**5. Create a GitHub PAT**

GitHub → Settings → Developer settings → Personal access tokens → Fine-grained tokens.  
Grant **Read and write** on **Contents** for your vault repo.

**6. Set up the agents**

Go to [claude.ai/code](https://claude.ai/code) → **Triggers** → **New trigger**.

Create both agents from the prompts in [AGENTS.md](./AGENTS.md). Replace:
- `YOUR_GITHUB_PAT` → your token from step 5
- `YOUR_USERNAME` → your GitHub username  
- `YOUR_REPO` → your repo name

**7. Write your first daily note**

Open the Calendar plugin sidebar, click today's date. Start writing.

---

## Folder Structure

```
vault/
├── _Index/                    # AI entry points and live indexes
│   ├── Now.md                 # ← AI reads this first every session
│   ├── Dashboard.md           # Progress bars, heatmap, project status
│   ├── Open Questions.md      # Async queue for questions needing your input
│   ├── Content Queue.md       # Daily curated content (auto-populated)
│   └── Content Queue Log.md   # URL dedup log
│
├── _Templates/                # All note templates
│
├── Daily/
│   ├── Life/Notes/            # YYYY-MM-DD.md  daily journal
│   └── Todo/                  # YYYY-MM-DD.md  daily todos
│
├── Life/
│   ├── People/                # Personal contacts
│   ├── Physical/              # Active life arcs (health, relationships, etc.)
│   ├── Ephemeral/             # Transient feelings, desires, states
│   └── Fact/                  # Static reference (values, thinking style)
│
├── Career/
│   ├── People/                # Work contacts
│   └── Physical/              # Work projects, sprint notes, incident log
│
├── Places/                    # Location notes — hierarchy, people, memories, media
│
├── Media/
│   ├── People/                # Public creators — artists, directors, musicians
│   ├── Channels/              # YouTube channels
│   └── *.md                   # Individual media notes
│
├── Projects/                  # Personal projects
├── Finance/                   # Financial notes and operating system
├── Learning/                  # Language, skills, courses
├── Reviews/                   # Weekly/monthly synthesis
└── Music/                     # Music notes
```

---

## Note Types

| Type | Location | Purpose |
|---|---|---|
| Daily | `Daily/Life/Notes/` | Day-to-day journal |
| Todo | `Daily/Todo/` | Work + life tasks with priorities |
| Person | `Life/People/` | Personal contacts |
| Creator | `Media/People/` | Public figures (artists, directors) |
| Place | `Places/` | Locations with hierarchy, people, media |
| Media | `Media/` | Photos, videos, movies, shows, albums |
| Project | `*/Physical/` | Arc-tracked projects |
| Ephemeral | `*/Ephemeral/` | Transient states and ideas |
| Fact | `*/Fact/` | Static reference material |
| Review | `Reviews/` | Weekly/monthly synthesis |

---

## Templates

| Template | Use For |
|---|---|
| `Daily Life Note.md` | Daily journal (auto-created by Calendar plugin) |
| `Todo.md` | Daily task list (auto-created by agent) |
| `Place.md` | Location — part_of hierarchy, people, memories, media |
| `Person - Creator.md` | Public figure (artist, director, musician) |
| `Personal Project.md` | Personal project with arc tracking |
| `Work Project.md` | Work project with sprint arc tracking |
| `Media - Photo.md` | Photo taken by you |
| `Media - Video (Personal).md` | Video taken by you |
| `Media - YouTube.md` | YouTube video — links to channel note |
| `Media - Movie.md` | Movie — director wikilink + cast table |
| `Media - Show.md` | TV show — creator wikilink + cast table |
| `Media - Album.md` | Music album |
| `Media - Channel.md` | YouTube channel |

---

## Linking Philosophy

Two rules that keep the graph useful:

**Wikilinks** — use when someone/something is *central* to the note:
- Director of the movie you're logging
- Artist whose work the photo captures
- Place a memory is fundamentally about

**Plain text** — use when someone was just *present*:
```yaml
with: Sarah    # ← plain text, not [[Life/People/Sarah]]
```

This prevents context overload. Asking about a person pulls their people note, relationship notes, and daily entries — not every movie you've watched together.

---

## The Agents

Two scheduled Claude agents run automatically. See [AGENTS.md](./AGENTS.md) for the full prompts.

### Hourly Digest
Runs at the top of every hour. Processes today + yesterday's daily notes:
- Creates missing people, place, and media notes
- Updates links and frontmatter
- Scores social activity (0–5)
- Writes today's `⚡ Today` section from Now.md
- Flags unknown people to Open Questions

### Daily Tasks + Weekly Review
Runs at 5am daily:
- Resolves answered Open Questions
- Writes weekly review (Saturdays only)
- Surfaces 5 categories of curated content (2 YouTube + 2 articles each, never repeats)

### Local Cron Alternative
If you have an always-on machine, you can run agents locally via WSL cron — no CCR trigger limits, no git clone overhead. Setup in [AGENTS.md](./AGENTS.md).

---

## Multiple Writers

| Writer | Role |
|---|---|
| Mobile Obsidian Git | Primary raw writing |
| Desktop Obsidian Git | Local editing |
| Hourly agent | Digest processing |
| Daily agent | Questions, review, content |
| Manual Claude Code | Structural vault work |

All writers use **pull-rebase** + **theirs** conflict resolution. The agents retry with `git pull --rebase` on push failure.

---

## Open Questions Queue

When the digest agent encounters a new person it doesn't recognize, it adds a question to `_Index/Open Questions.md`:

```
- [ ] [[Daily/Life/Notes/2026-04-03]] — Who is Sarah?
```

Answer inline, then check it off:

```
- [x] [[Daily/Life/Notes/2026-04-03]] — Who is Sarah? My college roommate, now lives in Austin.
```

The daily agent picks up answered questions, creates or updates the relevant note, and clears the queue.

---

## License

MIT — use it, fork it, sell templates based on it. See [LICENSE](./LICENSE).
