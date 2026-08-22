---
name: dependency-upgrade-stack
description: Replace open dependency update PRs with a tested GitHub stack. Use for periodic repository-wide Maven, Gradle, npm, Docker image, or GitHub Actions upgrades when minor and patch updates should land before researched major updates.
disable-model-invocation: true
---

# Build a dependency upgrade stack

Create manual dependency upgrade PRs instead of merging bot PRs. Work in one repository unless a dependency contract crosses repository boundaries.

Invoke `dependency-upgrade` before proceeding. That skill owns version eligibility, authoritative research, ecosystem-specific checks, migration work, validation, PR descriptions, and troubleshooting. This skill adds repository-wide inventory, grouping, stack orchestration, and replacement of bot PRs. When the skills conflict, this skill controls branch creation, PR bases, and stack submission.

## Stack rules

- Require the `gh stack` extension. If `gh stack --help` fails, stop and report that it is not installed. Do not install it unless the user asks.
- Fetch `origin/main` and create the first stack branch directly from that remote-tracking branch. Never base the stack on local `main`, the current branch, or another remote. If `origin/main` does not exist, stop and notify the user.
- Treat bot PRs as leads, not as sources of truth for target versions.
- Put dependencies that must remain compatible in the same PR.
- Separate unrelated major updates.
- Put all GitHub Actions updates in one PR at the bottom of the stack.
- Put all Docker image updates in one separate major-change PR.
- Put compatible application and build dependency patch and minor updates in one PR unless a meaningful breaking change makes that unsafe to review or validate.
- Complete the `dependency-upgrade` workflow for each layer, including required checks, before adding the next layer.
- Do not merge the stack unless the user asks.

## Inventory the repository

Start from the target repository and:

1. Follow `dependency-upgrade` repository inspection rules across every dependency source in the repository.
2. Query open Dependabot or Renovate PRs and inspect their diffs.
3. Build a current-version inventory from manifests, lockfiles, Docker files, Compose files, and workflow action references.
4. Re-query registries and upstream releases to find eligible targets.
5. Record the package family, update type, expected risk, and bot PR coverage for every direct update.

Do not copy stale bot targets. Include eligible direct updates even when no bot PR exists.

## Decide the stack

Use this order, omitting empty groups:

1. GitHub Actions
2. Compatible application and build dependency patch and minor updates
3. Docker images and runtimes
4. One PR per unrelated major dependency group

Keep a major group together when one member requires another. Split it when the dependencies can upgrade independently or one change deserves a clear rollback boundary.

Write the proposed order and a concrete risk assessment before editing. Name likely failures rather than assigning generic risk labels.

## Create the first layer

Confirm that `dependency-upgrade` has completed its clean-worktree check, then verify the required base:

```bash
git fetch origin main
git rev-parse --verify origin/main
git switch --detach origin/main
gh stack init --base main <first-branch>
```

Apply the first group's upgrade by following `dependency-upgrade`. Stay on the initialized branch and use:

```bash
gh stack submit --auto --open
```

Replace the generated PR body with the description required by `dependency-upgrade`. Do not add another layer until that skill's validation and check-watching steps are complete.

## Add each remaining layer

For every remaining group:

1. Add a branch from the current stack top:

   ```bash
   gh stack add <next-branch>
   ```

2. Follow the full `dependency-upgrade` workflow for that group. Use the stack branch instead of creating a standalone branch.
3. Submit with `gh stack submit --auto --open`.
4. Replace the generated PR body.
5. Finish validation and required checks before adding another layer.

The stack inventory may contain many updates, but each major layer should remain a small related group. The patch and minor layer and the GitHub Actions layer are explicit exceptions because they are review categories for a periodic repository-wide upgrade.

## Replace bot PRs

Close a bot PR only after the passing replacement stack covers its complete dependency group. Leave a short comment linking the replacement PR or stack.

Never close an unrelated or partly superseded bot PR. A grouped bot PR remains useful when the stack upgrades only some of its dependencies.

## Finish

Verify stack order and PR bases with `gh stack view` and GitHub PR data. Confirm every required check passes.

Report:

- stack order with PR links
- one direct GitHub link to the stack
- versions covered by each PR
- migration risks and decisions from each PR
- local and GitHub check results
- bot PRs closed as superseded
- dependencies left unchanged and why
- versions deferred by the eligibility rules in `dependency-upgrade`

End with the canonical stack URL when GitHub exposes one. Otherwise, use the top PR as the stack entry point.