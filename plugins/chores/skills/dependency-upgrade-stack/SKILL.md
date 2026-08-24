---
name: dependency-upgrade-stack
description: Replace open dependency update PRs with a tested GitHub stack. Use for periodic repository-wide Maven, Gradle, npm, Docker image, or GitHub Actions upgrades when minor and patch updates should land before researched major updates.
disable-model-invocation: true
---

# Build a dependency upgrade stack

Create manual dependency upgrade PRs instead of merging bot PRs. Work in one repository unless a dependency contract crosses repository boundaries.

Invoke `dependency-upgrade` before proceeding. That skill owns version eligibility, authoritative research, ecosystem-specific checks, migration work, validation, PR descriptions, and troubleshooting. This skill adds repository-wide inventory, grouping, commit structure, stack orchestration, and replacement of bot PRs. When the skills conflict, this skill controls dependency grouping, commit structure, branch creation, PR bases, and stack submission.

## Stack rules

- Require the `gh stack` extension. If `gh stack --help` fails, stop and report that it is not installed. Do not install it unless the user asks.
- Fetch `origin/main` and create the first stack branch directly from that remote-tracking branch. Never base the stack on local `main`, the current branch, or another remote. If `origin/main` does not exist, stop and notify the user.
- Treat bot PRs as leads, not as sources of truth for target versions.
- Put dependencies that must remain compatible in the same PR.
- Put major application and build dependency updates in one PR. Commit each dependency separately when the upgrades do not require a shared change.
- Give a major update its own PR at the top of the stack only when it has very high concrete risk or requires changes across many parts of the codebase.
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
4. Major application and build dependency updates
5. Any exceptional major update that needs its own PR

The major layer may exceed the three-direct-dependency limit in `dependency-upgrade`. Keep dependencies that require each other in one commit. Otherwise, commit each dependency separately so reviewers can inspect and revert it without splitting the PR.

Do not split a major update merely because it can upgrade independently. Split it only when the risk assessment identifies a very high-risk failure mode or the migration touches many different parts of the code. Put each exception above the grouped major layer and explain the decision in both PR descriptions.

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
3. In the grouped major layer, commit each independent dependency separately when possible. Keep required migration changes in the commit for the dependency that caused them.
4. Submit with `gh stack submit --auto --open`.
5. Replace the generated PR body.
6. Finish validation and required checks before adding another layer.

The stack inventory may contain many updates. The grouped major layer, patch and minor layer, and GitHub Actions layer are review categories for a periodic repository-wide upgrade, so they may contain more than three direct dependency updates.

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