#!/usr/bin/env python3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PLUGINS = ROOT / "plugins"
BANNED_SUFFIXES = {
    ".so", ".o", ".a", ".dll", ".dylib", ".exe", ".qsb", ".pyc",
    ".zip", ".7z", ".rar", ".tar", ".gz", ".bz2", ".xz"
}

errors = []
for folder in sorted(p for p in PLUGINS.iterdir() if p.is_dir()):
    for path in folder.rglob("*"):
        if not path.is_file():
            continue
        if path.suffix.lower() in BANNED_SUFFIXES:
            errors.append(f"{path.relative_to(ROOT)}: compiled/generated/archive files are not accepted")
        if path.name in {".lunadash-sdk.json", "Registration.c"}:
            errors.append(f"{path.relative_to(ROOT)}: generated SDK files are not accepted")
        if path.stat().st_size > 10 * 1024 * 1024:
            errors.append(f"{path.relative_to(ROOT)}: individual files may not exceed 10 MiB")

if errors:
    print("\n".join("ERROR: " + item for item in errors))
    raise SystemExit(1)

print("Source-only safety checks passed.")
