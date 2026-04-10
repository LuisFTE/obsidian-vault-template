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

There are no `Physical/`, `Ephemeral/`, or `Fact/` subfolders anywhere in the vault. Those types were eliminated. Notes live directly in their domain folder or inside arc folders.

```
_Index/          — Dashboard, Now, Friction Log, indexes (entry points)
_Templates/      — Note templates (daily, todo, entity, timeline, arc, memory, media, place)
Daily/
  Life/Notes/    — Daily life logs (YYYY-MM-DD.md)
  Todo/          — Combined work+life todos (YYYY-MM-DD.md)
[Root entity].md — Root entity (links to all domain entities)
Career/
  Career.md      — Entity
  [Company]/     — Entity subfolder for each employer
    [Company].md
    [Project]/   — Arc folder
  [Exit Arc]/    — Arc folder for job search / career transitions
  People/
Finance/
  Finance.md     — Entity
  [Financial arc folders]
Life/
  Life.md        — Entity
  [Arc folders for relationships, health, etc.]
  People/
Learning/
  Learning.md    — Entity
  [Reference notes flat]
Media/
  Media.md       — Entity
  People/        — Public creators only (NOT personal contacts)
  Channels/
Projects/
  Projects.md    — Entity
  [Project arc folders]/
Cooking/         — Flat; reference notes
Music/           — Flat; reference notes
Tools/           — Flat; reference notes
Places/          — Place notes
Scratchpad/
  Archived/
scripts/
```

**Arc-as-folder structure** — every arc is a folder from creation, even with zero memories:

```
Life/
  Relationship with Partner/     ← timeline folder
    Relationship with Partner.md ← type: timeline
    Conflict Arc/                ← sub-arc folder
      Conflict Arc.md            ← type: arc
      Memory - Specific Event.md ← type: memory (when added)
Career/Company/
  Big Project/                   ← arc folder
    Big Project.md               ← type: arc
```

### Note Types

| Type | Location | When to use |
|---|---|---|
| `entity` | Domain root (`Career/Career.md`, root entity) | Domain root or named entity; top of the graph |
| `timeline` | Inside domain or arc folder | Relationship or project timeline; owns arcs |
| `arc` | Inside its own arc folder | Named thread; always a folder from creation |
| `memory` | Inside its parent arc folder | Atomic event; links to People + Places |
| `person` | `*/People/` | One note per person — identity record |
| `reference` | Flat in domain folder | Static note; recipe, toolchain, baseline |
| `place` | `Places/` | Physical location |
| `daily` | `Daily/Notes/` | Day log |
| `todo` | `Daily/Todo/` | Task list |
| `media` | `Media/` | Consumed media — photo, movie, album, video |

**Eliminated types:** `physical`, `ephemeral`, `fact` — these no longer exist. Notes that were `physical` are now `arc`. Notes that were `fact` are now `reference`. Ephemeral desires live in the `## Ephemerals` section of their entity note, not as separate files.

### Ephemeral Lifecycle

Ephemeral desires live as entries in the `## Ephemerals` section of their parent entity note — not as separate files. Format:

```markdown
## Ephemerals

### Learn a new skill
- **status:** open
- **first_seen:** YYYY-MM
- **context:** One line — what sparked it, what's blocking it.
```

**Statuses:** `open` → `active` → graduates to arc (entry deleted) | `paused` | `abandoned`

When a desire gets real traction (dated action, research, decision) — extract it to its own arc folder and remove the entry from the Ephemerals section. Add it to `links:` in the entity note.

### Frontmatter

Every note has YAML frontmatter:
```yaml
---
title: Note Title
category: life | career | finance | learning | media | etc.
type: entity | timeline | arc | memory | reference | person | etc.
tags: [relevant, tags]
summary: "One-line description used by retrieval agent to decide relevance without reading body"
links:
  - target: "[[Path/To/Note]]"
    weight: 8          # 1–10; relevance of target to THIS note
    type: parent | child | related | peer
    reason: "Why this link exists — pre-compressed for retrieval agent"
    last_referenced: YYYY-MM-DD
    frequency: 1
---
```

**Type-specific graph fields:**

| Type | Extra fields |
|---|---|
| entity | `key_topics: []`, `priority_arcs: []` |
| timeline | `entity: "[[]]"`, `triggers: []`, `key_memories: []` |
| arc | `parent: "[[]]"`, `status: active\|resolved`, `started: YYYY-MM`, `triggers: []`, `key_memories: []` |
| memory | `arc: "[[]]"`, `topics: []` |

**Weight semantics:** 9–10 = essential, 7–8 = highly relevant, 5–6 = related, 1–4 = loosely connected.

---

## Knowledge Graph Architecture

The vault is a **weighted directional knowledge graph**. Every note is a node. Every link in the `links:` frontmatter array is a directed edge. The source note holds the weights.

### Graph hierarchy

```
Root entity
  └── Career entity       weight: 9
        └── Company entity
              └── Project arc
                    └── Memory
  └── Life entity         weight: 9
        └── Relationship timeline
              └── Arc
                    └── Memory
  └── Finance, Learning, Media, Projects entities
```

### Retrieval model

A retrieval agent navigating this graph:
1. Starts at the root entity closest to the question
2. Reads `summary` fields to decide which links to follow (without opening the file)
3. Follows high-weight links first
4. Opens a file only when its `reason` field confirms relevance

`summary` and `reason` fields must be accurate. One bad summary causes the agent to skip or over-follow a branch.

### Templates (all in `_Templates/`)

| Template | type | Use for |
|---|---|---|
| `Entity.md` | entity | Domain roots, company entities |
| `Timeline.md` | timeline | Relationship or project timelines |
| `Arc.md` | arc | Named threads; always a folder |
| `Memory.md` | memory | Atomic events inside arc folders |
| `Work Project.md` | arc | Work project arc (with sprint tracking) |
| `Personal Project.md` | arc | Personal project arc |

---

## Media Notes

Media notes live in `Media/` — photos, movies, shows, YouTube videos, albums.

### Media Templates

| Template | File | Key Fields |
|---|---|---|
| Photo | `Media - Photo.md` | `artist:`, `subject:`, `location:`, `with:` |
| Movie | `Media - Movie.md` | `director:`, `cast:`, `with:` |
| Show | `Media - Show.md` | `director:`, `cast:`, `with:` |
| YouTube | `Media - YouTube.md` | `channel: "[[Media/Channels/]]"`, `with:` |
| Album | `Media - Album.md` | `artist: "[[Media/People/]]"`, `with:` |

### Tiered Linking — Critical Rule

**Do not wikilink every person in a media note.**

- **Wikilink** only for the central person (artist, director, subject, creator)
- **Plain text** for incidental presence — `with: Person A, Person B`

The `with:` field is always plain text.

### Media/People vs Life/People

- `Media/People/` — public creators: artists, directors, musicians, filmmakers
- `Life/People/` — personal contacts: friends, family, coworkers

Never cross these.

### Person Notes — Arc Model

Personal contact notes use sections: `## Who`, `## Context`, `## Notes` (timestamped observations), `## Linked Notes`.

For people with significant history, the **relationship gets its own timeline note**:

```
Life/
  Relationship with Person/        ← timeline folder
    Relationship with Person.md    ← type: timeline; entity: [[Life/People/Person]]
    Key Arc/                       ← arc folder
      Key Arc.md                   ← type: arc
      Memory - Event.md            ← type: memory
```

For people with minimal history, keep everything inline in the person note.

### Place Notes

Place notes live in `Places/`. Key fields:
- `part_of: "[[Places/Parent]]"` — geographic hierarchy
- `subtype:` — e.g. `transit`, `neighborhood`, `city`

---

## The Two Instruction Notes

**`Claude - How to Process Daily Notes.md`**
Full playbook for daily digests: extract people, update arcs, detect patterns, generate todos, score social activity, update Now.md and Dashboard.

**`Claude - How to Parse ChatGPT HTML Chats.md`**
How to turn exported ChatGPT HTML files into vault notes.

---

## Arc Notes — Structure

Every arc is a folder. The arc note has a paragraph narrative followed by dated bullets.

Arc narrative categories: `Research`, `Design`, `Implementation`, `Testing`, `Review`, `Deployment`, `Communication: <Team>`, `Blocker: <Name>`, `Maintenance`

**Timeline** at the bottom of the parent note stitches arcs chronologically.

When something happens in a daily note that touches an arc:
- Add a dated bullet to the arc note
- Update the arc narrative if the situation changed
- Add a line to the parent's Timeline
- Update `## 🚦 Current State`
- Update `last_referenced` and `frequency` in relevant `links:` fields

---

## Sprint Tracking

Work runs in 2-week sprints. Ticket states: 📋 todo · 🔨 wip · 👀 review · 🚫 blocked · 🚀 deploy · ✅ done

Carry-over rules:
- ✅ done → never carries
- 🚫 blocked → carries to Blocked section, never counts as friction
- 🔨 wip / 👀 review / 🚀 deploy → always carries
- 📋 todo → carries normally; 3+ days unstarted → add `#friction` and force Kill / Shrink / Schedule / Diagnose

Sprint end: write sprint summary to arc notes, generate new todo with sprint transition header, update Now.md sprint block.

---

## The Sync Loop

```
User writes on iPhone (Obsidian Git) → pushes to GitHub
User writes on desktop (Obsidian Git) → pushes to GitHub
CCR agent wakes every hour → runs scripts → checks git diff gate → digests if user wrote → pushes back
Manual Claude Code session → pulls → edits → pushes
```

**Four writers, one branch (`main`), no coordination lock** — conflicts are prevented by pull-rebase discipline on every writer.

---

## Git Operations — Required Practice

Every manual Claude Code session MUST follow this sequence.

### Before starting work

```bash
cd "/path/to/vault"
git pull --rebase
```

### Committing

Stage specific files — never `git add -A` blindly:

```bash
git add path/to/file.md
git commit -m "vault: <type> — short description"
```

| Prefix | When to use |
|---|---|
| `vault: manual` | Structural changes, new features, system updates |
| `vault: chat` | ChatGPT HTML chat processing |
| `vault: daily` | Manual daily note digest |
| `vault: auto YYYY-MM-DD HH:MM` | CCR agent (auto-generated) |

### Pushing

```bash
git push
# If rejected:
git pull --rebase && git push
```

### Never do

- `git push --force`
- `git merge` — always rebase
- `git add -A` without checking `git status` first

---

## Scripts

Python utilities in `scripts/` at vault root.

| Script | What it does |
|---|---|
| `check-changes.py` | Gates Claude invocation — outputs `SKIP` or `PROCESS\n<diff>` |
| `carry-forward-todos.py` | Copies unchecked items from yesterday's todo; auto-tags `#friction` after 3+ days |
| `stamp-frontmatter.py` | Fills `YYYY-MM-DD` placeholders in today's daily note |
| `update-sprint-header.py` | Updates sprint header in today's todo |
| `update-dashboard.py` | Updates Dashboard date and Today links |
| `bookmark-todo.py` | Swaps bookmarks to point to today's todo |

`update-sprint-header.py` reads these fields from `_Index/Now.md`:
```yaml
sprint_name: Sprint Name
sprint_start: YYYY-MM-DD
sprint_end: YYYY-MM-DD
```

---

## Friction System

`#friction` tags things avoided, procrastinated on, or resisted.

**Carry-forward rule:** Any todo item carried 3+ days unstarted → add `#friction`, force Kill / Shrink / Schedule / Diagnose.

**`_Index/Friction Log.md`** — full history via DataviewJS.

---

## Key Index Files

**`_Index/Now.md`** — most important file. Updated every digest. Edit only what changed.

**`_Index/Dashboard.md`** — visual overview. Update Today links and project statuses each digest.

**`_Index/Notes.md`** — index of reference notes. Add a line when a new reference note is created.

**`_Index/Open Questions.md`** — async queue of clarifying questions from CCR digests.

**`_Index/Friction Log.md`** — DataviewJS query; no manual maintenance needed.

---

## Progress Bars (Advanced Progress Bars plugin)

```apb
[[group]] Group Label
Title: value/total
```

```apb
[[group]] Countdown Label
Title: 2026-01-01||2026-12-31
```

---

## Social Tracker

Every daily note has `social: 0–5` in frontmatter. The digest agent sets this. The heatmap in Dashboard reads from this field via DataviewJS.

Scoring: 0 = alone, 1 = household only, 2 = online, 3 = out in the world, 4 = friends/family in person, 5 = big social day.

---

## What NOT to Do

- **Don't rewrite daily notes** — they're raw logs
- **Don't create notes from a single mention** — look for a pattern first
- **Don't pad Now.md with events** — that's what daily notes are for; Now.md is state, not log
- **Don't add features beyond what was asked**
- **Don't duplicate information** — one line + a link beats copying content
- **Don't ask more than ~5 questions at once**

---

## Obsidian Git Plugin Config

Settings deliberately changed in `.obsidian/plugins/obsidian-git/data.json`:
- `disablePopupsForNoChanges: true` — suppresses "nothing to commit" notification spam
- `changesBeforeAutoBackup: 1` — only auto-backup when there's at least 1 change

---

## When Something Is Unclear

Check these in order:
1. `_Index/Now.md` — current state
2. The relevant arc or person note
3. `Claude - How to Process Daily Notes.md` — digest workflow
4. `Projects/Second Brain/Second Brain.md` — system design decisions

If still unclear, ask the user. Keep the question list short.
