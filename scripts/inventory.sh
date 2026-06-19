#!/usr/bin/env bash
# Print a live inventory of this repo's portable AI-config assets.
# Counts are derived on the fly so they never go stale in the README.
set -euo pipefail
cd "$(dirname "$0")/.."

count() { printf '%s' "$(find "$@" 2>/dev/null | wc -l | tr -d ' ')"; }

echo "ai-config inventory:"
echo "  skills:          $(count skills -maxdepth 2 -name SKILL.md)"
echo "  commands:        $(count commands -maxdepth 1 -name '*.md')"
echo "  doc pages:       $(count docs -maxdepth 1 -name '*.md')"
echo "  reference packs: $(count references -mindepth 1 -maxdepth 1 -type d)"
