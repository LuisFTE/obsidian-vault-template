"""
check-changes.py

Gate script for the hourly digest agent.
Checks whether the user has made any new commits touching Daily/ since the last agent run.

Output:
  SKIP              — no user changes, agent should run scripts only and exit
  PROCESS\n<diff>   — user changed daily notes; diff follows on subsequent lines

Run from vault root: python3 scripts/check-changes.py
"""

import subprocess
import sys
from pathlib import Path

VAULT = Path(__file__).parent.parent  # scripts/ -> vault root


def git(*args):
    result = subprocess.run(
        ["git"] + list(args),
        capture_output=True, text=True, cwd=VAULT
    )
    return result.stdout.strip()


def find_last_auto_commit():
    """Return the hash of the most recent vault: auto commit, or None."""
    log = git("log", "--format=%H|||%s", "-200")
    for line in log.splitlines():
        if "|||" not in line:
            continue
        hash_, subject = line.split("|||", 1)
        if "vault: auto" in subject:
            return hash_
    return None


last_auto = find_last_auto_commit()

if not last_auto:
    # No baseline found — tell agent to process normally
    print("PROCESS")
    sys.exit(0)

# Check for non-auto commits since last agent run
commits_since = git("log", "--format=%H|||%s", f"{last_auto}..HEAD")
user_commits = []
for line in commits_since.splitlines():
    if "|||" not in line:
        continue
    hash_, subject = line.split("|||", 1)
    if "vault: auto" not in subject and subject.strip():
        user_commits.append(hash_)

if not user_commits:
    print("SKIP")
    sys.exit(0)

# Get the diff of daily note files only
diff = git(
    "diff", last_auto, "HEAD", "--",
    "Daily/Life/Notes/", "Daily/Todo/"
)

if not diff.strip():
    print("SKIP")
    sys.exit(0)

print("PROCESS")
print(diff)
