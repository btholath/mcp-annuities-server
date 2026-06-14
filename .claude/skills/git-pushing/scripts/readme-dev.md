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
