# LunaDash Community Plugins

This repository is the submission gate, registry, and browser website for LunaDash Plugin SDK 2.

Every community plugin lives under `plugins/<id>/` and enters the registry through a pull request. Validation is based on the same SDK 2 contracts used by LunaDash: the target registry, manifest validator, and settings-schema validator are synchronized from `LuYishan-4/LunaDash` branch `fix/plugin`.

The repository follows the publishing model of `caelestia-kde-plugins`—one plugin per directory, generated index, CI, and maintainer review—but the plugin format itself is LunaDash's.

## Publishing flow

```text
author -> plugins/<id>/ -> pull request -> SDK validation + review
       -> merge -> generated index.json -> Astro catalogue -> LunaDash Store
```

## SDK 2 plugin types

| Type | Purpose |
| --- | --- |
| `quickshell` | QML/JavaScript visual extensions |
| `effect` | C11/C++20 native synchronous SDK hooks |
| `opengl` | GLSL packages hosted by supported visual targets |

Each plugin also declares a LunaDash `target`. The authoritative target/type combinations are in `contracts/targets.json`.

## Repository layout

- `plugins/<id>/`: published plugins.
- `template-plugin/`: copy-me SDK 2 starter.
- `contracts/`: LunaDash SDK validator/settings/target snapshots.
- `schemas/`: editor-friendly JSON Schemas.
- `scripts/`: registry validation and index generation.
- `index.json`: catalogue consumed by LunaDash.
- `site/`: Astro browser site.

See [CONTRIBUTING.md](CONTRIBUTING.md) before submitting a plugin.

## Source of truth

The runtime contract comes from LunaDash:
- `docs/en/PLUGINS.md`
- `docs/en/PLUGIN_TARGETS.md`
- `docs/en/SETTINGS_API.md`
- `data/plugins/targets.json`
- `cmake/plugins/ValidatePlugin.py`
- `cmake/plugins/SettingsSchema.py`

Store-only fields never replace the LunaDash runtime manifest.
