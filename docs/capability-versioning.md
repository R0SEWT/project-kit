# Versioning capabilities

Status: initial manual contract for review. There is no package resolver,
installer or automatic lockfile generator in project-kit yet. Git is the source
of immutable revisions; this contract can be exercised before building a CLI.

## Units and responsibilities

| Artifact | Responsibility | Example |
| --- | --- | --- |
| Skill | Agent capability, supporting scripts and validation cases | Diagnose a notebook environment |
| Playbook | Compose capabilities with decisions and expected deliverables | Bootstrap and validate a notebook project |
| Runbook | Repeat an operation with preconditions, checks and recovery | Repair or remove a registered kernel |

A capability release versions the files that must work together. List their
paths explicitly; do not version a prompt independently of scripts it invokes.
Keep the native skill layout expected by the agent host. This document does not
introduce a replacement SKILL.md format.

## Ownership boundary

- The capability owns reusable instructions, scripts, examples and checks.
- The consuming repository owns project paths, scientific assumptions, data
  references, thresholds and local overrides.
- Secrets belong in the environment or an appropriate secret store, never in
  the capability record.

Provide explicit configuration inputs rather than editing installed source.
When a local fork is necessary, record its own origin and revision. Never label
modified code as an unchanged upstream release.

## Release contract

Each candidate records: capability ID; version; purpose and activation scope;
input/output contract; required tools and versions; supported agent hosts;
dependency revisions; managed file paths; side effects and permissions;
validation cases; migration steps; rollback procedure; and release notes.

Use SemVer for declared releases:

- PATCH: corrections that preserve observable inputs, outputs and required steps.
- MINOR: compatible optional behavior or new optional inputs.
- MAJOR: changed or removed inputs/outputs, new mandatory dependencies or
  permissions, or incompatible required workflow steps.

For 0.x releases, explicitly describe compatibility even when the version does
not signal stability. A small wording change can alter agent behavior: classify
the observed contract impact, not the number of edited lines. Record candidate
versions as prereleases and validate them before advertising a stable release.

## Relation to the plugin version

Capabilities in this repository reach consumers through the Claude Code plugin.
The host installs it into a cache directory named after the `version` field of
`.claude-plugin/plugin.json` (for example
`~/.claude/plugins/cache/project-kit-local/project-kit/0.1.0/`) and records the
commit it installed. Changing files without changing that field can leave
installed copies on the old files.

- A PR that releases a capability shipped by the plugin also bumps the plugin
  `version` by the largest capability bump it contains. While the plugin is 0.x,
  shift one level down: an incompatible change bumps MINOR, anything else PATCH.
- The plugin version is the distribution version; capability versions stay in
  their own release notes. Never reuse a plugin version for different contents.
- In the consumer inventory, a capability loaded through the plugin records the
  plugin version and the installed commit from the host's install record as its
  revision, instead of hashes of copied files.
- Install from a clean checkout. For a local-directory marketplace the host
  copies the working tree, so uncommitted edits would land in a cache that
  matches no commit, and rolling back to the recorded commit would not
  reproduce what was loaded.

## Pinning in a consumer repo

Maintain `docs/capabilities.md` as a human-reviewed inventory initially. For each
capability record the following fields:

| Field | Required value |
| --- | --- |
| ID and version | Capability name and declared release |
| Source | Repository URL and source subdirectory |
| Revision | Full immutable Git commit SHA; a branch or tag alone is insufficient |
| Installed files | Copied capabilities: exact destination paths and file hashes. Plugin-loaded: plugin version and install commit (see above) |
| Dependencies | Capability IDs with tested exact revisions |
| Configuration | Local non-secret configuration paths |
| Validation | Evidence record and consumer commit tested |

Playbooks reference capability IDs from this inventory. Resolve every ID to one
installed revision and reject missing dependencies or incompatible requirements
before running. For the pilot, perform this review manually; do not imply that
the repository already enforces it automatically.

## Update and rollback

1. Review candidate release notes, source diff and changed dependencies.
2. In a lab worktree, compare what is installed with the inventory: file
   hashes for copied capabilities, plugin version and commit for plugin-loaded
   ones. Stop if local changes are unexplained; preserve and reconcile them
   before replacement.
3. Update only the declared managed files. Preserve project configuration and
   inspect any dependency or permission expansion.
4. Execute baseline, candidate and recovery cases. Record actual source revision
   loaded by the agent and any host reload needed.
5. Submit files, inventory and evidence in the same PR. Consumers upgrade
   independently; publishing a release does not upgrade all repositories.
6. To roll back, restore the previous file set and inventory together, then
   execute the runbook's environment recovery and repeat checks. Never assume
   a Git revert undoes external side effects.

## Promotion criterion

Before automating packaging, demonstrate one capability in two consumer repos:
pin both to the initial revision, update one to a candidate, verify the other
remains unchanged, and roll the first back successfully. A release decision must
include evidence from this exercise. A generated manifest or lockfile is future
automation of this contract, not a deliverable claimed by this change.
