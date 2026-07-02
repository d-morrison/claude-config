Avoid hard-coding data that already has a reliable external source of truth ---
a version number, a package list, a dependency's release date, a set of
downstream consumers, a schema, an enum's valid values. Read or generate it
from that source instead of copying a snapshot into the codebase:

- **Versions and pins.** Don't retype a dependency's version in prose or a
  second config file when a lockfile, `DESCRIPTION`, or manifest already
  states it --- reference that file, or generate the mention from it.
- **Generated lists.** A list of consumers, plugins, or registered items that
  the source system can enumerate (an API, a directory scan, a registry)
  should be produced by querying that system, not maintained by hand
  alongside it.
- **Cross-file duplication.** When the same fact must appear in two places
  (a usage example and a reference doc, a schema and its example), generate
  the second from the first, or have CI check they agree, rather than
  trusting two hand-edited copies to stay in sync.

This is conditioned on the external source being **reliably available** ---
don't add a network fetch or a fragile dependency where a static value would
do. A constant that has no external owner (a magic number intrinsic to the
algorithm, a default chosen by this project) is not "hard-coded data" in this
sense --- it is just a value. The target is duplicated *ownership* of a fact:
if updating the external source should have updated this value too, and
didn't, that is the bug this guidance prevents.
