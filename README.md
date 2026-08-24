# Fyllut-Sendinn local development

Tools and configuration for the Team Fyllut-Sendinn development environment:

- [Copilot CLI plugins](plugins/README.md)
- [Docker sandbox](sbx/README.md)

Run `mise tasks` to list the repository's development tasks.

## Development

Start a sandbox for this repo

```sh
mise run sandbox:run
```

You can pass `--name` to choose a sandbox name:

```sh
mise run sandbox:run --name innsending
```

Validate the kit after making changes:

```sh
mise run sandbox:validate
```
