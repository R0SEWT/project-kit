# Setup Options — Research Log

Append-only log of tooling evaluated for the kit. Newest first. Each entry is produced by the
`research-setup` skill. Verdicts: **adopt** (wire into the kit) · **trial** (use once, revisit) ·
**reject** (not a fit).

Format per entry:

```
## YYYY-MM-DD — <need>
- **Candidate**: <name> (<link>)
  - What it does: <one line>
  - Fit: <stack/profile fit, overlap notes>
  - Maintenance: <last release / activity>
  - Verdict: adopt | trial | reject — <rationale>
  - Wiring (if adopt): <what changed in templates/ or README>
```

---

<!-- entries below -->

## 2026-06-02 — an MCP for SQLite

Need: an MCP server to let Claude query a local SQLite DB. Constraint: must fit the local data
stack and run as a stdio server (like the existing playwright/context7 npx servers).

- **Candidate**: `jparkerweb/mcp-sqlite` — eQuill Labs (https://github.com/jparkerweb/mcp-sqlite)
  - What it does: full SQLite interaction — `list_tables`, `get_table_schema`, CRUD, raw `query`.
  - Runtime: Node/`npx` (matches the existing MCP pattern). stdio: yes.
  - Maintenance: v1.0.9 (2026-04-04), 107★, MIT — actively maintained.
  - Fit: clean, but **the stack is DuckDB/Parquet + Polars, not SQLite** (and beads uses dolt).
    Low default-fit; only useful in a project that actually ships a `.sqlite` file.
- **Candidate**: official `modelcontextprotocol/sqlite` reference server
  (https://glama.ai/mcp/servers/@modelcontextprotocol/sqlite)
  - What it does: SELECT/INSERT/UPDATE/DELETE, schema mgmt, `memo://insights` resource.
  - Fit: it's a reference/demo server; same SQLite-vs-DuckDB mismatch.
- **Verdict**: **trial** (per-project only, never in the default template) — if a project uses SQLite,
  add `jparkerweb/mcp-sqlite` to that project's `.mcp.json`. Do **not** wire into `templates/mcp.json.tmpl`.
- **Follow-up (higher value)**: research a **DuckDB MCP server** — that matches the real stack
  (DuckDB over parquet, `$SILVER`) and would be a stronger candidate for the template.
