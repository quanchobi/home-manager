"""Call one freecad-mcp tool over MCP stdio, outside the agent's MCP integration.

Usage (needs the `mcp` package; uv supplies it):
  uv run -q --with mcp python mcp_call.py list
  uv run -q --with mcp python mcp_call.py <tool> '<json args>'
  uv run -q --with mcp python mcp_call.py execute_code @script.py            # file -> {"code": ...}
  uv run -q --with mcp python mcp_call.py execute_code_headless @script.py

Images returned by the tool are written to $MCP_SHOT_DIR (default: cwd) as shot_<n>.png.
"""
import asyncio
import base64
import json
import os
import pathlib
import sys

from mcp import ClientSession, StdioServerParameters
from mcp.client.stdio import stdio_client


async def main() -> int:
    tool = sys.argv[1]
    arg = sys.argv[2] if len(sys.argv) > 2 else "{}"
    args = {"code": pathlib.Path(arg[1:]).read_text()} if arg.startswith("@") else json.loads(arg)
    shot_dir = pathlib.Path(os.environ.get("MCP_SHOT_DIR", "."))
    server = StdioServerParameters(command="uvx", args=["freecad-mcp"])
    async with stdio_client(server, errlog=open(os.devnull, "w")) as (r, w), ClientSession(r, w) as s:
        await s.initialize()
        if tool == "list":
            for t in (await s.list_tools()).tools:
                print(t.name, "-", (t.description or "").splitlines()[0])
            return 0
        res = await s.call_tool(tool, args)
        for i, c in enumerate(res.content):
            if c.type == "text":
                print(c.text)
            elif c.type == "image":
                out = shot_dir / f"shot_{i}.png"
                out.write_bytes(base64.b64decode(c.data))
                print(f"[image saved: {out.resolve()}]")
        # freecad-mcp reports failures in the text with is_error=False; detect them.
        texts = [c.text for c in res.content if c.type == "text"]
        failed = any(t.startswith("Failed") or " FAILED" in t.split("\n", 1)[0] for t in texts)
        return int(bool(failed or getattr(res, "is_error", None) or getattr(res, "isError", None)))


sys.exit(asyncio.run(main()))
