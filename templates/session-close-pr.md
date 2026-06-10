## Session Close (PR flow — supersedes the generic beads protocol in this file)

`main` is protected: a PR is required, and merges are gated on green CI plus resolved
review conversations — with **no approval count** (a solo dev can't self-approve, and
Copilot/Sourcery reviews only ever *Comment*, so they never satisfy a required-approval
rule). **Do not push directly to `main`.**

At session end:
1. Commit work on a **branch**; `git push -u origin <branch>`.
2. Open/update a **PR**; let the configured reviewer (Copilot/Sourcery) run.
3. The merge waits for **green CI + all review conversations resolved** — never `--admin`.
4. Tracking: `bd ready` at start; file follow-up issues at close for the cross-session
   backlog. **TodoWrite is fine for ephemeral, in-session steps.**
5. `bd dolt push` applies only if a dolt remote is configured; otherwise the git-tracked
   `.beads/issues.jsonl` is the sync. `bd remember` and an out-of-repo harness `MEMORY.md`
   don't conflict — use either.

> The generic beads "Session Completion" protocol elsewhere in this file assumes
> trunk-based development (direct push to `main`, `bd dolt push`) and is **superseded**
> by this section.
