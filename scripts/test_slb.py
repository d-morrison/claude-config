#!/usr/bin/env python3
"""Regression tests for the six bugs fixed in semantic-line-breaks.py."""
import tempfile
from pathlib import Path
import sys
sys.path.insert(0, str(Path(__file__).parent))

# Import via the file name which has a hyphen
import importlib.util
spec = importlib.util.spec_from_file_location("slb", Path(__file__).parent / "semantic-line-breaks.py")
slb = importlib.util.module_from_spec(spec)
spec.loader.exec_module(slb)
process_file = slb.process_file


def run(name, content, expected):
    with tempfile.NamedTemporaryFile(suffix='.md', mode='w', delete=False, encoding='utf-8') as f:
        f.write(content)
        p = Path(f.name)
    process_file(p)
    result = p.read_text(encoding='utf-8')
    p.unlink()
    if result == expected:
        print(f"PASS: {name}")
        return True
    else:
        print(f"FAIL: {name}")
        print("  Expected:")
        for line in expected.splitlines():
            print(f"    {repr(line)}")
        print("  Got:")
        for line in result.splitlines():
            print(f"    {repr(line)}")
        return False


passes = 0
failures = 0


def check(name, content, expected):
    global passes, failures
    if run(name, content, expected):
        passes += 1
    else:
        failures += 1


# Bug 1: @include directive must NOT be merged with a preceding HTML comment.
check(
    "@include not merged with HTML comment",
    "<!-- Shared with the lab manual; edit there, not here. -->\n"
    "@shared/writing/ai-tells.md\n",
    "<!-- Shared with the lab manual; edit there, not here. -->\n"
    "@shared/writing/ai-tells.md\n",
)

# Bug 1b: @directive standalone stays on its own line.
check(
    "@directive standalone passes through",
    "@shared/workflow/claim-pr.md\n\nSome prose after.\n",
    "@shared/workflow/claim-pr.md\n\nSome prose after.\n",
)

# Bug 2: Lines inside a ````-fenced block that also contains a ```-fenced block
# must not be reflowed.
check(
    "nested fenced code blocks (4 vs 3 backticks)",
    "Here is an example:\n\n"
    "````\n"
    "```{r}\n"
    "#| label: stage-at-dx-fig\n"
    "#| code-fold: true\n"
    "\n"
    "plot_stage_at_dx(pt_data)\n"
    "```\n"
    "````\n",
    "Here is an example:\n\n"
    "````\n"
    "```{r}\n"
    "#| label: stage-at-dx-fig\n"
    "#| code-fold: true\n"
    "\n"
    "plot_stage_at_dx(pt_data)\n"
    "```\n"
    "````\n",
)

# Bug 3: Numbered list inside a blockquote must not be merged.
check(
    "blockquote numbered list preserved",
    "> 1. Step one\n"
    "> 2. Step two\n"
    "> 3. Step three\n",
    "> 1. Step one\n"
    "> 2. Step two\n"
    "> 3. Step three\n",
)

# Sanity check: blockquote prose still gets sentence-split.
check(
    "blockquote prose still sentence-split",
    "> This is sentence one. And this is sentence two.\n",
    "> This is sentence one.\n"
    "> And this is sentence two.\n",
)

# Bug 4: a mid-sentence prose line starting with "@" must not be treated
# as a directive — only a standalone "@path.md" line is a directive.
check(
    "prose line starting with @ is still sentence-split",
    "Comments come from the bot, by a human, or by a re-trigger,\n"
    "@claude bot, by a human, or by a re-trigger), and that newer review may\n"
    "contain findings the old one missed. Always check.\n",
    "Comments come from the bot, by a human, or by a re-trigger, @claude bot, "
    "by a human, or by a re-trigger), and that newer review may contain "
    "findings the old one missed.\n"
    "Always check.\n",
)

# Bug 5: multi-line HTML comments must be preserved verbatim, not reflowed.
check(
    "multi-line HTML comment preserved",
    "<!--\n"
    "Shared with the lab manual; edit shared/writing/ai-tells.md, not here.\n"
    "Second line of the comment.\n"
    "-->\n"
    "@shared/writing/ai-tells.md\n",
    "<!--\n"
    "Shared with the lab manual; edit shared/writing/ai-tells.md, not here.\n"
    "Second line of the comment.\n"
    "-->\n"
    "@shared/writing/ai-tells.md\n",
)

# Bug 6: a tilde fence inside a backtick-fenced block must not close it.
check(
    "mismatched fence characters don't close the block",
    "```\n"
    "~~~\n"
    "code line\n"
    "~~~\n"
    "```\n",
    "```\n"
    "~~~\n"
    "code line\n"
    "~~~\n"
    "```\n",
)

print(f"\n{passes} passed, {failures} failed")
sys.exit(0 if failures == 0 else 1)
