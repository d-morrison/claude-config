#!/usr/bin/env bash
# Upload staged skills to the Anthropic Skills API (POST /v1/skills).
# Idempotent: skips any skill whose display_title already exists in the workspace.
#
# Usage:
#   ANTHROPIC_API_KEY=sk-ant-... ./upload_skills.sh
#
# Env:
#   ANTHROPIC_API_KEY  (required) a *workspace* API key — custom skills are workspace-scoped
#   STAGE              staging dir of <name>/SKILL.md folders (default /tmp/skill_upload)
#   MAP                output TSV of name -> skill_id (default ./skill_ids.tsv)
set -euo pipefail

: "${ANTHROPIC_API_KEY:?Set ANTHROPIC_API_KEY (a workspace API key) before running}"
API="https://api.anthropic.com/v1/skills"
STAGE="${STAGE:-/tmp/skill_upload}"
MAP="${MAP:-skill_ids.tsv}"
HDRS=(-H "x-api-key: $ANTHROPIC_API_KEY"
      -H "anthropic-version: 2023-06-01"
      -H "anthropic-beta: skills-2025-10-02")

[ -d "$STAGE" ] || { echo "No staging dir: $STAGE" >&2; exit 1; }
: > "$MAP"

# Pull existing skills once for idempotency (match on display_title). Capture
# the HTTP status so an auth failure bails out loudly instead of falling through
# to an empty-workspace fallback (which would make every POST below fail 401).
resp="$(curl -sS -w '\n%{http_code}' "${HDRS[@]}" "$API" 2>/dev/null || true)"
http_code="$(tail -n1 <<<"$resp")"
existing="$(sed '$d' <<<"$resp")"
case "$http_code" in
  200) : ;;
  401|403) echo "ERROR: Skills API auth failed (HTTP $http_code) — check ANTHROPIC_API_KEY (must be a workspace key)" >&2; exit 1 ;;
  "") echo "ERROR: could not reach Skills API at $API" >&2; exit 1 ;;
  *) echo "WARN: unexpected HTTP $http_code listing existing skills; treating workspace as empty" >&2; existing='{"data":[]}' ;;
esac
existing="${existing:-{\"data\":[]}}"

created=0 skipped=0 failed=0
for dir in "$STAGE"/*/; do
  name="$(basename "$dir")"
  [ -f "$dir/SKILL.md" ] || { echo "WARN no SKILL.md: $name"; continue; }

  if id="$(jq -er --arg n "$name" '.data[]? | select(.display_title==$n) | .id' <<<"$existing" 2>/dev/null | head -1)" && [ -n "$id" ]; then
    echo "skip (exists): $name -> $id"
    printf '%s\t%s\tEXISTS\n' "$name" "$id" >> "$MAP"
    skipped=$((skipped+1)); continue
  fi

  resp="$(curl -sS -X POST "$API" "${HDRS[@]}" \
            -F "display_title=$name" \
            -F "files[]=@${dir}SKILL.md;filename=${name}/SKILL.md")"
  id="$(jq -r '.id // empty' <<<"$resp")"
  if [ -n "$id" ]; then
    ver="$(jq -r '.latest_version // empty' <<<"$resp")"
    echo "created: $name -> $id (v$ver)"
    printf '%s\t%s\tCREATED\n' "$name" "$id" >> "$MAP"
    created=$((created+1))
  else
    echo "FAILED: $name"
    jq . <<<"$resp" 2>/dev/null || echo "$resp"
    printf '%s\t-\tFAILED\n' "$name" >> "$MAP"
    failed=$((failed+1))
  fi
done

echo "----"
echo "created=$created skipped=$skipped failed=$failed  (map: $MAP)"
