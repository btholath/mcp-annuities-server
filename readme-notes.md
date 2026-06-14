Now let me build the consolidated, fixed, WSL-ready project. First the corrected server (combining the calculator/tools pattern from MCP-Example with the YAML prompt-template pattern from mcp-prompt-templates, applied to your annuities domain):Now the prompt templates:Now the test client, requirements, configs, and README:Now let's actually test it to make sure it runs:Server imports cleanly. Now run the full test client end-to-end:Need to use the venv's Python interpreter for the subprocess. Let me fix `test_client.py`:Everything works end-to-end. Now package it up:## Summary

The transcript and both uploaded repos are about building an MCP server (tools + resources + prompts) and testing it with the Inspector before wiring it into Claude. The two repos demonstrated two halves of that: `MCP-Example-main` showed `@mcp.tool`/`@mcp.resource` with a calculator, but had hardcoded Windows paths (`C:\Users\Arnold\Desktop\...`) that won't work on WSL. `mcp-prompt-templates-main` showed YAML-driven prompt templates but used verbose low-level `Server` class code.

**I merged both into one working project**, applied to your annuities dataset, fixed for WSL/Linux paths, and verified it actually runs end-to-end (output above shows real results).

### What's in the zip

- **`server.py`** — 5 tools (`get_client`, `search_clients`, `portfolio_summary`, `calculate_payout`, `calculate_percentage`), 1 resource (`annuities://dataset`), 3 YAML-driven prompts — all using `FastMCP` decorators, no hardcoded paths.
- **`test_client.py`** — runs the whole server standalone, no IDE needed. **I already ran this and it works** (returns real client data, payout calcs, filled prompt templates).
- **`templates/`** — 3 prompt folders (`annuity_review`, `client_summary`, `portfolio_report`), each with `config.yaml` + `template.md` — same pattern as the original repo, just pointed at your data.
- **`.vscode/mcp.json`** — Claude Code MCP config for this project.
- **`CLAUDE.md`** — captures the transcript's key rule: keep tool count small.

### Test order (matches the transcript's advice)

```bash
unzip mcp-annuities-server.zip && cd mcp-annuities-server
python3 -m venv .venv
.venv/bin/pip install -r requirements.txt

# 1. No-IDE smoke test
.venv/bin/python test_client.py

# 2. Visual debugging
npx @modelcontextprotocol/inspector .venv/bin/python server.py

# 3. Then wire into Claude Code via .vscode/mcp.json
```

One thing to watch in step 3: point `.vscode/mcp.json`'s `command` at your venv's Python (`/home/YOUR_USERNAME/mcp-annuities-server/.venv/bin/python`) — that's the bug that originally broke `test_client.py` too (subprocess used system Python, not the venv with `mcp` installed).

## Step-by-Step: Wire the MCP Server into Claude Code

### Step 1 — Unzip and set up the venv (if not done already)

```bash
cd ~
unzip mcp-annuities-server.zip
cd mcp-annuities-server

python3 -m venv .venv
.venv/bin/pip install -r requirements.txt
.venv/bin/python data/generate_data.py
```

### Step 2 — Get the absolute path to your venv's Python

```bash
realpath .venv/bin/python
```

Copy that output — it'll look like:

```
/home/bijut/mcp-annuities-server/.venv/bin/python
```

### Step 3 — Edit `.vscode/mcp.json` with that exact path

```bash
nano .vscode/mcp.json
```

Replace the contents with (paste YOUR path from Step 2):

```json
{
  "mcpServers": {
    "annuities-server": {
      "command": "/home/bijut/mcp-annuities-server/.venv/bin/python",
      "args": ["server.py"],
      "cwd": "/home/bijut/mcp-annuities-server"
    }
  }
}
```

Save: `Ctrl+O` → Enter → `Ctrl+X`

### Step 4 — Open the project in VS Code

```bash
code ~/mcp-annuities-server
```

### Step 5 — Open Claude Code's terminal panel and check MCP status

In the Claude Code chat/terminal, run:

```
/mcp
```

You should see `annuities-server` listed. If it shows an error, jump to Troubleshooting below.

### Step 6 — Restart Claude Code to load the server

Either:

- Close and reopen the VS Code window, **or**
- Run `/mcp` again — Claude Code usually picks up `.vscode/mcp.json` changes on the next session start.

### Step 7 — Test it with a prompt

In Claude Code, type:

```
Use the annuities-server tools to look up CLIENT_0001 and give me a portfolio summary grouped by risk_profile.
```

Claude Code should call `get_client` and `portfolio_summary` and show you tool-call results inline — same data you saw from `test_client.py`.

### Step 8 — Try the prompts

```
Use the annuity_review prompt for CLIENT_0001
```

---

## Troubleshooting

| Symptom                             | Fix                                                                                               |
| ----------------------------------- | ------------------------------------------------------------------------------------------------- |
| `/mcp` shows nothing                | Confirm `.vscode/mcp.json` is valid JSON (run `cat .vscode/mcp.json \| python3 -m json.tool`)     |
| Server listed but errors on connect | The `command` path is wrong — re-run `realpath .venv/bin/python` and re-check Step 3              |
| "ModuleNotFoundError: mcp"          | You're pointing at system Python, not the venv — same bug as `test_client.py` originally had      |
| Tools listed but calls fail         | Run `.venv/bin/python test_client.py` again to confirm the server itself still works in isolation |
| Path has spaces (unlikely on Linux) | Wrap in quotes inside the JSON string — JSON strings handle spaces fine, no extra escaping needed |

---

## Quick Sanity Check Command

If you want to confirm the exact command Claude Code will run, just execute it manually:

```bash
/home/bijut/mcp-annuities-server/.venv/bin/python /home/bijut/mcp-annuities-server/server.py
```

It should hang silently (waiting for stdio input) — that's correct, it means the server started fine. `Ctrl+C` to exit.


README.md — plain-text version with the same complete content, for GitHub rendering and terminal reading (cat README.md).
To open the HTML version after unzipping in WSL:
bashcd ~/mcp-annuities-server
# Open in Windows browser from WSL:
explorer.exe README.html

# Or start a quick local server:
python3 -m http.server 8080
# Then open http://localhost:8080/README.html in your browser