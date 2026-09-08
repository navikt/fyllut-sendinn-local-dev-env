---
name: bug-triage-and-fix
description: Trace a suspected bug from evidence to root cause, file a detailed GitHub issue, implement and prove the fix, then publish a pull request. Use when a bug report needs investigation and delivery rather than a speculative patch.
license: MIT
metadata:
  version: "1.0.0"
---

# Triage and fix a bug

Own the path from the first symptom to a reviewable pull request. Keep confirmed
facts separate from hypotheses, and do not patch around an unexplained failure.

## Investigate

1. Read repository guidance and load every skill relevant to the affected code,
   tests, mocks, and local services.
2. Preserve unrelated work. Inspect repository status before changing anything.
3. Build a timeline from logs, request traces, metrics, and user actions. Parse
   structured logs instead of relying on broad text searches.
4. Follow the failing data through each application boundary. For
   cross-repository bugs, give separate subagents non-overlapping repository
   scopes and reconcile their findings centrally.
5. Trace the behavior to source, tests, and contracts. State what the evidence
   proves, what it only suggests, and whether the receiving service is rejecting
   invalid input correctly.
6. Write concrete reproduction steps before choosing a fix.

## File the issue

Search open and closed issues first. File the issue in the repository that owns
the faulty behavior, not merely where the error was logged.

Include:

- observed behavior and impact
- evidence and request timeline, with sensitive values removed
- root cause and relevant source locations
- reproduction steps
- affected flows that share the same code
- suggested solution and regression coverage

Do not paste complete source files or claim that absent log data proves a fact.

## Implement and prove the fix

1. Unless the user explicitly says otherwise, fetch `origin/main` and create
   the feature branch from that updated remote branch. Use an isolated worktree
   when requested or when the current checkout contains other work.
2. Use repository-pinned tools and follow its test-data and mock conventions.
3. Add the regression test before the production change. Prefer an assertion on
   a persisted value, API payload, test-case fixture, or other external contract
   over a DOM-only assertion.
4. Run the narrow test against the unfixed production code and record the exact
   relevant failure. Do not rewrite history just to manufacture a red run.
5. Implement the smallest root-cause fix. Keep downstream validation strict and
   do not silently discard malformed data.
6. Run the regression test again, then the smallest related unit, type, lint,
   build, and end-to-end checks required by repository guidance.

## Review and publish

1. Review the complete diff for races, false-positive tests, shared-flow gaps,
   and unrelated changes. Use a read-only reviewer when available.
2. Fix review findings in a new commit. Re-run affected checks.
3. Create conventional commits with required trailers, push the feature branch,
   and open a pull request against the intended base branch.
4. Put `Closes #NUMBER` in the pull request body. Explain the cause, behavior
   change, red-before-green proof, and validation commands.
5. Verify the remote branch, pull request body, target branch, linked issue, and
   repository status before reporting completion.

Finish with the issue and pull request links, commit SHAs, regression failure,
passing checks, and any CI or deployment work that is still pending.
