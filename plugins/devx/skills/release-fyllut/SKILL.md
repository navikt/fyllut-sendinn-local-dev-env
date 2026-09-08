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

2. Check the `fyllut-base` image for each of the ten newest commits. Use the
   production image repository and the full commit SHA as the image tag:

   ```bash
   IMAGE_REPOSITORY=europe-north1-docker.pkg.dev/nais-management-233d/skjemadigitalisering/skjemabygging-formio-fyllut-base

   git -C skjemabygging-formio log origin/main -10 --format='%H' |
     while read -r sha; do
       image="${IMAGE_REPOSITORY}:${sha}"

       if docker manifest inspect "$image" >/dev/null 2>&1; then
         git -C skjemabygging-formio show -s \
           --pretty=format:'%H%n%ad%n%an%n%s%n' --date=short "$sha"
       elif docker manifest inspect "$image" 2>&1 |
         grep -Eq 'manifest unknown|no such manifest|not found'; then
         printf 'Skipping %s because its fyllut-base image does not exist.\n' "$sha" >&2
       else
         printf 'Could not check %s. Check registry access and stop.\n' "$image" >&2
         exit 1
       fi
     done
   ```

3. Present only the commits whose `fyllut-base` image exists and ask the user to
   confirm one. Do not offer commits without an image. Do not dispatch the
   workflow until the user confirms the selected full 40-character SHA.

## Dispatch the release

Use `main` as the target branch unless the user specifies another branch. Confirm
that the target branch exists before dispatching:

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
