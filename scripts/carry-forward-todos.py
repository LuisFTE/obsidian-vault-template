"""
carry-forward-todos.py

Mechanically carries unfinished todo items from yesterday to today.
- Copies unchecked [ ] items into today's todo under ## ↩️ Carry Forward
- Tags items with #friction if they have appeared in 3+ previous todo files
- Injects decision checkboxes below #friction items (Kill / Shrink / Schedule / Diagnose)
- If a decision was checked: carries forward with the decision preserved for Claude to act on
- If no decision was checked: carries forward with fresh (reset) decision checkboxes

Run from vault root: python3 scripts/carry-forward-todos.py
"""

import re
from datetime import date, timedelta
from pathlib import Path

VAULT = Path(__file__).parent.parent
TODO_DIR = VAULT / "Daily" / "Todo"

today = date.today()
yesterday = today - timedelta(days=1)
today_str = today.strftime("%Y-%m-%d")
yesterday_str = yesterday.strftime("%Y-%m-%d")

yesterday_file = TODO_DIR / f"{yesterday_str}.md"
today_file = TODO_DIR / f"{today_str}.md"

if not yesterday_file.exists():
    exit(0)

yesterday_lines = yesterday_file.read_text(encoding="utf-8").splitlines()

DECISION_LABELS = ["🔪 Kill it", "✂️ Shrink it", "🧱 Schedule it", "🔍 Diagnose it"]
DECISION_BOXES  = [f"    - [ ] {d}" for d in DECISION_LABELS]

DECISION_MAP = {"🔪": "kill", "✂️": "shrink", "🧱": "schedule", "🔍": "diagnose"}


def is_main_item(line):
    """Top-level unchecked checkbox (not indented)."""
    return bool(re.match(r"^- \[ \]", line))


def is_sub_item(line):
    """Indented checkbox (decision sub-item)."""
    return bool(re.match(r"^ {2,}- \[", line))


def parse_blocks(lines):
    """
    Group lines into blocks: [main_line, sub_line, sub_line, ...]
    Only captures top-level unchecked items and their indented children.
    """
    blocks = []
    current = None
    for line in lines:
        if is_main_item(line):
            if current is not None:
                blocks.append(current)
            current = [line]
        elif current is not None and is_sub_item(line):
            current.append(line)
        else:
            if current is not None:
                blocks.append(current)
                current = None
    if current is not None:
        blocks.append(current)
    return blocks


def count_occurrences(item_text):
    """Count how many previous todo files contain this item (friction detection)."""
    core = re.sub(r"^- \[ \]\s*[🔴🟡🟠⚪🔵🟢🚫🔨👀🚀✅📋\s]*", "", item_text).strip()
    core = re.sub(r"#\w+", "", core).strip()
    if len(core) < 5:
        return 0
    count = 0
    for todo_file in sorted(TODO_DIR.glob("*.md")):
        if todo_file.stem in (today_str, yesterday_str):
            continue
        try:
            if core[:40] in todo_file.read_text(encoding="utf-8"):
                count += 1
        except Exception:
            pass
    return count


def tag_friction(line):
    if "#friction" in line:
        return line
    return line.rstrip() + " #friction"


def checked_decision(sub_lines):
    """Return the decision key if any sub-checkbox is checked, else None."""
    for line in sub_lines:
        if re.match(r"^ {2,}- \[x\]", line, re.IGNORECASE):
            for emoji, key in DECISION_MAP.items():
                if emoji in line:
                    return key
    return None


def has_decision_boxes(sub_lines):
    """Return True if decision checkboxes are already present."""
    return any("Kill it" in l or "Shrink it" in l for l in sub_lines)


# Parse yesterday into blocks of unchecked items
blocks = parse_blocks(yesterday_lines)

carried = []

for block in blocks:
    main_line = block[0]
    sub_lines = block[1:]

    # Apply friction tagging
    occurrences = count_occurrences(main_line)
    if occurrences >= 2:
        main_line = tag_friction(main_line)

    is_friction = "#friction" in main_line

    if not is_friction:
        # Plain item — carry as single line
        carried.append([main_line])
        continue

    # Friction item — check for a decision
    decision = checked_decision(sub_lines)

    if decision:
        # Decision was made — carry with checked box preserved, flag for Claude
        main_flagged = main_line.rstrip() + f" #friction-{decision}"
        # Keep the sub-lines with the checked box intact
        carried.append([main_flagged] + sub_lines)
    else:
        # No decision yet — carry with fresh decision checkboxes
        carried.append([main_line] + DECISION_BOXES)

if not carried:
    exit(0)

# Flatten blocks to lines
carried_lines = []
for block in carried:
    carried_lines.extend(block)

# Write to today's todo
if today_file.exists():
    today_content = today_file.read_text(encoding="utf-8")
    if "## ↩️ Carry Forward" in today_content:
        # Append to existing section
        today_content = re.sub(
            r"(## ↩️ Carry Forward\n)",
            r"\1\n" + "\n".join(carried_lines) + "\n",
            today_content,
        )
    else:
        today_content = today_content.rstrip() + "\n\n## ↩️ Carry Forward\n\n"
        today_content += "\n".join(carried_lines) + "\n"
    today_file.write_text(today_content, encoding="utf-8")
else:
    today_content = f"""---
title: Todo {today_str}
type: todo
date: {today_str}
tags: [todo]
---

# Todo {today_str}

## ↩️ Carry Forward

""" + "\n".join(carried_lines) + "\n"
    today_file.write_text(today_content, encoding="utf-8")

print(f"Carried {len(carried)} item(s) to {today_str}.md")
