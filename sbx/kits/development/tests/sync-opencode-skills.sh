#!/bin/sh
set -eu

kit_dir=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
tmp=$(mktemp -d)
trap 'chmod -R u+w "$tmp"; rm -rf "$tmp"' EXIT

home="$tmp/home"
repo="$home/.local/share/fyllut-sendinn-local-dev-env"
bin_dir="$tmp/bin"
source_repo="$tmp/source"

mkdir -p \
  "$bin_dir" \
  "$home/.config/opencode/skills" \
  "$source_repo/plugins/test/skills/example"
printf '%s\n' '---' 'name: example' 'description: Test skill' '---' \
  > "$source_repo/plugins/test/skills/example/SKILL.md"
git -C "$source_repo" init -q
git -C "$source_repo" add .
git -C "$source_repo" \
  -c user.name=Test \
  -c user.email=test@example.com \
  commit -qm "test fixture"
git clone -q "$source_repo" "$repo"
ln -s /usr/bin/true "$bin_dir/opencode"
chmod a-w "$home/.config/opencode/skills"

HOME="$home" PATH="$bin_dir:$PATH" \
  sh "$kit_dir/files/home/.local/bin/sync-fyllut-sendinn-opencode-skills"

test -L "$home/.agents/skills/example"
test "$(readlink "$home/.agents/skills/example")" = \
  "$repo/plugins/test/skills/example"
test ! -e "$home/.config/opencode/skills/example"

mkdir -p "$repo/plugins/test/skills/external"
printf '%s\n' '---' 'name: external' 'description: External skill' '---' \
  > "$repo/plugins/test/skills/external/SKILL.md"
ln -s "$repo/plugins/test/skills/example" "$home/.agents/skills/external"

if HOME="$home" PATH="$bin_dir:$PATH" \
  sh "$kit_dir/files/home/.local/bin/sync-fyllut-sendinn-opencode-skills"
then
  echo "Expected unmanaged skill symlink to be rejected" >&2
  exit 1
fi

test "$(readlink "$home/.agents/skills/external")" = \
  "$repo/plugins/test/skills/example"
