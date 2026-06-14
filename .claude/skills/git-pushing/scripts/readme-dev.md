# Make executable

chmod +x .claude/skills/git-pushing/scripts/smart_commit.sh

# Optional alias
# The script handles the entire flow: stages → asks Claude to write the message → commits with a  Co-Authored-By footer → pushes → prints a GitHub PR link if your remote is on GitHub.

echo 'alias smart-commit="bash .claude/skills/git-pushing/scripts/smart_commit.sh"' \

> > ~/.bashrc && source ~/.bashrc

# Use from any git project

cd ~/mcp-annuities-server
smart-commit



To actually trigger a commit, you need a real change in the repo. Try this:
bash# Make a small change — update the README with today's date
echo "" >> README.md
echo "<!-- Last updated: $(date '+%Y-%m-%d') -->" >> README.md

# Now run smart-commit
smart-commit



bijut@b:~/mcp-annuities-server$ echo "" >> README.md
echo "<!-- Last updated: $(date '+%Y-%m-%d') -->" >> README.md

# Now run smart-commit
smart-commit
echo "<-- See all tables with row Last updated: $(date '+%Y-%m-%d') -->" >> README.md
→  Branch: main
▸  Staging all changes...
→  Staged 9 file(s):
   .claude/skills/git-pushing/README.md
   .claude/skills/git-pushing/scripts/readme-dev.md
   .claude/skills/git-pushing/scripts/smart_commit.sh
   README.md
   docs/MCP-annuities-server.docx
   push-to-github.sh
   readme-commands.md
   readme-domain-2-MCP-integration.md
   readme-notes.md
▸  Asking Claude for a pirate commit message...
→  Claude says: docs(skill): ahoy! plundered git-pushing docs, arr matey!
▸  Creating commit...
[main 2ea1338] docs(skill): ahoy! plundered git-pushing docs, arr matey!
 9 files changed, 1426 insertions(+)
 create mode 100644 .claude/skills/git-pushing/README.md
 create mode 100644 .claude/skills/git-pushing/scripts/readme-dev.md
 create mode 100755 .claude/skills/git-pushing/scripts/smart_commit.sh
 create mode 100644 docs/MCP-annuities-server.docx
 create mode 100644 push-to-github.sh
 create mode 100644 readme-commands.md
 create mode 100644 readme-domain-2-MCP-integration.md
 create mode 100644 readme-notes.md
→  Commit created: 2ea1338 — docs(skill): ahoy! plundered git-pushing docs, arr matey!
▸  Pushing to origin/main...
Enumerating objects: 18, done.
Counting objects: 100% (18/18), done.
Delta compression using up to 14 threads
Compressing objects: 100% (14/14), done.
Writing objects: 100% (16/16), 99.58 KiB | 19.92 MiB/s, done.
Total 16 (delta 2), reused 0 (delta 0), pack-reused 0
remote: Resolving deltas: 100% (2/2), completed with 2 local objects.
To https://github.com/btholath/mcp-annuities-server.git
   2d2d94e..2ea1338  main -> main
→  Pushed to origin/main ✓

 .claude/skills/git-pushing/README.md               | 251 ++++++++++++++++
 .claude/skills/git-pushing/scripts/readme-dev.md   |  25 ++
 .claude/skills/git-pushing/scripts/smart_commit.sh | 219 ++++++++++++++
 README.md                                          |   2 +
 docs/MCP-annuities-server.docx                     | Bin 0 -> 85736 bytes
 push-to-github.sh                                  | 332 +++++++++++++++++++++
 readme-commands.md                                 | 306 +++++++++++++++++++
 readme-domain-2-MCP-integration.md                 | 138 +++++++++
 readme-notes.md                                    | 153 ++++++++++
 9 files changed, 1426 insertions(+)

⚠  Open PR → https://github.com/btholath/mcp-annuities-server.git/pull/new/main
bijut@b:~/mcp-annuities-server$ 
==========================================================