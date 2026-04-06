"""
carry-forward-todos.py

Mechanically carries unfinished todo items from yesterday to today.
- Copies unchecked [ ] items into today's todo under ## 🔁 Carried Forward
- Tags items with #friction if they have appeared in 3+ previous todo files
- Does NOT make judgment calls — the digest agent handles Kill/Shrink/Schedule/Diagnose for #friction items

Run from vault root: python3 scripts/carry-forward-todos.py
"""

import re
from datetime import date, timedelta
from pathlib import Path

VAULT = Path(__file__).parent.parent  # scripts/ -> vault root
TODO_DIR = VAULT / "Daily" / "Todo"

today = date.today()
yesterday = today - timedelta(days=1)
today_str = today.strftime("%Y-%m-%d")
yesterday_str = yesterday.strftime("%Y-%m-%d")

yesterday_file = TODO_DIR / f"{yesterday_str}.md"
today_file = TODO_DIR / f"{today_str}.md"

if not yesterday_file.exists():
    exit(0)

yesterday_content = yesterday_file.read_text(encoding="utf-8")

# Find unchecked items
unchecked = [
    line for line in yesterday_content.splitlines()
    if re.match(r"\s*- \[ \]", line)
]

if not unchecked:
    exit(0)


def count_occurrences(item_text):
    """Count how many todo files (excluding today/yesterday) contain this item text."""
    core = re.sub(r"- \[ \]\s*[🔴🟡🟠⚪🔵🟢🚫🔨👀🚀✅📋\s]*", "", item_text).strip()
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


carried = []
for item in unchecked:
    if count_occurrences(item) >= 2:  # yesterday + 2 previous = 3+ total
        item = tag_friction(item)
    carried.append(item)

if not carried:
    exit(0)

if today_file.exists():
    today_content = today_file.read_text(encoding="utf-8")
    if "## 🔁 Carried Forward" in today_content:
        exit(0)
    today_content = today_content.rstrip() + "\n\n## 🔁 Carried Forward\n\n"
    today_content += "\n".join(carried) + "\n"
    today_file.write_text(today_content, encoding="utf-8")
else:
    today_content = f"""---
title: Todo {today_str}
type: todo
date: {today_str}
tags: [todo]
---

# Todo {today_str}

## 🔁 Carried Forward

""" + "\n".join(carried) + "\n"
    today_file.write_text(today_content, encoding="utf-8")

print(f"Carried {len(carried)} item(s) to {today_str}.md")
