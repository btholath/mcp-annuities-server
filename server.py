"""
MCP Annuities Server (FastMCP)
================================
Consolidated from two reference projects:
  1. MCP-Example-main      -> @mcp.tool() pattern, @mcp.resource() pattern
  2. mcp-prompt-templates  -> YAML-driven, file-based prompt templates

FIXES APPLIED vs the original tutorial code:
  - No hardcoded Windows paths (C:\\Users\\Arnold\\...) -> uses pathlib
    relative to this file, works on WSL/Linux/Mac/Windows.
  - Resource reads data/annuities.csv (ships with this repo) instead
    of a missing typesdk.md on someone's Desktop.
  - Prompt templates are loaded dynamically from templates/*/ (config.yaml +
    template.md), same pattern as mcp-prompt-templates-main, but using
    FastMCP's simpler @mcp.prompt() decorator instead of the low-level
    Server class (less boilerplate, easier to extend).
  - Kept the tool COUNT SMALL on purpose (5 tools) -- the transcript
    explicitly warns: "as soon as you add too many tools, your MCP
    server will no longer work correctly. The LLMs aren't smart enough
    to decide... leave it to the small side."

Tools exposed (5 - intentionally minimal):
  - get_client            : look up one client by ID
  - search_clients        : filter clients by simple criteria
  - portfolio_summary      : aggregate stats grouped by a column
  - calculate_payout       : simple amortized monthly payment calc
  - calculate_percentage   : small utility kept from the original calculator demo

Resources exposed:
  - annuities://dataset    : raw CSV content (so an LLM can read it directly)

Prompts exposed (loaded from templates/):
  - annuity_review   : structured suitability review of one client
  - client_summary   : plain-English summary for a client letter
  - portfolio_report : executive portfolio report template

Run (stdio, for MCP Inspector / Claude Code / Claude Desktop):
    python server.py

Debug interactively with MCP Inspector:
    npx @modelcontextprotocol/inspector python server.py
"""
from __future__ import annotations

import csv
import os
from pathlib import Path

import yaml
from mcp.server.fastmcp import FastMCP

# ── Paths (relative, cross-platform - this is the #1 fix vs the tutorial repo) ─
BASE_DIR = Path(__file__).parent
DATA_FILE = BASE_DIR / "data" / "annuities.csv"
TEMPLATES_DIR = BASE_DIR / "templates"

mcp = FastMCP("Annuities Server")


# ══════════════════════════════════════════════════════════════════════════════
# DATA HELPERS
# ══════════════════════════════════════════════════════════════════════════════

def _load_all() -> list[dict]:
    if not DATA_FILE.exists():
        return []
    with open(DATA_FILE, newline="") as f:
        return list(csv.DictReader(f))


# ══════════════════════════════════════════════════════════════════════════════
# RESOURCES  (pattern from MCP-Example-main's @mcp.resource, fixed path)
# ══════════════════════════════════════════════════════════════════════════════

@mcp.resource("annuities://dataset")
def get_dataset_resource() -> str:
    """
    Provides the full annuities.csv dataset as raw text.

    In the original tutorial this pointed at a hardcoded Windows desktop
    path (C:\\Users\\Arnold\\Desktop\\typesdk.md). Here it points at a
    real file shipped with this repo: data/annuities.csv.
    """
    if not DATA_FILE.exists():
        return (
            "Error: data/annuities.csv not found. "
            "Run `python data/generate_data.py` first."
        )
    return DATA_FILE.read_text()


# ══════════════════════════════════════════════════════════════════════════════
# TOOLS  (pattern from MCP-Example-main's @mcp.tool, kept deliberately small)
# ══════════════════════════════════════════════════════════════════════════════

@mcp.tool()
def get_client(client_id: str) -> dict:
    """
    Retrieve full annuity contract details for one client by ID.

    Args:
        client_id: e.g. "CLIENT_0001"
    """
    for row in _load_all():
        if row["client_id"] == client_id:
            return row
    return {"error": f"Client {client_id} not found"}


@mcp.tool()
def search_clients(
    product_type: str | None = None,
    risk_profile: str | None = None,
    state: str | None = None,
    min_premium: float | None = None,
    max_premium: float | None = None,
    limit: int = 10,
) -> list[dict]:
    """
    Search the annuity portfolio by optional filters (all ANDed together).

    Args:
        product_type: e.g. "Fixed", "Variable", "Indexed", "Immediate", "Deferred Income"
        risk_profile: "Conservative" | "Moderate" | "Aggressive"
        state: two-letter US state code, e.g. "CA"
        min_premium: minimum premium_amount
        max_premium: maximum premium_amount
        limit: maximum number of results (default 10)
    """
    rows = _load_all()
    if product_type:
        rows = [r for r in rows if r["product_type"] == product_type]
    if risk_profile:
        rows = [r for r in rows if r["risk_profile"] == risk_profile]
    if state:
        rows = [r for r in rows if r["state"] == state]
    if min_premium is not None:
        rows = [r for r in rows if float(r["premium_amount"]) >= min_premium]
    if max_premium is not None:
        rows = [r for r in rows if float(r["premium_amount"]) <= max_premium]
    return rows[:limit]


@mcp.tool()
def portfolio_summary(group_by: str) -> dict:
    """
    Return aggregate statistics for the portfolio, grouped by a column.

    Args:
        group_by: one of "product_type", "risk_profile", "state", "payment_frequency"
    """
    valid_cols = {"product_type", "risk_profile", "state", "payment_frequency"}
    if group_by not in valid_cols:
        return {"error": f"group_by must be one of {sorted(valid_cols)}"}

    summary: dict[str, dict] = {}
    for row in _load_all():
        key = row.get(group_by, "Unknown")
        bucket = summary.setdefault(key, {"count": 0, "total_premium": 0.0})
        bucket["count"] += 1
        bucket["total_premium"] += float(row["premium_amount"])

    for bucket in summary.values():
        bucket["avg_premium"] = round(bucket["total_premium"] / bucket["count"], 2)
        bucket["total_premium"] = round(bucket["total_premium"], 2)

    return summary


@mcp.tool()
def calculate_payout(principal: float, annual_rate_pct: float, term_years: int) -> dict:
    """
    Calculate the amortized monthly payment for an annuity payout phase.

    Args:
        principal: account value being annuitized (e.g. 100000)
        annual_rate_pct: annual crediting/interest rate as a percentage (e.g. 4.5)
        term_years: payout term in years (e.g. 10)
    """
    if term_years <= 0:
        return {"error": "term_years must be positive"}

    monthly_rate = (annual_rate_pct / 100) / 12
    n_payments = term_years * 12

    if monthly_rate == 0:
        monthly_payment = principal / n_payments
    else:
        monthly_payment = (
            principal
            * monthly_rate
            / (1 - (1 + monthly_rate) ** (-n_payments))
        )

    return {
        "monthly_payment": round(monthly_payment, 2),
        "total_payments": n_payments,
        "total_paid": round(monthly_payment * n_payments, 2),
    }


@mcp.tool()
def calculate_percentage(value: float, percentage: float) -> float:
    """
    Calculate a percentage of a value. (Small utility kept from the
    original calculator demo to show a trivial tool example.)

    Args:
        value: base value, e.g. 100000
        percentage: percent to apply, e.g. 5 (for 5%)
    """
    return round((value * percentage) / 100, 2)


# ══════════════════════════════════════════════════════════════════════════════
# PROMPTS  (pattern from mcp-prompt-templates-main, simplified with FastMCP)
# ══════════════════════════════════════════════════════════════════════════════

def _load_template(name: str) -> tuple[dict, str]:
    """Load config.yaml + template.md for a named template folder."""
    folder = TEMPLATES_DIR / name
    config = yaml.safe_load((folder / "config.yaml").read_text())
    template = (folder / "template.md").read_text()
    return config, template


def _fill(template: str, **kwargs: str) -> str:
    """Replace {{ var }} placeholders, same syntax as the original repos."""
    for key, value in kwargs.items():
        template = template.replace(f"{{{{ {key} }}}}", str(value))
    return template


@mcp.prompt("annuity_review")
def annuity_review_prompt(client_id: str) -> str:
    """
    Structured suitability review prompt for one client.

    Args:
        client_id: e.g. "CLIENT_0001". The client's full record is looked
            up automatically and injected into the template.
    """
    _, template = _load_template("annuity_review")
    record = get_client(client_id)
    return _fill(template, client_id=client_id, client_data=str(record))


@mcp.prompt("client_summary")
def client_summary_prompt(client_id: str) -> str:
    """
    Plain-English client letter summary prompt.

    Args:
        client_id: e.g. "CLIENT_0001".
    """
    _, template = _load_template("client_summary")
    record = get_client(client_id)
    return _fill(template, client_id=client_id, client_data=str(record))


@mcp.prompt("portfolio_report")
def portfolio_report_prompt(group_by: str = "product_type") -> str:
    """
    Executive portfolio report prompt, grouped by a chosen column.

    Args:
        group_by: "product_type" | "risk_profile" | "state" | "payment_frequency"
    """
    _, template = _load_template("portfolio_report")
    summary = portfolio_summary(group_by)
    return _fill(template, group_by=group_by, summary_data=str(summary))


# ══════════════════════════════════════════════════════════════════════════════
# ENTRY POINT
# ══════════════════════════════════════════════════════════════════════════════

if __name__ == "__main__":
    mcp.run()
