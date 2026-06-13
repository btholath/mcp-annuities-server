"""
test_client.py
===============
A standalone MCP client (pattern from mcp-prompt-templates-main's client.py,
updated for FastMCP + modern mcp SDK) that:

  1. Launches server.py as a subprocess over stdio
  2. Lists available tools, resources, and prompts
  3. Calls one of each so you can verify everything works end-to-end
     WITHOUT needing Claude Desktop or Claude Code.

Run:
    python test_client.py
"""
import asyncio
import sys

from mcp import ClientSession, StdioServerParameters
from mcp.client.stdio import stdio_client
from mcp.types import TextContent, TextResourceContents
from pydantic import AnyUrl


async def main() -> None:
    server_params = StdioServerParameters(
        # Use the SAME interpreter running this script (so the venv's
        # `mcp` package is found by the subprocess too).
        command=sys.executable,
        args=["server.py"],
    )

    async with stdio_client(server_params) as (read, write):
        async with ClientSession(read, write) as session:
            await session.initialize()

            # ── List capabilities ──────────────────────────────────────────
            tools = await session.list_tools()
            print("🔧 Tools:")
            for t in tools.tools:
                print(f"   - {t.name}: {t.description}")

            resources = await session.list_resources()
            print("\n📄 Resources:")
            for r in resources.resources:
                print(f"   - {r.uri}: {r.name}")

            prompts = await session.list_prompts()
            print("\n📝 Prompts:")
            for p in prompts.prompts:
                print(f"   - {p.name}: {p.description}")

            # ── Call a tool ────────────────────────────────────────────────
            print("\n" + "─" * 60)
            print("➡️  Calling tool: get_client(client_id='CLIENT_0001')")
            result = await session.call_tool("get_client", {"client_id": "CLIENT_0001"})
            for block in result.content:
                print(block.text if isinstance(block, TextContent) else block)

            # ── Call portfolio_summary ───────────────────────────────────────
            print("\n" + "─" * 60)
            print("➡️  Calling tool: portfolio_summary(group_by='risk_profile')")
            result = await session.call_tool("portfolio_summary", {"group_by": "risk_profile"})
            for block in result.content:
                print(block.text if isinstance(block, TextContent) else block)

            # ── Calculate payout ──────────────────────────────────────────
            print("\n" + "─" * 60)
            print("➡️  Calling tool: calculate_payout(principal=100000, annual_rate_pct=4.5, term_years=10)")
            result = await session.call_tool(
                "calculate_payout",
                {"principal": 100000, "annual_rate_pct": 4.5, "term_years": 10},
            )
            for block in result.content:
                print(block.text if isinstance(block, TextContent) else block)

            # ── Read a resource ───────────────────────────────────────────
            print("\n" + "─" * 60)
            print("➡️  Reading resource: annuities://dataset (first 200 chars)")
            res = await session.read_resource(AnyUrl("annuities://dataset"))
            for content in res.contents:
                text = content.text if isinstance(content, TextResourceContents) else str(content)
                print(text[:200] + "...")

            # ── Get a prompt ──────────────────────────────────────────────
            print("\n" + "─" * 60)
            print("➡️  Getting prompt: annuity_review(client_id='CLIENT_0001')")
            prompt_result = await session.get_prompt(
                "annuity_review", {"client_id": "CLIENT_0001"}
            )
            for message in prompt_result.messages:
                text = (
                    message.content.text
                    if isinstance(message.content, TextContent)
                    else message.content
                )
                print(text)


if __name__ == "__main__":
    asyncio.run(main())
