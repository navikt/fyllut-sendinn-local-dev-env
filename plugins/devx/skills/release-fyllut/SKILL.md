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

## Choose the source commit

1. Fetch the latest `main` branch in the source repository:

   ```bash
   git -C skjemabygging-formio fetch origin main
   ```

2. List the ten newest commits from `origin/main`, including their full hashes:

   ```bash
   git -C skjemabygging-formio log origin/main -10 \
     --pretty=format:'%H%n%ad%n%an%n%s%n' --date=short
   ```

3. Present the commits clearly and ask the user to confirm one. Do not dispatch
   the workflow until the user confirms the selected full 40-character SHA.

## Dispatch the release

Use `main` as the target branch unless the user specifies another branch. Confirm
that the target branch exists before dispatching:

```bash
gh api "repos/navikt/skjemautfylling-formio/git/ref/heads/<target-branch>"
```

Dispatch the workflow with the selected full SHA. The workflow must run from the
target branch so its generated commit is pushed there:

```bash
gh workflow run release-fyllut.yaml \
  --repo navikt/skjemautfylling-formio \
  --ref <target-branch> \
  --field monorepoGitHash=<full-40-character-sha>
```

Report the target branch and full commit hash after GitHub accepts the dispatch.
