# Docker sandbox

NAV recommends [cplt](https://github.com/navikt/cplt) for running agents in a sandbox, but it primarily supports single-repository workspaces. See the [multi-repository support issue](https://github.com/navikt/cplt/issues/165) for alternatives. This setup uses [Docker Sandboxes](https://docs.docker.com/ai/sandboxes/).

## Setup

1. [Install Docker Sandboxes](https://docs.docker.com/ai/sandboxes/install/).
2. Sign in and configure GitHub authentication:

   ```sh
   sbx login
   sbx secret set -g github -t "$(gh auth token)"
   ```

3. Build and load the custom Copilot image from the repository root:

   ```sh
   docker build -f sbx/templates/Dockerfile.sbx-copilot sbx/templates -t innsending-sbx-copilot
   docker save innsending-sbx-copilot:latest -o sbx/templates/innsending-sbx-copilot.tar
   sbx template load sbx/templates/innsending-sbx-copilot.tar
   sbx template ls
   ```

The image extends Docker's [Copilot template](https://docs.docker.com/ai/sandboxes/customize/templates/) with a nested Docker engine, Cypress dependencies, and [mise](https://mise.jdx.dev/) for managing project-specific tool versions.

## GitHub Packages

Before creating the sandbox, configure a GitHub token with `read:packages` access. Remove `--sandbox innsending` to share the secret with all sandboxes.

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

```sh
sbx run innsending-copilot --kit ./sbx/kits/copilot/
```

The agent name must be `innsending-copilot` because local kits cannot override the built-in `copilot` agent. The kit must be provided when creating the sandbox; it cannot be added later. Local kits require `kit.allowLocalKits` to be `true`, which is the default.

Validate the kit after making changes:

```sh
sbx kit validate ./sbx/kits/copilot/
```

### Manual setup

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
