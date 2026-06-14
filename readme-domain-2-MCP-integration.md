# 🎯 Recap: MCP Server End-to-End — What You Built & How to Run It

## ✅ Proof It Works

Your last session **succeeded**:

- `get_client` tool called → returned CLIENT_0001's full record, formatted as a table
- `calculate_payout` tool called → in progress when you exited
- Claude Code automatically picked the right tool based on natural language

That's the entire Domain 2 (MCP Integration) exam pattern, working live.

---

## 📖 The Journey — What Each Step Accomplished

| #   | What You Did                                                                | Why It Mattered                                                                                                                                             |
| --- | --------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1   | Built `server.py` with 5 tools, 1 resource, 3 prompts                       | Core MCP server (FastMCP)                                                                                                                                   |
| 2   | Ran `test_client.py` standalone                                             | Proved server logic works _without_ any AI involved                                                                                                         |
| 3   | (Optional) MCP Inspector                                                    | Visual debugging — you skipped this, that's fine                                                                                                            |
| 4   | `claude mcp add annuities-server -- $(realpath .venv/bin/python) server.py` | First attempt — **failed** because `realpath` followed the symlink to system Python (`/usr/bin/python3.12`), which doesn't have the `mcp`/`pyyaml` packages |
| 5   | `claude mcp remove` then re-add with `"$(pwd)/.venv/bin/python"`            | **Fixed** — `pwd` keeps the venv path intact, so the subprocess has access to installed packages                                                            |
| 6   | `claude mcp list` → `✔ Connected`                                           | Config saved to `~/.claude.json` (project-scoped)                                                                                                           |
| 7   | `claude` → model switched to **Opus 4.8 / API Usage Billing**               | Note: this session used your **API key**, not Pro subscription (see below)                                                                                  |
| 8   | Asked Claude to look up CLIENT_0001                                         | ✅ Worked — tool called, data returned, formatted nicely                                                                                                    |

---

## ⚠️ One Loose End: The Auth Warning Came Back

Notice it switched to **"Opus 4.8 · API Usage Billing"** instead of "Sonnet 4.6 · Claude Pro" from before. This means **this session is billing your API key**, not your Pro subscription — likely because `/mcp` → "MCP dialog dismissed" triggered a re-prompt that defaulted to API key.

To fix permanently:

```bash
claude /logout
claude
# When asked "use claude.ai account?" → say YES
# When asked "approve API key?" → say NO
```

---

## 🔁 The Complete End-to-End Command Sequence (Repeatable)

Save this as your "golden path" — run this any time to verify everything from scratch:

```bash
# ── 1. Activate environment ──────────────────────────────────
cd ~/mcp-annuities-server
source .venv/bin/activate

# ── 2. Standalone test (no AI, proves server logic) ──────────
python test_client.py

# ── 3. Check MCP registration status ─────────────────────────
claude mcp list
# Expect: annuities-server: .../.venv/bin/python server.py - ✔ Connected

# ── 4. Launch Claude Code ────────────────────────────────────
claude

# ── 5. Inside Claude Code, verify MCP loaded ─────────────────
/mcp

# ── 6. Test each capability with natural language ────────────
# Tool test:
Use the annuities-server to look up CLIENT_0001

# Tool chaining test:
Calculate the payout for CLIENT_0001 assuming a 10-year term

# Search/filter test:
Find Aggressive risk clients in CA with premium over 200000

# Aggregation test:
Give me a portfolio summary grouped by product_type

# Resource test:
Read the annuities dataset resource and tell me how many rows it has

# Prompt template test:
Use the annuity_review prompt for CLIENT_0050

# Prompt test #2:
Use the portfolio_report prompt grouped by state
```

---

## 🧠 What This Maps to on the Exam (Domain 2 — 18%)

| What You Did                                             | Exam Concept                                         |
| -------------------------------------------------------- | ---------------------------------------------------- |
| `@mcp.tool()` decorators                                 | Tool schema design                                   |
| stdio transport (`server.py` via subprocess)             | Local, single-client MCP deployment                  |
| `claude mcp add`                                         | MCP client configuration                             |
| 5-tool limit                                             | Tool boundary design — preventing reasoning overload |
| `@mcp.resource("annuities://dataset")`                   | MCP resources                                        |
| `@mcp.prompt(...)` + YAML templates                      | MCP prompt templates                                 |
| Claude auto-selecting `get_client` vs `calculate_payout` | Tool selection reasoning                             |

---

## 📝 Quick Reference Card — Save This

```
┌─────────────────────────────────────────────────────────┐
│  MCP ANNUITIES SERVER — QUICK START                       │
├─────────────────────────────────────────────────────────┤
│  cd ~/mcp-annuities-server && source .venv/bin/activate  │
│  python test_client.py        ← sanity check             │
│  claude mcp list               ← should show ✔ Connected │
│  claude                        ← launch                  │
│  /mcp                          ← verify in-session        │
│  "Use annuities-server to..."  ← natural language calls   │
└─────────────────────────────────────────────────────────┘

Fix auth (if Opus/API billing instead of Pro):
  claude /logout → re-login → choose claude.ai, decline API key
```

---

## 🎓 What's Next in Your Study Plan

You've now completed **Domain 2 hands-on practice**. Suggested next:

```bash
# Domain 1 - Hub-and-spoke (if not done yet)
python ../ccaf-annuities-lab/domain1_agentic_architecture/03_hub_and_spoke/orchestrator.py

# Domain 1 - Two-agent collaboration
python ../ccaf-annuities-lab/domain1_agentic_architecture/02_multi_agent/multi_agent.py
```

Or — **bonus exercise** — try extending `server.py` with a 6th tool and observe whether Claude's tool selection gets _less_ reliable. That's a live demo of the "tool boundary" concept the exam tests.
