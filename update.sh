#!/usr/bin/env bash
# =============================================================================
# Obsidian Vault — Update Script
# Pulls the latest system files from the template repo into your vault.
# Safe to run — never touches your personal notes or vault content.
# Run from inside your vault directory, or pass the vault path as an argument.
# =============================================================================

set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

info()    { echo -e "${CYAN}→${NC} $*"; }
success() { echo -e "${GREEN}✓${NC} $*"; }
warn()    { echo -e "${YELLOW}!${NC} $*"; }

TEMPLATE_REPO="https://github.com/LuisFTE/obsidian-vault-template.git"

# --- Locate vault ------------------------------------------------------------

VAULT_PATH="${1:-$(pwd)}"

if [ ! -f "$VAULT_PATH/_Index/Now.md" ]; then
  echo -e "${YELLOW}!${NC} Not a vault directory: $VAULT_PATH"
  echo "  Run from inside your vault, or: bash update.sh /path/to/vault"
  exit 1
fi

cd "$VAULT_PATH"
echo ""
echo -e "${BOLD}=== Vault Update ===${NC}"
echo -e "${CYAN}Vault:${NC} $VAULT_PATH"
echo ""

# --- Pull latest vault changes first -----------------------------------------

info "Pulling latest vault changes..."
git stash --quiet 2>/dev/null || true
git pull --rebase --quiet
git stash pop --quiet 2>/dev/null || true
success "Vault up to date"
echo ""

# --- Clone template to temp dir ----------------------------------------------

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

info "Fetching latest template..."
git clone --depth=1 "$TEMPLATE_REPO" "$TMPDIR/template" --quiet
success "Template fetched"
echo ""

# --- System files to update --------------------------------------------------
# These are safe to overwrite — they contain no personal data.

SYSTEM_FILES=(
  "_Templates"
  "scripts"
  "Claude - How to Process Daily Notes.md"
  "Claude - Vault Engineer Guide.md"
  "OBSIDIAN_SETUP.md"
)

info "Updating system files..."
CHANGED=()

for item in "${SYSTEM_FILES[@]}"; do
  SRC="$TMPDIR/template/$item"
  DST="$VAULT_PATH/$item"

  if [ ! -e "$SRC" ]; then
    warn "Not found in template: $item (skipping)"
    continue
  fi

  if [ -d "$SRC" ]; then
    # Directory — sync contents, keeping any extra files the user added
    if diff -rq --exclude=".gitkeep" "$SRC" "$DST" &>/dev/null 2>&1; then
      continue  # no changes
    fi
    cp -r "$SRC/." "$DST/"
    CHANGED+=("$item/")
  else
    # File — compare and copy if different
    if cmp -s "$SRC" "$DST" 2>/dev/null; then
      continue  # no changes
    fi
    cp "$SRC" "$DST"
    CHANGED+=("$item")
  fi
done

if [ ${#CHANGED[@]} -eq 0 ]; then
  success "All system files already up to date"
else
  for f in "${CHANGED[@]}"; do
    success "Updated: $f"
  done
fi
echo ""

# --- AGENTS.md — update prompt text, preserve credentials -------------------

TEMPLATE_AGENTS="$TMPDIR/template/AGENTS.md"
VAULT_AGENTS="$VAULT_PATH/AGENTS.md"

if [ -f "$VAULT_AGENTS" ] && [ -f "$TEMPLATE_AGENTS" ]; then
  info "Checking AGENTS.md..."

  # Extract existing credentials from the filled vault copy
  CREDS=$(python3 - "$VAULT_AGENTS" << 'PYEOF'
import re, sys

text = open(sys.argv[1]).read()
m = re.search(r'https://([^@\s]+)@github\.com/([^/\s]+)/([^.\s]+)\.git', text)
if m:
    token, username, repo = m.groups()
    print(f"{token}\n{username}\n{repo}")
else:
    print("\n\n")
PYEOF
  )

  GH_TOKEN=$(echo "$CREDS" | sed -n '1p')
  GH_USER=$(echo "$CREDS" | sed -n '2p')
  REPO_NAME=$(echo "$CREDS" | sed -n '3p')

  if [ -z "$GH_TOKEN" ] || [ -z "$GH_USER" ] || [ -z "$REPO_NAME" ]; then
    warn "Could not extract credentials from AGENTS.md — skipping agent update."
    warn "Your AGENTS.md was not changed. Update it manually if needed."
  elif cmp -s "$TEMPLATE_AGENTS" <(sed \
      -e "s/YOUR_GITHUB_PAT/$GH_TOKEN/g" \
      -e "s/YOUR_USERNAME/$GH_USER/g" \
      -e "s/YOUR_REPO/$REPO_NAME/g" \
      -e "s/YOUR_CCR_ENVIRONMENT_ID/default/g" \
      "$VAULT_AGENTS" 2>/dev/null) 2>/dev/null; then
    success "AGENTS.md already up to date"
  else
    # Fill new template with existing creds
    python3 - "$TEMPLATE_AGENTS" "$VAULT_AGENTS" "$GH_TOKEN" "$GH_USER" "$REPO_NAME" << 'PYEOF'
import sys

src, dst, token, username, repo = sys.argv[1:]
content = open(src).read()
content = content.replace('YOUR_GITHUB_PAT', token)
content = content.replace('YOUR_USERNAME', username)
content = content.replace('YOUR_REPO', repo)
content = content.replace('YOUR_CCR_ENVIRONMENT_ID', 'default')
open(dst, 'w').write(content)
PYEOF
    CHANGED+=("AGENTS.md")
    success "Updated: AGENTS.md (credentials preserved)"
    warn "Agent prompts changed — re-run the agents or update them at claude.ai/code"
  fi
  echo ""
fi

# --- Commit if anything changed ----------------------------------------------

if [ ${#CHANGED[@]} -eq 0 ]; then
  echo -e "${GREEN}${BOLD}Already up to date. Nothing to commit.${NC}"
  echo ""
  exit 0
fi

# Show diff before committing so user can see exactly what changed
info "Changes:"
echo ""
git add "${CHANGED[@]}"
git diff --cached --stat
echo ""
git diff --cached -- "${CHANGED[@]}" | head -120
echo ""

git commit -m "vault: manual — update system files from template" --quiet
git pull --rebase --quiet
git push --quiet

echo ""
echo -e "${GREEN}${BOLD}=== Update Complete ===${NC}"
echo ""
echo -e "Updated files:"
for f in "${CHANGED[@]}"; do
  echo -e "  ${CYAN}$f${NC}"
done
echo ""
