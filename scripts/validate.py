#!/usr/bin/env python3
import json
import re
import sys
from pathlib import Path
from urllib.parse import urlparse

ROOT = Path(__file__).resolve().parents[1]
CONTRACTS = ROOT / "contracts"
sys.path.insert(0, str(CONTRACTS))

from ValidatePlugin import validate as validate_lunadash

PLUGINS = ROOT / "plugins"
TARGETS = json.loads((CONTRACTS / "targets.json").read_text())
BANNED_SUFFIXES = {
    ".so", ".o", ".a", ".dll", ".dylib", ".exe", ".qsb", ".pyc",
    ".zip", ".7z", ".rar", ".tar", ".gz", ".bz2", ".xz"
}

def require(ok, message):
    if not ok:
        raise ValueError(message)

def https(value):
    try:
        parsed = urlparse(value)
        return parsed.scheme == "https" and bool(parsed.netloc)
    except Exception:
        return False

def load_json(path, limit):
    require(path.is_file(), f"Missing {path.relative_to(ROOT)}")
    require(path.stat().st_size <= limit, f"Oversized {path.relative_to(ROOT)}")
    try:
        return json.loads(path.read_text())
    except json.JSONDecodeError as error:
        raise ValueError(f"Invalid JSON in {path.relative_to(ROOT)}: {error}") from error

def validate_store(folder, manifest):
    store = load_json(folder / "store.json", 32768)
    require(store.get("storeSchemaVersion") == 1, f"{manifest['id']}: storeSchemaVersion must be 1")
    allowed = {"storeSchemaVersion", "license", "repository", "homepage", "upstream",
               "screenshots", "featured", "deprecated", "replacement"}
    require(set(store) <= allowed,
            f"{manifest['id']}: unknown store.json fields: {sorted(set(store) - allowed)}")
    license_id = store.get("license")
    require(isinstance(license_id, str) and re.fullmatch(r"[A-Za-z0-9.+-]{1,80}", license_id),
            f"{manifest['id']}: invalid SPDX-style license id")
    require((folder / "LICENSE").is_file(), f"{manifest['id']}: LICENSE is required")
    require(https(store.get("repository", "")), f"{manifest['id']}: repository must use HTTPS")
    for key in ("homepage", "upstream"):
        if key in store:
            require(https(store[key]), f"{manifest['id']}: {key} must use HTTPS")
    screenshots = store.get("screenshots", [])
    require(isinstance(screenshots, list) and len(screenshots) <= 8 and
            len(set(screenshots)) == len(screenshots),
            f"{manifest['id']}: invalid screenshots")
    for name in screenshots:
        require(isinstance(name, str) and
                re.fullmatch(r"[A-Za-z0-9_.-]+\.(?:png|jpe?g|webp)", name, re.I),
                f"{manifest['id']}: invalid screenshot path {name!r}")
        path = folder / name
        require(path.is_file() and path.resolve().parent == folder.resolve() and
                path.stat().st_size <= 5 * 1024 * 1024,
                f"{manifest['id']}: missing or oversized screenshot {name}")
    deprecated = store.get("deprecated", False)
    require(type(deprecated) is bool, f"{manifest['id']}: deprecated must be boolean")
    if "featured" in store:
        require(type(store["featured"]) is bool, f"{manifest['id']}: featured must be boolean")
    if "replacement" in store:
        require(deprecated and isinstance(store["replacement"], str) and
                re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9._-]+", store["replacement"]),
                f"{manifest['id']}: replacement requires deprecated=true and a valid id")
    return store

def validate_package(folder):
    manifest = load_json(folder / "metadata.json", 65536)
    plugin_id = manifest.get("id", folder.name)
    require(folder.name == plugin_id,
            f"{folder.name}: directory must exactly match metadata id {plugin_id!r}")
    validate_lunadash(manifest, folder, TARGETS)
    require(manifest.get("enabledByDefault", False) is False,
            f"{plugin_id}: community store plugins must default to disabled")
    require((folder / "CMakeLists.txt").is_file(), f"{plugin_id}: CMakeLists.txt is required")
    cmake = (folder / "CMakeLists.txt").read_text()
    require("lunadash_add_plugin" in cmake,
            f"{plugin_id}: CMakeLists.txt must use lunadash_add_plugin")
    store = validate_store(folder, manifest)
    for path in folder.rglob("*"):
        if path.is_symlink():
            raise ValueError(f"{plugin_id}: symlinks are not accepted: {path.name}")
        if path.is_file() and path.suffix.lower() in BANNED_SUFFIXES:
            raise ValueError(f"{plugin_id}: generated/binary/archive file is not accepted: {path.name}")
        if path.name in {".lunadash-sdk.json", "Registration.c"}:
            raise ValueError(f"{plugin_id}: generated SDK files must not be submitted")
    return manifest, store

def main():
    require(PLUGINS.is_dir(), "plugins/ directory is missing")
    seen = set()
    packages = []
    for folder in sorted(p for p in PLUGINS.iterdir() if p.is_dir()):
        manifest, store = validate_package(folder)
        require(manifest["id"] not in seen, f"Duplicate plugin id {manifest['id']}")
        seen.add(manifest["id"])
        packages.append((manifest, store))
    for manifest, store in packages:
        replacement = store.get("replacement")
        if replacement:
            require(replacement in seen,
                    f"{manifest['id']}: replacement {replacement} is not in the registry")
    print(f"Validated {len(packages)} LunaDash SDK 2 plugin package(s).")

if __name__ == "__main__":
    try:
        main()
    except (OSError, ValueError, TypeError, KeyError, re.error) as error:
        raise SystemExit(f"Plugin store validation: {error}")
