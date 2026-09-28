#!/usr/bin/env python3
"""Fetch OpenUpgrade upgrade_analysis.txt files for core Odoo modules.

The analysis files list the data-model changes of each core module: fields
added, removed or retyped, obsolete models, and added or deleted XML records.
Their path carries the module's target version (scripts/sale/19.0.1.2/...),
which moves whenever the core module's version is bumped, so the path is
resolved from the branch on every run rather than hardcoded.

    python3 openupgrade_analysis.py sale stock
    python3 openupgrade_analysis.py --manifest path/to/__manifest__.py
    python3 openupgrade_analysis.py --list
"""

from __future__ import annotations

import argparse
import ast
import json
import sys
import urllib.error
import urllib.request

TREE_URL = "https://api.github.com/repos/OCA/OpenUpgrade/git/trees/{branch}?recursive=1"
RAW_URL = "https://raw.githubusercontent.com/OCA/OpenUpgrade/{branch}/{path}"
PREFIX = "openupgrade_scripts/scripts/"
FILENAME = "upgrade_analysis.txt"


def get(url: str) -> bytes:
    with urllib.request.urlopen(url, timeout=60) as response:
        return response.read()


def analysis_paths(branch: str) -> dict[str, str]:
    """Map each core module name to its analysis file path on the branch."""
    tree = json.loads(get(TREE_URL.format(branch=branch)))
    if tree.get("truncated"):
        sys.exit(f"the {branch} tree came back truncated, clone the repository instead")
    paths = (entry["path"] for entry in tree["tree"])
    return {
        path[len(PREFIX):].split("/")[0]: path
        for path in paths
        if path.startswith(PREFIX) and path.endswith("/" + FILENAME)
    }


def manifest_depends(manifest_path: str) -> list[str]:
    manifest = ast.literal_eval(open(manifest_path, encoding="utf-8").read())
    return manifest.get("depends", [])


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("modules", nargs="*", help="core module names")
    parser.add_argument("--manifest", help="read the module names from this __manifest__.py")
    parser.add_argument("--branch", default="19.0", help="OpenUpgrade branch (default: 19.0)")
    parser.add_argument("--list", action="store_true", help="list every module that has an analysis file")
    args = parser.parse_args()

    try:
        paths = analysis_paths(args.branch)
    except urllib.error.URLError as error:
        sys.exit(f"cannot reach GitHub: {error}")

    if args.list:
        print("\n".join(sorted(paths)))
        return

    modules = args.modules + (manifest_depends(args.manifest) if args.manifest else [])
    if not modules:
        parser.error("name at least one module, or pass --manifest")

    for module in dict.fromkeys(modules):
        path = paths.get(module)
        if path is None:
            print(f"=== {module}: no analysis file, the module is unchanged or is not a core module\n")
            continue
        print(f"=== {module}: {path}")
        print(get(RAW_URL.format(branch=args.branch, path=path)).decode("utf-8"))


if __name__ == "__main__":
    main()
