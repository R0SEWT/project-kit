# <Experiment name>

- Status: proposed | running | accepted | rejected
- Owner and date:
- Tracking issue or bead:
- Base commit and candidate commit:
- Agent host/version and loaded skill source path:
- Consumer repo/commit and environment:

## Problem and hypothesis

What fails today, and what observable outcome should improve?

## Scope and compatibility

List changed capabilities, files, dependencies, permissions and affected
consumers. Identify project-specific configuration that must be preserved.

## Baseline and acceptance criteria

Describe the baseline behavior and measurable pass/fail conditions. Include
one failure/recovery case and any platform-specific observation required.

## Evidence

| Case | Exact command or agent task | Expected | Observed | Evidence |
| --- | --- | --- | --- | --- |
| Baseline | | | Not run | |
| Candidate | | | Not run | |
| Recovery | | | Not run | |

Record manual interventions and redacted logs. Never substitute an expected
result for an observed result.

## Decision and integration

Explain accept/reject, remaining limits, release version if applicable and PR.
Link follow-up issues rather than maintaining an additional task backlog here.

## Rollback

Specify the previous capability commit, configuration restoration, and how to
undo external effects such as a registered kernel. Code reversion alone may
not restore the environment.
