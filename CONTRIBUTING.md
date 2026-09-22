# Contributing plugins

All community plugins are submitted through this repository.

## Required package layout

```text
plugins/<id>/
├── metadata.json
├── store.json
├── CMakeLists.txt
├── LICENSE
└── source/assets declared by the plugin
```

The directory name must exactly match `metadata.json:id`.

## Runtime manifest

`metadata.json` is a LunaDash Plugin SDK 2 manifest:

```json
{
  "schemaVersion": 2,
  "sdk": {"name": "LunaDash", "apiVersion": 2},
  "id": "org.example.plugin",
  "name": "Example plugin",
  "description": "What the plugin does.",
  "version": "1.0.0",
  "author": {"name": "Your name"},
  "icon": "applications-system",
  "type": "quickshell",
  "target": "desktop-widgets",
  "mode": "augment",
  "entry": "Main.qml",
  "enabledByDefault": false,
  "tags": ["Widget"],
  "settings": {}
}
```

CI calls the copied LunaDash validator in `contracts/ValidatePlugin.py`. Accepted target/type combinations come from `contracts/targets.json`.

### Types
- `quickshell`: local QML entry.
- `effect`: native SDK 2 source; the manifest entry names the installed shared library.
- `opengl`: GLSL vertex/fragment sources compiled by the LunaDash SDK.

### Modes
- `replace`: replace the built-in target after successful load.
- `augment`: run alongside/after the built-in target.

### Settings
LunaDash generates settings controls from the manifest. The shared contract supports booleans, strings, integers, numbers and supported arrays. Controls include `toggle`, `select`, `number`, and `slider`; omitted controls are inferred by LunaDash.

## Store metadata

`store.json` is registry metadata. Required fields:
- `storeSchemaVersion: 1`
- `license`
- `repository` using HTTPS

Optional fields: `homepage`, `upstream`, `screenshots`, `featured`, `deprecated`, and `replacement`.

## Rules

- Source only: do not submit built libraries, object files, generated shader packages, SDK receipts, or archives.
- One plugin change per plugin PR. Infrastructure changes use a separate PR.
- Published IDs are stable; deprecate an old ID rather than renaming it.
- Bump the plugin version when updating a published plugin.
- Community plugins default to disabled. Native effects are also required by LunaDash to default to disabled.
- Include a license and keep package paths local to the plugin directory.
- Passing CI is required, and a maintainer still reviews the source.

## Local checks

```sh
python3 scripts/validate.py
python3 scripts/check_safety.py
python3 scripts/build_index.py --check

cd site
npm install
npm run check
npm run build
```

Plugin PRs do not edit `index.json`; it is regenerated after merge.
