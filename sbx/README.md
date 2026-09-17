# Docker sandbox

NAV recommends [cplt](https://github.com/navikt/cplt) for running agents in a
sandbox, but it primarily supports single-repository workspaces. See the
[PRD: Sessions that span several repositories](https://github.com/navikt/cplt/issues/344).

This setup uses [Docker Sandboxes](https://docs.docker.com/ai/sandboxes/).

## Development mixin

`sbx/kits/development` is a schema-v2 mixin for the FyllUt and SendInn
repositories. It adds:

- System packages required by the frontend tools and Cypress
- [mise](https://mise.jdx.dev/) and its shims on `PATH`
- The `github/gh-stack` GitHub CLI extension
- The required network allow list
- `USE_BUILTIN_RIPGREP=false` for Copilot CLI on arm64 hosts with 16 KB pages

The mixin is separate from the agent. It can be combined with Copilot,
OpenCode, T3 Code, and other agents that use a Debian-based image.

## Setup

1. [Install Docker Sandboxes](https://docs.docker.com/ai/sandboxes/install/).
2. Sign in and configure the GitHub service credential used by `gh` and Git:

   ```sh
   sbx login
   sbx secret set github --command 'gh auth token'
   ```

3. Configure Copilot's separate credential using the token from the host's
   authenticated GitHub CLI:

   ```sh
   sbx secret set copilot --command 'gh auth token'
   ```

   The built-in Copilot kit uses `GH_TOKEN` for GitHub and
   `COPILOT_GITHUB_TOKEN` for the Copilot API. Both services may resolve the
   same host token, but they remain separate so the proxy injects it only into
   the domains declared for each service. The token must belong to an account
   with an active Copilot subscription.

4. Allow kits from this repository's GitHub organization in addition to Docker
   Hub:

   ```sh
   sbx settings set kit.allowedSources '["docker.io/","github.com/navikt/"]'
   ```

## GitHub Packages

Some repository `.npmrc` files and lockfiles resolve `@navikt` packages from
`npm.pkg.github.com`. Configure `NODE_AUTH_TOKEN` even when the same package is
also publicly available from npmjs, because the configured registry and locked
tarball URL determine where the package manager downloads it.

First verify that the host GitHub CLI token has the `read:packages` scope:

```sh
gh auth status
```

If the scope is missing, add it and verify again:

```sh
gh auth refresh -h github.com -s read:packages
gh auth status
```

Register the current GitHub CLI token as a global custom secret. The command is
resolved on demand, and the real token remains on the host:

```sh
sbx secret set-custom \
  --host npm.pkg.github.com \
  --env NODE_AUTH_TOKEN \
  --command 'gh auth token'
```

The command prints a generated `sbx-cs-...` placeholder. New sandboxes created
after the global secret is registered receive this `NODE_AUTH_TOKEN` placeholder
automatically, and the development mixin writes it to npm's user configuration
during creation. The real token remains on the host and the sandbox proxy
substitutes it for requests to `npm.pkg.github.com`.

## Create Sandboxes

A mixin is applied only when the sandbox is created, so remove an existing
sandbox before recreating it with changed kit configuration. These examples
load the development mixin directly from its GitHub repository, so this
repository does not need to be checked out locally.

### Copilot

The built-in `copilot` agent supplies the standard `copilot-docker` image:

```sh
sbx create copilot ~/ws-innsending \
  --name ws01 \
  --kit "git+https://github.com/navikt/fyllut-sendinn-local-dev-env.git#dir=sbx/kits/development"
```

### OpenCode

```sh
sbx create opencode ~/Projects/ws4 \
  --name ws4 \
  --kit "git+https://github.com/navikt/fyllut-sendinn-local-dev-env.git#dir=sbx/kits/development"
```

### OpenCode With T3 Code

Add the T3 Code mixin when the sandbox will be accessed through T3 Code:

```sh
sbx create opencode ~/Projects/ws4 \
  --name ws4 \
  --kit docker.io/sbx/t3code-kit:latest \
  --kit "git+https://github.com/navikt/fyllut-sendinn-local-dev-env.git#dir=sbx/kits/development"
```

## Use The Sandbox

Attach to the configured agent:

```sh
sbx run --name <sandbox-name>
```

Open a shell:

```sh
sbx exec -it <sandbox-name> bash
```

Run repository commands through mise so the versions pinned in each
repository's `mise.toml` are used. For example:

```sh
sbx exec <sandbox-name> -- bash -lc \
  'cd /path/to/repository && mise install && mise exec -- pnpm install --frozen-lockfile'
```

## Develop The Mixin

Validate the mixin after making changes:

```sh
mise run sandbox:validate
```

To test uncommitted changes, replace the Git URL in any creation command with a
path to the local kit and run the command from this repository's root:

```sh
--kit "$(pwd)/sbx/kits/development"
```

Local kits require `kit.allowLocalKits` to be `true`, which is the default.

## Troubleshooting

Inspect blocked requests and proxy routing:

```sh
sbx policy log
```

Requests using proxy-managed credentials must show `forward` rather than
`forward-bypass`. A `forward-bypass` request sends the placeholder without
credential substitution.

### GitHub Credential Proxy Regression

Docker Sandboxes v0.43.0 has an open
[credential-proxy issue](https://github.com/docker/sbx-releases/issues/595)
where requests to GitHub may use `forward-bypass`. In that case, `GH_TOKEN`
contains a proxy placeholder that GitHub rejects as invalid. Confirm the
problem only after confirming that both required service secrets exist:

```sh
sbx secret ls
```

The output should include global `github` and `copilot` service secrets. Run
`gh auth status` inside the sandbox and check the host's policy log:

```sh
sbx policy log
```

If `github` is configured but `gh auth status` still fails because GitHub
requests use `forward-bypass`, pass the host's real GitHub token into the agent
session:

```sh
GH_TOKEN="$(gh auth token)" sbx run --name <sandbox-name> -e GH_TOKEN
```

For a new sandbox, pass it during creation:

```sh
GH_TOKEN="$(gh auth token)" sbx create opencode /path/to/workspace \
  --name <sandbox-name> \
  -e GH_TOKEN \
  --kit "git+https://github.com/navikt/fyllut-sendinn-local-dev-env.git#dir=sbx/kits/development"
```

This workaround weakens the sandbox's credential isolation. The real token is
placed in the sandbox environment instead of remaining on the host behind the
credential proxy. Processes and agents inside the sandbox can read and exfiltrate
it, and a value supplied during creation is stored with the sandbox for future
sessions. Prefer a narrowly scoped token, avoid untrusted code while using the
workaround, remove the sandbox when finished, and return to the proxy-managed
credential as soon as the upstream issue is fixed.

### GitHub Packages In An Existing Sandbox

A global custom secret is applied automatically only to sandboxes created after
the secret was registered. To update an existing sandbox, copy the safe
`sbx-cs-...` placeholder shown by `sbx secret set-custom` or `sbx secret ls`,
then configure npm inside that sandbox:

```sh
NODE_AUTH_PLACEHOLDER='<paste-sbx-cs-placeholder>'
sbx exec -e NODE_AUTH_TOKEN="$NODE_AUTH_PLACEHOLDER" <sandbox-name> -- \
  bash -lc 'npm config set "//npm.pkg.github.com/:_authToken" "$NODE_AUTH_TOKEN" --location=user'
```

Test the credential without changing a repository:

```sh
sbx exec -e NODE_AUTH_TOKEN="$NODE_AUTH_PLACEHOLDER" <sandbox-name> -- \
  bash -lc 'npm view @navikt/fnrvalidator@2.2.1 version --registry=https://npm.pkg.github.com'
```

If a global and a sandbox-scoped custom secret both use `NODE_AUTH_TOKEN`, the
sandbox cannot synchronize them. Use `sbx secret ls` to find the duplicate and
remove the sandbox-scoped entry by its placeholder:

```sh
sbx secret rm --sandbox <sandbox-name> --placeholder <duplicate-placeholder> --force
```

Unpublish a port:

```sh
sbx ports <sandbox-name> --unpublish <host-port>:<sandbox-port>
```
