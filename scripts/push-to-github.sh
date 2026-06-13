#!/usr/bin/env bash
# =============================================================================
# push-to-github.sh
#
# Idempotent script to stage, commit (Conventional Commits), and push the
# mcp-annuities-server project to GitHub under the btholath account.
#
# Usage (run from the project root):
#   bash scripts/push-to-github.sh [REPO_NAME]
#
# Example:
#   bash scripts/push-to-github.sh mcp-annuities-server
#
# Prerequisites:
#   - git         → sudo apt-get install git
#   - gh CLI      → https://cli.github.com  then: gh auth login
# =============================================================================

set -euo pipefail

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
GITHUB_USER="btholath"
REPO_NAME="${1:-mcp-annuities-server}"
DEFAULT_BRANCH="main"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REMOTE_URL="https://github.com/${GITHUB_USER}/${REPO_NAME}.git"

REPO_DESCRIPTION="CCAF study lab: MCP server for retirement annuities data built with FastMCP + Python. Exposes 5 tools, 1 resource, and 3 YAML-driven prompt templates. Wired into Claude Code (stdio transport). Covers CCAF Domains 1-5."

TOPICS=(
  mcp model-context-protocol fastmcp
  claude-code anthropic ccaf
  python annuity retirement-planning fintech
  prompt-engineering agentic-ai
  wsl ubuntu vscode
)

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
log()  { echo "[INFO]  $*"; }
warn() { echo "[WARN]  $*" >&2; }
die()  { echo "[ERROR] $*" >&2; exit 1; }

require() {
  command -v "$1" >/dev/null 2>&1 || die "'$1' is required but not installed. $2"
}

# ---------------------------------------------------------------------------
# Preflight checks
# ---------------------------------------------------------------------------
require git "Install via: sudo apt-get install git"
require gh  "Install via: https://cli.github.com  →  gh auth login"

cd "$REPO_ROOT"
log "Working directory : $REPO_ROOT"
log "Target repository : https://github.com/${GITHUB_USER}/${REPO_NAME}"

# ---------------------------------------------------------------------------
# Verify this looks like the right project
# ---------------------------------------------------------------------------
if [[ ! -f "server.py" ]] || [[ ! -f "requirements.txt" ]]; then
  die "Expected to find server.py and requirements.txt in $REPO_ROOT. Are you running from the project root?"
fi

# ---------------------------------------------------------------------------
# Git init (idempotent)
# ---------------------------------------------------------------------------
if [[ ! -d ".git" ]]; then
  git init --initial-branch="$DEFAULT_BRANCH"
  log "Initialized new git repository."
else
  log "Git repository already initialized."
fi

# Set identity from global config (fall back to GitHub username)
GIT_NAME="$(git config --global user.name  2>/dev/null || echo "Biju Tholath")"
GIT_EMAIL="$(git config --global user.email 2>/dev/null || echo "${GITHUB_USER}@users.noreply.github.com")"
git config user.name  "$GIT_NAME"
git config user.email "$GIT_EMAIL"

# Ensure main branch
CURRENT_BRANCH="$(git symbolic-ref --short HEAD 2>/dev/null || echo "")"
if [[ "$CURRENT_BRANCH" != "$DEFAULT_BRANCH" ]]; then
  git checkout -B "$DEFAULT_BRANCH"
  log "Switched to branch '$DEFAULT_BRANCH'."
fi

# ---------------------------------------------------------------------------
# .gitignore — create / extend (never commit secrets or venv)
# ---------------------------------------------------------------------------
GITIGNORE_ENTRIES=(
  ".env"
  ".env.local"
  ".env*.local"
  "*.pem"
  ".DS_Store"
  ".venv/"
  "__pycache__/"
  "*.pyc"
  "*.pyo"
  ".pytest_cache/"
  "*.egg-info/"
  "dist/"
  "build/"
  "*.log"
)

for entry in "${GITIGNORE_ENTRIES[@]}"; do
  if ! grep -qxF "$entry" .gitignore 2>/dev/null; then
    echo "$entry" >> .gitignore
    log "Added '$entry' to .gitignore"
  fi
done

# ---------------------------------------------------------------------------
# Commit helper — only commits if there are staged changes
# ---------------------------------------------------------------------------
commit_if_staged() {
  local message="$1"
  if ! git diff --cached --quiet; then
    git commit -m "$message"
    log "Committed: $(echo "$message" | head -1)"
  else
    log "Nothing to commit for: $(echo "$message" | head -1)"
  fi
}

# ---------------------------------------------------------------------------
# Commit 1 — chore: project config and tooling
# ---------------------------------------------------------------------------
git add \
  .gitignore \
  requirements.txt \
  CLAUDE.md \
  .vscode/ \
  claude_desktop_config.example.json \
  2>/dev/null || true

commit_if_staged "chore: project configuration and tooling

- requirements.txt: mcp[cli]>=1.9.4, pyyaml>=6.0
- CLAUDE.md: project context for Claude Code (golden rules, tool-count limit)
- .vscode/mcp.json: Claude Code MCP server config using venv Python path
- claude_desktop_config.example.json: WSL-friendly desktop config example
- .gitignore: excludes .venv, __pycache__, .env, secrets"

# ---------------------------------------------------------------------------
# Commit 2 — feat: FastMCP server with tools, resource, and prompts
# ---------------------------------------------------------------------------
git add server.py 2>/dev/null || true

commit_if_staged "feat(server): FastMCP annuities server — 5 tools, 1 resource, 3 prompts

Tools (intentionally limited to 5 per transcript guidance):
  - get_client: look up one client by ID from annuities.csv
  - search_clients: filter by product_type/risk_profile/state/premium
  - portfolio_summary: aggregate stats grouped by a column
  - calculate_payout: amortized monthly payout (amortization formula)
  - calculate_percentage: simple percentage utility

Resource:
  - annuities://dataset: raw CSV served as text content

Prompts (YAML-driven, loaded from templates/):
  - annuity_review: structured suitability assessment
  - client_summary: plain-English client letter
  - portfolio_report: executive portfolio report

Transport: stdio (subprocess + JSON-RPC 2.0 over stdin/stdout)
Uses Path(__file__).parent for all file refs — no hardcoded OS paths"

# ---------------------------------------------------------------------------
# Commit 3 — feat: synthetic annuities dataset
# ---------------------------------------------------------------------------
git add data/ 2>/dev/null || true

commit_if_staged "feat(data): synthetic retirement annuities dataset (500 rows)

- generate_data.py: creates annuities.csv with random.seed(42)
- 15 columns: client_id, dob, age, product_type, premium_amount,
  crediting_rate_pct, term_years, monthly_payment, surrender_charge_pct,
  rider, risk_profile, state, payment_frequency, contract_start_date,
  current_account_value
- All CSV values stored as strings (csv.DictReader behaviour)
- Realistic ranges: premium 25k-500k, rate 2.5-6.5%, term 5/7/10/15/20yr
- Product types: Fixed, Variable, Indexed, Immediate, Deferred Income
- Risk profiles: Conservative, Moderate, Aggressive
- 10 US states, 3 payment frequencies, 5 rider types"

# ---------------------------------------------------------------------------
# Commit 4 — feat: YAML-driven prompt templates
# ---------------------------------------------------------------------------
git add templates/ 2>/dev/null || true

commit_if_staged "feat(templates): YAML-driven MCP prompt templates

Each template folder contains:
  - config.yaml: description, version, argument list with types
  - template.md: prompt body with {{ variable }} placeholders

Templates:
  - annuity_review/  : suitability + rate + surrender risk + recommendation
  - client_summary/  : plain-English annual statement letter
  - portfolio_report/: executive breakdown table by chosen dimension

Pattern: adding a new prompt = new folder only, no Python code changes needed"

# ---------------------------------------------------------------------------
# Commit 5 — test: standalone MCP test client
# ---------------------------------------------------------------------------
git add test_client.py 2>/dev/null || true

commit_if_staged "test: standalone MCP client for end-to-end server verification

- Launches server.py as stdio subprocess using sys.executable
  (ensures same venv Python is used — avoids the realpath/symlink trap)
- Lists all tools, resources, and prompts via MCP protocol
- Calls get_client, portfolio_summary, calculate_payout
- Reads annuities://dataset resource (prints first 200 chars)
- Triggers annuity_review prompt for CLIENT_0001
- No IDE or Claude Code required — pure MCP protocol test"

# ---------------------------------------------------------------------------
# Commit 6 — docs: README files
# ---------------------------------------------------------------------------
git add README.md README.html 2>/dev/null || true

commit_if_staged "docs: comprehensive README with architecture diagrams

README.md:
  - Full lifecycle flow (6-layer ASCII diagram)
  - Tool chaining explanation (get_client → calculate_payout)
  - Layer-by-layer explanations (terminal, Claude Code, stdio, FastMCP,
    tool execution, CSV structure)
  - Step-by-step Claude Code wiring guide with exact commands
  - Common failures and fixes (realpath trap, auth warning, Failed to connect)
  - CCAF exam domain mapping table (D1-D5)
  - Quick reference card

README.html:
  - Same content with embedded SVG architecture diagrams
  - Dark-themed layout with color-coded layer visualization
  - Open in browser: python3 -m http.server 8080 → localhost:8080/README.html"

# ---------------------------------------------------------------------------
# Commit 7 — chore: push script itself
# ---------------------------------------------------------------------------
mkdir -p scripts
# Copy this script into scripts/ if it isn't already there
SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"
TARGET_PATH="$REPO_ROOT/scripts/push-to-github.sh"
if [[ "$SCRIPT_PATH" != "$TARGET_PATH" ]]; then
  cp "$SCRIPT_PATH" "$TARGET_PATH"
  chmod +x "$TARGET_PATH"
  log "Copied script to scripts/push-to-github.sh"
fi

git add scripts/ 2>/dev/null || true
commit_if_staged "chore(scripts): add idempotent GitHub push script

- Conventional Commits across 7 logical layers
- Idempotent: safe to re-run without duplicate commits
- Creates GitHub repo via gh CLI if it doesn't exist
- Sets repository description and 13 topic tags automatically
- Preflight: verifies server.py + requirements.txt are present
- .gitignore: extended to exclude .venv, __pycache__, secrets"

# ---------------------------------------------------------------------------
# GitHub repository — create if it doesn't exist
# ---------------------------------------------------------------------------
if ! gh repo view "${GITHUB_USER}/${REPO_NAME}" &>/dev/null; then
  log "Creating GitHub repository: ${GITHUB_USER}/${REPO_NAME}"
  gh repo create "${GITHUB_USER}/${REPO_NAME}" \
    --public \
    --description "$REPO_DESCRIPTION"
  log "Repository created."
else
  log "Repository already exists: ${GITHUB_USER}/${REPO_NAME}"
fi

# ---------------------------------------------------------------------------
# Remote — configure if not set or wrong
# ---------------------------------------------------------------------------
if ! git remote get-url origin &>/dev/null; then
  git remote add origin "$REMOTE_URL"
  log "Remote 'origin' added: $REMOTE_URL"
else
  EXISTING_REMOTE="$(git remote get-url origin)"
  if [[ "$EXISTING_REMOTE" != "$REMOTE_URL" ]]; then
    git remote set-url origin "$REMOTE_URL"
    log "Remote 'origin' updated to: $REMOTE_URL"
  else
    log "Remote 'origin' already correct."
  fi
fi

# ---------------------------------------------------------------------------
# Push
# ---------------------------------------------------------------------------
log "Pushing to ${REMOTE_URL} ..."
git push -u origin "$DEFAULT_BRANCH"
log "Push complete."

# ---------------------------------------------------------------------------
# Set repository topics
# ---------------------------------------------------------------------------
TOPIC_ARGS=()
for topic in "${TOPICS[@]}"; do
  TOPIC_ARGS+=(--add-topic "$topic")
done

gh repo edit "${GITHUB_USER}/${REPO_NAME}" "${TOPIC_ARGS[@]}" \
  && log "Topics applied: ${TOPICS[*]}" \
  || warn "Topic update failed (check repo admin permissions)."

# ---------------------------------------------------------------------------
# Done
# ---------------------------------------------------------------------------
echo ""
echo "============================================================"
echo "  ✅ ${REPO_NAME} pushed to GitHub"
echo "  🔗 https://github.com/${GITHUB_USER}/${REPO_NAME}"
echo "============================================================"
echo ""
echo "Next steps:"
echo "  • Open the repo and verify all 7 commits landed cleanly"
echo "  • Add ANTHROPIC_API_KEY as a GitHub Actions secret if you"
echo "    plan to use the CI/CD review workflow from your CCAF lab"
echo "  • Star the repo and add it to your CV / LinkedIn 🎓"