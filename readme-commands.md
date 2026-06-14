bijut@b:cd ~/mcp-annuities-server
python3 -m venv .venv
source .venv/bin/activate
.venv/bin/pip install -r requirements.txt

Note:
If found slow network timeout.
.venv/bin/pip install --default-timeout=180 -r requirements.txt
If it still times out on the same package, install it separately first then retry
.venv/bin/pip install --default-timeout=180 cryptography
.venv/bin/pip install --default-timeout=180 -r requirements.txt
pip caches what it already downloaded, so this will skip everything already fetched and just retry the failed package.

# 1. No-IDE smoke test

## runs the whole server standalone, no IDE needed. returns real client data, payout calcs, filled prompt templates).

.venv/bin/python test_client.py

# 2. Visual debugging

## 5 tools (get_client, search_clients, portfolio_summary, calculate_payout, calculate_percentage),

## 1 resource (annuities://dataset),

## 3 YAML-driven prompts — all using FastMCP decorators, no hardcoded paths.

npx @modelcontextprotocol/inspector .venv/bin/python server.py

Following site opened in browser
http://localhost:6274/?MCP_PROXY_AUTH_TOKEN=72b452e2d488d994cf4b77446b2dd80c8511d71aaf3e0a2ee491b5b186355153

Note:
templates/ — 3 prompt folders (annuity_review, client_summary, portfolio_report), each with config.yaml + template.md — same pattern just pointed at your data.

.vscode/mcp.json — Claude Code MCP config for this project.

CLAUDE.md — captures the transcript's key rule: keep tool count small.

# Step-by-Step: Wire the MCP Server into Claude Code

## Step 1 — generate data

(.venv) bijut@b:~/mcp-annuities-server$ .venv/bin/python data/generate_data.py
✅ Generated 500 rows → data/annuities.csv

## Step 2 — Get the absolute path to your venv's Python

(.venv) bijut@b:~/mcp-annuities-server$ realpath .venv/bin/python
/usr/bin/python3.12
/home/bijut/mcp-annuities-server/.venv/bin/python

## Step 3 — Edit .vscode/mcp.json with that exact path

nano .vscode/mcp.json

## Step 4 — Open the project in VS Code

code ~/mcp-annuities-server

## Step 5 — Open Claude Code's terminal panel and check MCP status

In the Claude Code chat/terminal, run:
/mcp

You should see annuities-server listed. If it shows an error, jump to Troubleshooting below.

## Step 6 — Restart Claude Code to load the server

Either:
Close and reopen the VS Code window, or
Run /mcp again — Claude Code usually picks up .vscode/mcp.json changes on the next session start.

Claude Code v2.1.172
▝▜█████▛▘ Sonnet 4.6 · Claude Pro
▘▘ ▝▝ ~/mcp-annuities-server

▎ [✻] [✻] [✻] · Share Claude Code and earn $20 in usage credits · /passes

- i.e Claude Code is now running on your Claude Pro subscription (not the API key), shown by the Sonnet 4.6 · Claude Pro

=====================================================================
Issue
▐▛███▜▌ Claude Code v2.1.172
▝▜█████▛▘ Sonnet 4.6 · Claude Pro
▘▘ ▝▝ ~/mcp-annuities-server

▎ [✻] [✻] [✻] · Share Claude Code and earn $20 in usage credits · /passes

❯ /mcp
⎿ No MCP servers configured. Please run /doctor if this is unexpected. Otherwise, run claude mcp --help or visit https://code.claude.com/docs/en/mcp to learn more.

Solution:
Claude Code CLI doesn't read `.vscode/mcp.json` (that's a VS Code-specific format) — it uses its own config. Let's add the server properly via the CLI:

## Step 1 — Add the MCP server using `claude mcp add`

From inside `~/mcp-annuities-server`:

```bash
claude mcp add annuities-server -- $(realpath .venv/bin/python) server.py
```

This creates a `.mcp.json` file in the project root with the correct config and absolute paths.

## Step 2 — Verify it was added

```bash
claude mcp list
```

You should see `annuities-server` listed.

## Step 3 — Restart Claude Code and check again

Exit Claude Code (`Ctrl+D` or `/exit`), then:

```bash
claude
```

Then run:

```
/mcp
```

It should now show `annuities-server` as connected.

## Step 4 — Test it

```
Use the annuities-server tools to look up CLIENT_0001
```

---

**If `/mcp` still shows nothing after this**, check the generated config:

```bash
cat .mcp.json
```

and verify the python path is correct and absolute. You can also run `/doctor` inside Claude Code as it suggested — it'll diagnose MCP config issues directly.

remove and re-add with the correct path
bash# Remove the broken entry
claude mcp remove annuities-server

# Re-add using pwd instead of realpath (doesn't follow the symlink)

claude mcp add annuities-server -- "$(pwd)/.venv/bin/python" server.py

ijut@b:~/mcp-annuities-server$ # Remove the broken entry
claude mcp remove annuities-server

# Re-add using pwd instead of realpath (doesn't follow the symlink)

claude mcp add annuities-server -- "$(pwd)/.venv/bin/python" server.py
Removed MCP server "annuities-server" from local config
File modified: /home/bijut/.claude.json [project:
/home/bijut/mcp-annuities-server]
Added stdio MCP server annuities-server with command: /home/bijut/mcp-annuities-server/.venv/bin/python server.py to local config
File modified: /home/bijut/.claude.json [project: /home/bijut/mcp-annuities-server]
bijut@b:~/mcp-annuities-server$ claude mcp list
annuities-server: /home/bijut/mcp-annuities-server/.venv/bin/python server.py

- ✔ Connected
  bijut@b:~/mcp-annuities-server$

Claude Code stored it in ~/.claude.json (project-scoped "local config") instead of a .mcp.json file. Both are valid; .mcp.json is only used when you want to share the config via git. Since claude mcp list shows ✔ Connected, the config is working correctly as-is.
Now just start Claude Code and use it:
claude
Then:
/mcp
You should see annuities-server listed with its 5 tools, 1 resource, and 3 prompts. Then test:
Use the annuities-server tools to look up CLIENT_0001
If you ever want to inspect the saved config directly:
bashcat ~/.claude.json | python3 -m json.tool | grep -A 5 annuities-server
But that's optional — you're ready to use it now.

/mcp

──────────────────────────────────────────────────────────────────────────────
Manage MCP servers
1 server

    Local    (/home/bijut/.claude.json [project:
    MCPs    /home/bijut/mcp-annuities-server])

❯ annuities-server · ✔ connected · 5 tools

https://code.claude.com/docs/en/mcp for help
↑/↓ to navigate · Enter to confirm · Esc to cancel

❯ /mcp
⎿ MCP dialog dismissed

❯ Use the annuities-server tools to look up CLIENT_0001

● I'll look up CLIENT_0001 using the annuities-server tools. Let me load the tool schema first.

Called annuities-server (ctrl+o to expand)

● Here are the full contract details for CLIENT_0001:

┌───────────────────────┬─────────────────────┐
│ Field │ Value │
├───────────────────────┼─────────────────────┤
│ Date of Birth │ 1969-05-05 (Age 57) │
├───────────────────────┼─────────────────────┤
│ Product Type │ Fixed │
├───────────────────────┼─────────────────────┤
│ Premium Amount │ $77,882.26 │
├───────────────────────┼─────────────────────┤
│ Current Account Value │ $83,588.87 │
├───────────────────────┼─────────────────────┤
│ Crediting Rate │ 5.47% │
├───────────────────────┼─────────────────────┤
│ Term │ 7 years │
├───────────────────────┼─────────────────────┤
│ Monthly Payment │ $1,118.06 │
├───────────────────────┼─────────────────────┤
│ Payment Frequency │ Quarterly │
├───────────────────────┼─────────────────────┤
│ Surrender Charge │ 2.23% │
├───────────────────────┼─────────────────────┤
│ Rider │ None │
├───────────────────────┼─────────────────────┤
│ Risk Profile │ Conservative │
├───────────────────────┼─────────────────────┤
│ State │ CO │
├───────────────────────┼─────────────────────┤
│ Contract Start Date │ 2010-09-18 │
└───────────────────────┴─────────────────────┘

A few quick observations: this is a Fixed annuity with a Conservative risk profile and no rider. The
account value ($83,588.87) has grown about 7.3% above the original premium ($77,882.26). Note that the
payment frequency is listed as Quarterly while there's also a "monthly payment" field — let me know if
you'd like me to calculate the payout, look up other clients, or run a portfolio summary.

✻ Crunched for 13s

─────────────────────────────────────────────────────────────────────────────────────────────────────────────
❯ calculate the payout for this client
─────────────────────────────────────────────────────────────────────────────────────────────────────────────
? for shortcuts · ← for agents

==================================================================
Issue:
Both claude.ai and ANTHROPIC_API_KEY set · auth may not work as expected
· to use claude.ai: Unset the ANTHROPIC_API_KEY environment variable, or claude /logout then say "No" to the API key approval before login.
· to use ANTHROPIC_API_KEY: claude /logout to sign out of claude.ai.

Solution:
This warning means Claude Code found **two** auth methods configured at once and isn't sure which to use:

1. A claude.ai login session (from when you ran `claude login` or similar)
2. An `ANTHROPIC_API_KEY` environment variable (which you set earlier for your Python scripts)

## Which one should you use?

| Method                | Cost                                           | Used for                                                                 |
| --------------------- | ---------------------------------------------- | ------------------------------------------------------------------------ |
| **claude.ai login**   | Included in your Claude subscription (Pro/Max) | Claude Code interactive sessions                                         |
| **ANTHROPIC_API_KEY** | Pay-per-token via API billing                  | Your Python scripts in `ccaf-annuities-lab/` AND Claude Code if no login |

**Recommendation: use claude.ai login for Claude Code** (no extra cost if you have a subscription), and **keep the API key only for your Python scripts**.

## Fix — Option A (recommended): Use claude.ai subscription for Claude Code

The key insight: your shell's `ANTHROPIC_API_KEY` env var is global, but you only need it when running your Python scripts. **Unset it for Claude Code sessions**, set it only when running Python:

```bash
# Remove it from your shell startup if you added it there
nano ~/.bashrc
# delete or comment out the line: export ANTHROPIC_API_KEY="..."
```

Then for Claude Code:

```bash
unset ANTHROPIC_API_KEY
claude
```

When running your CCAF Python scripts, set it just for that command:

```bash
ANTHROPIC_API_KEY="sk-ant-..." python domain1_agentic_architecture/01_single_agent/agent.py
```

Or keep it in `.env` (already set up in your lab) and load it per-script with `python-dotenv` — that way it never pollutes your shell environment at all.

## Fix — Option B: Use API key for everything

```bash
claude /logout
# When prompted "use API key?", say Yes
```

This means Claude Code usage gets billed to your API account (separate from any Claude.ai subscription).

---

# **For your setup** (CCAF lab + Claude Code), Option A is better — Claude Code rides on your subscription (free-ish), and your Python scripts use the API key only when needed via `.env`.
