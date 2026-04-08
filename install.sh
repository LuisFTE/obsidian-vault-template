#!/usr/bin/env bash
# =============================================================================
# Obsidian Vault Setup Script
# Safe to re-run — skips any step already completed.
# Requires WSL2 (or native Linux/macOS).
# =============================================================================

set -euo pipefail

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
prompt()  { echo -e "\n${BOLD}$*${NC}"; }
divider() { echo -e "\n${CYAN}────────────────────────────────────${NC}"; }

echo ""
echo -e "${BOLD}=== Obsidian Second Brain — Setup ===${NC}"
echo -e "${CYAN}Safe to re-run. Skips steps already completed.${NC}"
echo ""

# =============================================================================
# 1. Dependencies
# =============================================================================

divider
info "Checking dependencies..."
echo ""

install_apt() {
  sudo apt-get update -qq && sudo apt-get install -y "$1" -qq
}

if ! command -v git &>/dev/null; then
  info "Installing git..."
  install_apt git
fi
success "git $(git --version | awk '{print $3}')"

if ! command -v node &>/dev/null; then
  info "Installing Node.js LTS..."
  curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash - -qq
  install_apt nodejs
fi
success "node $(node --version)"

if ! command -v claude &>/dev/null; then
  info "Installing Claude Code CLI..."
  npm install -g @anthropic-ai/claude-code --silent
fi
success "claude $(claude --version 2>/dev/null | head -1)"

if ! command -v gh &>/dev/null; then
  info "Installing GitHub CLI..."
  curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg 2>/dev/null
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
    | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
  install_apt gh
fi
success "gh $(gh --version | head -1 | awk '{print $3}')"

# =============================================================================
# 2. GitHub Account + Auth
# =============================================================================

divider
echo ""
if ! gh auth status &>/dev/null; then
  echo -e "${BOLD}GitHub account required${NC}"
  echo "The vault lives in a private GitHub repo — it's how your phone, desktop,"
  echo "and AI agents all stay in sync."
  echo ""
  echo -e "  Don't have an account? Create a free one at ${CYAN}https://github.com/signup${NC}"
  echo ""
  read -rp $'\n[Press Enter to open GitHub in your browser...] '
  gh auth login --web --git-protocol https
fi

GH_USER=$(gh api user --jq '.login')
GH_NAME=$(gh api user --jq '.name // .login')
success "GitHub: $GH_NAME ($GH_USER)"

# =============================================================================
# 3. Claude Account + Auth
# =============================================================================

divider
echo ""
if ! claude auth status &>/dev/null; then
  echo -e "${BOLD}Claude account required${NC}"
  echo "The scheduled agents (hourly digest, daily tasks) run on Claude's servers."
  echo "This requires a ${BOLD}Claude Pro or Max${NC} subscription."
  echo ""
  echo -e "  No account? Sign up at ${CYAN}https://claude.ai${NC}"
  echo -e "  Already have free Claude? Upgrade at ${CYAN}https://claude.ai/upgrade${NC}"
  echo ""
  read -rp $'\n[Press Enter to open Claude in your browser...] '
  claude auth login
fi
success "Claude: signed in"

# =============================================================================
# 4. Vault Configuration
# =============================================================================

divider
echo ""
read -rp $'\n\033[1mVault repo name\033[0m (default: obsidian-vault): ' REPO_NAME
REPO_NAME="${REPO_NAME:-obsidian-vault}"

DEFAULT_VAULT_PATH="$HOME/$REPO_NAME"
read -rp $'\033[1mInstall path\033[0m (default: '"$DEFAULT_VAULT_PATH"'): ' VAULT_PATH_INPUT
VAULT_PATH="${VAULT_PATH_INPUT:-$DEFAULT_VAULT_PATH}"
VAULT_PATH=$(eval echo "$VAULT_PATH")

PARENT_DIR=$(dirname "$VAULT_PATH")
GH_EMAIL=$(gh api user --jq '.email // empty' 2>/dev/null || true)

# =============================================================================
# 5. Repo — Create or Resume
# =============================================================================

divider
echo ""

REPO_EXISTS=false
if gh repo view "$GH_USER/$REPO_NAME" &>/dev/null; then
  REPO_EXISTS=true
fi

if [ -d "$VAULT_PATH/.git" ]; then
  # Already cloned — just pull latest
  success "Vault already exists: $VAULT_PATH"
  info "Pulling latest changes..."
  git -C "$VAULT_PATH" pull --rebase
elif [ "$REPO_EXISTS" = true ]; then
  # Repo on GitHub but not cloned locally
  info "Repo exists on GitHub — cloning..."
  mkdir -p "$PARENT_DIR"
  git clone "https://github.com/$GH_USER/$REPO_NAME.git" "$VAULT_PATH"
  git -C "$VAULT_PATH" config user.name "$GH_NAME"
  git -C "$VAULT_PATH" config user.email "${GH_EMAIL:-vault@local}"
  success "Cloned: $VAULT_PATH"
else
  # Fresh setup — create repo from template and clone
  info "Creating repo $GH_USER/$REPO_NAME from template..."
  mkdir -p "$PARENT_DIR"
  cd "$PARENT_DIR"
  gh repo create "$REPO_NAME" \
    --template "LuisFTE/obsidian-vault-template" \
    --private \
    --description "Personal Obsidian second brain vault" \
    --clone
  CLONED_NAME=$(basename "$REPO_NAME")
  [ "$PARENT_DIR/$CLONED_NAME" != "$VAULT_PATH" ] && mv "$CLONED_NAME" "$VAULT_PATH"
  git -C "$VAULT_PATH" config user.name "$GH_NAME"
  git -C "$VAULT_PATH" config user.email "${GH_EMAIL:-vault@local}"
  success "Vault created: $VAULT_PATH"
fi

cd "$VAULT_PATH"

# =============================================================================
# 6. ChatGPT Chats Folder
# =============================================================================

CHATS_DIR="$(dirname "$VAULT_PATH")/ChatGPT Chats/Archived"
if [ ! -d "$CHATS_DIR" ]; then
  mkdir -p "$CHATS_DIR"
  success "Created: $CHATS_DIR"
else
  success "Chats folder: $CHATS_DIR"
fi

# =============================================================================
# 7. Scheduled Agents
# =============================================================================

divider
echo ""
info "Setting up scheduled agents..."

GH_TOKEN=$(gh auth token)
FILLED_AGENTS=$(mktemp)

python3 - "$GH_TOKEN" "$GH_USER" "$REPO_NAME" "$FILLED_AGENTS" << 'PYEOF'
import sys

token, username, repo, outfile = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]

with open('AGENTS.md') as f:
    content = f.read()

content = content.replace('YOUR_GITHUB_PAT', token)
content = content.replace('YOUR_USERNAME', username)
content = content.replace('YOUR_REPO', repo)
content = content.replace('YOUR_CCR_ENVIRONMENT_ID', 'default')

with open(outfile, 'w') as f:
    f.write(content)
PYEOF

echo ""
claude -p "You are setting up scheduled vault agents for a new user.

The filled AGENTS.md (with real PAT, username, repo already substituted) is at: $FILLED_AGENTS

First, list any existing RemoteTrigger agents. If agents named 'Vault — Digest' and 'Vault — Daily Tasks + Weekly Review' already exist, print 'Agents already configured' and stop.

If they do not exist, create both:

Agent 1:
- Name: Vault — Digest
- Cron: 0 * * * *
- Tools: Bash, Read, Write, Edit, Glob, Grep
- Prompt: full text of the Agent 1 code block in $FILLED_AGENTS

Agent 2:
- Name: Vault — Daily Tasks + Weekly Review
- Cron: 0 5 * * *
- Tools: Bash, Read, Write, Edit, Glob, Grep, WebSearch
- Prompt: full text of the Agent 2 code block in $FILLED_AGENTS"

rm -f "$FILLED_AGENTS"
success "Agents ready"

# =============================================================================
# 8. Fill in Now.md (skip if already done)
# =============================================================================

divider
echo ""

NOW_FILE="$VAULT_PATH/_Index/Now.md"
NOW_NEEDS_FILL=false
if grep -q "YYYY-MM-DD\|YOUR_USERNAME\|Name · Role" "$NOW_FILE" 2>/dev/null; then
  NOW_NEEDS_FILL=true
fi

if [ "$NOW_NEEDS_FILL" = true ]; then
  echo -e "${CYAN}Starting a Claude session to fill in your Now.md..."
  echo -e "Claude will ask you a few questions about yourself and set it up.${NC}"
  echo ""

  claude "You are helping a new user set up their Obsidian second brain vault.

Your only job right now is to fill in \`_Index/Now.md\` in the vault at: $VAULT_PATH

Read it first, then ask the user questions one section at a time — do not ask everything at once:

1. Who are you? (name, what you do, where you live — 1-2 sentences)
2. Do you work in sprints? If yes: sprint name, start date, end date, any active tickets right now.
3. What are you actively working on right now? (projects, rough status)
4. Quick life snapshot: finances, relationships, health — anything worth tracking?
5. Anything the AI agent should know every session? (tone preferences, recurring context)

Write each answer into Now.md immediately after receiving it. When all sections are filled:
- Replace all \`YYYY-MM-DD\` placeholders with today's date
- Replace \`Month YYYY\` in the H1 with the current month and year
- Replace \`YOUR_USERNAME/obsidian-vault\` with $GH_USER/$REPO_NAME

Then commit and push:
  cd $VAULT_PATH && git add _Index/Now.md && git commit -m 'vault: manual — fill Now.md on setup' && git push"
else
  success "Now.md already filled — skipping"
fi

# =============================================================================
# Done
# =============================================================================

divider
echo ""
echo -e "${GREEN}${BOLD}=== Setup Complete ===${NC}"
echo ""
echo -e "  ${BOLD}Vault:${NC}  $VAULT_PATH"
echo -e "  ${BOLD}GitHub:${NC} https://github.com/$GH_USER/$REPO_NAME"
echo -e "  ${BOLD}Chats:${NC}  $CHATS_DIR"
echo ""
echo -e "${BOLD}2 steps left (manual):${NC}"
echo ""
echo -e "  1. ${YELLOW}Install Obsidian${NC} → https://obsidian.md"
echo -e "     Open vault at: $VAULT_PATH"
echo ""
echo -e "  2. ${YELLOW}Install plugins${NC}"
echo -e "     Follow: $VAULT_PATH/OBSIDIAN_SETUP.md"
echo ""
echo -e "${CYAN}Agents start running automatically. Write your first daily note and they'll pick it up.${NC}"
echo ""
