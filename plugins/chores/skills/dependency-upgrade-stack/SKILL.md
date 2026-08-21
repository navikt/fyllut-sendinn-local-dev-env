---
name: dependency-upgrade-stack
description: Replace open dependency update PRs with a tested GitHub stack. Use for periodic Maven, Gradle, npm, Docker image, or GitHub Actions upgrades when minor and patch updates should land before researched major updates.
disable-model-invocation: true
---

# Build a dependency upgrade stack

Create manual dependency upgrade PRs instead of merging bot PRs. Work in one repository unless the dependency contract crosses repository boundaries.

If the `unslop` skill is available, invoke it before writing branch names, commits, PR text, risk notes, or the final report. Do not assume every machine has it installed.

## Rules

- Read the repository's `AGENTS.md`, contribution guide, manifests, lockfiles, workflows, and validation commands first.
- Require a clean worktree before doing anything else. If `git status --porcelain` returns any entry, stop and tell the user which files are changed. Do not stash, commit, discard, or work around local changes.
- Require the `gh stack` extension. If `gh stack --help` fails, stop and tell the user it is not installed. Do not install it unless the user asks.
- Fetch `origin/main` and create the first stack branch directly from that remote-tracking branch. Never base the stack on local `main`, the current branch, or another remote. If `origin/main` does not exist, stop and notify the user.
- Treat bot PRs as leads. Query the package registry or upstream releases for the latest stable version available now.
- Exclude snapshots, release candidates, milestones, betas, and alphas unless the user asks for them.
- Only select a version whose release timestamp is more than seven full days old. Record the timestamp and source. If the newest stable release is too recent, use the newest eligible stable release instead.
- Do not upgrade to a Node.js major version until it has entered Long-Term Support according to the official Node.js release schedule. Exclude majors whose status is `Current`, even when they pass the seven-day release-age rule. Record the release status and source.
- Keep lockfiles, generated files, checksums, and dependency metadata in sync.
- Use package manager commands where they produce reliable edits. Review every resulting diff.
- Do not hide migration failures with exclusions, broad version overrides, skipped tests, or compatibility shims that bypass the new version.
- Delegate changelog and migration research to focused subagents, one related dependency group per agent. Ask each agent for authoritative source links, compatibility constraints, concrete risks, and required migration work. Keep the main context for repository decisions and implementation.
- Read authoritative release notes and migration guides for every major update. For a large minor update, research them when code generation, serialization, persistence, authentication, or deployment behavior may change.
- Put dependencies that must remain compatible in the same PR. Common examples are React and its types, Spring Boot and a matching springdoc major, an SDK and its plugins, or a framework and its test tools.
- Separate unrelated major updates. A framework migration should not share a PR with a CI action major.
- Put all GitHub Actions updates in one separate PR. Use major-only references such as `actions/checkout@v7`, never `actions/checkout@v7.0.3`. Make this the bottom PR in the stack when action updates exist.
- Put Docker image updates in one separate PR and treat that PR as a major change, even when the image publisher labels an update as minor. Runtime image changes can alter the application's operating environment.
- Wait for required GitHub checks after each PR. Fix failures before adding the next stack layer.
- Do not merge the stack unless the user asks.

## Inspect the repository

Start from the target repository and confirm:

1. Git status, branch, remotes, and default branch.
2. Open Dependabot or Renovate PRs and their diffs.
3. Dependency sources:
   - Maven `pom.xml`
   - Gradle build files, version catalogs, and wrapper
   - npm `package.json` and lockfile
   - Docker `FROM` lines and Compose image tags
   - GitHub Actions `uses` references
4. Existing build, test, lint, generated-code, and integration commands.
5. Confirm that `gh stack --help` succeeds before continuing.

Record each direct update with its current version, newest eligible stable version, release timestamp, timestamp source, update type, related package family, and expected risk. Also record newer versions excluded by the seven-day wait period.

## Find current versions

Do not copy stale bot targets.

For Maven, use the Versions plugin to inspect parent, property, dependency, plugin, and BOM updates. Check effective dependency management before changing an explicit override. A framework BOM may already manage the correct compatible version.

For Gradle, use the repository's dependency update task or version catalog tooling. Review rejected versions and resolution rules.

For npm, query the registry and use the repository's package manager. Respect workspaces and the pinned package manager. Inspect peer dependency ranges before grouping framework majors.

For Docker images, check the publisher's tags and release notes. Preserve digest pinning when the repository uses it. Confirm architecture support and migration notes for stateful services.

For GitHub Actions, check the latest eligible release for every referenced action. Search all workflow files so the repository does not run mixed majors by accident. Write only the major tag in workflow files, even when research uses a specific release to assess age and risk.

## Write every PR description

Every stack PR must contain:

- an exact version-change table, including release dates
- direct links to the changelog, release notes, migration guides, compatibility tables, or other authoritative sources used for research
- concrete risks and behavior reviewers should check
- local validation results and GitHub check status
- a separate `Migration work and decisions` section

In `Migration work and decisions`, call out every workaround, necessary rewrite, configuration adjustment, unexpected version pin, and judgment call. Explain why each one was needed and which reasonable alternatives were considered. If no migration work was needed, say so plainly.

## Handle GitHub Actions

When the repository has GitHub Actions updates, create their PR first so it becomes the bottom stack layer.

1. Include every eligible action update in that PR. Do not mix application, build plugin, or runtime dependencies into it.
2. Use major-only action references. `actions/checkout@v7` is correct. `actions/checkout@v7.0.3` is not.
3. Read release notes for major action updates. Check workflow triggers, permissions, runner requirements, and runtime changes.
4. Validate every workflow reference and wait for the PR checks before adding the next layer.

If no action updates are eligible, start the stack with compatible application patch and minor updates.

## Handle Docker and runtime versions

Put all Docker image updates in one separate major-change PR. Do not include them in the patch and minor PR.

- Prefer major-only image tags such as `FROM node:24-alpine`. Do not introduce minor or patch precision such as `FROM node:24.14.0-alpine`.
- If the repository already pins an image to a minor or patch version, preserve that precision unless the user asks to change the pinning policy.
- Before changing the Node.js major, verify that the target major has entered LTS using the official Node.js release schedule. Keep the current LTS major when the newest stable major is still `Current`.
- Keep the application's runtime declarations aligned with the image. Check `mise.toml` and other mise files, `.nvmrc`, `engines.node` in `package.json`, Node versions in workflows, Java toolchains, Maven `java.version` or compiler settings, Gradle toolchains, and Java versions in workflows.
- When Node changes, update `@types/node` to the compatible major in the same PR.
- Check native module support, architecture support, removed runtime features, garbage collector or memory defaults, TLS and certificate changes, and base distribution changes.

## Create the patch and minor PR

The patch and minor PR contains all compatible application and build dependency updates. It sits above the GitHub Actions PR when that PR exists. If one minor update has a meaningful breaking change, isolate it only when the repository cannot review or validate it safely with the rest.

1. Fetch and verify the required base:

   ```bash
   git fetch origin main
   git rev-parse --verify origin/main
   ```

2. If GitHub Actions updates exist, initialize the stack from `origin/main` with the actions branch and complete that PR first. Otherwise, initialize it with the patch and minor branch:

   ```bash
   git switch --detach origin/main
   gh stack init --base main <first-branch>
   ```

3. Add the patch and minor branch above the actions PR with `gh stack add <minor-branch>`, or use the initialized first branch when no actions PR exists.
4. Apply the newest eligible stable patch and minor updates.
5. Run the smallest complete repository-native validation. Use the same build command as CI when practical.
6. Commit with a plain description.
7. Submit the stack:

   ```bash
   gh stack submit --auto --open
   ```

8. Replace the generated PR body with the required PR description.
9. Wait for required checks:

   ```bash
   gh pr checks <number> --watch
   ```

Do not start Docker or other major work until this PR passes.

## Plan major PRs

For each major update:

1. Assign a focused research subagent to the related dependency group. Require direct links to the upstream migration guide, release notes, compatibility table, and known issues.
2. Search the repository for removed packages, renamed configuration keys, custom serializers, persistence converters, generated code flags, test utilities, and plugin APIs.
3. Check whether internal or third-party integrations support the new major.
4. Decide the PR boundary.

Keep a major group together when one member requires the other. Split it when dependencies can upgrade independently or when one change deserves a clear rollback boundary.

Write the risk assessment before editing. Name concrete failure modes such as JSON changes, schema output changes, authentication defaults, database migrations, runtime requirements, or CI permission changes.

## Add and verify each major layer

For every major group:

1. Add a branch from the current stack top:

   ```bash
   gh stack add <major-branch>
   ```

2. Apply the version changes and required migration work.
3. Run the full relevant validation.
4. Fix root causes. Framework majors often split modules or move packages. Add the supported module instead of recreating old behavior by hand.
5. Commit and submit:

   ```bash
   gh stack submit --auto --open
   ```

6. Write the required PR description. Include unresolved compatibility concerns and test counts.
7. Do not bury migration work or decisions in the version list.
8. Wait for GitHub checks before adding another layer.

If local tests pass but CI fails, inspect the failed job log. Reproduce the same command locally before changing code.

## Finish

Verify the stack order and PR bases with `gh stack view` and GitHub PR data. Confirm every required check passes.

Close superseded bot PRs only after the replacement stack exists and checks pass. Leave a short comment linking the replacement PR or stack. Never close unrelated update PRs.

Print a concise summary in chat after all work is complete. Give the human a high-level understanding of what was upgraded, what was not upgraded, and why. End with one direct link to the PR stack on GitHub. Use the canonical stack URL when GitHub exposes one; otherwise use the top PR as the stack entry point.

Report:

- stack order with PR links
- one direct GitHub link to the PR stack
- versions covered by each PR
- authoritative research sources used in each PR
- major migration risks
- workarounds, rewrites, adjustments, pins, and judgment calls
- local and GitHub check results
- any bot PRs closed as superseded
- any dependency intentionally left unchanged and why
- versions deferred because they had not passed the seven-day wait period
- Node.js majors deferred because they had not entered LTS

## Lessons from real upgrades

- Bot PRs can be weeks behind. Re-query every source before editing.
- A dependency override can silently defeat a framework BOM. Remove it when the framework now manages a compatible release.
- A framework major may compile before application contexts fail. Run tests that start the real application.
- Serialization migrations need more than import changes. Check mapper construction, custom modules, annotations, configuration keys, database converters, generated models, and response payloads.
- Modular frameworks may require explicit runtime and test starters that older versions pulled in transitively.
- Generated-code upgrades can change wire formats without changing handwritten source. Inspect generated diffs or exercise serialization in tests.
- GitHub Action majors may change security defaults only for certain triggers. Read every workflow trigger before rating the risk.
- GitHub Action majors can remove environment variables that package managers relied on indirectly. After upgrading setup actions, run non-install commands as well as installation and check generated registry configuration. Use a non-secret placeholder only when the package manager requires a variable to parse that configuration, and override it with the real secret only for the install step.
- A broad Yarn Classic lockfile refresh can update unrelated production dependencies and create failures that look like direct-package regressions. Start again from the original lockfile, update the smallest dependency set possible, and audit unchanged production entries before attributing a failure.
- Authenticate to every private package registry before changing manifests or lockfiles. Never commit local `file:` references, placeholder packages, or rewritten private registry metadata. Confirm that unchanged private entries retain their original version, resolved URL, and integrity hash.
- Minimal test environments may lack browser binaries, Xvfb, shared desktop libraries, or access to external resources loaded by the application. Separate environment and network failures from dependency failures before changing code, then run the same complete browser suite as CI.
- Mounted workspaces can cause intermittent linking and standalone-build errors during large JavaScript installs. Reproduce in a clean copy on a stable filesystem before treating those errors as repository defects, and let CI validate the final artifact.
- ESLint major compatibility requires running the real lint command. Declared peer support in the top-level parser does not prove that framework-bundled plugins, parsers, or older transitive copies support the new rule and scope APIs.
- A grouped bot PR may be only partly superseded when some dependencies pass and others are deferred. Leave it open unless a passing manual PR replaces the complete group.
