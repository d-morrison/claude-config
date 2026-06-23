#!/usr/bin/env python3
"""Check that vendored files match their manifest hashes.

`shared/vendored/` holds pinned copies of fragments authored in another repo
(see README, "Shared content"). Each copy is recorded in a `MANIFEST.json` with
a content `sha256`. This check recomputes each file's hash and asserts it matches
the manifest, so a hand-edit to a vendored copy fails CI -- those files must be
edited upstream and refreshed by the sync workflow, not changed here.

Exits 1 on any mismatch, missing file, or malformed manifest; prints a success
line otherwise. No network access.
"""
from __future__ import annotations

import hashlib
import json
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
MANIFESTS = sorted(REPO_ROOT.glob("shared/vendored/**/MANIFEST.json"))


def sha256_of(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def check_manifest(manifest_path: Path, errors: list[str]) -> int:
    rel = manifest_path.relative_to(REPO_ROOT)
    try:
        data = json.loads(manifest_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        errors.append(f"{rel}: cannot read manifest ({exc})")
        return 0
    files = data.get("files")
    if not isinstance(files, list):
        errors.append(f"{rel}: 'files' missing or not a list")
        return 0
    verified = 0
    for entry in files:
        if not isinstance(entry, dict):
            errors.append(f"{rel}: 'files' entry is not an object: {entry!r}")
            continue
        path_str = entry.get("path")
        expected = entry.get("sha256")
        if not path_str or not expected:
            errors.append(f"{rel}: entry missing 'path' or 'sha256': {entry!r}")
            continue
        vendored = REPO_ROOT / path_str
        if not vendored.resolve().is_relative_to(REPO_ROOT):
            errors.append(f"{path_str}: path escapes the repo root; refusing to read")
            continue
        if not vendored.is_file():
            errors.append(f"{path_str}: listed in {rel} but missing on disk")
            continue
        actual = sha256_of(vendored)
        if actual != expected:
            errors.append(
                f"{path_str}: sha256 mismatch (manifest {expected[:12]}..., "
                f"file {actual[:12]}...). Don't edit vendored copies; "
                f"edit upstream and let the sync workflow refresh them."
            )
            continue
        verified += 1
    return verified


def main() -> int:
    if not MANIFESTS:
        print("✓ no vendored manifests to check")
        return 0
    errors: list[str] = []
    checked = 0
    for manifest in MANIFESTS:
        checked += check_manifest(manifest, errors)
    if errors:
        print("Vendored drift check failed:")
        for err in errors:
            print(f"  - {err}")
        return 1
    print(f"✓ {checked} vendored file(s) match their manifest hashes")
    return 0


if __name__ == "__main__":
    sys.exit(main())
