# Debugging notes

## ARDI/iterate: must poll for new review after pushing
- After pushing fixes during an iterate loop, DON'T declare "clean" based on
  the previous review. A new push triggers a new auto-review.
- Poll until a review note appears that references your latest commit SHA.
- Wait ~30-60s, then check. If nothing after ~2min, check pipeline status.
- The iterate skill now has explicit polling instructions for both GitHub and GitLab.

## VS Code editor buffer vs disk desync
- `replace_string_in_file` / `read_file` operate on the VS Code editor buffer.
- If the file was externally modified (e.g., by `git pull`), the editor buffer
  may be stale or the edit may land in a buffer that doesn't match disk.
- `git diff` and terminal `cat`/`sed` see the DISK, not the editor buffer.
- Symptom: `read_file` shows your edit, but `git diff` shows nothing.
- Fix: write via terminal (`sed -i`, `cat >`, etc.) to guarantee disk write,
  OR save the VS Code buffer before committing.
- When `replace_string_in_file` fails with "could not find matching text",
  the disk file likely differs from what `read_file` showed (stale buffer).

## bash "syntax error: unexpected end of file" at last line
- Almost always an unclosed construct (`if`/`fi`, quote, `$(`).
- BUT a sneaky cause is **CRLF line endings**: `\r` makes bash read `then\r`/`fi\r`
  as non-keywords, so the `if` never closes -> EOF error.
- Diagnose: `sed -n 'A,Bp' file | od -c | head` and look for `\r \n`.
- Fix: `perl -i -pe 's/\r\n/\n/g' file`, then re-run `bash -n file`.
- Prevent: add `.gitattributes` with `*.sh text eol=lf`.

## Writing robust bash scripts (recurring review findings)
Lessons the reviewer flagged across the `session-lock` PR (d-morrison/ai-config#38) —
pre-empt these when authoring shell, especially under `set -euo pipefail`:
- **`mktemp` + rename: add a cleanup trap.** A process killed between `mktemp`
  and the `mv` orphans temp files forever. Pattern: `tmp=$(mktemp <dir>/.tmp.XXXXXX);
  trap 'rm -f "${tmp:-}"' EXIT; … > "$tmp"; mv -f "$tmp" "$dest"; trap - EXIT`.
  Belt-and-suspenders for `SIGKILL` (trap can't fire): a prune path that sweeps
  `find <dir> -name '.tmp.*' -mmin +60 -delete` — but the `-name` glob must match
  the `mktemp` prefix you chose, or it silently misses every orphan
  (`.tmp.XXXXXX` → `'.tmp.*'`; mktemp's bare `tmp.XXXXXX` default → `'tmp.*'`).
- **Bounds-check value-taking flags before `shift 2`.** In a `set -e` arg
  parser, `--flag` as the last arg makes `${2:-}` expand to "" but the following
  `shift 2` fail (count out of range) → script aborts with a cryptic error.
  Guard with the `set -u`-safe presence test:
  `--flag) [ "${2+set}" = set ] || die "--flag requires a value"; V="$2"; shift 2 ;;`
  (`${2+set}` → `set` when `$2` is present even if empty, `""` when absent.)
- **Never interpolate shell vars into a `python3 -c` / `awk` program string.**
  Pass them as arguments: `python3 -c '…sys.argv[1]…' "$val"` (not `"…'$val'…"`)
  — keeps code and data separate and avoids quoting/injection breakage.
- **Declare loop-local vars once** in the function's top `local` line; bash
  `local` is function-scoped, so re-declaring inside loop bodies is redundant.
- **bash 3.2 (macOS default) compatibility:** indexed arrays, C-style
  `for ((…))`, and `${2+set}` all work; **associative arrays do NOT** (4.0+).
  Parse key=value records with `while IFS='=' read -r k v; do case "$k" in …`.
