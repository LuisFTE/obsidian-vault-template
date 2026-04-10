"""
stamp-frontmatter.py

Fills in placeholder values in today's daily note frontmatter and header.
Replaces YYYY-MM-DD with actual date values so the note is properly indexed.
Also stamps the last_digest timestamp in _Index/Now.md.

Run from vault root: python3 scripts/stamp-frontmatter.py
"""

import re
import subprocess
from datetime import datetime
from pathlib import Path

VAULT = Path(__file__).parent.parent  # scripts/ -> vault root

today = datetime.today()
today_str = today.strftime("%Y-%m-%d")
today_full = today.strftime("%A, %B %-d, %Y")  # e.g. Sunday, April 6, 2026

# --- Stamp today's daily note ---
daily_note = VAULT / f"Daily/Notes/{today_str}.md"

if daily_note.exists():
    text = daily_note.read_text(encoding="utf-8")
    if "YYYY-MM-DD" in text:
        text = text.replace("title: YYYY-MM-DD", f"title: {today_full}")
        text = text.replace("date: YYYY-MM-DD", f"date: {today_str}")
        text = text.replace("# 📅 YYYY-MM-DD", f"# 📅 {today_full}")
        daily_note.write_text(text, encoding="utf-8")
        print(f"Stamped frontmatter in {today_str}.md")

# --- Stamp last_digest in Now.md ---
now_file = VAULT / "_Index/Now.md"
ts = subprocess.check_output(["date", "+%Y-%m-%d %H:%M UTC"]).decode().strip()

if now_file.exists():
    text = now_file.read_text(encoding="utf-8")
    text = re.sub(r"last_digest:.*", f"last_digest: {ts}", text)
    text = re.sub(r"\*\*Last digest:\*\*.*", f"**Last digest:** `{ts}`", text)
    now_file.write_text(text, encoding="utf-8")
    print(f"Stamped last_digest: {ts}")
