# git-pushing — Claude Code Skill

**Location:** `~/.claude/skills/git-pushing/`

A Claude Code skill that stages all changes, generates a pirate-flavoured
[Conventional Commit](https://www.conventionalcommits.org/) message using
the Claude CLI, commits, and pushes to the current branch — in one command.

---

## What it does

```
git add -A
    ↓
Analyse staged files (type + scope detection)
    ↓
Claude CLI generates a pirate Conventional Commit message
  (fallback: auto-generated message if Claude is unavailable)
    ↓
git commit -m "<message>" + Co-Authored-By: Claude footer
    ↓
git push  (sets -u on new branches)
    ↓
Print PR link if remote is GitHub
```

### Why pirate?

The pirate style is a learning aid — the unusual phrasing makes commit
messages memorable when reviewing history, and it demonstrates Claude
Code's `-p` (non-interactive print) mode in a fun, harmless way. Swap
the prompt inside `smart_commit.sh` to change the tone to anything you
like (professional, emoji-heavy, Shakespearean, etc.).

---

## Folder structure

```
~/.claude/skills/git-pushing/
├── README.md             ← this file
└── scripts/
    └── smart_commit.sh   ← the main script
```

---

## Requirements

| Tool | Purpose | Install |
|---|---|---|
| `git` | Version control | `sudo apt-get install git` |
| `claude` | Claude Code CLI | `npm install -g @anthropic-ai/claude-code` |
| Claude auth | Powers AI message generation | `claude /login` → choose claude.ai |

---

## Setup

```bash
# 1. Create the skill directory
mkdir -p ~/.claude/skills/git-pushing/scripts

# 2. Copy the script
cp smart_commit.sh ~/.claude/skills/git-pushing/scripts/smart_commit.sh

# 3. Make it executable
chmod +x ~/.claude/skills/git-pushing/scripts/smart_commit.sh

# 4. (Optional) add a shell alias for convenience
echo 'alias smart-commit="bash ~/.claude/skills/git-pushing/scripts/smart_commit.sh"' \
  >> ~/.bashrc && source ~/.bashrc
```

---

## Usage

```bash
# Run from any git repository root

# Let Claude generate the commit message (recommended)
bash ~/.claude/skills/git-pushing/scripts/smart_commit.sh

# Or: use the alias (after setup above)
smart-commit

# Or: supply your own message (skips Claude generation)
smart-commit "feat(api): add payout endpoint"
```

### Expected output

```
→  Branch: main
▸  Staging all changes...
→  Staged 3 file(s):
   server.py
   templates/annuity_review/template.md
   README.md
▸  Asking Claude for a pirate commit message...
→  Claude says: feat(server): ahoy! new payout tool plundered, arr!
▸  Creating commit...
→  Commit created: a3f92c1 — feat(server): ahoy! new payout tool plundered, arr!
▸  Pushing to origin/main...
→  Pushed to origin/main ✓

 3 files changed, 87 insertions(+), 2 deletions(-)
```

---

## How each part works

### 1. Preflight checks
The script verifies `git` and `claude` are in PATH, and that the current
directory is inside a git repository. If any check fails it exits with a
clear error message before touching anything.

### 2. Change detection
```bash
git diff --quiet && git diff --cached --quiet
```
Checks both unstaged and staged areas. Exits cleanly with a warning if
nothing has changed — no empty commits are created.

### 3. Staging
```bash
git add -A
```
Stages all changes: new files, modifications, and deletions. The original
script used `git add .` which misses deletions in some git versions;
`-A` is safer.

### 4. Commit type detection (`determine_commit_type`)
Scans staged filenames and the diff content to choose the right
Conventional Commit type:

| Pattern found | Type |
|---|---|
| `test`, `spec` in filename | `test` |
| `.md`, `.txt`, `.rst` extension | `docs` |
| `package.json`, `requirements.txt`, etc. | `chore` |
| `fix`, `bug`, `patch` in diff additions | `fix` |
| `refactor` in diff additions | `refactor` |
| anything else | `feat` |

### 5. Scope detection (`determine_scope`)
Scans filenames for known keywords (`plugin`, `skill`, `agent`, `api`,
`mcp`, `auth`, `data`, `domain`, `scripts`). Falls back to the first
directory component of the first staged file. If no scope can be
determined, scope is omitted from the commit message.

### 6. Claude message generation
```bash
claude -p "<prompt>"
```
`-p` runs Claude in non-interactive print mode — it prints one response
and exits. The prompt instructs Claude to output **only** the commit
message (no markdown, no explanation). The result is trimmed and capped
at 72 characters.

**Fallback:** if `claude -p` returns nothing (e.g. no network, auth
expired), the script auto-generates a safe message:
`feat(scope): ahoy! plundered N file(s), arr!`

### 7. Commit with Co-Authored-By footer
```
feat(server): ahoy! new payout tool plundered, arr!

🤖 Generated with Claude Code (https://claude.ai/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
```
The footer follows GitHub's co-author format so the commit shows as
co-authored by Claude in the repository's contributor graph.

### 8. Push with upstream detection
```bash
git ls-remote --exit-code --heads origin "$CURRENT_BRANCH"
```
Checks if the branch already exists on the remote. If not, adds `-u` to
set the upstream tracking reference (`git push -u origin <branch>`).

### 9. GitHub PR link
If the remote URL contains `github.com`, the script prints a direct link
to open a pull request for the pushed branch.

---

## Differences from the original script

| Issue in original | Fix applied |
|---|---|
| `set -e` only — no `set -u` or `set -o pipefail` | Changed to `set -euo pipefail` — catches unbound variables and pipe failures |
| `git add .` misses deletions | Changed to `git add -A` |
| Claude prompt used shell variable substitution without quoting | Variables wrapped in double-quotes; prompt passed as single argument |
| No hard limit on Claude output length (could produce >72 chars) | `PIRATE_MSG="${PIRATE_MSG:0:72}"` enforces the cap |
| `wc -l \| xargs` for file count is fragile on some platforms | Replaced with `grep -c .` with fallback |
| `sed` regex for GitHub URL extraction broke on SSH remotes | Updated regex handles both HTTPS and SSH remote formats |
| `$1` access without `:-` default causes unbound variable error with `set -u` | Changed to `${1:-}` throughout |
| No preflight check that `claude` CLI is installed | Added `require claude` check |
| No check that script runs inside a git repo | Added `git rev-parse --is-inside-work-tree` guard |

---

## Customising the commit style

To change from pirate to professional, edit the `CLAUDE_PROMPT` variable
in `smart_commit.sh`:

```bash
# Replace the pirate instruction with:
"Write a concise, professional Conventional Commit message for the git diff below.
Format: type(scope): description (under 72 characters)
Output only the commit message."
```

To use emoji prefixes:
```bash
"Write a Conventional Commit message with a relevant emoji prefix.
Example: ✨ feat(api): add payout endpoint
Output only the commit message, under 72 characters."
```

---

## CCAF exam relevance

This skill demonstrates several exam domains in a real script:

| Technique used | CCAF Domain |
|---|---|
| `claude -p` non-interactive mode | Domain 3 — Claude Code Workflows |
| Shell-level fallback when Claude unavailable | Domain 5 — Context Management & Reliability |
| Structured prompt with explicit output format | Domain 4 — Prompt Engineering |
| Conventional Commits structure | Domain 3 — CI/CD integration |
| Co-Authored-By footer | Domain 3 — Claude Code configuration |

---

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `claude: command not found` | Claude Code CLI not installed | `npm install -g @anthropic-ai/claude-code` |
| Claude returns empty message, fallback used | Auth expired or no network | `claude /login` to re-authenticate |
| `Push failed` | Remote credentials or branch protection | Check `git remote -v` and repo permissions |
| `Not inside a git repository` | Script run from wrong directory | `cd` to your project root first |
| SSH remote URL not parsed for PR link | Regex edge case | Open GitHub and navigate to the branch manually |
