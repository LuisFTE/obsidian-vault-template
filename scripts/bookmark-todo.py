#!/usr/bin/env python3
"""
Run from vault root: python3 scripts/bookmark-todo.py
Updates .obsidian/bookmarks.json to bookmark today's todo, removing any previous todo bookmark.
"""
import json, time
from datetime import date
from pathlib import Path

VAULT = Path(__file__).parent.parent  # scripts/ -> vault root

today = date.today().strftime("%Y-%m-%d")
todo_path = f"Daily/Todo/{today}.md"
bookmarks_file = VAULT / ".obsidian/bookmarks.json"

if not bookmarks_file.exists():
    data = {"items": []}
else:
    data = json.loads(bookmarks_file.read_text())

# Remove any existing Daily/Todo bookmarks
data["items"] = [i for i in data["items"] if not i.get("path", "").startswith("Daily/Todo/")]

# Add today's todo
data["items"].append({
    "type": "file",
    "ctime": int(time.time() * 1000),
    "path": todo_path,
    "title": f"Todo {today}"
})

bookmarks_file.write_text(json.dumps(data, indent=2))
print(f"Bookmarked {todo_path}")
