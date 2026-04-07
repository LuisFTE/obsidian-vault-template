#!/usr/bin/env python3
"""
Run from vault root: python3 scripts/update-dashboard.py
Updates _Index/Dashboard.md:
  - Today section: today's daily note + todo links
  - updated frontmatter field
"""
import re
from datetime import date
from pathlib import Path

VAULT = Path(__file__).parent.parent  # scripts/ -> vault root

today = date.today().strftime("%Y-%m-%d")
dashboard = VAULT / "_Index/Dashboard.md"
content = dashboard.read_text()

# --- Update frontmatter updated field ---
content = re.sub(r"(updated:\s*)[\d-]+", f"\\g<1>{today}", content)

# --- Update Today section ---
today_block = f"""## Today

- 📓 [[Daily/Life/Notes/{today}]] — daily note
- ✅ [[Daily/Todo/{today}]] — todo"""

content = re.sub(
    r"## Today\n\n- 📓 \[\[Daily/Life/Notes/[\d-]+\]\].*?\n- ✅ \[\[Daily/Todo/[\d-]+\]\].*",
    today_block,
    content
)

dashboard.write_text(content)
print(f"Dashboard updated for {today}")
