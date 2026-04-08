#!/usr/bin/env bash
# =============================================================================
# Obsidian Vault Setup Script
# Sets up the full second brain stack: repo, folders, dependencies, agents
# Run from any directory. Requires WSL2 (or native Linux/macOS).
# =============================================================================

set -euo pipefail

# --- Colors ------------------------------------------------------------------
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

info()    { echo -e "${CYAN}→${NC} $*"; }
success() { echo -e "${GREEN}✓${NC} $*"; }
warn()    { echo -e "${YELLOW}!${NC} $*"; }
error()   { echo -e "${RED}✗${NC} $*" >&2; exit 1; }
prompt()  { echo -e "${BOLD}$*${NC}"; }

echo ""
echo -e "${BOLD}=== Obsidian Second Brain — Setup ===${NC}"
echo ""

# =============================================================================
# 1. Dependencies
# =============================================================================

info "Checking dependencies..."

install_apt() {
  local pkg="$1"
  info "Installing $pkg..."
  sudo apt-get update -qq && sudo apt-get install -y "$pkg" -qq
}

# git
if ! command -v git &>/dev/null; then
  install_apt git
fi
success "git $(git --version | awk '{print $3}')"

# Node.js (LTS)
if ! command -v node &>/dev/null; then
  info "Installing Node.js LTS..."
  curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash - -qq
  install_apt nodejs
fi
success "node $(node --version)"

# Claude Code CLI
if ! command -v claude &>/dev/null; then
  info "Installing Claude Code..."
  npm install -g @anthropic-ai/claude-code --silent
fi
success "claude $(claude --version 2>/dev/null | head -1)"

# GitHub CLI
if ! command -v gh &>/dev/null; then
  info "Installing GitHub CLI..."
  curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg 2>/dev/null
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
    | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
  install_apt gh
fi
success "gh $(gh --version | head -1 | awk '{print $3}')"

echo ""

# =============================================================================
# 2. GitHub Auth
# =============================================================================

if ! gh auth status &>/dev/null; then
  info "Authenticating with GitHub (browser will open)..."
  gh auth login --web --git-protocol https
fi

GH_USER=$(gh api user --jq '.login')
GH_NAME=$(gh api user --jq '.name // .login')
success "GitHub: $GH_NAME ($GH_USER)"
echo ""

# =============================================================================
# 3. Claude Auth
# =============================================================================

if ! claude auth status &>/dev/null; then
  info "Signing in to Claude (browser will open)..."
  claude auth login
fi
success "Claude: signed in"
echo ""

# =============================================================================
# 4. Vault Configuration
# =============================================================================

prompt "Vault repo name (default: obsidian-vault):"
read -r REPO_NAME
REPO_NAME="${REPO_NAME:-obsidian-vault}"

DEFAULT_VAULT_PATH="$HOME/$REPO_NAME"
prompt "Install path (default: $DEFAULT_VAULT_PATH):"
read -r VAULT_PATH_INPUT
VAULT_PATH="${VAULT_PATH_INPUT:-$DEFAULT_VAULT_PATH}"
VAULT_PATH=$(eval echo "$VAULT_PATH")  # expand ~

if [ -d "$VAULT_PATH" ]; then
  warn "Directory already exists: $VAULT_PATH"
  prompt "Overwrite? (y/N)"
  read -r OVERWRITE
  [ "$OVERWRITE" = "y" ] || [ "$OVERWRITE" = "Y" ] || error "Aborting."
  rm -rf "$VAULT_PATH"
fi

echo ""
info "Creating GitHub repo $GH_USER/$REPO_NAME from template..."

# =============================================================================
# 5. Create Repo from Template
# =============================================================================

PARENT_DIR=$(dirname "$VAULT_PATH")
mkdir -p "$PARENT_DIR"
cd "$PARENT_DIR"

gh repo create "$REPO_NAME" \
  --template "LuisFTE/obsidian-vault-template" \
  --private \
  --description "Personal Obsidian second brain vault" \
  --clone

# gh clones into ./$REPO_NAME — rename if path differs
CLONED_NAME=$(basename "$REPO_NAME")
if [ "$PARENT_DIR/$CLONED_NAME" != "$VAULT_PATH" ]; then
  mv "$CLONED_NAME" "$VAULT_PATH"
fi

cd "$VAULT_PATH"

# Git identity
GH_EMAIL=$(gh api user --jq '.email // empty' 2>/dev/null || true)
git config user.name "$GH_NAME"
git config user.email "${GH_EMAIL:-vault@local}"

success "Vault cloned: $VAULT_PATH"
echo ""

# =============================================================================
# 6. ChatGPT Chats Folder
# =============================================================================

CHATS_DIR="$(dirname "$VAULT_PATH")/ChatGPT Chats/Archived"
mkdir -p "$CHATS_DIR"
success "Created: $CHATS_DIR"
echo ""

# =============================================================================
# 7. Fill Agent Prompts
# =============================================================================

info "Preparing agent prompts..."

GH_TOKEN=$(gh auth token)
FILLED_AGENTS=$(mktemp)

python3 - "$GH_TOKEN" "$GH_USER" "$REPO_NAME" "$FILLED_AGENTS" << 'PYEOF'
import sys, re

token, username, repo, outfile = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]

with open('AGENTS.md') as f:
    content = f.read()

# Replace placeholders
content = content.replace('YOUR_GITHUB_PAT', token)
content = content.replace('YOUR_USERNAME', username)
content = content.replace('YOUR_REPO', repo)
content = content.replace('YOUR_CCR_ENVIRONMENT_ID', 'default')

with open(outfile, 'w') as f:
    f.write(content)

print("Prompts filled.")
PYEOF

success "Agent prompts ready"
echo ""

# =============================================================================
# 8. Create RemoteTrigger Agents via Claude
# =============================================================================

info "Creating scheduled agents via Claude Code..."
echo ""

SETUP_PROMPT=$(cat << 'PROMPT_EOF'
You are setting up two scheduled vault agents. Read the AGENTS.md file at the path provided and create both RemoteTrigger agents exactly as documented there.

The file has already had all placeholders (YOUR_GITHUB_PAT, YOUR_USERNAME, YOUR_REPO) filled in with real values.

Create exactly these two agents:

Agent 1:
- Name: "Vault — Digest"
- Cron: "0 * * * *"
- Tools: Bash, Read, Write, Edit, Glob, Grep
- Prompt: the full text from the "Agent 1: Hourly Digest — Prompt" code block in the file

Agent 2:
- Name: "Vault — Daily Tasks + Weekly Review"
- Cron: "0 5 * * *"
- Tools: Bash, Read, Write, Edit, Glob, Grep, WebSearch
- Prompt: the full text from the "Agent 2: Daily Tasks + Weekly Review — Prompt" code block in the file

Read the file, extract each prompt, and create both RemoteTrigger agents now.
PROMPT_EOF
)

# Launch Claude to create the agents, pointing it at the filled AGENTS.md
claude -p "The filled AGENTS.md is at: $FILLED_AGENTS

$SETUP_PROMPT"

rm -f "$FILLED_AGENTS"

echo ""
success "Agents created"
echo ""

# =============================================================================
# 9. Done — Manual Steps
# =============================================================================

echo -e "${GREEN}${BOLD}=== Setup Complete ===${NC}"
echo ""
echo -e "${BOLD}Your vault:${NC} $VAULT_PATH"
echo -e "${BOLD}GitHub:${NC}    https://github.com/$GH_USER/$REPO_NAME"
echo -e "${BOLD}Chats:${NC}     $CHATS_DIR"
echo ""
echo -e "${BOLD}3 manual steps remaining:${NC}"
echo ""
echo -e "  1. ${YELLOW}Install Obsidian${NC}"
echo -e "     https://obsidian.md → open vault at: $VAULT_PATH"
echo ""
echo -e "  2. ${YELLOW}Install and configure plugins${NC}"
echo -e "     Follow: $VAULT_PATH/OBSIDIAN_SETUP.md"
echo ""
echo -e "  3. ${YELLOW}Fill in Now.md${NC}"
echo -e "     Open: $VAULT_PATH/_Index/Now.md"
echo -e "     Add your name, job, active projects, current goals, sprint info"
echo ""
echo -e "${CYAN}The hourly digest agent will start running automatically."
echo -e "Write your first daily note tomorrow and it will process it.${NC}"
echo ""
