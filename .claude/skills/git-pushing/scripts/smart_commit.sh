#!/usr/bin/env bash
# =============================================================================
# smart_commit.sh
# Location: ~/.claude/skills/git-pushing/scripts/smart_commit.sh
#
# Smart Git Commit Script — Claude Code Skill
# Stages, generates a Conventional Commit message (pirate flavour via Claude),
# commits, and pushes to the current branch.
#
# Usage:
#   bash smart_commit.sh [optional commit message]
#
# Examples:
#   bash smart_commit.sh                    # Claude generates the message
#   bash smart_commit.sh "fix(auth): patch" # Use your own message
#
# Requirements:
#   - git     (in PATH)
#   - claude  (Claude Code CLI, in PATH)
#   - An authenticated Claude Code session (claude.ai Pro or API key)
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

# ── Colours ───────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

info()  { echo -e "${GREEN}→${NC}  $*"; }
warn()  { echo -e "${YELLOW}⚠${NC}  $*"; }
error() { echo -e "${RED}✗${NC}  $*" >&2; }
step()  { echo -e "${CYAN}▸${NC}  $*"; }

# ── Preflight checks ──────────────────────────────────────────────────────────
require() {
  command -v "$1" >/dev/null 2>&1 || {
    error "'$1' not found in PATH. $2"
    exit 1
  }
}

require git    "Install: sudo apt-get install git"
require claude "Install: npm install -g @anthropic-ai/claude-code"

# Must be inside a git repo
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  error "Not inside a git repository. Run from your project root."
  exit 1
fi

# ── Detect current branch ─────────────────────────────────────────────────────
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
info "Branch: $CURRENT_BRANCH"

# ── Bail early if nothing to commit ───────────────────────────────────────────
if git diff --quiet && git diff --cached --quiet; then
  warn "No changes detected — nothing to commit."
  exit 0
fi

# ── Stage everything ──────────────────────────────────────────────────────────
step "Staging all changes..."
git add -A

STAGED_FILES=$(git diff --cached --name-only)
DIFF_STAT=$(git diff --cached --stat)
FILE_COUNT=$(echo "$STAGED_FILES" | grep -c . || true)

if [ "$FILE_COUNT" -eq 0 ]; then
  warn "Nothing staged after git add -A. Exiting."
  exit 0
fi

info "Staged $FILE_COUNT file(s):"
echo "$STAGED_FILES" | sed 's/^/   /'

# ── Determine Conventional Commit type ───────────────────────────────────────
determine_commit_type() {
  local files="$1"
  local diff_content="$2"

  if echo "$files" | grep -qiE "(test|spec)"; then
    echo "test"
  elif echo "$files" | grep -qiE "\.(md|txt|rst|adoc)$"; then
    echo "docs"
  elif echo "$files" | grep -qiE "(package\.json|requirements\.txt|Cargo\.toml|pyproject\.toml|go\.mod)$"; then
    echo "chore"
  elif echo "$diff_content" | grep -qE "^\+.*(fix|bug|patch|hotfix)"; then
    echo "fix"
  elif echo "$diff_content" | grep -qE "^\+.*(refactor|restructure|reorganize)"; then
    echo "refactor"
  else
    echo "feat"
  fi
}

# ── Determine scope (first meaningful directory or keyword) ──────────────────
determine_scope() {
  local files="$1"

  # Prefer known keywords
  for keyword in plugin skill agent api mcp auth data domain scripts; do
    if echo "$files" | grep -qi "$keyword"; then
      echo "$keyword"
      return
    fi
  done

  # Fall back to first directory component
  local first_dir
  first_dir=$(echo "$files" | head -1 | cut -d'/' -f1)
  if [ -n "$first_dir" ] && [ "$first_dir" != "." ] && [ "$first_dir" != "$files" ]; then
    echo "$first_dir"
    return
  fi

  echo ""   # no scope
}

# ── Build commit message ──────────────────────────────────────────────────────
DIFF_CONTENT=$(git diff --cached)
COMMIT_TYPE=$(determine_commit_type "$STAGED_FILES" "$DIFF_CONTENT")
SCOPE=$(determine_scope "$STAGED_FILES")

if [ -n "${1:-}" ]; then
  # ── Manual message supplied ─────────────────────────────────────────────
  COMMIT_MSG="$1"
  info "Using provided message: $COMMIT_MSG"
else
  # ── Ask Claude to write a pirate-flavoured Conventional Commit ──────────
  step "Asking Claude for a pirate commit message..."

  CLAUDE_PROMPT="You are a salty pirate who also happens to be a senior software engineer.

Write a Conventional Commit message for the git diff below.
Rules:
- Format: type(scope): description
- type must be one of: feat | fix | docs | chore | refactor | test
- Keep the full message under 72 characters
- Make the description sound like a pirate (arr, ahoy, matey, plunder, etc.)
- Output ONLY the commit message — no explanation, no markdown, no quotes

Context:
  Commit type : $COMMIT_TYPE
  Scope       : ${SCOPE:-none}
  Files       : $STAGED_FILES

Diff:
$DIFF_CONTENT"

  # Run claude -p (non-interactive print mode). Capture stderr separately
  # so a failed Claude call doesn't abort the script — we fall back below.
  PIRATE_MSG=$(claude -p "$CLAUDE_PROMPT" 2>/dev/null || true)

  # Strip leading/trailing whitespace and any surrounding quotes
  PIRATE_MSG=$(echo "$PIRATE_MSG" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' -e 's/^["'"'"']//' -e 's/["'"'"']$//')

  # Enforce 72-char hard cap
  PIRATE_MSG="${PIRATE_MSG:0:72}"

  if [ -n "$PIRATE_MSG" ]; then
    COMMIT_MSG="$PIRATE_MSG"
    info "Claude says: $COMMIT_MSG"
  else
    # Fallback if Claude CLI is unavailable or returned nothing
    warn "Claude did not respond — using fallback message."
    if [ -n "$SCOPE" ]; then
      COMMIT_MSG="${COMMIT_TYPE}(${SCOPE}): ahoy! plundered $FILE_COUNT file(s), arr!"
    else
      COMMIT_MSG="${COMMIT_TYPE}: ahoy! plundered $FILE_COUNT file(s), arr!"
    fi
    info "Fallback message: $COMMIT_MSG"
  fi
fi

# ── Commit ────────────────────────────────────────────────────────────────────
step "Creating commit..."
git commit -m "${COMMIT_MSG}

🤖 Generated with Claude Code (https://claude.ai/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"

COMMIT_HASH=$(git rev-parse --short HEAD)
info "Commit created: $COMMIT_HASH — $COMMIT_MSG"

# ── Push ──────────────────────────────────────────────────────────────────────
step "Pushing to origin/$CURRENT_BRANCH..."

PUSH_FLAGS=""
if ! git ls-remote --exit-code --heads origin "$CURRENT_BRANCH" >/dev/null 2>&1; then
  # Branch does not yet exist on remote — set upstream
  PUSH_FLAGS="-u"
  warn "New branch — will set upstream tracking."
fi

if git push $PUSH_FLAGS origin "$CURRENT_BRANCH"; then
  info "Pushed to origin/$CURRENT_BRANCH ✓"
  echo ""
  echo "$DIFF_STAT"
  echo ""

  # Offer a PR link when remote is GitHub
  REMOTE_URL=$(git remote get-url origin 2>/dev/null || true)
  if echo "$REMOTE_URL" | grep -q "github.com"; then
    REPO=$(echo "$REMOTE_URL" \
      | sed -E 's#.*github\.com[:/](.+?)(\.git)?$#\1#')
    warn "Open PR → https://github.com/$REPO/pull/new/$CURRENT_BRANCH"
  fi
else
  error "Push failed. Check your remote configuration and credentials."
  exit 1
fi

exit 0
