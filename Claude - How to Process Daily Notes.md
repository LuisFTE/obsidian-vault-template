---
title: Claude - How to Process Daily Notes
type: reference
tags: [claude, instructions, daily, workflow]
---

# Claude — How to Process Daily Notes

This note is for Claude. When Luis asks you to process or review his daily notes, follow this workflow.

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

Read the daily note(s) Luis points you to. Also check `_Index/Now.md` for current context.

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
- `tags` → ensure `[daily, life]` present; add content-based tags if strong signals exist (e.g. `boxing` if boxing mentioned, `travel` if trip mentioned)

## Step 2 — Extract people

Identify every person mentioned by name (or clear identifier). For each one:

1. Check if a Person note already exists anywhere in the vault (`find ... -path "*/People/*.md"`)
2. If yes — check whether the daily note adds anything new; update if so
3. If no — write questions about this person to `_Index/Open Questions.md` (see Step 3)

Don't create a Person note with just a name and nothing else. Queue the questions instead.

## Step 3 — Queue clarifying questions

Instead of asking Luis directly, write questions to `_Index/Open Questions.md`. This file is his async queue — he answers when he has time, and a manual Claude Code session processes the answers.

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
for i in range(5):
    d = datetime.today() - timedelta(days=i)
    print(d.strftime('Daily/Life/Notes/%Y-%m-%d.md'))
"
```

For each file that exists, run the full workflow (Steps 1–3, 5–11). If a file doesn't exist for a given date, skip it.

## Step 4b — Maintain the knowledge graph

The vault uses a 3-layer progressive retrieval model. Every time you create or update a note, maintain these graph fields so an agent can navigate efficiently without reading everything.

---

### Layer 1 — Entity notes (Person, Place)

```yaml
summary: "One sentence. Core identity + current state. Written for an agent deciding whether to open this note."
key_topics: [relationship, conflict, finances]    # domains this entity matters in
priority_arcs: ["[[Arc Note Title]]"]             # highest-signal arcs, pre-ranked
links:
  - target: "[[Arc or related note]]"
    weight: 9           # 1–3 weak · 4–6 moderate · 7–8 strong · 9–10 critical
    type: conflict      # emotional | conflict | growth | finance | relationship | practical | identity
    reason: "One phrase — why this connection exists. Pre-compressed so an agent doesn't have to open the target to decide relevance."
    last_referenced: YYYY-MM-DD
    frequency: 1        # increment each time this link is traversed
```

**`summary`** — keep under 2 sentences. Update whenever core state changes (relationship status, job status, etc.).
**`key_topics`** — the domains an agent should use to match this entity to a question.
**`priority_arcs`** — the 1–3 arc notes that best represent this entity's active threads. Ranked by importance.
**`reason`** on each link — this is the token optimization. An agent reads `reason` to decide relevance without opening the target.

---

### Layer 2 — Arc notes (Physical notes, relationship threads, project notes)

```yaml
summary: "What this arc is about and where it currently stands."
triggers: [chores, disrespect, money]    # keywords that make this arc relevant to a question
key_memories: ["[[Memory Note]]"]        # the 1–3 memories that best illustrate this arc
links:
  - target: "[[Memory or related arc]]"
    weight: 8
    type: emotional
    reason: "Clearest example of the recurring pattern."
    last_referenced: YYYY-MM-DD
    frequency: 1
```

**`triggers`** — what topics or keywords in a question should route an agent to this arc.
**`key_memories`** — the specific Memory notes that illustrate this arc. The agent loads these, not all memories.

---

### Layer 3 — Memory notes (atomic events)

```yaml
summary: "What happened and why it matters. One sentence."
topics: [conflict, respect, relationship]    # what this memory is about
arc: "[[Parent arc]]"                        # which arc this belongs to
links:
  - target: "[[]]"
    weight: 
    type: 
    reason: ""
    last_referenced: 
    frequency: 1
```

**Keep memories minimal.** The body holds the full detail — the frontmatter is the fast path. `summary` should be enough for an agent to decide if it needs to read further.

---

### Rules for all layers

- **Weights are directional** — A → B at weight 9 does not mean B → A at weight 9
- **`reason` is mandatory on any link weight ≥ 6** — if you can't write a reason, reconsider the link
- **Update `summary` whenever core state changes** — stale summaries break retrieval
- **`last_referenced`** — update when you meaningfully revisit or reference this note
- **`frequency`** — increment when the link is traversed; used for future decay computation
- **Do NOT update graph fields for minor edits** (typo fixes, date stamps)

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
3. vault-importer lives here as an example: `Projects/Physical/vault-importer.md`

**Key signals to watch for:**
- "working on X", "started X", "shipped X", "blocked on X" → project update
- New tool, codebase, or system mentioned for the first time → propose new project note
- Tech stack details dropped casually → add to the relevant project's Tech Stack section

## Step 6b — Act on friction decisions

Scan the Carry Forward section of today's todo for items tagged `#friction-kill`, `#friction-shrink`, `#friction-schedule`, or `#friction-diagnose`. These are items where the user checked a decision box yesterday.

For each:

**#friction-kill** → Remove the item entirely from the todo. Log it as a one-liner in a comment or the Done section: `~~item text~~ — killed`.

**#friction-shrink** → Rewrite the item as the smallest possible next action. Replace the full item text with something completable in 20-30 min. Remove the `#friction-shrink` tag and `#friction` tag. Move to the appropriate Work or Life section.

**#friction-schedule** → Rewrite the item with a time placeholder: `Today HH:MM–HH:MM — item text`. Remove the friction tags. Move to Work or Life section. If you can infer a good time from context (morning task, evening errand), suggest it — otherwise leave `HH:MM` for the user to fill.

**#friction-diagnose** → Rewrite the item as a question: `Why am I avoiding [item]?` Add it to `_Index/Open Questions.md` instead of the todo. Remove from Carry Forward.

After acting on each decision, remove the decision sub-checkboxes from the item.

## Step 7 — Pattern detection

After extracting people and projects, scan the daily note for recurring themes — activities, frustrations, health observations, habits, feelings. Then grep across previous daily notes to count how many times each appears.

**Rule: if something appears in 3+ daily notes, create a vault note for it.**

```bash
grep -ril "boxing" "/mnt/o/Notes/Obsidian Vault/Daily/" | wc -l
```

**What type of note to create:**
- Recurring activity or habit (boxing, gym, walks) → **Physical** note in the appropriate category
- Recurring frustration or feeling (subway anger, work stress, loneliness) → **Ephemeral** note
- Recurring health observation (headaches, fatigue, blood pressure symptoms) → update `Life/Fact/Health Baseline.md` or create a new Physical note
- Recurring desire or goal → **Ephemeral** note

**Exceptions — do NOT create notes for:**
- To-do items or tasks → those belong on the relevant project or todo file
- One-off mentions that happen to repeat without real pattern

**On the third occurrence**, propose the note to Luis with: "Boxing has come up 3 times — want me to create a note for it?"

## Step 7b — Update project arcs

For every project touched in the daily note, update that project's `## Arcs` section with what happened today, then update the `## Timeline` to reflect it.

See project note format below for the Arcs + Timeline structure.

## Step 7c — Sprint lifecycle tracking

Bloomberg sprints run **Wednesday → Tuesday (2 weeks)**. Sprints are named after foods/restaurants (e.g. "Jimmy Johns," "Chipotle"). The current sprint is tracked in `_Index/Now.md`.

### Ticket states (use these in work todo items and project notes)

| Emoji | State | Carry-over rule |
|---|---|---|
| 📋 | To Do | Carry normally. If unstarted 3+ days in sprint → `#friction` |
| 🔨 | In Progress | Always carry — active work |
| 👀 | In Review | Always carry — waiting on reviewer, not on Luis |
| 🚫 | Blocked | Always carry — external dependency, not Luis's fault; never counts as friction |
| 🚀 | In Deployment | Always carry — in flight |
| ✅ | Done | Move to Done section; never carry forward |

### Daily carry-over logic (Step 8, work items)

When generating the next-day todo, apply these rules to each work item:

1. **✅ Done** → do not carry; mark in today's Done section
2. **🚫 Blocked** → carry to next day's Blocked section, not Work section
3. **🔨 wip / 👀 review / 🚀 deploy** → carry to Work section unchanged
4. **📋 todo** → carry normally; count how many days it has appeared:
   ```bash
   grep -rl "TICKET NAME" "/mnt/o/Notes/Obsidian Vault/Daily/Todo/"
   ```
   If it appears in 3+ todo files unstarted → tag `#friction` and force Kill / Shrink / Schedule / Diagnose

### Sprint end detection (Tuesday night digest)

If tomorrow is Wednesday, the sprint has just ended. Before generating the new-day todo:

1. **Write a sprint summary** to the project notes for any active project touched this sprint:
   - Add a row to the `## 📅 Sprint History` table: sprint name, dates, what was delivered, what carried over
   - Update `## 🎫 Jira Tickets` with final states

2. **In the new Wednesday todo**, add the sprint transition header:
   ```
   *🏁 Sprint END: NAME ended Tue MMM DD*
   *🏃 New sprint: TBD (name announced Wed) · Wed MMM DD – Tue MMM DD · 14 days left*
   ```
   Use "TBD" for the new sprint name until Luis writes the daily note and mentions it.

3. **Update `_Index/Now.md`** sprint block with the new sprint (even if name is TBD).

### Updating the sprint header in todos

Every day, update the sprint header line in the Work section:
```
*🏃 Sprint: Jimmy Johns · Wed Mar 29 – Tue Apr 11 · N days left*
```
Calculate days remaining by counting calendar days from today to the sprint end date (inclusive of end date).

## Step 8 — Work ToDo (same-day)

Read the Work ToDo for the same date alongside the life note. Check if todo items map to existing project notes and flag any that don't have a home yet.

## Step 8b — Process Today section

Check the daily note for a `## ⚡ Today` section. If it has items (non-empty bullets):

1. Read the same-day todo (`Daily/Todo/YYYY-MM-DD.md`)
2. Add the Today items to its **Life section** as `- [ ] 🔴` items (they're same-day, treat as urgent)
3. If the same-day todo doesn't exist yet, create it from the template and add them

Today items are quick captures — things Luis remembered mid-day that need doing before the day ends. They are NOT carried forward to tomorrow automatically. If they appear unchecked in tomorrow's digest, treat them as normal unfinished items and apply the carry-forward rules.

## Step 9 — Generate next-day Todo

After processing, create one combined todo file for the following day: `Daily/Todo/<next-date>.md`

Use the daily note + `_Index/Now.md` as context.

**## Work section** — pull from:
- Unfinished or blocked work items from today's note
- Open project actions (PRs to fix, tickets to create, deploys pending)
- Anything time-sensitive or follow-up from today's interactions

**## Life section** — pull from:
- Personal items mentioned in the log
- Active ephemerals in Now.md that have actionable next steps
- Anything from relationships, health, personal projects, or finances that needs attention

**Rules:**
- Keep each section focused — 3-5 items max, no padding
- Only include things genuinely actionable tomorrow, not vague reminders
- Carry Forward section is for items that didn't get done if a same-day todo existed

**Carry Forward friction rule:**
When moving an item to Carry Forward, check how many previous todos it has appeared in (grep across `Daily/Todo/` for the item text). If it has been carried forward more than twice, tag it with `#friction`:

```bash
grep -rl "item text" "/mnt/o/Notes/Obsidian Vault/Daily/Todo/"
```

- Carried forward 1–2 times → move as normal
- Carried forward 3+ times → add `#friction` tag to the item

Example: `- [ ] 🟡 Interview prep #friction`

**A #friction item cannot be carried forward again unchanged. Force one of these four decisions:**

- 🔪 **Kill it** — not actually important → remove it entirely, note it as deleted
- ✂️ **Shrink it** — too big or vague → rewrite as the smallest possible next action (e.g. "Prepare for interviews" → "Do 1 problem, 20 min")
- 🧱 **Schedule it** — emotional avoidance → rewrite with a specific time + duration (e.g. "Today 6:30–7:00pm — 1 Leetcode problem")
- 🔍 **Diagnose it** — something deeper is going on → rewrite as a question to answer (e.g. "Why am I avoiding interview prep? Scared of failing? Don't actually want this job?")

When you encounter a #friction item during digest, pick the right decision and rewrite the task accordingly. If it's ambiguous, flag it to Luis: "This has been carried 3+ times — kill, shrink, schedule, or diagnose?"

This feeds directly into the Saturday friction analysis — avoidance shows up in behavior (repeated deferral) before it shows up in self-reflection.

**If tomorrow is Saturday — populate the Weekly Reflection section:**

Pull from the week's daily notes and vault state to pre-fill context for each question:

1. **What did I say I wanted?** — scan this week's ephemerals, Plans sections from daily notes, and any goals mentioned across the week
2. **What did I actually do?** — summarize what actually happened across Work and Life from daily notes and completed todos
3. **Where is the mismatch?** — leave blank for Luis to fill in; optionally flag obvious gaps you noticed (e.g. something mentioned Mon that never appeared in a todo)
4. **Why did that happen?** — leave blank; this is introspective, Luis fills it
5. **What changes next week?** — leave blank; Luis fills in 1–3 adjustments

Pre-fill 1 and 2 with bullets drawn from the week. Leave 3, 4, 5 empty for Luis to answer during the 30–45 min session.

**Friction analysis (Saturday only):**

Before generating the Saturday todo, grep the week's daily notes for `#friction`:

```bash
grep -r "#friction" "/mnt/o/Notes/Obsidian Vault/Daily/Life/Notes/" --include="*.md"
```

Summarize the results into a short friction report to prepend to question 3:

- List each friction point with the date it appeared
- Flag anything that appeared more than once — repetition is a pattern, not a one-off
- Note whether the friction is around a specific area (work, health, relationships, habits)

This gives Luis something concrete to react to rather than starting question 3 cold.

**Key rule — enforce this when reviewing a completed reflection:**
The reflection is not done until question 5 contains at least one concrete behavior change — not an intention, not "try harder," but an actual adjustment to how something is done. If Luis fills in the reflection and question 5 is vague or empty, flag it: "This reflection doesn't have a behavior change yet — what's the one thing that actually changes next week?"

## Step 9b — Score social activity

After generating the next-day todo, set the `social` score in the daily note's frontmatter. This feeds the heatmap in `Life/Physical/Social Tracker.md` and `_Index/Dashboard.md`.

**Scoring rules:**

| Score | When to use |
|---|---|
| 0 | WFH alone, no meaningful interaction outside household |
| 1 | WFH with Miki home; or household only (Miki, Kai, Sol) |
| 2 | Online with friends — gaming with Danny, Ben, Luis R., Achyut |
| 3 | Office day (coworkers = social contact); boxing; out in the world with real interaction |
| 4 | Saw friends or family in person — Charlie, Melissa, Karen, Vero, etc. |
| 5 | Big social day — event, multiple groups, family gathering |

**Rules:**
- Use the highest score that applies if multiple things happened (e.g. office day + saw a friend = 4, not 3)
- WFH alone is always 0 regardless of how productive the day was
- Going to the office is always at least a 3 even if no deep interactions happened
- Gaming online counts as 2 even if it was brief

Update the frontmatter of the daily note:
```bash
# Use Python to safely update frontmatter (handles emoji in file)
python3 -c "
import re
path = 'Daily/Life/Notes/YYYY-MM-DD.md'
text = open(path).read()
text = re.sub(r'(^social:\s*)\d+', r'\g<1>SCORE', text, flags=re.MULTILINE)
open(path, 'w').write(text)
"
```

If `social:` is not yet in the frontmatter, add it after the `date:` line.

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

This gives Luis a visible confirmation that the agent ran and when.

## Step 11 — Update Now.md

After every daily digest, update `_Index/Now.md` to reflect the current month's state. This is the agent's orientation document — keep it accurate.

**What to update:**
- Work section: change project status if anything progressed, resolved, or got blocked
- Life section: update finance snapshot if numbers changed, relationship/health if anything notable
- Pending Decisions: add new open questions, remove ones that resolved
- What Agent Should Know: add anything that came out of today's note that an agent needs to know but wouldn't find easily in other notes

**What NOT to do:**
- Don't rewrite the whole file on every digest — edit only what changed
- Don't log daily events in Now.md — that's what the daily note is for
- Don't duplicate information already findable in linked notes — one line + a link is enough

**At month rollover:** rename the current Now.md to `Reviews/Now - YYYY-MM.md` as an archive, then create a fresh Now.md for the new month pulling forward anything still relevant.

## Step 12 — Generate Signals Block

Every morning, generate the `🔭 Signals` block for today's daily note. This is done by the 5am agent — not the hourly digest. It runs before the user opens the note so they see it as a writing key when they start their day.

**Source material:** Read the last 5 daily notes and `_Index/Now.md`. Do not re-read the full vault — work from what's in the recent notes and follow wikilinks only where clearly relevant.

**Three fields to fill:**

**Patterns** — What themes, words, feelings, or situations have appeared across multiple recent notes? Look for things that repeat without necessarily being named as a project or goal. Examples: sleep issues appearing 4 days running, anxiety + money appearing together twice, work mentioned but without detail (avoidance signal), a person mentioned more than once.
- Keep to 2–3 bullets max. Be specific and observational, not interpretive.
- Bad: "You seem stressed" — Good: "Anxiety + money appeared together twice this week"

**Threads** — Ideas, desires, or creative sparks that have surfaced more than once but aren't a project or todo yet. Things that want to become something. Look for half-formed thoughts, "I want to...", recurring curiosities, things mentioned then dropped.
- Keep to 1–3 threads. Name them concisely.
- Bad: "You mentioned VFX" — Good: "VFX pipeline direction — came up again unprompted"

**Connects** — Links between recent writing and existing vault notes. Where does what you've been writing touch something already alive in the vault? Check ephemerals in `_Index/Ephemeral - Active.md`, open questions, active projects.
- Keep to 1–2 connections. Always include the wikilink.
- Bad: "You mentioned work stress" — Good: "Feeling behind at work → [[Career/Ephemeral/Bloomberg Exit]] active 3 weeks"

**Inject into today's daily note** by replacing the placeholder lines:

```python
python3 -c "
import re

path = 'Daily/Life/Notes/YYYY-MM-DD.md'
text = open(path).read()

signals = '''> [!abstract]- 🔭 Signals
> **Patterns:** PATTERNS_HERE
> **Threads:** THREADS_HERE
> **Connects:** CONNECTS_HERE'''

# Replace the placeholder block
text = re.sub(
    r'> \[!abstract\]- 🔭 Signals\n> \*\*Patterns:\*\* —\n> \*\*Threads:\*\* —\n> \*\*Connects:\*\* —',
    signals,
    text
)
open(path, 'w').write(text)
"
```

If today's daily note doesn't exist yet, create it from the template first (`_Templates/Daily Life Note.md`), fill the frontmatter placeholders, then inject the Signals block.

**Tone:** Observational, not prescriptive. The system is noticing — not advising. Short phrases, not sentences. The user decides what to do with it.

---

## Step 13 — Update Dashboard

After every daily digest, update `_Index/Dashboard.md`:

- **Today section:** update links to the new date's daily note and todo
- **Work Projects table:** update status emoji and one-line status if anything changed
- **Upcoming table:** add any new dates that surfaced in the daily note (Dr appts, trips, plans)
- **Life Pulse:** update the one-liner for any area that changed

---

## People question bank

When a new person appears, ask a subset of these based on context — don't ask all of them at once:

**Basics**
- How do you know [name]?
- How long have you known them?
- How often do you interact?

**Relationship context**
- Are they a friend, colleague, family member, romantic interest?
- What's the dynamic like?
- Is this relationship positive, complicated, or somewhere in between?

**Relevant to Luis's life**
- Does this person connect to any of your current situations (work, dating, family)?
- Anything important about them worth remembering?

## Person note format

```yaml
---
title: <Name>
category: <life | career | family | friends | ...>
type: person
tags: [person, ...]
summary: "One sentence — who they are and why they appear in the vault."
links:
  - target: "[[]]"
    weight: 
    type: 
---

## Who
Brief description — who they are in relation to Luis.

## Context
How they met, frequency of contact, dynamic.

## Notes
- [date] Observations over time, notable interactions
```

---

## Project note format (Arcs + Timeline)

Projects have categorized arcs — each a self-contained thread — and an overall timeline that pieces them together.

**Arc categories** (use only what applies — not every project has all of them):
- `Research` — exploration, spikes, feasibility
- `Design` — architecture, technical design, presentations
- `Implementation` — actual development work
- `Testing` — unit, integration, QA
- `Review` — code review, design review, PR feedback
- `Deployment` — releasing to beta, staging, prod
- `Communication: <Team>` — cross-team coordination, stakeholder updates
- `Blocker: <Name>` — something specific blocking progress
- `Maintenance` — ongoing operational work, bug fixes post-launch

**Arc writing standard:** Each arc must have enough narrative to reconstruct what happened, why, who was involved, key decisions made, and how it resolved — without needing to re-read daily notes. A bullet list of dates alone is not sufficient.

```markdown
## Arcs

### Implementation
One paragraph describing what was built, who did it, scope, notable technical decisions.

- [YYYY-MM-DD] Specific event
- [YYYY-MM-DD] How it progressed or resolved

### Blocker: <Name>
One paragraph describing what the blocker was, who caused it, the impact, and how/whether it resolved.

- [YYYY-MM-DD] Blocker arose
- [YYYY-MM-DD] Resolved / still open

## Timeline

- [YYYY-MM-DD] Project started
- [YYYY-MM-DD] Arc: Implementation — began
- [YYYY-MM-DD] Arc: Blocker: <Name> — arose / resolved
```

**When updating from a daily note:**
- Fits an existing arc → add a dated bullet and update the arc narrative if needed
- New thread → create a new arc with the appropriate category
- Always add a line to the Timeline referencing the arc

---

## What NOT to do

- Don't ask about every single person if there are many — prioritize new or significant ones
- Don't rewrite the daily note — it's a dump, leave it as-is
- Don't create vault notes from daily notes automatically — ask first or propose clearly
- Don't ask more than ~5 questions in one pass
- Don't create a project note from a single offhand mention — look for pattern or ask first
