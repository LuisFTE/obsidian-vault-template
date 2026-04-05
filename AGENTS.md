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

### Prompt

```
You are a scheduled vault agent for an Obsidian second brain vault.

```bash
git clone --depth=1 https://YOUR_GITHUB_PAT@github.com/YOUR_USERNAME/YOUR_REPO.git vault
cd vault
git config user.email "vault-agent@auto"
git config user.name "Vault Agent"
```

All file paths below are relative to the `vault/` directory. Get today's date as YYYY-MM-DD.

## Task 1: Today's notes

Check if `Daily/Life/Notes/YYYY-MM-DD.md` exists.
- If missing: read `_Templates/Daily Life Note.md`, replace all `YYYY-MM-DD` with today's date, write the file.
- If exists but frontmatter `date` field says `YYYY-MM-DD`: update `date`, `title`, add `social: 0` if missing.

Check if `Daily/Todo/YYYY-MM-DD.md` exists.
- If missing: read `_Templates/Todo.md` and `_Index/Now.md` (for sprint name + days left). Create the todo with today's date filled in and the sprint line populated. Read yesterday's todo and carry forward any `- [ ]` items.

## Task 2: Process today and yesterday's daily life notes

For each of the last 2 days (today and yesterday), if `Daily/Life/Notes/YYYY-MM-DD.md` exists:

1. Fix frontmatter placeholders (date, title, tags, social: 0 if missing)
2. **People:** For each person mentioned by name: check if a person note exists in `Career/People/` or `Life/People/`. If not, add `- [ ] [[Daily/Life/Notes/DATE]] — Who is NAME?` to `_Index/Open Questions.md`
3. **Places:** For any place mentioned (restaurant, neighborhood, city, venue, country): check if `Places/PLACE.md` exists. If not, create it using `_Templates/Place.md` with what's known from context. If it exists, append a dated bullet to the Memories section.
4. **Media:** For any media mentioned, use the right template from `_Templates/`:
   - Photo or video taken → `Media - Photo.md` or `Media - Video (Personal).md` — set artist to your name, link to place if known
   - YouTube video watched → `Media - YouTube.md` — include URL and channel if mentioned
   - Movie or show watched/mentioned → `Media - Movie.md` or `Media - Show.md`
   - Album or music mentioned → `Media - Album.md` — include artist, genre if known
   Save to `Media/TITLE.md`. If the note already exists, append a dated bullet to Notes.
   - `with:` field = plain text only (e.g. "Sarah") — no wikilinks for incidental presence
   - Wikilinks only for artist/director/subject (central to the work)
5. **WPs (World Problems):** For any significant work incident mentioned: append a row to `Career/Physical/World Problems.md`.
6. **Projects:** For any work project mentioned: find the relevant note in `Career/Physical/`, read it, append a dated bullet to the right arc. Do not duplicate.
7. Set `social` score if still 0: 1=household only, 2=online gaming, 3=office/boxing/out, 4=friends in person, 5=big social day
8. In today's life note only: write a `## ⚡ Today` section (2-3 bullets of what's time-sensitive — pull from `_Index/Now.md`)

## Task 3: Update Now.md

Read `_Index/Now.md`. Update only:
- `last_digest:` frontmatter field → today's date
- The `**Last digest:**` line → current timestamp

## Commit and push

```bash
git add -A
git diff --staged --quiet || git commit -m "vault: digest $(date +%Y-%m-%d) $(date +%H:%M)"
git push origin main || (git pull --rebase origin main && git push origin main)
```
```

---

## Agent 2: Daily Tasks + Weekly Review

**Name:** Vault — Daily Tasks + Weekly Review  
**Schedule:** `0 12 * * *` (noon daily — adjust to your timezone)  
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

Append to `_Index/Content Queue.md`:

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

Append all new URLs to `_Index/Content Queue Log.md`, one per line:
```
YYYY-MM-DD | url
```

Remove entries in `_Index/Content Queue.md` older than 14 days.

## Commit and push

```bash
git add -A
git diff --staged --quiet || git commit -m "vault: questions $(date +%Y-%m-%d) $(date +%H:%M)"
git push origin main
```
```

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
