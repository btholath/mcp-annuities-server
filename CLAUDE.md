# MCP Annuities Server — CLAUDE.md

## What This Project Is
A small, FastMCP-based MCP server exposing annuity-domain tools,
one resource, and three YAML-driven prompt templates. Built from two
reference repos (MCP-Example-main + mcp-prompt-templates-main),
consolidated and fixed for cross-platform (WSL/Linux) use.

## Golden Rules (from the course transcript)
- Keep the TOOL COUNT SMALL. We have 5 on purpose. Don't add more without
  good reason — too many tools confuses the LLM's tool-selection reasoning.
- No hardcoded absolute paths. Everything is relative to `Path(__file__).parent`.
- Prompts are data-driven: adding a new prompt = new folder under `templates/`
  with `config.yaml` + `template.md`. No new Python code required.

## How to Test (in order)
1. `python test_client.py` — standalone, no IDE needed. Proves the server works.
2. `npx @modelcontextprotocol/inspector python server.py` — visual debugging UI.
3. Wire into Claude Code via `.vscode/mcp.json` (already configured for this repo).

## Adding a New Tool
```python
@mcp.tool()
def your_tool(param: float) -> dict:
    """One-line description Claude will see."""
    ...
```
Add it to `server.py`, keep total tool count ≤ ~7.

## Adding a New Prompt Template
1. `mkdir templates/your_prompt`
2. Create `config.yaml` (description, version, arguments list)
3. Create `template.md` with `{{ variable }}` placeholders
4. Add a thin `@mcp.prompt("your_prompt")` wrapper in `server.py` that
   loads the template and fills in variables (copy the pattern from
   `annuity_review_prompt`).
