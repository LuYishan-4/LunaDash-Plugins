#!/usr/bin/env python3
import os
import subprocess
from pathlib import PurePosixPath

base = os.environ.get("GITHUB_BASE_REF", "main")
subprocess.run(["git", "fetch", "origin", base, "--depth=1"], check=True)
changed = subprocess.check_output(
    ["git", "diff", "--name-only", f"origin/{base}...HEAD"], text=True
).splitlines()

plugin_roots = set()
for name in changed:
    parts = PurePosixPath(name).parts
    if len(parts) >= 2 and parts[0] == "plugins":
        plugin_roots.add("/".join(parts[:2]))

if plugin_roots:
    if len(plugin_roots) != 1:
        raise SystemExit("A plugin PR may modify only one plugins/<id>/ directory.")
    root = next(iter(plugin_roots))
    outside = [name for name in changed
               if not (name == root or name.startswith(root + "/"))]
    if outside:
        raise SystemExit("Plugin PRs cannot mix infrastructure changes: " + ", ".join(outside))

print("PR scope check passed.")
