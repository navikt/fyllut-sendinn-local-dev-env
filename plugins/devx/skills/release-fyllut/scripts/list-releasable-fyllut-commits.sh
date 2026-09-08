#!/usr/bin/env bash

set -euo pipefail

readonly image_repository="europe-north1-docker.pkg.dev/nais-management-233d/skjemadigitalisering/skjemabygging-formio-fyllut-base"
readonly limit="${1:-10}"

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
plugin_repository="$(git -C "$script_dir" rev-parse --show-toplevel)"
source_repository="$(dirname "$plugin_repository")/skjemabygging-formio"

git -C "$source_repository" fetch origin main

git -C "$source_repository" log origin/main "-${limit}" --format='%H' |
  while read -r sha; do
    image="${image_repository}:${sha}"

    if manifest_error="$(docker manifest inspect "$image" 2>&1)"; then
      git -C "$source_repository" show -s \
        --pretty=format:'%H%n%ad%n%an%n%s%n' --date=short "$sha"
    elif grep -Eqi 'manifest unknown|no such manifest|not found' <<<"$manifest_error"; then
      printf 'Skipping %s because its fyllut-base image does not exist.\n' "$sha" >&2
    else
      printf 'Could not check %s. Check registry access and stop.\n%s\n' \
        "$image" "$manifest_error" >&2
      exit 1
    fi
  done
