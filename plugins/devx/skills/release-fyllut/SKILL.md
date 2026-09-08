---
name: release-fyllut
description: Release a selected skjemabygging-formio main commit to skjemautfylling-formio. Use when publishing or propagating the FyllUt monorepo reference.
license: MIT
metadata:
  version: "1.0.0"
---

# Release FyllUt

Publish a specific `skjemabygging-formio` commit by dispatching
`release-fyllut.yaml` in `skjemautfylling-formio`.

Run the commands from the `ws-innsending` workspace root.

## Branch conventions

`skjemabygging-formio` is the source repository and always uses its `main`
branch to find release candidates. `skjemautfylling-formio` is the target
repository and uses `master` by default for the release workflow. A user can
name another target branch, such as `test-publishing`.

## Choose the source commit

1. Fetch the latest `main` branch in `skjemabygging-formio`:

   ```bash
   git -C skjemabygging-formio fetch origin main
   ```

2. Ask for the `skjemautfylling-formio` target branch before listing candidates.
   Use `master` unless the user specifies another branch. List up to five recent
   commits whose `build-and-test.yaml` workflow completed successfully:

   ```bash
   plugins/devx/skills/release-fyllut/scripts/list-releasable-fyllut-commits.sh \
     <target-branch>
   ```

   The script examines the 25 newest `main` commits and returns the five newest
   with a successful, completed `build-and-test.yaml` run in
   `navikt/skjemabygging-formio`. That workflow builds the `fyllut-base` image.
   It reads `MONOREPO` from the target branch first and marks the matching
   candidate as currently deployed. It omits commits without a successful run
   and exits with an error if it cannot access GitHub.

3. Present the script's output and ask the user to confirm one. Do not offer
   commits without a successful build. Do not dispatch the workflow until the
   user confirms the selected full 40-character SHA.

## Dispatch the release

Use `skjemautfylling-formio:master` as the target unless the user specifies
another branch. Confirm that the target branch exists before dispatching:

```bash
gh api "repos/navikt/skjemautfylling-formio/git/ref/heads/<target-branch>"
```

Read the currently published monorepo commit from that branch:

```bash
gh api "repos/navikt/skjemautfylling-formio/contents/MONOREPO?ref=<target-branch>" \
  --jq .content | base64 --decode
```

Compare the returned full SHA with the selected commit before dispatching:

- If they match, report that the branch already references the selected commit.
  Do not dispatch the workflow.
- If the current `MONOREPO` commit is a descendant of the selected commit, the
  selected commit is older. Give an explicit rollback warning that includes both
  full SHAs, and ask the user to confirm the rollback before dispatching.
- If Git cannot compare the two commits, tell the user that their order is
  unknown. Do not describe it as a rollback.

Use Git ancestry to determine whether the selected commit is older:

```bash
git -C skjemabygging-formio merge-base --is-ancestor \
  <selected-full-sha> <current-monorepo-full-sha>
```

This command exits successfully when the current `MONOREPO` commit is newer
than the selected commit. Skip this comparison when the SHAs already match.

Dispatch the workflow with the selected full SHA. The workflow must run from the
target branch so its generated commit is pushed there:

```bash
gh workflow run release-fyllut.yaml \
  --repo navikt/skjemautfylling-formio \
  --ref <target-branch> \
  --field monorepoGitHash=<full-40-character-sha>
```

Report the target branch and full commit hash after GitHub accepts the dispatch.
