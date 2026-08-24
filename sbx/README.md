# Docker sandbox

NAV recommends [cplt](https://github.com/navikt/cplt) for running agents in a sandbox, but it primarily supports single-repository workspaces. See the [multi-repository support issue](https://github.com/navikt/cplt/issues/165) for alternatives. This setup uses [Docker Sandboxes](https://docs.docker.com/ai/sandboxes/).

## Setup

1. [Install Docker Sandboxes](https://docs.docker.com/ai/sandboxes/install/).
2. Sign in and configure GitHub authentication:

   ```sh
   sbx login
   sbx secret set -g github -t "$(gh auth token)"
   ```

The image extends Docker's [Copilot template](https://docs.docker.com/ai/sandboxes/customize/templates/) with a nested Docker engine, Cypress dependencies, and [mise](https://mise.jdx.dev/) for managing project-specific tool versions.

## Development in this repository

First, build and load the custom Copilot image from the repository root:

```sh
mise run sandbox:build
```

Start a sandbox:

```sh
mise run sandbox:run
```

Or you can pass `--name` to choose a sandbox name:

```sh
mise run sandbox:run --name innsending
```

Validate the kit after making changes:

```sh
mise run sandbox:validate
```

## GitHub Packages access

Before creating the sandbox, configure a GitHub token with `read:packages` access. Running this command is necessary if you need access to download @navikt npm packages. Remove `--sandbox innsending` to share the secret with all sandboxes. 

```sh
read -s PACKAGE_TOKEN
sbx secret set-custom \
  --sandbox innsending \
  --host npm.pkg.github.com \
  --env NODE_AUTH_TOKEN \
  --value "$PACKAGE_TOKEN"
unset PACKAGE_TOKEN
```

## Start the sandbox

From the workspace containing the checked-out repositories, use either the kit or the manual setup.

### Kit (recommended)

The kit uses the custom image and includes the required network policy:

Allow kits from the NAV GitHub organization and create the sandbox directly from the kit's Git URL:

```sh
sbx settings set kit.allowedSources '["docker.io/","github.com/navikt/"]'
```

```sh
sbx run innsending-copilot --name ws1 --kit "git+https://github.com/navikt/fyllut-sendinn-local-dev-env.git#dir=sbx/kits/copilot"
```

`innsending-copilot` is the agent name defined by the kit, while `ws1` is the name of the sandbox. The kit only needs to be specified when the sandbox is created. To run the same sandbox later, omit `--kit`:

```sh
sbx run innsending-copilot --name ws1
```

The agent name remains `innsending-copilot` because kits cannot override the built-in `copilot` agent. Local kits require `kit.allowLocalKits` to be `true`, which is the default.

### Manual setup (without kit)

```sh
sbx run copilot -t innsending-sbx-copilot:latest
sbx policy allow network --sandbox <sandbox-name> "archive.apache.org:443,download.cypress.io:443,github-package-registry-mirror.gc.nav.no:443,mise-java.jdx.dev:443,packages.confluent.io:443,repo1.maven.org:443,cdn.nav.no:443,www.nav.no:443,cdn.cypress.io:443"
```

## Troubleshooting

Inspect blocked network requests and add required hosts to `permissions.network.allow` in `sbx/kits/copilot/spec.yaml`:

```sh
sbx policy log
```

Unpublish a port:

```sh
sbx ports <sandbox-name> --unpublish <host-port>:<sandbox-port>
```
