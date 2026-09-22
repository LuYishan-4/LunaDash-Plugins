# Registry ingestion contract

LunaDash Store reads `index.json` over HTTPS.

```json
{
  "schemaVersion": 1,
  "format": "lunadash-plugin-index",
  "plugins": []
}
```

The current LunaDash catalogue parser requires every entry to have a valid unique `id`, non-empty `name` and `version`, a `type` accepted by the declared `target`, and valid optional tags. Remote icon/source URLs use HTTPS.

Generated fields include `id`, `name`, `description`, `version`, `author`, `icon`, `type`, `target`, `mode`, `tags`, and `sourceUrl`.

Extra reviewed fields such as `siteUrl`, `license`, `repository`, `settings`, screenshots, and deprecation metadata are retained for the website and future installer.

The runtime manifest remains `plugins/<id>/metadata.json`. The index is discovery metadata, not a replacement for package validation.
