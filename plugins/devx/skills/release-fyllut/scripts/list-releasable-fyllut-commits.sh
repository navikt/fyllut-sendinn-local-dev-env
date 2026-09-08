#!/usr/bin/env bash

set -euo pipefail

readonly target_count="${1:-5}"
readonly scan_limit=25
readonly repository="navikt/skjemabygging-formio"
readonly workflow="build-and-test.yaml"

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
plugin_repository="$(git -C "$script_dir" rev-parse --show-toplevel)"
source_repository="$(dirname "$plugin_repository")/skjemabygging-formio"

git -C "$source_repository" fetch origin main

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
