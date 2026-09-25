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
