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

## 2026-10-03 — what practitioners actually do with coding agents (git flow, parallelism, guardrails, context)

Need: an open sweep, not one tool. What do people running Claude Code daily use and complain about,
across four axes, and what should the kit scaffold because of it? Constraint: evidence from
practitioners (HN threads, GitHub, docs, blogs), not papers or vendor pages; fit uv + beads + GitHub
Actions + Claude Code; cost matters. Reddit returned 403 to every agent, so it is absent.

Two facts reframe the rest. Since 2026-08-14 Claude Code defaults to **auto mode**
([HN 49239021](https://news.ycombinator.com/item?id=49239021)), so allowlists matter less and `deny`
rules plus hooks are what actually stop the agent. And Claude Code reads `AGENTS.md` **only when there
is no `CLAUDE.md`** ([49760187](https://news.ycombinator.com/item?id=49760187)): the kit emits both, so
today the agent never sees `AGENTS.md`.

### Git flow with agents
- **Candidate**: one session = one bead = one branch, small scope (practice)
  - What it does: fixes the granularity at scope time instead of cleaning history afterwards.
  - Fit: this is `/project-start` (5q6.4). "Inconclusive diff is the result of bad scope, not bad
    commits" ([48265976](https://news.ycombinator.com/item?id=48265976)); "one task per session, each in
    its own git worktree" ([49655485](https://news.ycombinator.com/item?id=49655485)).
  - Verdict: **adopt** — already the epic's design; offer `claude --worktree` rather than own worktrees.
- **Candidate**: explicit `attribution` in `.claude/settings.json` (https://code.claude.com/docs/en/settings-reference.md)
  - What it does: decides the commit trailer / PR line / session URL instead of inheriting the default.
  - Fit: the session-URL default drew a 209-pt complaint thread
    ([49498201](https://news.ycombinator.com/item?id=49498201)); Firefox committed an explicit setting.
  - Verdict: **adopt** — the kit should make the choice explicit (trailer on, `sessionUrl: false` is
    the suggested default; the owner decides).
- **Candidate**: PR-title check in CI (regex, or amannn/action-semantic-pull-request)
  - What it does: with squash-merge the PR title is the only commit left on `main`; validate it.
  - Verdict: **trial** — a regex step in the kit's CI, no new dependency.
- **Candidate**: git-absorb / `git history fixup` (Git ≥ 2.54)
  - Verdict: **reject** as a dependency — squash-merge makes branch fixups moot; absorb "still gets
    things wrong a couple times a week" ([48262983](https://news.ycombinator.com/item?id=48262983)).
- **Candidate**: Jujutsu (jj, https://github.com/jj-vcs/jj)
  - Verdict: **reject** — "agents are always confused about JJ and fall back to git"
    ([46846034](https://news.ycombinator.com/item?id=46846034)); breaks beads and Claude worktrees.

### Parallel agents
- **Candidate**: native Claude Code worktrees (`claude -w`, `.worktreeinclude`, `isolation: worktree`,
  `claude agents`) — https://code.claude.com/docs/en/worktrees
  - Fit: what people use ("I literally only ever start claude with `claude agents`",
    [48870961](https://news.ycombinator.com/item?id=48870961)); superpowers' worktree skill already prefers it.
  - Verdict: **adopt** — scaffold a worktree-ready repo: `.claude/worktrees/` in `.gitignore`, a
    `.worktreeinclude` (`.env*`), an idempotent setup step (`uv sync`).
- **Candidate**: beads as the coordination layer (`bd update --claim` as an atomic lock, shared DB
  across worktrees) — keep; protocol "one bead = one worktree = one PR", 2–3 lanes max, distinct files.
  The bottleneck is review, not generation: "8 parallel cards means 8x the diffs to read"
  ([48246797](https://news.ycombinator.com/item?id=48246797)).
- **Candidate**: agent teams (experimental) — **trial**, research/review only: ~7× tokens in plan mode
  per the official cost docs.
- **Candidate**: Worktrunk (`wt`, ★8.7k, active) — **trial**, optional; overlaps `claude -w`.
- **Candidate**: Gas Town — **hold**: effort moved to `gascity`, and issue #3649 (HN 253 pts) reported
  default formulas opening PRs to Gas Town with the user's credits. Don't scaffold it.
- **Candidate**: claude-squad, container-use, Vibe Kanban (sunsetting), Conductor (macOS), Crystal, uzi
  - Verdict: **reject** — duplicates native features, stale, or dead.

### Guardrails
- **Candidate**: PreToolUse guard hook on Bash (own ~40-line script)
  - What it does: returns **`deny`** for `--no-verify`, `HUSKY=0`/`SKIP=`, push to `main`/`develop`,
    `push --force`, `reset --hard`, `pip install`.
  - Fit: "the guard hook was the only thing that reliably stopped git reset --hard (1.00 with, 0.33
    without)" ([49468946](https://news.ycombinator.com/item?id=49468946)); `ask` shows no prompt in auto
    mode, `deny` works in every mode ([49844794](https://news.ycombinator.com/item?id=49844794)).
    Containment, not security.
  - Verdict: **adopt** — `templates/claude-settings.json` + a new hook script.
- **Candidate**: PostToolUse `ruff format` (+ `ruff check --fix --unfixable F401`) after edits
  - Verdict: **adopt** — "never send an LLM to do a linter's job"
    ([46098838](https://news.ycombinator.com/item?id=46098838)).
- **Candidate**: test-integrity checks in CI, not hooks
  - What it does: `xfail_strict = true`, `--strict-markers`, and a CI step that flags added
    `skip`/`xfail` or deleted `def test_`. Hooks that lock `tests/` would break TDD.
  - Verdict: **adopt** (the cheap part) — "Ok, I've deleted all the failing tests"
    ([46897538](https://news.ycombinator.com/item?id=46897538)).
- **Candidate**: prek (https://github.com/j178/prek, ★8.5k, v0.5.4) + betterleaks/gitleaks
  - Fit: uv-native, adopted by CPython/FastAPI; closes the local-commit gap GitGuardian leaves. Only
    worth it together with the guard hook, since agents skip opt-in hooks
    ([45442088](https://news.ycombinator.com/item?id=45442088)).
  - Verdict: **trial** — betterleaks is the maintained successor of gitleaks.
- **Candidate**: Claude Code native sandbox — **trial** in one repo: on Linux sandboxed commands can't
  reach host localhost (bd's Dolt server), `allowedDomains` starts empty, needs bubblewrap + socat.
- **Candidate**: extra AI reviewers (CodeRabbit, Greptile, Claude Code Review, claude-code-action)
  - Verdict: **reject** — "pretty much pure noise" ([46777079](https://news.ycombinator.com/item?id=46777079));
    overlaps Sourcery/Copilot. Watch Copilot review now billing Actions minutes + AI credits.

### Context, memory, data
- **Candidate**: short `CLAUDE.md` (< ~100 lines) that imports `@AGENTS.md` and indexes `docs/`
  - Verdict: **adopt** — fixes the ignored-`AGENTS.md` problem above; progressive disclosure beat
    skills in Vercel's eval ([46809708](https://news.ycombinator.com/item?id=46809708), small sample).
- **Candidate**: DuckDB from the CLI with a token budget (`DESCRIBE`, `SUMMARIZE`, `LIMIT 20` via
  `uv run python -c`) — **adopt** as 3–4 lines in the template's Data Conventions.
- **Candidate**: DuckDB MCP — motherduckdb/mcp-server-motherduck (★525, v1.0.8, read-only by default)
  - Fit: its core tool is "execute SQL", which the CLI already gives; default 1024 rows / 50k chars
    per call; no practitioner evidence of real use; MCP context bloat is a recurring complaint.
  - Verdict: **reject** as a default, **trial** opt-in per project (`--max-rows 50 --max-chars 8000`).
    Closes the dl7 follow-up. ktanaka101/mcp-server-duckdb is abandoned → reject.
- **Candidate**: marimo-pair (https://github.com/marimo-team/marimo-pair) — **trial** at user level:
  "daily driving Marimo with Claude for several months" ([48756957](https://news.ycombinator.com/item?id=48756957)).
- **Candidate**: beads — **keep**, plus one `AGENTS.md` line: project facts → `bd remember`, personal
  preferences → harness memory. The Dolt move cost it users (issue #2573); `wedow/ticket` is the
  simplest plan B. Other trackers and memory MCPs → **reject**.
- **Candidate**: pandera[polars] / dataframely for silver→gold contracts — **trial** in one project.

Wiring: none in this entry. The adopts become beads under the v0.2 epic.

## 2026-09-24 — a home for a project's gitignored data

Need: every data project gitignores `data/{bronze,silver,gold}`, but the kit never says where that
data lives or how to rebuild it. Constraint: CLI-driven, no secrets in the repo, private data stays
private, and the profile's differentiator (own data, Peruvian regional domain) can be published when
it is ours to publish.

- **Candidate**: Hugging Face dataset repos (https://huggingface.co/docs/hub/datasets)
  - What it does: versioned (git + Xet) dataset hosting with a card, a viewer and one-line download
    (`hf download`, `datasets.load_dataset`); public or private.
  - Fit: strong for **publishing own data** — a card, a license and a download line are the visibility
    the profile lacks. Weak as working storage: deleting a file frees no quota until history is squashed.
    Free accounts get 100 GB private; public storage is best-effort, and HF expects large public
    datasets to carry a card and be reusable by others.
  - Maintenance: `huggingface_hub` 2.0.0 (2026-09-24), very active.
- **Candidate**: Hugging Face Storage Buckets (https://huggingface.co/docs/hub/storage-buckets)
  - What it does: S3-like, non-versioned, mutable storage on the Hub (`hf sync`, `hf buckets cp`, or an
    S3-compatible gateway that rclone and DVC can use).
  - Fit: good for private working data (bronze/silver, checkpoints, rolling backups): deleting frees
    quota. Shares the 100 GB private tier. **A bucket is created public unless `--private` is passed**:
    create it private and check its visibility before uploading.
  - Maintenance: same library and CLI as above.
- **Candidate**: DVC (https://dvc.org)
  - What it does: pointer files in git, content in a remote (S3, GCS, SSH, Google Drive; an HF bucket
    through its S3 gateway).
  - Fit: a second versioning system next to git, for data the stack mostly regenerates. Worth it only
    when exact dataset versions must travel with the code.
  - Maintenance: 3.67.1 (2026-03-31), ★15.9k, active.
- **Candidate**: git-annex with rclone (`rclone gitannex`)
  - What it does: large files tracked by git-annex, content in any rclone remote.
  - Fit: DVC's niche with a steeper learning curve, and it overlaps with the HF path. Not needed.
  - Maintenance: rclone v1.75.1 (2026-09-04).
- **Current practice** (kept): remote silver on an own server via `$SILVER` (tesis_redes), or data
  regenerable from source (infelix).
- **Verdict**: **trial** — no project in the stack uses HF yet. In the next data project: an HF dataset
  repo (card + license) for data we publish and a **private** HF Storage Bucket for working data; DVC
  or git-annex only if a project needs dataset versions pinned to commits. Never publish third-party or
  personal data (course material, class recordings, PII). Revisit after one project ships.
- **Wiring**: not a default. `templates/CLAUDE.md.tmpl` gains a "Where it lives" fill prompt in Data
  Conventions listing these options next to `$SILVER` and regenerate-from-source, so every new data
  project states where its gitignored data lives and how to rebuild it.
  A deliberate exception to wiring only adopted tools: the prompt asks the question and lists the
  options, but installs no HF tooling. Ships in plugin 0.2.0.

## 2026-09-11 — tooling for a verified literature review (+ BibTeX for a LaTeX report)

Need: find, verify and cite ~9 recent papers (≤5 years) for a course deliverable, and produce a
`.bib` for a LaTeX report. Constraints: every DOI/venue/figure must be checkable (the deliverable
is graded on source quality), no paid API, and it must work from the CLI.

- **Candidate**: `claude-scholar` plugin — already installed (`openalex`, `doi-bibtex`,
  `check-refs`, `arxiv-metadata` skills)
  - What it does: OpenAlex queries, DOI → BibTeX, and a reference checker for LaTeX `.bib` files.
  - Fit: strong. No key, free, and `check-refs` closes the loop against the written report — which
    matches the reproducibility value better than a search-only tool.
  - Maintenance: installed plugin, in use.
  - Verdict: **adopt** — primary tool. Used for the PC1 review in `cursos/concurrente` (R0SEWT/concurrente#5).
- **Candidate**: direct REST calls to OpenAlex + Crossref + `doi.org` content negotiation (curl)
  - What it does: same data, one layer down; `api.crossref.org/works?query.bibliographic=` turned
    out to be **better than OpenAlex for CS venues** (found the ICPP/IEEE Access papers that
    OpenAlex relevance search buried), and `Accept: application/x-bibtex` on `doi.org` gives BibTeX.
  - Verdict: **adopt** as the fallback whenever a skill's results look thin. Worth knowing that
    OpenAlex `title_and_abstract.search` silently misses records with no stored abstract.
- **Candidate**: an academic MCP server — ScholarMCP (https://github.com/lstudlo/scholarmcp),
  `openags/paper-search-mcp` (https://github.com/openags/paper-search-mcp),
  `oksure/openalex-research-mcp` (https://github.com/oksure/openalex-research-mcp)
  - What they do: wrap OpenAlex/Crossref/Semantic Scholar/arXiv search, PDF ingestion, citation export.
  - Fit: heavy overlap with `claude-scholar` + `exa`, both already installed. PDF ingestion is the
    only real gap, and it did not come up: the deliverable needs metadata and DOIs, not full texts.
  - Verdict: **reject** for the template — revisit only if a project needs bulk PDF ingestion.
- **Candidate**: `exa` plugin (installed) for discovery
  - Verdict: **trial**, complementary — good at finding the *non-indexed* material (vendor blogs,
    a paper accepted but not yet in a DOI registry), weak for bibliographic metadata.
    It runs on a metered Exa API key, so under the no-paid-API constraint it stays optional —
    never part of the required verification path.
- **Friction found**: the **dblp API is behind a bot check** (`dblp.org/search/publ/api` returns an
  Anubis HTML challenge, HTTP 200). Don't script it; use Crossref for CS-venue coverage instead.
- **Wiring**: none. All adopted pieces are already installed or plain `curl`; nothing to add to
  `templates/`. Recorded here so the next literature task starts with Crossref in hand.

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
