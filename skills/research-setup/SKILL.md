---
name: research-setup
description: Research and evaluate new tooling (MCP servers, Claude Code skills/plugins, dev tools) for the setup, score candidates against the user's stack and profile, and record verdicts. Use when looking for a new tool to add to the kit.
---

# project-kit: Research a Setup Option

Turn "is there something better for X?" into a scored, recorded decision — and, when adopted,
into concrete wiring in the kit. This keeps the setup evolving instead of frozen.

## Stack & values to evaluate against
- **Stack**: uv-managed Python ≥3.11, beads for tracking, GitHub Actions CI, src layout.
- **Profile / values** (from github-map): applied ML + data engineering with **own data and
  Peruvian regional domain** as the differentiator; reproducibility; agentic dev (Claude Code + beads).
- **Already installed** (don't re-propose / weigh overlap): `superpowers`, `frontend-design`,
  `github-map` plugins; `playwright` + `context7` MCP servers.

## Workflow

1. **Restate the need** in one line, plus the constraint it must fit (e.g. "must work with uv", "stdio MCP").
2. **Research** with `WebSearch`/`WebFetch`: official MCP/plugin registries, GitHub repos, docs.
   Find 2–4 real candidates. Note maintenance signals (last release, stars, issues).
3. **Score** each candidate against github-map's rubric (`schema.md` in the github-map repo):
   weigh **market_fit**, **real_impact_potential**, **code_quality**, and **agentic_dev_level**
   as relevant — plus fit-to-profile and overlap with what's installed. Bias toward tools that
   raise the bar, not generic popularity.
4. **Record** a dated entry in `catalog/setup-options.md` (see its format) with a verdict:
   **adopt** / **trial** / **reject**, and a one-line rationale.
5. **If adopt, offer wiring.** Edit the **source repo**, never the installed plugin cache
   (`~/.claude/plugins/cache/...` is a copy that gets overwritten). Resolve the source via
   `${PROJECT_KIT_HOME:-$HOME/Code/project-kit}`. If that path isn't writable/available, emit a
   **unified diff** the user can apply with `git apply`. Typical targets:
   - add an MCP server to `templates/mcp.json.tmpl`
   - add a permission to `templates/claude-settings.local.json`
   - add a dependency to `templates/pyproject.toml.tmpl`
   - note a global install (marketplace add / plugin install) in `README.md`

## Notes
- Editing files in this repo requires a session restart before Claude Code picks up plugin changes.
- Prefer `trial` over `adopt` when a tool is promising but unproven in this stack — record why.
