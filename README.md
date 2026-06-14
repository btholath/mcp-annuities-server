# MCP Annuities Server

**Consolidated & fixed from `MCP-Example-main` + `mcp-prompt-templates-main`**
For: VS Code + Claude Code on WSL/Ubuntu

> 📄 Open `README.html` in a browser for the full documentation with embedded architecture diagrams.

---

## What Was Fixed

| Issue in original repos                       | Fix applied                                           |
| --------------------------------------------- | ----------------------------------------------------- |
| Hardcoded `C:\Users\Bijut\Desktop\typesdk.md` | `Path(__file__).parent` — cross-platform              |
| Windows paths + `uv` in desktop config        | WSL-friendly `.venv/bin/python` absolute paths        |
| Two separate repos                            | Merged into one: 5 tools + 1 resource + 3 prompts     |
| Low-level `Server` class (verbose)            | FastMCP `@mcp.tool` / `@mcp.resource` / `@mcp.prompt` |
| No automated test                             | `test_client.py` — full end-to-end, no IDE needed     |
| `realpath` resolves symlink to system Python  | Use `$(pwd)/.venv/bin/python` in `claude mcp add`     |

**Key rule applied:** tool count kept to **5**. Too many tools breaks LLM tool-selection reliability.

---

## Project Structure

```
mcp-annuities-server/
├── CLAUDE.md
├── README.md                    ← this file
├── README.html                  ← full docs with diagrams (open in browser)
├── requirements.txt
├── server.py                    ← MCP server (5 tools + 1 resource + 3 prompts)
├── test_client.py               ← standalone end-to-end test
├── claude_desktop_config.example.json
├── .vscode/
│   └── mcp.json
├── data/
│   ├── annuities.csv            ← 500-row dataset
│   └── generate_data.py
└── templates/
    ├── annuity_review/          ← config.yaml + template.md
    ├── client_summary/
    └── portfolio_report/
```

---

## Setup

```bash
cd ~/mcp-annuities-server
python3 -m venv .venv
.venv/bin/pip install -r requirements.txt
.venv/bin/python data/generate_data.py
```

---

## Full Lifecycle — How a Request Flows

```
[1] User terminal (VS Code / WSL)
     │  Natural-language request typed
     ▼
[2] Claude Code reasoning (Sonnet / Opus)
     │  Matches request to tool schema
     │  Produces tool_use block: {name, arguments}
     ▼
[3] MCP stdio handshake
     │  JSON-RPC 2.0 sent over child process stdin
     │  Server lives in .venv/bin/python subprocess
     ▼
[4] FastMCP dispatch + validation
     │  Validates args against JSON Schema (from type hints)
     │  Routes to the matching @mcp.tool() function
     ▼
[5] Tool execution
     │  get_client: reads annuities.csv, returns matching row
     │  calculate_payout: amortization math, no data lookup
     ▼
[6] data/annuities.csv
     │  500 rows, 15 columns, all values stored as strings
     │
     └──► Result serialized → stdout → layers 4→3→2→1 → user
```

### Tool chaining (your session)

When you said "calculate the payout for this client", Claude Code
chained two tools without any orchestrator script:

```
"Calculate the payout..."
    → Call 1: get_client("CLIENT_0001")         [retrieves record]
    → Model extracts current_account_value + rate [type-converts strings]
    → Call 2: calculate_payout(principal, rate, term) [math]
    → Final answer combining both results
```

This is the live minimal version of Domain 1's agentic loop.

---

## Layer-by-Layer Explanations

### Layer 1 — User terminal

The terminal is just the I/O surface. All orchestration (deciding which
tool to call, building JSON-RPC, managing the subprocess) happens inside
the `claude` process, not in bash. Auth: use Claude Pro login (not API
key) to avoid extra billing. The ANTHROPIC_API_KEY env var set for your
Python lab scripts causes the "both auth methods" warning in Claude Code.

### Layer 2 — Claude Code reasoning

Tool selection is pure pattern matching against schema descriptions.
"look up CLIENT_0001" matches `get_client` because its description says
"Retrieve full annuity contract details for one client by ID". A vague
description causes wrong picks — this is the "tool boundary design"
Domain 2 exam concept. The model emits a `tool_use` block, Claude Code
intercepts it, sends to layer 3, and waits for the result before writing
the final answer.

### Layer 3 — MCP stdio handshake

Server.py is spawned ONCE as a child process at session start (not per
call). Three pipes wired: stdin (requests in), stdout (results out),
stderr (logs — never corrupts the protocol). JSON-RPC 2.0, newline-
delimited. The `✘ Failed to connect` happened because `realpath` resolved
the venv symlink to `/usr/bin/python3.12` (no mcp package) — `$(pwd)/
.venv/bin/python` keeps the venv path and the handshake succeeds.

### Layer 4 — FastMCP dispatch + validation

FastMCP's event loop reads each JSON-RPC line, dispatches on `method:
tools/call`, validates `arguments` against the auto-generated JSON Schema
(from type hints) before calling Python, serializes the return value into
a text content block, and writes the response to stdout. No print()
allowed in server.py — it would corrupt the stream.

### Layer 5 — Tool execution

`get_client`: linear scan of CSV, returns matching dict (all strings).
`calculate_payout`: amortization formula with zero-rate edge-case handler
and explicit input validation (returns structured error, not exception).
Both are pure functions with no side effects — safe for an LLM to call.

### Layer 6 — data/annuities.csv

500 rows, 15 columns (client_id, dob, age, product_type, premium_amount,
crediting_rate_pct, term_years, monthly_payment, surrender_charge_pct,
rider, risk_profile, state, payment_frequency, contract_start_date,
current_account_value). IMPORTANT: csv.DictReader returns ALL values as
strings — tools doing math must cast with float()/int(). Pydantic models
with typed fields do this automatically (Domain 4 connection).

---

## Step-by-Step: Wire into Claude Code

```bash
# 1. Standalone test (proves server logic, no AI)
.venv/bin/python test_client.py

# 2. MCP Inspector (visual debugging)
npx @modelcontextprotocol/inspector .venv/bin/python server.py

# 3. Register with Claude Code
claude mcp remove annuities-server  # if exists
claude mcp add annuities-server -- "$(pwd)/.venv/bin/python" server.py
claude mcp list
# → annuities-server: .../.venv/bin/python server.py - ✔ Connected

# 4. Fix auth (if showing Opus / API billing)
claude /logout
# → choose claude.ai YES, API key NO

# 5. Launch and test
claude
/mcp
"Use the annuities-server to look up CLIENT_0001"
```

---

## Tool / Resource / Prompt Reference

### Tools (5)

| Tool                   | Purpose            | Key args                                         |
| ---------------------- | ------------------ | ------------------------------------------------ |
| `get_client`           | Look up one client | `client_id`                                      |
| `search_clients`       | Filter portfolio   | `product_type`, `risk_profile`, `state`, `limit` |
| `portfolio_summary`    | Aggregate stats    | `group_by`                                       |
| `calculate_payout`     | Amortized payout   | `principal`, `annual_rate_pct`, `term_years`     |
| `calculate_percentage` | Utility math       | `value`, `percentage`                            |

### Resource

| URI                   | Content                 |
| --------------------- | ----------------------- |
| `annuities://dataset` | Raw CSV of all 500 rows |

### Prompts

| Prompt             | Purpose                | Args        |
| ------------------ | ---------------------- | ----------- |
| `annuity_review`   | Suitability assessment | `client_id` |
| `client_summary`   | Client letter          | `client_id` |
| `portfolio_report` | Executive report       | `group_by`  |

---

## CCAF Exam Domain Mapping

| What you built                         | Exam concept                       | Domain |
| -------------------------------------- | ---------------------------------- | ------ |
| `@mcp.tool()` with type hints          | Tool schema design                 | D2     |
| stdio subprocess transport             | Local MCP deployment               | D2     |
| `claude mcp add` with venv path        | MCP client configuration           | D2     |
| 5-tool limit                           | Tool boundary / reasoning overload | D2     |
| `@mcp.resource()`                      | Resources vs tools distinction     | D2     |
| YAML + `@mcp.prompt()`                 | MCP prompt templates               | D2     |
| get_client → calculate_payout chaining | Implicit task decomposition        | D1     |
| CLAUDE.md at project root              | CLAUDE.md hierarchy                | D3     |
| String CSV → Pydantic coercion         | Structured output enforcement      | D4     |
| JSON-RPC id correlation                | Context / multi-turn state         | D5     |

---

## Quick Reference

```bash
# Golden path
cd ~/mcp-annuities-server && source .venv/bin/activate
python test_client.py        # sanity check
claude mcp list              # ✔ Connected
claude                       # launch
/mcp                         # verify
"Use annuities-server to look up CLIENT_0001"

# Fix ✘ Failed to connect
claude mcp remove annuities-server
claude mcp add annuities-server -- "$(pwd)/.venv/bin/python" server.py

# Fix Opus / API billing instead of Pro
claude /logout → claude.ai YES → API key NO
```

<-- See all tables with row Last updated: 2026-06-13 -->
