"""
carry-forward-todos.py

Mechanically carries unfinished todo items from yesterday to today.
- Only parses Work, Life, and Carry Forward sections (skips Recurring, Blocked, Done)
- Deduplicates: skips items whose core text already appears in today's file
- Tags items with #friction if they have appeared in 3+ previous todo files
- Injects decision checkboxes below #friction items (Kill / Shrink / Schedule / Diagnose)
- If a decision was checked: carries forward with the decision preserved for Claude to act on
- If no decision was checked: carries forward with fresh (reset) decision checkboxes
- Final pass: injects decision boxes under any #friction item in the whole file missing them

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

# Sections to carry forward from (everything else is skipped)
CARRY_SECTIONS = {"💼 Work", "🌿 Life", "↩️ Carry Forward"}


def section_name(line):
    """Extract section name from a ## header line, or None."""
    m = re.match(r"^## (.+)", line)
    return m.group(1).strip() if m else None


def is_carry_section(name):
    if name is None:
        return False
    return any(key in name for key in CARRY_SECTIONS)


def is_main_item(line):
    """Top-level unchecked checkbox (not indented)."""
    return bool(re.match(r"^- \[ \]", line))


def is_sub_item(line):
    """Indented checkbox (decision sub-item)."""
    return bool(re.match(r"^ {2,}- \[", line))


def parse_blocks(lines):
    """
    Group lines into blocks: [main_line, sub_line, sub_line, ...]
    Only captures top-level unchecked items and their indented children,
    from carry-eligible sections only (Work, Life, Carry Forward).
    Skips Recurring, Blocked, Done, and any other sections.
    """
    blocks = []
    current_block = None
    in_carry_section = False
    current_section = None

    for line in lines:
        sec = section_name(line)
        if sec is not None:
            # Flush any open block
            if current_block is not None:
                blocks.append(current_block)
                current_block = None
            current_section = sec
            in_carry_section = is_carry_section(sec)
            continue

        if not in_carry_section:
            if current_block is not None:
                blocks.append(current_block)
                current_block = None
            continue

        if is_main_item(line):
            if current_block is not None:
                blocks.append(current_block)
            current_block = [line]
        elif current_block is not None and is_sub_item(line):
            current_block.append(line)
        else:
            if current_block is not None:
                blocks.append(current_block)
                current_block = None

    if current_block is not None:
        blocks.append(current_block)

    return blocks


def item_core(line):
    """Extract the core text of an item for deduplication / friction counting."""
    core = re.sub(r"^- \[.\]\s*[🔴🟡🟠⚪🔵🟢🚫🔨👀🚀✅📋\s]*", "", line).strip()
    core = re.sub(r"#\w+", "", core).strip()
    core = re.sub(r"—.*$", "", core).strip()  # strip status suffixes
    return core


def count_occurrences(item_text):
    """Count how many previous todo files contain this item (friction detection)."""
    core = item_core(item_text)
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


def already_in_today(core, today_content):
    """Return True if the item's core text already appears in today's file."""
    if len(core) < 5:
        return False
    return core[:40] in today_content


# Parse yesterday into blocks of unchecked items (carry-eligible sections only)
blocks = parse_blocks(yesterday_lines)

# Load today's existing content for deduplication
today_content = today_file.read_text(encoding="utf-8") if today_file.exists() else ""

carried = []

for block in blocks:
    main_line = block[0]
    sub_lines = block[1:]

    # Deduplication: skip if core text already present in today's file
    core = item_core(main_line)
    if already_in_today(core, today_content):
        continue

    # Apply friction tagging
    occurrences = count_occurrences(main_line)
    if occurrences >= 2:
        main_line = tag_friction(main_line)

    is_friction = "#friction" in main_line

    if not is_friction:
        carried.append([main_line])
        continue

    # Friction item — check for a decision
    decision = checked_decision(sub_lines)

    if decision:
        main_flagged = main_line.rstrip() + f" #friction-{decision}"
        carried.append([main_flagged] + sub_lines)
    else:
        carried.append([main_line] + DECISION_BOXES)

if not carried:
    # Still run the friction injection pass even if nothing to carry
    pass
else:
    # Flatten blocks to lines
    carried_lines = []
    for block in carried:
        carried_lines.extend(block)

    # Write to today's todo
    if today_file.exists():
        today_content = today_file.read_text(encoding="utf-8")
        if "## ↩️ Carry Forward" in today_content:
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


def inject_missing_decision_boxes(file_path):
    """
    Scan the entire file for #friction items that are missing decision sub-checkboxes.
    Inject the 4 decision boxes immediately after any such item.
    Skips items inside the Recurring section.
    """
    lines = file_path.read_text(encoding="utf-8").splitlines()
    out = []
    i = 0
    injected = 0
    in_recurring = False

    while i < len(lines):
        line = lines[i]
        sec = section_name(line)
        if sec is not None:
            in_recurring = "Recurring" in sec
        out.append(line)

        if not in_recurring and re.match(r"^- \[ \]", line) and "#friction" in line:
            j = i + 1
            existing_subs = []
            while j < len(lines) and re.match(r"^ {2,}-", lines[j]):
                existing_subs.append(lines[j])
                j += 1
            if not has_decision_boxes(existing_subs):
                out.extend(existing_subs)
                out.extend(DECISION_BOXES)
                i = j
                injected += 1
                continue
        i += 1

    if injected:
        file_path.write_text("\n".join(out) + "\n", encoding="utf-8")
        print(f"Injected decision boxes into {injected} friction item(s) in {file_path.name}")


inject_missing_decision_boxes(today_file)
