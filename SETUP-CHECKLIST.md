# Setup checklist — post-push manual steps

The scaffold lays down every file a collab-ready repo needs, but some settings live in your
**GitHub account / repo settings**, not in a file the scaffold can commit. Do these once, by hand,
after the first push.

**What's on this list:** only steps that (a) can't be committed and (b) you'd want on a *minimal*
collab-ready repo. Config for a specific pain — environments, deployment gates, protected tags,
advanced secrets — is deliberately out of scope; add it when the need shows up.

## 1. Branch protection / require review

Settings → Rules → Rulesets (or Branches → branch protection) on the default branch: require a pull
request before merging, gate it on CI, and — working solo — **require conversation resolution instead
of approvals**.

**Recommended solo-dev config** — exactly what `scripts/protect-branch.sh` applies:
- Require a pull request before merging, with **0 required approvals**.
- Require the CI status check (`test`) to pass, branch up to date (`strict`).
- **Require conversation resolution before merging.**
- Leave admins un-enforced (`enforce_admins: false`) — an escape hatch if CI ever wedges.

One command (needs `gh`, authenticated, admin on the repo):

```bash
scripts/protect-branch.sh <owner/repo>     # protects main; --branch / --check NAME to override
```

**Solo-dev trap — why approvals don't work.** On your own PR your *own* approval doesn't count toward
the required number, and GitHub blocks self-approval, so someone else would have to approve. A
`* @owner` line in `CODEOWNERS` makes you required-reviewer of everything, which can block your own
merge too. A `required_approving_review_count: 1` on a solo repo is therefore **unsatisfiable** — every
merge would need `--admin`, which bypasses CI (security theater). Require **conversation resolution**
instead: it makes review comments a real merge gate without needing a human Approve.

## 2. Copilot automatic code review

This is a repo/account toggle (or an org policy plus a ruleset) — not a committable file, which is
why it's here and not in the scaffold. Enable it under Settings → Rules → Rulesets as an
**independent automatic-review rule** (since Sept 2025 it no longer has to ride on the "require a
pull request before merging" gate). Requires a **paid Copilot plan** — Copilot Pro ($10/mo) is the
entry tier; org members can use it with no license if the org enables the policy.

**Trap — and the fix.** Copilot's review is always a **Comment** — never Approve or Request-changes —
so it does **not** satisfy a require-approval rule. Pairing auto-review with require-*approval* on a
solo repo leaves you unable to merge without a human Approve. But pair it with require **conversation
resolution** (§1) and its comments *do* become a binding soft-gate: every Copilot/Sourcery thread must
be resolved before the PR can merge, no human Approve required. That's the combination — auto-review
for the signal, conversation-resolution to make it stick.

## Note — Actions billing (awareness, not a step)

Since **June 1, 2026**, Copilot code review consumes GitHub Actions minutes. On **private** repos
those minutes draw from your plan's Actions entitlement (metered, then billable); on **public** repos
Actions minutes stay free. Nothing to configure — just know that auto-review on a private repo isn't
free the way it was before.
