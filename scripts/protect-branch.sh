#!/usr/bin/env bash
# protect-branch.sh — apply the solo-dev-friendly branch protection to a repo.
#
# Makes a PR required and gates merges on CI (the required check) + resolved review
# conversations, while dropping the approval requirement a solo dev cannot satisfy
# (GitHub blocks self-approval; Copilot/Sourcery reviews only ever Comment, so they
# never count as an approval). See SETUP-CHECKLIST.md §1.
#
# Usage:
#   protect-branch.sh <owner/repo> [--branch BRANCH] [--check NAME]...
#
# Options:
#   --branch BRANCH   Branch to protect (default: main)
#   --check NAME      Required status check context; repeatable (default: test)
#   -h, --help        Show this help
#
# Requires: gh (GitHub CLI), authenticated with admin rights on the repo.
set -euo pipefail

usage() { sed -n '2,17p' "$0"; }

REPO=""
BRANCH="main"
CHECKS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --branch) BRANCH="$2"; shift 2 ;;
    --check)  CHECKS+=("$2"); shift 2 ;;
    -h|--help) usage; exit 0 ;;
    -*) echo "error: unknown option $1" >&2; exit 1 ;;
    *)  if [[ -z "$REPO" ]]; then REPO="$1"; else echo "error: unexpected arg $1" >&2; exit 1; fi; shift ;;
  esac
done

[[ -n "$REPO" ]] || { echo "error: <owner/repo> required" >&2; usage; exit 1; }
command -v gh >/dev/null 2>&1 || { echo "error: gh (GitHub CLI) not found on PATH" >&2; exit 1; }
[[ ${#CHECKS[@]} -gt 0 ]] || CHECKS=("test")

# Build the JSON contexts array from the (simple, identifier-like) check names.
contexts_json="["
for i in "${!CHECKS[@]}"; do
  [[ "$i" -gt 0 ]] && contexts_json+=","
  contexts_json+="\"${CHECKS[$i]}\""
done
contexts_json+="]"

echo "Applying branch protection to ${REPO}@${BRANCH} (required checks: ${CHECKS[*]})..."

gh api -X PUT "repos/${REPO}/branches/${BRANCH}/protection" --input - >/dev/null <<JSON
{
  "required_status_checks": { "strict": true, "contexts": ${contexts_json} },
  "enforce_admins": false,
  "required_pull_request_reviews": { "required_approving_review_count": 0, "dismiss_stale_reviews": true },
  "required_conversation_resolution": true,
  "restrictions": null
}
JSON

echo "Done: PR required; merges gated on CI + resolved conversations; no approval count."
echo "enforce_admins is false (owner keeps an escape hatch). Pass it to true by hand to harden."
