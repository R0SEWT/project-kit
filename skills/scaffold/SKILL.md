---
name: scaffold
description: Bootstrap a new project with the standard setup — beads, uv, CLAUDE.md/AGENTS.md, GitHub Actions CI. Use when starting a new repo/project and you want the usual scaffold laid down.
---

# project-kit: Scaffold a New Project

Lay down the standard project setup, then help fill the `CLAUDE.md` skeleton.

The deterministic work is done by `scripts/scaffold.sh` (in this plugin's dir). This skill
gathers the inputs, runs it, and then guides the human-judgment part (Domain Context, Architecture).

## Workflow

1. **Gather inputs** (ask only what's not obvious):
   - Target directory (absolute path) and project name (defaults to the dir basename).
   - Profile: `data` (default — data-eng archetype with `data/{bronze,silver,gold}`),
     `python` (plain uv lib), or `minimal` (beads + docs only).
   - Whether to include `.mcp.json` (playwright/context7) — keep it for scraping/web projects, drop with `--no-mcp` otherwise.
   - CI is on by default (closes the portfolio's CI gap); drop with `--no-github` only if there's a reason.

2. **Dry-run first.** Run the script with `--dry-run` and show the planned actions:
   ```bash
   "$CLAUDE_PLUGIN_ROOT/scripts/scaffold.sh" <target> --name <name> --profile <p> --dry-run
   ```
   (If `$CLAUDE_PLUGIN_ROOT` is unset, use `${PROJECT_KIT_HOME:-$HOME/Code/project-kit}/scripts/scaffold.sh`.)

3. **Confirm, then run for real** (drop `--dry-run`). The script is non-destructive: it skips
   existing files unless `--force`/`--backup` is passed, and won't re-run `bd init` if `.beads/` exists.

4. **Fill `CLAUDE.md` with the user.** The template ships with `<!-- fill -->` prompts. Help the
   user complete:
   - **Domain / Scientific Context** — the real problem, the outcome/target, and especially the
     **data provenance** (own data? regional/Peruvian domain? public source?). This is the differentiator.
   - **Architecture** — stages and data flow.
   - **Key Files** — the table.
   Remove the Data Conventions section if the project isn't data-oriented.

5. **Report** what was created/skipped and the next steps the script printed.

6. **After the first push** (once the repo exists on GitHub), enforce the PR flow the scaffold
   assumes — a protected `main` with no unsatisfiable approval gate:
   ```bash
   "$CLAUDE_PLUGIN_ROOT/scripts/protect-branch.sh" <owner/repo>
   ```
   This requires a PR and gates merges on CI + resolved review conversations (no approval count —
   see `SETUP-CHECKLIST.md` §1 for the solo-dev rationale). Then enable Copilot/Sourcery auto-review
   in repo settings so those comments become the binding review.

## Adopting an existing repo (brownfield)

Learned retrofitting a client repo — check these before step 3:
- **Branch first.** `bd init` commits on the current branch.
- **Whose `origin` is it?** `bd init` copies `origin` into `sync.remote` and the Dolt remote, so
  `bd dolt push` would publish the issue DB there. On a client/org repo, repoint both to your own
  remote (the script prints the commands) — `git remote set-url --push` does NOT cover it.
- **Profile `python`**, not `data`: the existing layout (`data/raw`, `src/` package) stays; the
  script now skips `src/<pkg>`, `test_smoke.py` (if real tests exist) and merges missing
  `bd prime` hooks into an existing `.claude/settings.json`.
- **Lowercase `agents.md`** blocks `AGENTS.md` (Linux is case-sensitive): `git mv` it (e.g. to
  `docs/`) and fold its domain content into CLAUDE.md.
- **Fill CLAUDE.md from what exists** (readme, specs, ADRs). Drop template defaults that
  contradict the codebase (e.g. "Polars over pandas" in a pandas project).
- **Lint debt:** the CI template runs `ruff check .` — exclude notebooks, apply safe `--fix`,
  `noqa` with a reason anything that would change behavior.
- **Verify from a clean clone** (or watch the first CI run): gitignored files the code needs at
  import time (e.g. `config/*.yml`) pass locally and fail in CI.

## Notes
- beads is per-project here: the script runs a fresh `bd init` (it auto-detects the issue prefix).
- After scaffolding, `bd ready` should work inside the new project for task tracking.
- The script needs `bd` and `uv` on PATH for those steps; it prints a hint and continues if either is missing.
