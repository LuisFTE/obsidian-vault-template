"""
update-sprint-header.py

Updates the sprint header line in today's todo with the correct days-remaining count.
Reads sprint name and end date from _Index/Now.md frontmatter.

Required Now.md frontmatter fields:
  sprint_name: Sprint Name
  sprint_start: YYYY-MM-DD
  sprint_end: YYYY-MM-DD

Run from vault root: python3 scripts/update-sprint-header.py
"""

import re
from datetime import date
from pathlib import Path

VAULT = Path(__file__).parent.parent  # scripts/ -> vault root

today = date.today()
today_str = today.strftime("%Y-%m-%d")
todo_file = VAULT / f"Daily/Todo/{today_str}.md"

if not todo_file.exists():
    exit(0)

now_file = VAULT / "_Index/Now.md"
if not now_file.exists():
    exit(0)

now_text = now_file.read_text(encoding="utf-8")

sprint_name_match = re.search(r"sprint_name:\s*(.+)", now_text)
sprint_end_match = re.search(r"sprint_end:\s*(\d{4}-\d{2}-\d{2})", now_text)
sprint_start_match = re.search(r"sprint_start:\s*(\d{4}-\d{2}-\d{2})", now_text)

if not sprint_name_match or not sprint_end_match:
    exit(0)

sprint_name = sprint_name_match.group(1).strip()
sprint_end = date.fromisoformat(sprint_end_match.group(1))
sprint_start = date.fromisoformat(sprint_start_match.group(1)) if sprint_start_match else None

days_left = max(0, (sprint_end - today).days + 1)

start_fmt = sprint_start.strftime("%-d %b") if sprint_start else "?"
end_fmt = sprint_end.strftime("%-d %b")

new_header = (
    f"*🏃 Sprint: {sprint_name} · "
    f"Wed {start_fmt} – Tue {end_fmt} · "
    f"{days_left} day{'s' if days_left != 1 else ''} left*"
)

todo_text = todo_file.read_text(encoding="utf-8")
updated = re.sub(r"\*🏃 Sprint:.*?\*", new_header, todo_text)

if updated != todo_text:
    todo_file.write_text(updated, encoding="utf-8")
    print(f"Updated sprint header: {new_header}")
else:
    print("No sprint header found to update.")
