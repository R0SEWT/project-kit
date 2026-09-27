# Agent workflow laboratory

Use `lab/agent-workflows` as an opt-in experiment branch for skills, playbooks
and runbooks. Approved capabilities live on `main` alongside the code they
support. This guide defines a manual workflow; it does not add a new CLI command.

## Start an experiment

Start from a clean checkout and fetch the current base:

```bash
git status --short
git fetch origin
git worktree add --no-track -b lab/agent-workflows ../project-kit-agent-lab origin/main
cd ../project-kit-agent-lab
git push -u origin lab/agent-workflows
```

`--no-track` keeps the lab branch from tracking `main`: otherwise a routine
`git pull --rebase` rebases the lab history onto `main`, and `git push` targets
the wrong branch.

Stop if the status output contains changes: commit or preserve them deliberately.
If the branch or worktree already exists, reuse it after inspecting its status;
do not reset, delete or recreate it. For independent experiments, use separate
`lab/<topic>` branches and worktrees. Do not use `lab/agent-workflows` both as a
branch and as a prefix for other branches.

Run experiments against disposable fixtures or a dedicated consumer worktree.
An agent may read the checked-out documentation immediately, while an installed
plugin may still be loading its cached release. The installed plugin is
served from its cache (`~/.claude/plugins/cache/.../<version>/`), never from the
lab worktree, so reloading does not pick up lab changes. Start a fresh session
that loads the lab copy for that session only:

```bash
claude --plugin-dir ../project-kit-agent-lab
```

Record the actual source path and commit used, and verify that the experimental
skill is loaded before evaluating it.

## Keep an experiment record

Copy [the record template](experiments/TEMPLATE.md) into
`docs/experiments/<topic>.md`. It is evidence, not a second task tracker: link the
existing bead or GitHub issue instead of maintaining another backlog.

Declare the problem, hypothesis, affected files, baseline, success criteria and
rollback before testing. Record failures and manual interventions as well as
successful runs. Do not commit transcripts containing credentials or private
project data; retain minimal redacted evidence.

## Integrate a validated change

1. Keep the experiment branch current with `origin/main`; merge the base into
   the branch and resolve conflicts explicitly. Avoid rewriting shared history.
2. Repeat the relevant checks after updating the base. Verify the actual agent
   behavior as well as deterministic scripts and generated files.
3. Open a PR to `main` containing one coherent capability change, its evidence
   and its rollback procedure. If the lab contains unrelated trials, create a
   clean promotion branch from `origin/main` and cherry-pick only the intended
   commits, then revalidate their dependencies.
4. State affected consumers and compatibility changes. A candidate is not a
   released capability until its approved commit is available to consumers.
5. Wait for required CI and review resolution. Merge through the repository's
   normal process; do not bypass protection or automatically merge.

If a trial fails, record the rejection or next hypothesis. Do not merge it just
to clear the branch. Keep the worktree until useful work is committed and its
retention is decided. Once a trial is integrated, prefer a fresh branch for the
next trial, especially after a squash merge.

## First pilot

Use a notebook-environment capability, grounded in issue #6. Test the same
candidate in two disposable uv projects: one at the repository root and one
nested under `labs/`. Verify interpreter and dependencies, notebook launch,
behavior after environment synchronization, and kernel removal. Do not claim
VS Code discovery works without observing it in VS Code.

Success means another developer can execute the documented procedure and
recover from a broken kernel without relying on the author's chat history.
This pilot is proposed; no successful execution is claimed by this guide.
