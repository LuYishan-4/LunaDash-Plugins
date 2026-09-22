#!/usr/bin/env python3
import argparse
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PLUGINS = ROOT / "plugins"
OUTPUT = ROOT / "index.json"
RAW = "https://raw.githubusercontent.com/LuYishan-4/LunaDash-Plugins/main/plugins/{id}/{file}"
SOURCE = "https://github.com/LuYishan-4/LunaDash-Plugins/tree/main/plugins/{id}"
SITE = "https://luyishan-4.github.io/LunaDash-Plugins/plugins/{id}/"
IMAGE_SUFFIXES = (".png", ".jpg", ".jpeg", ".webp", ".svg")

def author_name(value):
    if isinstance(value, dict):
        return str(value.get("name", ""))
    return str(value or "")

def build():
    plugins = []
    for folder in sorted(p for p in PLUGINS.iterdir() if p.is_dir()):
        metadata = json.loads((folder / "metadata.json").read_text())
        store = json.loads((folder / "store.json").read_text())
        plugin_id = metadata["id"]
        icon = metadata.get("icon", "applications-system")
        if icon.lower().endswith(IMAGE_SUFFIXES):
            icon = RAW.format(id=plugin_id, file=icon)
        item = {
            "id": plugin_id,
            "name": metadata["name"],
            "description": metadata.get("description", ""),
            "version": metadata["version"],
            "author": author_name(metadata.get("author")),
            "icon": icon,
            "type": metadata["type"],
            "target": metadata["target"],
            "mode": metadata["mode"],
            "tags": metadata.get("tags", []),
            "sourceUrl": SOURCE.format(id=plugin_id),
            "siteUrl": SITE.format(id=plugin_id),
            "license": store["license"],
            "repository": store["repository"],
            "featured": store.get("featured", False),
            "deprecated": store.get("deprecated", False),
            "settings": metadata.get("settings", {})
        }
        for key in ("homepage", "upstream", "replacement"):
            if key in store:
                item[key] = store[key]
        if store.get("screenshots"):
            item["screenshots"] = [
                RAW.format(id=plugin_id, file=name) for name in store["screenshots"]
            ]
        plugins.append(item)
    return {"schemaVersion": 1, "format": "lunadash-plugin-index", "plugins": plugins}

def rendered():
    return json.dumps(build(), indent=2, ensure_ascii=False) + "\n"

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    expected = rendered()
    if args.check:
        current = OUTPUT.read_text() if OUTPUT.exists() else ""
        if current != expected:
            raise SystemExit("index.json is stale; run python3 scripts/build_index.py")
        print("index.json is up to date.")
        return
    OUTPUT.write_text(expected)
    print(f"Wrote {OUTPUT.relative_to(ROOT)}")

if __name__ == "__main__":
    main()
