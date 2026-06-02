# project-kit — AI Agent Instructions

## Project Context

project-kit is a Claude Code **plugin + marketplace** that bootstraps new projects with the
standard setup (beads, uv, `CLAUDE.md`/`AGENTS.md`, GitHub Actions CI) and researches new tooling
to evolve that setup. Defaults encode the github-map profile: applied-ML / data-engineering
archetype, agentic dev (beads + Claude Code), and **CI on every new repo**.

This repo dogfoods its own kit: it uses beads for tracking and ships CI that lints itself.

## Architecture

Two skills sit over a deterministic core:

- **`skills/scaffold/`** → `/project-kit:scaffold`. Gathers inputs, runs `scripts/scaffold.sh`,
  then helps fill the new project's `CLAUDE.md`.
- **`skills/research-setup/`** → `/project-kit:research-setup`. Researches/scores a candidate tool,
  records a verdict in `catalog/setup-options.md`, and wires adopted ones into `templates/`.
- **`scripts/scaffold.sh`** does all file/command work. It is **non-destructive by default**
  (skips existing files unless `--force`/`--backup`; guards `bd init` if `.beads/` exists).
- **`templates/`** are the source files copied/rendered into target projects. They are kept
  **faithful to real repos** (tesis_redes, exp_tesis, infelix) — reuse, don't invent.

## Key Files

| File | Purpose |
|------|---------|
| `scripts/scaffold.sh` | Deterministic scaffold engine (safety model, profiles, render) |
| `templates/*.tmpl` | Rendered files (`{{name}}`, `{{pkg}}`, `{{python}}`, `{{target_version}}`, `{{deps}}`) |
| `templates/*` (no `.tmpl`) | Copied verbatim (settings, gitignore, AGENTS.md, test_smoke.py) |
| `.claude-plugin/plugin.json` | Plugin manifest |
| `.claude-plugin/marketplace.json` | Marketplace manifest (`project-kit-local`) |
| `catalog/setup-options.md` | Append-only research log |

## Conventions

- **Edit the source repo, never the installed plugin cache** (`~/.claude/plugins/cache/...` is a
  copy that gets overwritten). Plugin/skill changes require a session restart to load.
- Templates must render with the placeholder set above; multi-line `{{deps}}` is substituted via awk.
- The scaffold's safety model is load-bearing: never overwrite without `--force`/`--backup`,
  and never re-`bd init`. Preserve this when editing `scripts/scaffold.sh`.
- `.claude/settings.local.json` is emitted only when absent — don't clobber a tuned local file.
- New tooling decisions go through `research-setup` and land in `catalog/setup-options.md`.


<!-- BEGIN BEADS INTEGRATION v:1 profile:minimal hash:ca08a54f -->
## Beads Issue Tracker

This project uses **bd (beads)** for issue tracking. Run `bd prime` to see full workflow context and commands.

### Quick Reference

```bash
bd ready              # Find available work
bd show <id>          # View issue details
bd update <id> --claim  # Claim work
bd close <id>         # Complete work
```

### Rules

- Use `bd` for ALL task tracking — do NOT use TodoWrite, TaskCreate, or markdown TODO lists
- Run `bd prime` for detailed command reference and session close protocol
- Use `bd remember` for persistent knowledge — do NOT use MEMORY.md files

## Session Completion

**When ending a work session**, you MUST complete ALL steps below. Work is NOT complete until `git push` succeeds.

**MANDATORY WORKFLOW:**

1. **File issues for remaining work** - Create issues for anything that needs follow-up
2. **Run quality gates** (if code changed) - Tests, linters, builds
3. **Update issue status** - Close finished work, update in-progress items
4. **PUSH TO REMOTE** - This is MANDATORY:
   ```bash
   git pull --rebase
   bd dolt push
   git push
   git status  # MUST show "up to date with origin"
   ```
5. **Clean up** - Clear stashes, prune remote branches
6. **Verify** - All changes committed AND pushed
7. **Hand off** - Provide context for next session

**CRITICAL RULES:**
- Work is NOT complete until `git push` succeeds
- NEVER stop before pushing - that leaves work stranded locally
- NEVER say "ready to push when you are" - YOU must push
- If push fails, resolve and retry until it succeeds
<!-- END BEADS INTEGRATION -->
