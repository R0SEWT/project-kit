# project-kit

A Claude Code **plugin + marketplace** that bootstraps a new project with the standard setup —
**beads** (issue tracking), **uv** (Python), twin **CLAUDE.md**/**AGENTS.md** instruction files,
and **GitHub Actions CI** — and gives a repeatable way to **research new tooling** for that setup.

The defaults encode the github-map profile: an applied-ML / data-engineering archetype, agentic dev
(beads + Claude Code), and **CI on every new repo** — the highest-return gap that `github-map/story`
identified (only 3 of 83 repos had active CI).

## Skills

| Skill | Command | What it does |
|-------|---------|--------------|
| scaffold | `/project-kit:scaffold` | Lay down the standard scaffold into a new project, then help fill `CLAUDE.md`. |
| research-setup | `/project-kit:research-setup <need>` | Research, score, and record a candidate tool; wire it in if adopted. |

## The scaffold

`scripts/scaffold.sh <target-dir> [options]` does the deterministic work (the skill drives it):

```
--name NAME        Project name (default: basename of target dir)
--profile P        data | python | minimal   (default: data)
--python X.Y       Python version (default: 3.11)
--no-data          Skip data/{bronze,silver,gold}
--no-github        Skip .github/ (CI + smoke test, dependabot, PR template, CODEOWNERS)
--no-mcp           Skip .mcp.json (playwright/context7)
--backup           Back up existing files to <file>.bak-<ts>
--force            Overwrite existing files
--dry-run          Print actions, change nothing
```

**Non-destructive by default**: existing files are skipped (no overwrite without `--force`/`--backup`),
and `bd init` is skipped if `.beads/` already exists.

**Profiles**
- `data` (default) — data-eng archetype: `src/` layout, `data/{bronze,silver,gold}`, polars/duckdb deps, data-conventions in `CLAUDE.md`.
- `python` — plain uv library, no data dirs.
- `minimal` — beads + `CLAUDE.md`/`AGENTS.md` + `.gitignore` only; no build/CI.

What gets laid down (data profile): `pyproject.toml`, `.gitignore`, `src/<pkg>/`, `data/{bronze,silver,gold}/`,
`.claude/settings.json` (bd-prime hooks) + `.claude/settings.local.json` (minimal safe perms),
`CLAUDE.md` + `AGENTS.md`, `.beads/` (via `bd init`), a collab-ready `.github/`
(`workflows/ci.yml` + `tests/test_smoke.py`, `dependabot.yml`, `pull_request_template.md`, a commented
`CODEOWNERS`), and optional `.mcp.json`. Then `uv sync`.

## Install

```bash
/plugin marketplace add ~/Code/project-kit
/plugin install project-kit@project-kit-local
```

Or add to `~/.claude/settings.json`:

```json
{
  "extraKnownMarketplaces": {
    "project-kit-local": { "source": { "source": "directory", "path": "/path/to/project-kit" } }
  },
  "enabledPlugins": { "project-kit@project-kit-local": true }
}
```

Restart the session for Claude Code to load the plugin. To use the script standalone, set
`PROJECT_KIT_HOME` to this repo (defaults to `~/Code/project-kit`).

## Requirements

`bd` (beads) and `uv` on PATH for those steps; the script prints a hint and continues if either is missing.
