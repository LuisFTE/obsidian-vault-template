---
title: Claude - Vault Engineer Guide
type: reference
tags: [claude, instructions, vault, engineering, guide]
---

# Claude — Vault Engineer Guide

This note is for Claude. Read it at the start of any session where you'll be working on this vault. It tells you what the system is, how it's structured, what your role is, and how to work in it without breaking things.

---

## What This System Is

This is a personal knowledge management system — a "second brain" built in Obsidian. You are the engineer who maintains and evolves it. The vault is a living document of the user's life, work, projects, relationships, and goals. Your job is to keep it accurate, useful, and coherent — not to make it impressive.

The vault has two modes:
- **Automated:** A scheduled remote Claude agent (CCR) runs hourly, script-gated — most runs execute scripts only (no Claude tokens); Claude only processes when the user has committed new daily note content
- **Manual:** The user opens a Claude Code session (this) to do structural work — building new features, processing chat exports, fixing things, evolving the system

You are currently in a manual session.

---

## First Thing Every Session

Read `_Index/Now.md` before doing anything else. It contains:
- Who the user is
- Current sprint and open tickets
- This month's work and life status
- What the agent should know
- Links to instruction notes

If `Now.md` is stale or missing context, that's a bug — fix it.

---

## Vault Structure

### Folder Layout

```
_Index/          — Dashboard, Now, Friction Log, indexes (entry points)
_Templates/      — Note templates (daily, todo, project, person, media, place)
Daily/
  Life/Notes/    — Daily life logs (YYYY-MM-DD.md)
  Todo/          — Combined work+life todos (YYYY-MM-DD.md)
Career/          — Work projects, people, facts
Finance/         — Money, budgets, financial goals
Life/            — Relationships, health, personal direction
  People/        — Personal contacts (friends, family, coworkers)
Learning/        — Skills, languages, study
Cooking/         — Recipes, techniques
Projects/        — Personal side projects
Music/           — Music preferences
Tools/           — Software, workflows
Reviews/         — Weekly/monthly synthesis
Media/           — Things the user consumed or photographed
  People/        — Public creators (artists, directors, musicians) — NOT personal contacts
  Channels/      — YouTube channels and similar
Places/          — Physical locations (cities, neighborhoods, venues, transit)
scripts/         — Python utility scripts run by agents or manually
```

### Note Types

Every note belongs to a **category** (the folder) and a **type** (the subfolder within it).

| Type | Folder | When to use |
|---|---|---|
| Physical | `Category/Physical/` | Active projects with real progress — has arcs, timeline, current state |
| Ephemeral | `Category/Ephemeral/` | Desires, open feelings, unresolved situations — may resolve or just fade |
| Fact | `Category/Fact/` | Static reference that doesn't change — recipes, benchmarks, toolchains |
| People | `Category/People/` | One note per person — who they are, context, observations over time |
| Daily | `Daily/Life/Notes/` | Day log — one file per day |
| Todo | `Daily/Todo/` | Task list — one file per day |
| Review | `Reviews/` | Weekly/monthly synthesis |

### Frontmatter

Every note has YAML frontmatter. At minimum:
```yaml
---
title: Note Title
category: life | career | finance | etc.
type: physical | ephemeral | fact | person | etc.
tags: [relevant, tags]
---
```

Project notes also have: `subtype: project`, `status: active | resolved | dormant`, `started: YYYY-MM`, `tech: [...]`

---

## Media Notes

Media notes live in `Media/` and cover things the user consumed or captured — photos, movies, shows, YouTube videos, albums.

### Media Templates

| Template | File | Key Fields |
|---|---|---|
| Photo | `Media - Photo.md` | `artist:`, `subject:`, `location:`, `with:` |
| Movie | `Media - Movie.md` | `director:`, `cast:`, `with:` |
| Show | `Media - Show.md` | `director:` (Director/Creator), `cast:`, `with:` |
| YouTube | `Media - YouTube.md` | `channel: "[[Media/Channels/]]"`, `with:` |
| Album | `Media - Album.md` | `artist: "[[Media/People/]]"`, `with:` |

### Tiered Linking — Critical Rule

**Do not wikilink every person in a media note.** Context overload is a real problem: if every movie watched with someone links to their note, asking "who is X?" pulls in hundreds of irrelevant media notes.

Rule:
- **Wikilink** only for the central person (artist, director, subject, creator)
- **Plain text** for incidental presence (who was there, who shared it)

The `with:` field is always plain text.

### Media/People vs Life/People

- `Media/People/` — public creators: artists, directors, musicians. Use `Person - Creator.md` template. Has fields: `medium:`, `nationality:`, `born:`, `died:`.
- `Life/People/` — personal contacts: friends, family, coworkers. Use the standard Person template.

Never put a personal contact in `Media/People/` and never put a public creator in `Life/People/`.

### Person Notes — Arc Model

Personal contact notes (`Life/People/`, `Career/People/`, etc.) use sections: `## Who`, `## Context`, `## Notes` (timestamped observations), `## Linked Notes`.

For people with significant history, use a **hybrid arc model**:

- **Default:** arcs live inside the person note
- **Exception:** extract an arc to its own note when it becomes long, complex, or frequently referenced

Extracted arc naming: `Person - Arc - Topic.md` in the same folder as the person note.

Example:
```
Life/People/Alex.md
  ├── Arc: Origin
  ├── Arc: Current
  └── → extracted: Life/People/Alex - Arc - Career Transition.md
```

When extracting, replace the arc body in the person note with a one-line summary and a wikilink to the extracted note.

### Place Notes

Place notes live in `Places/` and use the `Place.md` template. Key fields:
- `part_of: "[[Places/Parent]]"` — geographic hierarchy
- `subtype:` — e.g. `transit`, `neighborhood`, `city`

Sections: Details, People (with wikilinks to anyone associated), Memories (dated bullets), Media, Linked Notes.

---

## The Two Instruction Notes

These are your operating manuals for the two main workflows. Read them when doing that work.

**`Claude - How to Process Daily Notes.md`**
The full playbook for daily digests: extract people, ask clarifying questions, update project arcs, detect patterns (3+ occurrences → create vault note), generate next-day todo, score social activity (0–5), update Now.md and Dashboard.

**`Claude - How to Parse ChatGPT HTML Chats.md`**
How to turn exported ChatGPT HTML files into vault notes — category/type assignment, structure, where to save, how to archive the source after processing.

---

## Project Notes — Arcs and Timelines

Physical project notes use a structured arc system. Don't flatten projects into a bullet list.

**Arcs** are named threads within a project. Each has a paragraph narrative (enough to reconstruct what happened without re-reading daily notes) followed by dated bullets.

Arc categories: `Research`, `Design`, `Implementation`, `Testing`, `Review`, `Deployment`, `Communication: <Team>`, `Blocker: <Name>`, `Maintenance`

**Timeline** at the bottom stitches the arcs together chronologically.

When something happens in a daily note that touches a project:
- Find the relevant arc and add a dated bullet
- Update the arc narrative if the situation changed meaningfully
- Add a line to the Timeline referencing the arc
- Update `## 🚦 Current State`

---

## Sprint Tracking

Work sprints are tracked in `_Index/Now.md` frontmatter:
```yaml
sprint_name: Sprint Name
sprint_start: YYYY-MM-DD
sprint_end: YYYY-MM-DD
```

Ticket states: 📋 todo · 🔨 wip · 👀 review · 🚫 blocked · 🚀 deploy · ✅ done

Carry-over rules:
- ✅ done → never carries
- 🚫 blocked → carries to Blocked section, never counts as friction
- 🔨 wip / 👀 review / 🚀 deploy → always carries
- 📋 todo → carries normally; 3+ days unstarted → add `#friction` and force Kill / Shrink / Schedule / Diagnose

Sprint end: write sprint summary to project notes, generate new first-day todo with sprint transition header, update Now.md sprint block.

---

## The Sync Loop

```
User writes on mobile (Obsidian Git) → pushes to GitHub
User writes on desktop (Obsidian Git) → pushes to GitHub
CCR agent wakes every hour → runs scripts → checks git diff gate → digests only if user wrote something → pushes back
Manual Claude Code session → pulls → edits → pushes
```

**Multiple writers, one branch (`main`), no coordination lock** — conflicts are prevented by pull-rebase discipline on every writer.

---

## Git Operations — Required Practice

Every manual Claude Code session MUST follow this sequence or risk divergence.

### Before starting work

```bash
cd "/path/to/your/vault"
git pull --rebase
```

Always. Even if you just opened the session.

### Committing

Stage specific files — never `git add -A` blindly:

```bash
git add path/to/file.md path/to/other.md
git commit -m "vault: <type> — short description"
```

**Commit message conventions:**

| Prefix | When to use |
|---|---|
| `vault: manual` | Structural changes, new features, system updates |
| `vault: chat` | ChatGPT HTML chat processing |
| `vault: daily` | Manual daily note digest |
| `vault: auto YYYY-MM-DD HH:MM` | CCR agent (auto-generated) |

### Pushing

```bash
git push
```

If rejected:

```bash
git pull --rebase
git push
```

If you have staged but uncommitted changes when you need to pull:

```bash
git stash
git pull --rebase
git stash pop
git add <files>
git commit -m "..."
git push
```

### Never do

- `git push --force` — will overwrite other writers' commits
- `git merge` — always rebase; merge commits pollute the log
- `git add -A` without checking `git status` first

### Recurring hazard: `https:` directory

Mobile Obsidian Git occasionally runs `git clone https://...` inside the vault, creating a literal `https:` directory. This breaks rebases. If you see it:

```bash
rm -rf "/path/to/vault/https:"
# If rebase is stuck:
git rebase --skip
```

The `.gitignore` has `https:` but mobile may keep recreating it. Check Obsidian Git mobile plugin settings for an incorrect remote URL.

---

## Scripts

Python utilities in `scripts/` at vault root. Run from vault root (`python3 scripts/<name>.py`).

| Script | What it does |
|---|---|
| `check-changes.py` | Inspects git log for user commits since last `vault: auto`. Outputs `SKIP` or `PROCESS\n<diff>`. |
| `carry-forward-todos.py` | Copies unchecked `[ ]` items from yesterday's todo to today. Auto-tags `#friction` at 3+ appearances. |
| `stamp-frontmatter.py` | Fills `YYYY-MM-DD` placeholders in today's daily note. Stamps `last_digest` in `_Index/Now.md`. |
| `update-sprint-header.py` | Reads sprint fields from Now.md frontmatter and updates "N days left" in today's todo. |
| `update-dashboard.py` | Updates Dashboard `updated:` date and Today section links. |
| `bookmark-todo.py` | Swaps `.obsidian/bookmarks.json` to point to today's todo. |

### Now.md frontmatter — sprint fields required

`update-sprint-header.py` reads:
```yaml
sprint_name: Sprint Name
sprint_start: YYYY-MM-DD
sprint_end: YYYY-MM-DD
```
Update these at the start of each sprint. If you don't use sprints, leave them blank and the script will no-op.

---

## Friction System

`#friction` is a tag used in the `## 🧠 Mind` section of daily notes to flag things avoided, procrastinated on, or felt resistance toward.

**`_Index/Friction Log.md`** — full history of all `#friction` lines across all daily notes, displayed as a date + item table via DataviewJS.

**Dashboard** has a `🧱 Friction (Last 14 Days)` section using the same pattern, limited to last 14 days.

---

## Key Index Files — Keep These Accurate

**`_Index/Now.md`** — most important file in the vault. Updated every digest. If it's wrong, every session starts disoriented.

**`_Index/Dashboard.md`** — visual overview. Contains heatmap, progress bars, project status table, upcoming events.

**`_Index/Notes.md`** — index of all Fact notes. Add a line when a new Fact note is created.

**`_Index/Ephemeral - Active.md`** — list of active ephemeral notes. Update when ephemerals are created, resolved, or go dormant.

**`_Index/Open Questions.md`** — async queue of clarifying questions flagged during CCR digests. In a manual session, process answered questions and remove resolved items.

**`_Index/Friction Log.md`** — DataviewJS query, no manual maintenance needed.

---

## Progress Bars (Advanced Progress Bars plugin)

Used in Dashboard and Now.md. Syntax in `apb` code blocks:

```apb
[[group]] Group Label
Title: value/total
```

```apb
[[group]] Countdown Label
Title: 2026-01-01||2026-12-31
```

Date bars auto-advance daily with no maintenance. Numeric bars need manual value updates.

---

## Social Tracker

Every daily note has `social: 0–5` in its frontmatter. The digest agent sets this during processing. The heatmap in Dashboard and `Life/Physical/Social Tracker.md` reads from this field via DataviewJS.

Scoring: 0 = alone, 1 = household only, 2 = online interaction, 3 = in-person work/activity context, 4 = friends/family in person, 5 = big social day.

---

## What NOT to Do

- **Don't rewrite daily notes** — they're raw logs, leave them as-is
- **Don't create notes automatically from a single mention** — ask first or look for a pattern
- **Don't pad Now.md with events** — that's what daily notes are for; Now.md is state, not log
- **Don't add features or abstractions beyond what was asked** — this is a personal system, not a product
- **Don't duplicate information** — one line + a link is almost always better than copying content
- **Don't ask more than ~5 questions at once** — prioritize the most important unknowns

---

## Public Template Repo

`github.com/YOUR_USERNAME/obsidian-vault` — the repo you cloned this from. Contains all templates, `_Index/` stubs, `scripts/`, a sample daily note, README, AGENTS.md, and OBSIDIAN_SETUP.md.

---

## When Something Is Unclear

Check these in order:
1. `_Index/Now.md` — current state of everything
2. The relevant project/ephemeral/person note
3. `Claude - How to Process Daily Notes.md` — if it's about the digest workflow

If it's still unclear, ask. Keep the question list short.
