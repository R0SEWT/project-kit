# Setup checklist — post-push manual steps

The scaffold lays down every file a collab-ready repo needs, but some settings live in your
**GitHub account / repo settings**, not in a file the scaffold can commit. Do these once, by hand,
after the first push.

**What's on this list:** only steps that (a) can't be committed and (b) you'd want on a *minimal*
collab-ready repo. Config for a specific pain — environments, deployment gates, protected tags,
advanced secrets — is deliberately out of scope; add it when the need shows up.

## 1. Branch protection / require review

Settings → Rules → Rulesets (or Branches → branch protection) on the default branch: require a pull
request before merging, and require N approvals.

**Solo-dev trap.** On your own PR your *own* approval doesn't count toward the required number —
someone else must approve. And a `* @owner` line in `CODEOWNERS` makes you required-reviewer of
everything, which can block your own merge. Working solo: either don't require approvals, or require
them knowing you need a second human (or account) to satisfy the gate.

## 2. Copilot automatic code review

This is a repo/account toggle (or an org policy plus a ruleset) — not a committable file, which is
why it's here and not in the scaffold. Enable it under Settings → Rules → Rulesets as an
**independent automatic-review rule** (since Sept 2025 it no longer has to ride on the "require a
pull request before merging" gate). Requires a **paid Copilot plan** — Copilot Pro ($10/mo) is the
entry tier; org members can use it with no license if the org enables the policy.

**Trap.** Copilot's review is always a **Comment** — never Approve or Request-changes — so it does
**not** satisfy a require-approval rule. Pairing auto-review with require-approval on a solo repo
still leaves you unable to merge without a human Approve. Treat Copilot review as a signal, not a
merge gate.

## Note — Actions billing (awareness, not a step)

Since **June 1, 2026**, Copilot code review consumes GitHub Actions minutes. On **private** repos
those minutes draw from your plan's Actions entitlement (metered, then billable); on **public** repos
Actions minutes stay free. Nothing to configure — just know that auto-review on a private repo isn't
free the way it was before.
