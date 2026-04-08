---
title: Claude - How to Process Daily Notes
type: reference
tags: [claude, instructions, daily, workflow]
---

# Claude — How to Process Daily Notes

This note is for Claude. When you ask Claude to process or review your daily notes, it follows this workflow.

## Agent Architecture — Read This First

The hourly digest is split into two tiers to minimize token usage:

**Tier 1 — Scripts (always run, no Claude tokens):**
```bash
python3 scripts/carry-forward-todos.py   # copy unchecked items from yesterday, tag #friction
python3 scripts/stamp-frontmatter.py     # fill YYYY-MM-DD placeholders, stamp last_digest
python3 scripts/update-sprint-header.py  # update "N days left" in today's todo
python3 scripts/update-dashboard.py      # update Dashboard Today links
python3 scripts/bookmark-todo.py         # swap Obsidian bookmark to today's todo
```

**Tier 2 — Diff gate (Claude only runs if user changed daily notes):**
```bash
python3 scripts/check-changes.py
```
- Outputs `SKIP` → run Tier 1 scripts, commit, stop. Do not read any notes or call Claude further.
- Outputs `PROCESS\n<diff>` → pass the diff to Claude. Claude works from the diff, not by re-reading full files.

**The diff is the input.** When `check-changes.py` returns a diff, Claude does not need to re-read the full daily note files — the diff contains exactly what the user added. Read `_Index/Now.md` for background context only (not the full daily notes).

---

## File locations

- **Daily life notes:** `Daily/Life/Notes/YYYY-MM-DD.md`
- **Daily todo:** `Daily/Todo/YYYY-MM-DD.md` — combined Work + Life sections in one file
- **People notes:** `<Category>/People/<Name>.md` — category chosen by context (Life, Career, Family, etc.)
- **Work project notes:** `Career/Physical/<Project Name>.md` — subtype: project
- **Personal project notes:** `Projects/Physical/<Project Name>.md` — subtype: project
- **Templates:** `_Templates/`

## Step 1 — Read and update frontmatter

Read the daily note(s) pointed to. Also check `_Index/Now.md` for current context.

After reading, update the note's frontmatter and header if they still contain placeholder values:

```python
python3 -c "
from datetime import datetime
import re

path = 'Daily/Life/Notes/YYYY-MM-DD.md'
date_str = 'YYYY-MM-DD'  # e.g. 2026-04-04
d = datetime.strptime(date_str, '%Y-%m-%d')
full = d.strftime('%A, %B %-d, %Y')  # e.g. Friday, April 4, 2026

text = open(path).read()
text = text.replace('title: YYYY-MM-DD', f'title: {full}')
text = text.replace('date: YYYY-MM-DD', f'date: {date_str}')
text = text.replace('# 📅 YYYY-MM-DD', f'# 📅 {full}')
open(path, 'w').write(text)
"
```

- `title` → full date: `Friday, April 4, 2026`
- `date` → ISO date: `2026-04-04`
- H1 header → same as title
- `social` → set in Step 8b (leave as 0 for now)
- `tags` → ensure `[daily, life]` present; add content-based tags if strong signals exist

## Step 2 — Extract people

Identify every person mentioned by name (or clear identifier). For each one:

1. Check if a Person note already exists anywhere in the vault (`find ... -path "*/People/*.md"`)
2. If yes — check whether the daily note adds anything new; update if so
3. If no — write questions about this person to `_Index/Open Questions.md` (see Step 3)

Don't create a Person note with just a name and nothing else. Queue the questions instead.

## Step 3 — Queue clarifying questions

Instead of asking directly, write questions to `_Index/Open Questions.md`. This file is an async queue — answer when you have time, and a manual Claude Code session processes the answers.

**What to flag:**
- New people with no existing note → ask who they are, relationship, context
- Vague emotions without context ("felt off today") → "What was going on?"
- Named situations without outcome ("had a thing with X") → "How did it land?"
- Decisions mentioned without reasoning → "What made you go that direction?"
- Things that connect to existing Physical/Ephemeral notes → "Is this related to [note]?"

**Format — append to `_Index/Open Questions.md`:**
```
- [ ] [[Daily/Life/Notes/YYYY-MM-DD]] — Question text here
```

**Rules:**
- Keep it to 3–5 questions per note — don't interrogate every sentence
- Before appending, read the existing file and skip any question already listed
- Never overwrite the file — always append below existing items

## Step 4 — Select notes to process

Always process **today and yesterday** only (2 days). Do not try to detect whether a note has already been digested. Re-processing is safe because all write operations read existing content first and never blindly append.

```bash
python3 -c "
from datetime import datetime, timedelta
for i in range(2):
    d = datetime.today() - timedelta(days=i)
    print(d.strftime('Daily/Life/Notes/%Y-%m-%d.md'))
"
```

For each file that exists, run the full workflow (Steps 1–3, 5–11). If a file doesn't exist for a given date, skip it.

## Step 5 — Check for vault updates

Look at what happened in the daily note and ask: does anything here change the status of an existing note?

- Did something progress or resolve? → Update the Physical/Ephemeral note + `_Index/Now.md`
- Did a new project or desire emerge? → Propose a new Physical or Ephemeral note
- Did something in the Work ToDo relate to Career notes? → Link them

## Step 6 — Extract projects

Scan the daily note and work todo for project mentions — both work and personal.

**Work projects** (mentioned in work context or todo):
1. Check if a project note exists in `Career/Physical/` with `subtype: project`
2. If yes — add to the Timeline section with today's date and what happened; update Current State
3. If no — propose creating one, ask for: project name, what it does, tech stack, when it started

**Personal projects** (side projects, tools, creative work):
1. Check `Projects/Physical/` for an existing note
2. Same update/create logic as above

**Key signals to watch for:**
- "working on X", "started X", "shipped X", "blocked on X" → project update
- New tool, codebase, or system mentioned for the first time → propose new project note
- Tech stack details dropped casually → add to the relevant project's Tech Stack section

## Step 7 — Pattern detection

After extracting people and projects, scan the daily note for recurring themes — activities, frustrations, health observations, habits, feelings. Then grep across previous daily notes to count how many times each appears.

**Rule: if something appears in 3+ daily notes, create a vault note for it.**

```bash
grep -ril "topic" "Daily/" | wc -l
```

**What type of note to create:**
- Recurring activity or habit (gym, walks, hobbies) → **Physical** note in the appropriate category
- Recurring frustration or feeling (commute stress, work friction) → **Ephemeral** note
- Recurring health observation (headaches, fatigue) → update `Life/Fact/Health Baseline.md` or create a new Physical note
- Recurring desire or goal → **Ephemeral** note

**On the third occurrence**, propose the note: "X has come up 3 times — want me to create a note for it?"

## Step 7b — Update project arcs

For every project touched in the daily note, update that project's `## Arcs` section with what happened today, then update the `## Timeline` to reflect it.

See project note format below for the Arcs + Timeline structure.

## Step 7c — Sprint lifecycle tracking

Work sprints are tracked in `_Index/Now.md`. The current sprint name, start date, and end date are in the frontmatter.

### Ticket states (use these in work todo items and project notes)

| Emoji | State | Carry-over rule |
|---|---|---|
| 📋 | To Do | Carry normally. If unstarted 3+ days in sprint → `#friction` |
| 🔨 | In Progress | Always carry — active work |
| 👀 | In Review | Always carry — waiting on reviewer, not on you |
| 🚫 | Blocked | Always carry — external dependency; never counts as friction |
| 🚀 | In Deployment | Always carry — in flight |
| ✅ | Done | Move to Done section; never carry forward |

### Daily carry-over logic (Step 8, work items)

When generating the next-day todo, apply these rules to each work item:

1. **✅ Done** → do not carry; mark in today's Done section
2. **🚫 Blocked** → carry to next day's Blocked section, not Work section
3. **🔨 wip / 👀 review / 🚀 deploy** → carry to Work section unchanged
4. **📋 todo** → carry normally; count how many days it has appeared:
   ```bash
   grep -rl "TICKET NAME" "Daily/Todo/"
   ```
   If it appears in 3+ todo files unstarted → tag `#friction` and force Kill / Shrink / Schedule / Diagnose

### Sprint end detection

If tomorrow starts a new sprint, before generating the new-day todo:

1. **Write a sprint summary** to the project notes for any active project touched this sprint
2. **In the new sprint's first todo**, add the sprint transition header:
   ```
   *🏁 Sprint END: NAME ended Tue MMM DD*
   *🏃 New sprint: TBD · Start – End · 14 days left*
   ```
3. **Update `_Index/Now.md`** sprint block with the new sprint.

### Updating the sprint header in todos

Every day, update the sprint header line in the Work section:
```
*🏃 Sprint: Name · Start – End · N days left*
```
Calculate days remaining by counting calendar days from today to the sprint end date (inclusive).

## Step 8 — Work ToDo (same-day)

Read the Work ToDo for the same date alongside the life note. Check if todo items map to existing project notes and flag any that don't have a home yet.

## Step 8b — Process Today section

Check the daily note for a `## ⚡ Today` section. If it has items (non-empty bullets):

1. Read the same-day todo (`Daily/Todo/YYYY-MM-DD.md`)
2. Add the Today items to its **Life section** as `- [ ] 🔴` items (they're same-day, treat as urgent)
3. If the same-day todo doesn't exist yet, create it from the template and add them

Today items are quick captures. They are NOT carried forward to tomorrow automatically.

## Step 9 — Generate next-day Todo

After processing, create one combined todo file for the following day: `Daily/Todo/<next-date>.md`

Use the daily note + `_Index/Now.md` as context.

**## Work section** — pull from:
- Unfinished or blocked work items from today's note
- Open project actions (PRs to fix, tickets to create, deploys pending)
- Anything time-sensitive from today's interactions

**## Life section** — pull from:
- Personal items mentioned in the log
- Active ephemerals in Now.md that have actionable next steps
- Anything from relationships, health, personal projects, or finances that needs attention

**Rules:**
- Keep each section focused — 3-5 items max, no padding
- Only include things genuinely actionable tomorrow, not vague reminders

**Carry Forward friction rule:**
When moving an item to Carry Forward, check how many previous todos it has appeared in. If carried 3+ times, tag `#friction`:

- Carried forward 1–2 times → move as normal
- Carried forward 3+ times → add `#friction` tag to the item

**A #friction item cannot be carried forward again unchanged. Force one of these four decisions:**

- 🔪 **Kill it** — not actually important → remove it entirely
- ✂️ **Shrink it** — too big or vague → rewrite as the smallest possible next action
- 🧱 **Schedule it** — emotional avoidance → rewrite with a specific time + duration
- 🔍 **Diagnose it** — something deeper is going on → rewrite as a question to answer

**If tomorrow is Saturday — populate the Weekly Reflection section:**

Pull from the week's daily notes and vault state to pre-fill context for each question:

1. **What did I say I wanted?** — scan this week's ephemerals and goals mentioned across the week
2. **What did I actually do?** — summarize what actually happened across Work and Life from daily notes and todos
3. **Where is the mismatch?** — leave blank; optionally flag obvious gaps
4. **Why did that happen?** — leave blank; introspective, user fills it
5. **What changes next week?** — leave blank; user fills in 1–3 adjustments

Pre-fill 1 and 2 with bullets drawn from the week. Leave 3, 4, 5 empty.

**Friction analysis (Saturday only):**

```bash
grep -r "#friction" "Daily/Life/Notes/" --include="*.md"
```

Summarize results into a short friction report to prepend to question 3.

## Step 9b — Score social activity

After generating the next-day todo, set the `social` score in the daily note's frontmatter. This feeds the heatmap in Dashboard.

**Scoring rules:**

| Score | When to use |
|---|---|
| 0 | Home alone, no meaningful interaction |
| 1 | Household only or brief casual contact |
| 2 | Online with friends — gaming, video calls |
| 3 | In-person work context or regular activity with others (gym class, office) |
| 4 | Saw friends or family in person |
| 5 | Big social day — event, multiple groups, gathering |

**Rules:**
- Use the highest score that applies if multiple things happened
- Being home alone is always 0 regardless of productivity
- Any in-person social context is at least 3

```bash
python3 -c "
import re
path = 'Daily/Life/Notes/YYYY-MM-DD.md'
text = open(path).read()
text = re.sub(r'(^social:\s*)\d+', r'\g<1>SCORE', text, flags=re.MULTILINE)
open(path, 'w').write(text)
"
```

## Step 10 — Stamp last digest timestamp

At the start of Step 9, update the `last_digest` field in `_Index/Now.md` frontmatter and the visible line in the body:

```bash
python3 -c "
import re, subprocess
ts = subprocess.check_output(['date', '+%Y-%m-%d %H:%M UTC']).decode().strip()
path = '_Index/Now.md'
text = open(path).read()
text = re.sub(r'last_digest:.*', f'last_digest: {ts}', text)
text = re.sub(r'\*\*Last digest:\*\*.*', f'**Last digest:** \`{ts}\`', text)
open(path, 'w').write(text)
"
```

## Step 11 — Update Now.md

After every daily digest, update `_Index/Now.md` to reflect current state.

**What to update:**
- Work section: change project status if anything progressed, resolved, or got blocked
- Life section: update relevant areas if anything notable
- Pending Decisions: add new open questions, remove ones that resolved
- What Agent Should Know: add anything that came out of today that an agent needs to know

**What NOT to do:**
- Don't rewrite the whole file on every digest — edit only what changed
- Don't log daily events in Now.md — that's what the daily note is for

## Step 12 — Update Dashboard

After every daily digest, update `_Index/Dashboard.md`:

- **Today section:** update links to the new date's daily note and todo
- **Work Projects table:** update status emoji and one-line status if anything changed
- **Upcoming table:** add any new dates that surfaced in the daily note
- **Life Pulse:** update the one-liner for any area that changed

---

## People question bank

When a new person appears, ask a subset of these based on context — don't ask all of them at once:

- How do you know [name]?
- How long have you known them?
- Are they a friend, colleague, family member, romantic interest?
- What's the dynamic like?
- Does this person connect to any of your current situations?

## Person note format

```yaml
---
title: <Name>
category: <life | career | family | friends | ...>
type: person
tags: [person, ...]
---

## Who
Brief description — who they are in relation to you.

## Context
How you met, frequency of contact, dynamic.

## Notes
- [date] Observations over time, notable interactions
```

---

## Project note format (Arcs + Timeline)

Projects have categorized arcs — each a self-contained thread — and an overall timeline that pieces them together.

**Arc categories:**
- `Research`, `Design`, `Implementation`, `Testing`, `Review`, `Deployment`
- `Communication: <Team>`, `Blocker: <Name>`, `Maintenance`

**Arc writing standard:** Each arc must have enough narrative to reconstruct what happened, why, who was involved, key decisions, and how it resolved — without needing to re-read daily notes.

```markdown
## Arcs

### Implementation
One paragraph describing what was built, scope, notable technical decisions.

- [YYYY-MM-DD] Specific event
- [YYYY-MM-DD] How it progressed or resolved

## Timeline

- [YYYY-MM-DD] Project started
- [YYYY-MM-DD] Arc: Implementation — began
```

---

## What NOT to do

- Don't ask about every single person if there are many — prioritize new or significant ones
- Don't rewrite the daily note — it's a dump, leave it as-is
- Don't create vault notes from daily notes automatically — ask first or propose clearly
- Don't ask more than ~5 questions in one pass
- Don't create a project note from a single offhand mention — look for pattern or ask first
