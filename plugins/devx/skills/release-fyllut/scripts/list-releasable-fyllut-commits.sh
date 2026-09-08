#!/usr/bin/env bash

set -euo pipefail

readonly target_branch="${1:-main}"
readonly target_count=5
readonly scan_limit=25
readonly repository="navikt/skjemabygging-formio"
readonly workflow="build-and-test.yaml"
readonly target_repository="navikt/skjemautfylling-formio"

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
plugin_repository="$(git -C "$script_dir" rev-parse --show-toplevel)"
source_repository="$(dirname "$plugin_repository")/skjemabygging-formio"

git -C "$source_repository" fetch origin main

if ! current_monorepo_sha="$(
  gh api "repos/${target_repository}/contents/MONOREPO?ref=${target_branch}" \
    --jq .content | base64 --decode
)"; then
  printf 'Could not read MONOREPO from %s:%s. Check GitHub access and stop.\n' \
    "$target_repository" "$target_branch" >&2
  exit 1
fi

if ! [[ "$current_monorepo_sha" =~ ^[0-9a-f]{40}$ ]]; then
  printf 'MONOREPO on %s:%s does not contain a full commit SHA. Stop.\n' \
    "$target_repository" "$target_branch" >&2
  exit 1
fi

printf 'Current MONOREPO on %s: %s\n\n' "$target_branch" "$current_monorepo_sha"

listed_count=0

while read -r sha; do
  if ! run_status="$(gh run list \
    --repo "$repository" \
    --workflow "$workflow" \
    --branch main \
    --commit "$sha" \
    --status completed \
    --json conclusion \
    --jq 'any(.[]; .conclusion == "success")')"; then
    printf 'Could not check the build workflow for %s. Check GitHub access and stop.\n' \
      "$sha" >&2
    exit 1
  fi

  if [ "$run_status" = true ]; then
    git -C "$source_repository" show -s \
      --pretty=format:'%H%n%ad%n%an%n%s%n' --date=short "$sha"

    if [ "$sha" = "$current_monorepo_sha" ]; then
      printf 'Currently deployed on %s\n' "$target_branch"
    fi

    listed_count=$((listed_count + 1))

    if [ "$listed_count" -eq "$target_count" ]; then
      break
    fi
  elif [ "$run_status" = false ]; then
    printf 'Skipping %s because build-and-test.yaml has no successful run.\n' "$sha" >&2
  else
    printf 'Could not determine build status for %s. Check GitHub access and stop.\n' \
      "$sha" >&2
    exit 1
  fi
done < <(git -C "$source_repository" log origin/main "-${scan_limit}" --format='%H')
