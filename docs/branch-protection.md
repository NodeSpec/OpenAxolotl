# Branch protection

The half of the merge gate that lives in repository settings rather than in a
file (REQ-018 AC-4, REQ-020). `.github/workflows/pr.yml` produces the checks;
**branch protection is what makes a red check un-mergeable** — without it the
pipeline is advisory, and this project's whole premise is that it is not.

This page is the deliverable for that setting: what to configure, exactly,
and why. It must be applied by a repository admin under
**Settings → Branches → Branch protection rules** (or a ruleset with the same
content). A check name becomes selectable after the workflow has run once.

## Rule for `main`

| Setting | Value | Why |
|---|---|---|
| Require a pull request before merging | **on** | No direct pushes; every change goes through the gate. |
| Required approvals | **1** (maintainer) | REQ-020: community submissions require explicit human maintainer approval. This is the load-bearing human gate — an automated-only merge path is a firm project non-goal, so no bot, auto-merge rule, or bypass may satisfy it. |
| Require status checks to pass before merging | **on** | REQ-018 AC-4: a PR failing any contract check or test cannot merge. |
| Required status checks | `level-contract`, `static-gate`, `test-harness`, `build` | The four jobs in `pr.yml`. Add `asset-contract` in the same PR that adds the Asset Contract Validator and its job. |
| Require branches to be up to date before merging | **on** | A PR green against a stale base can still break `main`; the contract checks must have run against what will actually merge. |
| Do not allow bypassing the above settings | **on** (admins included) | The human-review rule is only real if nobody is exempt from it. |
| Allow force pushes / deletions | **off** | History on `main` is the provenance record for every merged world. |

## What this enforces, requirement by requirement

- **REQ-018 AC-3/AC-4** — every PR runs the Level Contract checker, the
  static analysis gate, the test suite and the build; any failure blocks the
  merge button.
- **REQ-020 (human review)** — required approvals ≥ 1 with bypass disabled
  means no community world reaches `main` on automation alone, ever. The
  validators narrow what a human must read; they never replace the human.

## Verification status

Applying and verifying this configuration requires repository admin access,
which this project's automation does not have (and by design the setting
cannot live in the repo as code). Until an admin applies the rule and a PR is
observed blocked on a red check, REQ-018 AC-4 stays **unverified** — the
criterion is deliberately not reported as passing on the strength of this
document alone.
