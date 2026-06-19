#!/usr/bin/env python3
"""Validate ai-config skills and plugin manifests.

Clean-room reimplementation inspired by the MIT-licensed validators in
terrylica/cc-skills (`validate-plugins.mjs`) and
jeremylongshore/claude-code-plugins-plus-skills (`validate-skills-schema.py`).
No source was copied; see CREDITS.md.

Checks:
  * every skills/<name>/ has a SKILL.md with parseable YAML frontmatter
  * frontmatter has non-empty `name` and `description`
  * `name` matches the directory name
  * `user-invocable` (if present) is a bool
  * `allowed-tools` (if present) is a list of strings
  * .claude-plugin/marketplace.json and plugin.json are valid JSON with the
    required top-level keys

Exits non-zero if any error is found.
"""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

try:
    import yaml
except ImportError:  # pragma: no cover
    sys.exit("validate-skills: PyYAML is required — run `pip install pyyaml`.")

ROOT = Path(__file__).resolve().parent.parent
errors: list[str] = []
warnings: list[str] = []


FRONTMATTER = re.compile(r"\A---\r?\n(.*?)\r?\n---\r?\n", re.S)


def parse_frontmatter(text: str, where: str):
    match = FRONTMATTER.match(text)
    if not match:
        errors.append(
            f"{where}: missing or unterminated YAML frontmatter "
            "(expected a '---' block at the very top of the file)"
        )
        return None
    try:
        data = yaml.safe_load(match.group(1))
    except yaml.YAMLError as exc:
        errors.append(f"{where}: invalid YAML frontmatter: {exc}")
        return None
    if not isinstance(data, dict):
        errors.append(f"{where}: frontmatter is not a mapping")
        return None
    return data


def check_skill(skill_dir: Path) -> None:
    skill_md = skill_dir / "SKILL.md"
    rel = skill_md.relative_to(ROOT)
    if not skill_md.is_file():
        errors.append(f"{skill_dir.relative_to(ROOT)}: no SKILL.md")
        return
    fm = parse_frontmatter(skill_md.read_text(encoding="utf-8"), str(rel))
    if fm is None:
        return
    name = fm.get("name")
    if not name or not str(name).strip():
        errors.append(f"{rel}: frontmatter `name` is missing or empty")
    elif name != skill_dir.name:
        errors.append(f"{rel}: `name: {name}` does not match directory `{skill_dir.name}`")
    desc = fm.get("description")
    if not desc or not str(desc).strip():
        errors.append(f"{rel}: frontmatter `description` is missing or empty")
    if "user-invocable" in fm and not isinstance(fm["user-invocable"], bool):
        errors.append(f"{rel}: `user-invocable` must be true or false")
    tools = fm.get("allowed-tools")
    if tools is not None and (
        not isinstance(tools, list) or not all(isinstance(t, str) for t in tools)
    ):
        errors.append(f"{rel}: `allowed-tools` must be a list of strings")


def check_skills() -> None:
    skills_dir = ROOT / "skills"
    if not skills_dir.is_dir():
        warnings.append("no skills/ directory")
        return
    count = 0
    for child in sorted(skills_dir.iterdir()):
        if child.is_dir() and not child.name.startswith("."):
            count += 1
            check_skill(child)
    print(f"  checked {count} skills")


def check_json(rel: str, required: list[str]) -> None:
    path = ROOT / rel
    if not path.is_file():
        errors.append(f"{rel}: missing")
        return
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        errors.append(f"{rel}: invalid JSON: {exc}")
        return
    for key in required:
        if key not in data:
            errors.append(f"{rel}: missing required key `{key}`")


def main() -> None:
    print("Validating skills…")
    check_skills()
    print("Validating manifests…")
    check_json(".claude-plugin/marketplace.json", ["name", "owner", "plugins"])
    check_json(".claude-plugin/plugin.json", ["name"])

    for w in warnings:
        print(f"  warning: {w}")
    if errors:
        print(f"\n✗ {len(errors)} error(s):")
        for e in errors:
            print(f"  - {e}")
        sys.exit(1)
    print("\n✓ all skills and manifests valid")


if __name__ == "__main__":
    main()
