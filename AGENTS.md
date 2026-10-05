# Repository instructions

## Plugin version bumps

When changing a plugin's skills or other shipped files, bump its version in
both places in the same commit:

- `plugins/<plugin-name>/plugin.json`, in the top-level `version` field.
- `.github/plugin/marketplace.json`, in the matching `plugins` entry's
  `version` field.

Use the same new version in both files. If the existing versions differ, choose
the bump from the higher version and align both files.

Use a patch bump for fixes, wording changes, and upstream skill refreshes.
Use a minor bump for new skills or features, and a major bump for breaking
changes. Bump only the plugins affected by the change.

The marketplace's `metadata.version` is separate from individual plugin
versions. Do not bump it solely because a plugin changed.

Changes to repository documentation alone, including this file, do not require
a plugin version bump.
