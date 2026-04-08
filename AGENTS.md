# Vault Agents

This file contains the prompts for the two scheduled Claude Code Remote (CCR) agents that power the vault automation. Set these up at [claude.ai/code](https://claude.ai/code) under **Triggers**.

Before using these prompts, replace:
- `YOUR_GITHUB_PAT` — a GitHub personal access token with `repo` scope
- `YOUR_USERNAME` — your GitHub username
- `YOUR_REPO` — your vault repo name (default: `obsidian-vault`)
- `YOUR_CCR_ENVIRONMENT_ID` — your CCR environment ID (found in claude.ai/code settings)

---

## Agent 1: Hourly Digest

**Name:** Vault — Digest  
**Schedule:** `0 * * * *` (top of every hour)  
**Tools:** Bash, Read, Write, Edit, Glob, Grep

**How it works:** A gate script checks git for user commits since the last agent run. If nothing new was written, only mechanical scripts run (no Claude reasoning, ~0 tokens). If the user wrote something, Claude processes only the diff — not full files.

### Prompt

```
You are a scheduled vault agent for an Obsidian second brain vault.

Setup:
git clone --depth=20 https://YOUR_GITHUB_PAT@github.com/YOUR_USERNAME/YOUR_REPO.git vault
cd vault
git config user.email "vault-agent@auto"
git config user.name "Vault Agent"

All file paths are relative to vault/.

Step 1 - Run mechanical scripts (always):
python3 scripts/carry-forward-todos.py
python3 scripts/stamp-frontmatter.py
python3 scripts/update-sprint-header.py
python3 scripts/update-dashboard.py
python3 scripts/bookmark-todo.py

Step 2 - Gate check:
Run: python3 scripts/check-changes.py
- If output starts with SKIP: skip to Step 4. Do not read any daily notes.
- If output starts with PROCESS: the diff of user changes follows. Proceed to Step 3.

Step 3 - Digest (only if PROCESS):
Read _Index/Now.md for context. Work from the diff output - do NOT re-read full daily note files.
Follow the workflow in Claude - How to Process Daily Notes.md:
- Extract people; update existing notes or queue in _Index/Open Questions.md
- Update project notes (Career/Physical/, Projects/Physical/) if touched
- Update _Index/Now.md if status changed
- Update Dashboard project statuses and Life Pulse if anything changed
- Generate next-day todo if end-of-day content is present
- Set social score in today's daily note frontmatter

Step 4 - Commit and push:
git add -A
git diff --staged --quiet || git commit -m "vault: auto $(date +%Y-%m-%d) $(date +%H:%M)"
git push origin main || (git pull --rebase origin main && git push origin main)
```

> **Note:** The commit message format `vault: auto YYYY-MM-DD HH:MM` is the sentinel `check-changes.py` uses to find the last agent run. Do not change it.

---

## Agent 2: Daily Tasks + Weekly Review

**Name:** Vault — Daily Tasks + Weekly Review  
**Schedule:** `0 5 * * *` (5am daily — adjust to your timezone)  
**Tools:** Bash, Read, Write, Edit, Glob, Grep, WebSearch

### Prompt

```
You are a scheduled vault agent for an Obsidian second brain vault.

```bash
git clone --depth=1 https://YOUR_GITHUB_PAT@github.com/YOUR_USERNAME/YOUR_REPO.git vault
cd vault
git config user.email "vault-agent@auto"
git config user.name "Vault Agent"
```

All file paths are relative to `vault/`.

## Task 1: Open Questions

Read `_Index/Open Questions.md`.

For each `- [ ]` line:
- Read the linked daily note for context
- Search for the relevant person/project note in the vault
- If resolvable from vault content: update the relevant note, change `- [ ]` to `- [x]`
- If it needs the user to answer: leave as-is

After processing, remove ALL `- [x]` lines from the file — resolved or not. The file should only ever contain unresolved `- [ ]` items. Write the file back.

## Task 2: Weekly Review (Saturdays only)

Run `date +%u`. If the result is 6 (Saturday):
1. Read `_Index/Now.md` and the last 7 `Daily/Life/Notes/YYYY-MM-DD.md` files
2. Get week ID: `date +%Y-W%V`
3. Write or update `Reviews/YYYY-WNN.md` with sections: Work, Life, Patterns, Carry Forward
4. Update `_Index/Now.md` only if something materially changed

If not Saturday, skip Task 2.

## Task 3: Curated Content

### Step 3a — Build the interest pool

Read these files to build a dynamic list of topic candidates:
- `_Index/Ephemeral - Active.md` — follow each wikilink and read the actual ephemeral note to extract specific sub-topics
- `_Index/Now.md` — current sprint tech stack, what's blocked, what's on your mind
- `Learning/` folder — list files and read any active notes
- `Life/Physical/` folder — health goals
- Last 3 `Daily/Life/Notes/YYYY-MM-DD.md` files — what's been on your mind recently

From this, build a pool of 15+ specific topic candidates. Be specific:
- Not "Japanese" but "Japanese pitch accent practice" or "Japanese immersion reading N3"
- Not "Finance" but "index fund allocation strategy" or "emergency fund milestone planning"
- Not "Kotlin" but "Kotlin coroutines patterns" or "Kafka consumer group rebalancing"

### Step 3b — Pick 5 categories

Read `_Index/Content Queue.md` to see which categories appeared in the last 5 daily entries. Avoid repeating any of them today.

Pick 5 candidates from your pool that haven't been covered recently.

### Step 3c — Find content

Read `_Index/Content Queue Log.md` to get all previously suggested URLs. Do not suggest any URL already in that file.

For each of the 5 categories:
- Run a WebSearch with a specific, targeted query
- Find exactly 2 YouTube videos and 2 articles (prefer YouTube channels, reputable publications, GitHub repos)
- Skip any URL already in the log

### Step 3d — Write output

Insert the new block at the **top** of `_Index/Content Queue.md`, immediately after the `<!-- Agent appends -->` comment line:

```
## YYYY-MM-DD — Weekday

### [Specific Category Name]
**YouTube**
- [Title](url) — one line: why relevant right now
- [Title](url) — one line: why relevant
**Articles**
- [Title](url) — one line: why relevant
- [Title](url) — one line: why relevant

[repeat for all 5 categories]
```

Insert all new URLs at the **top** of `_Index/Content Queue Log.md`, immediately after the `<!-- Agent appends -->` comment line:
```
YYYY-MM-DD | url
```

Remove entries in `_Index/Content Queue.md` with a date older than 3 days from today.

Remove entries in `_Index/Content Queue Log.md` with a date older than 7 days from today.

## Task 4: Signals Block

Generate a `🔭 Signals` block for today's daily note — a writing key the user sees when they open the note.

Read the last 5 `Daily/Life/Notes/YYYY-MM-DD.md` files and `_Index/Ephemeral - Active.md`. From this, generate three fields:

**Patterns** (2–3 bullets) — recurring themes, words, feelings across recent notes. Specific and observational.
- Bad: "You seem stressed" → Good: "Anxiety + money appeared together twice this week"

**Threads** (1–3 bullets) — ideas or desires that surfaced more than once, not yet a project. Things that want to become something.
- Bad: "You mentioned VFX" → Good: "VFX pipeline direction — came up again unprompted"

**Connects** (1–2 bullets) — links between recent writing and existing vault notes. Always include the wikilink.
- Bad: "You mentioned work stress" → Good: "Feeling behind at work → [[Career/Ephemeral/Example]] active 3 weeks"

If today's daily note doesn't exist, create it from `_Templates/Daily Life Note.md` and fill the frontmatter placeholders (title, date, H1) with today's date.

Then inject the Signals by replacing the placeholder block in the note:

```python
python3 -c "
import re, sys
from datetime import datetime

today = datetime.today().strftime('%Y-%m-%d')
path = f'Daily/Life/Notes/{today}.md'

patterns = 'LINE1 · LINE2'  # replace with actual content
threads  = 'LINE1 · LINE2'
connects = 'LINE1'

signals = f'''> [!abstract]- 🔭 Signals
> **Patterns:** {patterns}
> **Threads:** {threads}
> **Connects:** {connects}'''

text = open(path).read()
text = re.sub(
    r'> \[!abstract\]- 🔭 Signals\n> \*\*Patterns:\*\* —\n> \*\*Threads:\*\* —\n> \*\*Connects:\*\* —',
    signals,
    text
)
open(path, 'w').write(text)
"
```

Tone: observational, not prescriptive. Short phrases. The user decides what to do with it.

## Task 5: Suggest

Generate one suggestion for today's todo based on what's alive in the vault. This sits at the top of the todo as a nudge — not a task, just a spark.

Read recent media notes, person notes, and ephemerals. Look for something the user has been returning to — a director, author, artist, topic, idea — and make one specific follow-through recommendation derived from that.

**Rules:**
- One item only — never a list
- Must come from something already in the vault — not invented
- Specific: "Arrival and Enemy are his most different from Dune" not "his other films"
- Framing: curious, not prescriptive — "you keep coming back to X" not "you should do Y"
- If nothing stands out, skip it — leave the placeholder as `—`

Inject into today's todo by replacing the `—` placeholder in the `[!tip]- 💡 Suggest` callout:

```python
python3 -c "
import re
from datetime import datetime

today = datetime.today().strftime('%Y-%m-%d')
path = f'Daily/Todo/{today}.md'
suggestion = 'YOUR SUGGESTION HERE'

text = open(path).read()
text = re.sub(
    r'(> \[!tip\]- 💡 Suggest\n> \*.*?\*\n>\n> )—',
    rf'\g<1>{suggestion}',
    text
)
open(path, 'w').write(text)
"
```

## Task 6: Scratchpad Processing

Read all `.md` files in `Scratchpad/` (not `Scratchpad/Archived/`). For each file:

### Step 1 — Read and assess

Read the full content. Determine if there is extractable signal:

**Has signal:**
- Named people not yet in the vault
- A desire, idea, or creative direction that keeps coming back
- A decision or realization worth remembering
- A project thread or tech interest
- An emotional pattern worth tracking

**No signal (noise):**
- Pure venting with nothing new — no people, no decisions, no ideas
- Content already fully captured in a same-day daily note
- Thoughts too vague or transient to be worth a note

### Step 2 — Extract and create vault notes (signal only)

Apply the same logic as ChatGPT chat processing:
- Named person not in vault → queue in `_Index/Open Questions.md`
- New desire or creative direction → propose or create an Ephemeral note
- Project or tech thread → update or propose a Physical note
- Emotional pattern → check if an Ephemeral exists; update or propose one
- Connects to an existing note → update it with dated bullet

Do not create notes from a single vague mention. Look for specificity.

### Step 3 — Stamp metadata

Whether signal or noise, stamp the file with frontmatter before archiving:

```python
python3 -c "
import re, sys
from datetime import datetime

path = sys.argv[1]
text = open(path).read()

# Skip if frontmatter already exists
if text.startswith('---'):
    sys.exit(0)

# Generate title from first non-empty line, or filename
lines = [l.strip() for l in text.splitlines() if l.strip()]
title = lines[0][:60] if lines else path.split('/')[-1].replace('.md', '')
title = re.sub(r'^#+\s*', '', title)  # strip markdown heading prefix

date = datetime.today().strftime('%Y-%m-%d')

frontmatter = f'---\ntitle: {title}\ndate: {date}\ntags: [scratchpad]\nprocessed: true\n---\n\n'
open(path, 'w').write(frontmatter + text)
" FILEPATH
```

Add `processed: noise` instead of `processed: true` if no signal was found.

Auto-detect and add content tags if strong signals exist (e.g. `videography`, `relationships`, `career`).

### Step 4 — Archive

Move the file to `Scratchpad/Archived/`:

```bash
mv "Scratchpad/FILENAME.md" "Scratchpad/Archived/FILENAME.md"
```

Never delete scratchpad files. Always archive.

## Commit and push

```bash
git add -A
git diff --staged --quiet || git commit -m "vault: questions $(date +%Y-%m-%d) $(date +%H:%M)"
git push origin main
```
```

---

## Helper Scripts

Six Python scripts in `scripts/` handle all mechanical vault maintenance. They run as Step 1 of every hourly digest — before the gate check.

| Script | What it does |
|---|---|
| `check-changes.py` | Git diff gate — outputs `SKIP` or `PROCESS\n<diff>` |
| `carry-forward-todos.py` | Copies unchecked todos yesterday→today; auto-tags `#friction` at 3+ appearances |
| `stamp-frontmatter.py` | Fills `YYYY-MM-DD` placeholders in today's daily note; stamps `last_digest` in Now.md |
| `update-sprint-header.py` | Reads `sprint_name/start/end` from Now.md frontmatter; updates "N days left" in today's todo |
| `update-dashboard.py` | Updates Dashboard Today links and `updated:` date |
| `bookmark-todo.py` | Swaps Obsidian bookmark to today's todo |

### Sprint frontmatter in Now.md

`update-sprint-header.py` requires these fields in `_Index/Now.md` frontmatter:
```yaml
sprint_name: Your Sprint Name
sprint_start: YYYY-MM-DD
sprint_end: YYYY-MM-DD
```
Update these at the start of each sprint.

---

## Local Cron Alternative (Home Server / WSL)

If you have an always-on machine with WSL2, you can run agents locally instead of via CCR — no trigger slot limits, no git clone overhead (direct file access).

### Setup

```bash
# Install Claude Code CLI
npm install -g @anthropic-ai/claude-code

# Add to environment
export ANTHROPIC_API_KEY=your_key_here

# Create a digest script
cat > ~/scripts/vault-digest.sh << 'EOF'
#!/bin/bash
cd "/path/to/your/vault"
claude -p "$(cat ~/scripts/digest-prompt.txt)"
EOF

chmod +x ~/scripts/vault-digest.sh
```

### WSL Crontab

```bash
crontab -e
# Add:
0 * * * * /home/youruser/scripts/vault-digest.sh >> /home/youruser/logs/vault-digest.log 2>&1
0 12 * * * /home/youruser/scripts/vault-tasks.sh >> /home/youruser/logs/vault-tasks.log 2>&1
```

Save the prompt text (without the git clone block — agent has direct file access) to `~/scripts/digest-prompt.txt`.
