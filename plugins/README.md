# Copilot plugins

This repository is a Copilot CLI plugin marketplace named
`fyllut-sendinn-plugins`. It publishes the `chores`, `devx`, and
`specification` plugins.

## Local development

Install the plugin directly while developing it:

```sh
copilot plugin install ./plugins/chores
copilot plugin install ./plugins/devx
copilot plugin install ./plugins/specification
```

Local plugin installs are cached. Run the same command again after changing the
plugin, then verify the skill in an interactive session:

```text
/skills info dependency-upgrade-stack
```

## Install in another repository

Add `.github/copilot/settings.json` to the consuming repository:

```json
{
  "extraKnownMarketplaces": {
    "fyllut-sendinn-plugins": {
      "source": {
        "source": "github",
        "repo": "navikt/fyllut-sendinn-local-dev-env"
      }
    }
  },
  "enabledPlugins": {
    "chores@fyllut-sendinn-plugins": true,
    "devx@fyllut-sendinn-plugins": true
  }
}
```

Copilot CLI and Copilot cloud agent read these repository settings. The plugin
is automatically installed and enabled only while working in that repository.
Users must have access to this repository if it is private.

The equivalent manual setup is:

```sh
copilot plugin marketplace add navikt/fyllut-sendinn-local-dev-env
copilot plugin install chores@fyllut-sendinn-plugins
copilot plugin install devx@fyllut-sendinn-plugins
copilot plugin install specification@fyllut-sendinn-plugins
```

## Automatic updates

Repository settings can auto-install a plugin, but they cannot opt a custom
marketplace into session-start updates. Each user must add `autoUpdate: true`
to the marketplace entry in `~/.copilot/settings.json`:

```json
{
  "extraKnownMarketplaces": {
    "fyllut-sendinn-plugins": {
      "source": {
        "source": "github",
        "repo": "navikt/fyllut-sendinn-local-dev-env"
      },
      "autoUpdate": true
    }
  }
}
```

Preserve any existing settings when adding this entry. Automatic updates run at
the start of interactive and `copilot -p` sessions, but not SDK or server
sessions. For centralized rollout, place the same marketplace entry in Copilot
enterprise managed settings instead of requiring each user to configure it.

To update manually:

```sh
copilot plugin update chores@fyllut-sendinn-plugins
copilot plugin update devx@fyllut-sendinn-plugins
copilot plugin update specification@fyllut-sendinn-plugins
```

When publishing a change, increment the plugin version in both its
`plugin.json` and `.github/plugin/marketplace.json`.
