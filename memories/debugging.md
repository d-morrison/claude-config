# Debugging notes

## Testing CSS/JS-dependent web features — use a REAL browser, not a DOM stub
- A hand-rolled DOM shim (or jsdom-style unit test) can PASS while the feature is
  visibly broken, because it doesn't apply the page's CSS or run the framework's
  own scripts. On rme#929 a DOM-stub test of a mobile TOC passed, but in a real
  browser the menu never opened: a framework CSS rule (`nav[role=doc-toc]{display:none}`)
  hid the cloned node, and native `<details>` closed-hiding didn't apply either.
  Neither failure is observable without real CSS.
- Drive a real headless browser. **In the remote/web-session runner** (paths
  below are that runner's — they differ on a local CLI setup; `which chromium` /
  `npm root -g` to find yours), Playwright is installed globally; the chromium
  binary is at `/opt/pw-browsers/chromium-*/chrome-linux/chrome` (the
  `/usr/bin/chromium-browser` is a snap stub that won't launch — pass the real
  path as `executablePath`, plus `args:['--no-sandbox']`). Import Playwright by
  its absolute global path (`/opt/node22/lib/node_modules/playwright/index.js`),
  which is a CommonJS default export: `import pkg from '…'; const {chromium}=pkg`.
- Serve the built site over HTTP (`python3 -m http.server` in `_site`) and load
  `http://localhost:<port>/…` — `file://` blocks the framework's `type=module`
  scripts (e.g. Quarto's `quarto-nav.js` / `quarto.js`) via CORS, so headroom/nav
  behavior won't run. Test viewport-specific behavior with `newPage({ viewport })`,
  and assert computed styles / `offsetHeight` (not just DOM presence).

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

## macOS sed vs GNU sed syntax differences
- `sed '1{/pattern/d}'` works on GNU sed (Linux CI) but FAILS on macOS BSD sed
- Portable form: `sed -e '1{' -e '/pattern/d' -e '}'` (separate -e expressions)
- Always test sed commands locally before committing if they use address+command blocks
- The CI runs on Linux (GNU sed) but local dev is macOS (BSD sed) — use portable form

## bash "syntax error: unexpected end of file" at last line
- Almost always an unclosed construct (`if`/`fi`, quote, `$(`).
- BUT a sneaky cause is **CRLF line endings**: `\r` makes bash read `then\r`/`fi\r`
  as non-keywords, so the `if` never closes -> EOF error.
- Diagnose: `sed -n 'A,Bp' file | od -c | head` and look for `\r \n`.
- Fix: `perl -i -pe 's/\r\n/\n/g' file`, then re-run `bash -n file`.
- Prevent: add `.gitattributes` with `*.sh text eol=lf`.

## Programmatic comment edits leave punctuation/grammar artifacts
Recurring across the sparta scrub PRs (Lacaedemon/sparta#150, Lacaedemon/sparta#152)
— removing inline content from comments (issue refs like `(#138)`, parentheticals,
clauses) via sed/scripted passes repeatedly broke the surrounding prose. The reviewer
(and Copilot) flagged ~6 of these. After any scripted comment edit, **re-audit the
touched lines** before pushing:
- **Mid-sentence parenthetical removed → orphaned comma/period on the wrapped continuation line.** When the ref opened a continuation line — `# ...launched from the map` / `# (#122), before...` — stripping `(#122)` leaves `# , before...`. Fix: move the comma/period up to the end of the prior line (`# ...launched from the map,` / `# before...`).
- **Line-leading `(#NN).` removed → comment marker + bare punctuation.** `## (#82/#84).` opening a continuation line → `##.`. Fix: end the previous line's sentence and drop the marker-orphan.
- **Trailing clause/ref removed → dangling text.** `# ... see issue #61.` → `# ... see issue.` (referent gone). Fix: drop the now-meaningless phrase.
- **Repeated word exposed.** `keyed off the uid (#50): keyed off get_instance_id()` → `...uid: keyed off...`. Fix: reword.
- Audit greps (ERE — `grep -E`): `grep -rnE "^[[:space:]]*#+[[:space:]]*[.,;:]"` (orphaned leading punctuation),
  and scan for `see issue\.`, `, #[0-9]+,`, double spaces, broken section-header dashes.
- The blanket strip patterns that work cleanly (with `sed -E` / `sed -r` — they need
  ERE for the `+` quantifier; in ERE, `\(` and `\)` match literal parens, not groups):
  `s/ \(#[0-9]+\)//g` (inline), `s/^# #[0-9]+: /# /` (prefix — `^`-anchored, so no `g`), `s/, #[0-9]+,/,/g` — but
  the line-leading and sentence-internal cases need hand edits, not sed.

## Merging main into a sibling PR can silently clobber an un-customized file
When PR-A merges and you sync sibling PR-B (which touches the same files), a file
that B never customized takes main's (A's) version **with no merge conflict** — so
it can end up with content describing A's change, not B's. Hit on Lacaedemon/sparta#152:
the `demos/demo.json` reason silently became Lacaedemon/sparta#143's diplomacy text.
After such a
merge, don't just resolve the marked conflicts — **diff the whole merge result vs
the PR's intent** and check files that merged "cleanly" but belong to this PR
(demo manifests, PR-specific metadata) still say the right thing. Also re-run the
PR's own invariant (here: the ref-scrub) over files main re-touched, since A may
have re-introduced exactly what B removed.

## A parallel session can force-push your PR branch out from under you
On Lacaedemon/sparta#150 another driver (a second `@claude` task, or GitHub's
"Update with rebase") force-pushed the PR branch three times, each time replacing
my sync-merge commit with a rebase that dropped my conflict resolutions and
reverted fixes. Defenses:
- **Before pushing to a shared PR branch, `git fetch` and check that `origin/<branch>`
  hasn't moved since your last push** — don't assume your last push is still HEAD.
  `git log --oneline HEAD..origin/<branch>`: non-empty means a parallel session pushed
  past you. (This handles unpushed local commits, where a bare `rev-parse HEAD` vs
  `origin` would always differ by design.)
- **When it was force-pushed, reset to origin and re-verify the content** (refs,
  the specific fixes, demo/metadata) rather than force-pushing your divergent copy
  back. The rebase may already carry the same correct content — diff it.
- **If origin's content is already correct, stand down — don't push.** Pushing a
  divergent merge just restarts the tug-of-war. Reset local to origin and let the
  review run.
- **Escalate to the user to settle who drives the PR** once you see repeated
  force-pushes — that's the claim-pr/parallel-session collision, and one driver
  should own it.

## Appending to skill/memory files: grep for duplicate sections first
Before adding a new `##` section to an existing skill or memory file, grep the
file for the section heading. It's easy to append a section that already exists —
the scout-peers duplicate `## Relationship to other skills` bug (ai-config#132)
happened because an existing section was missed and a duplicate was appended at
the end. Run `grep -n "^## " <file>` before appending.

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
