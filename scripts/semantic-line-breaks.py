#!/usr/bin/env python3
"""
Reformat Markdown prose to use semantic line breaks.

Semantic line breaks = each sentence or independent clause on its own
source line. Never break a phrase mid-way at a column boundary.

Preserves: YAML frontmatter, fenced code blocks, tables, headings,
horizontal rules. Reformats: prose paragraphs, bullet continuation text,
and blockquote prose.
"""
import re
import sys
from pathlib import Path


# Sentence splitting

# Abbreviations whose trailing period should NOT trigger a sentence split.
# Matched as whole words (word-boundary on the left, literal period on right).
_ABBREVS = [
    'e.g', 'i.e', 'vs', 'etc', 'Dr', 'Mr', 'Mrs', 'Ms', 'Jr', 'Sr',
    'Fig', 'Eq', 'Ref', 'Sec', 'Ch', 'Vol', 'pp', 'No', 'approx',
    'incl', 'excl', 'ca', 'cf', 'ibid', 'op', 'pt', 'Dept',
    'al',   # et al.
]
_ABBREV_RE = re.compile(
    r'(?<!\w)(' + '|'.join(re.escape(a) for a in _ABBREVS) + r')\.'
)

# Sentence boundary: [.!?] + optional closing chars + whitespace + uppercase/quote.
_SENT_BREAK_RE = re.compile(r'([.!?][`"\')\]]*)\s+(?=[A-Z"\'`\*\[])')


_PLACEHOLDER = '\x00'


def _protect_inline_code(m: re.Match) -> str:
    """Replace sentence-ending punctuation inside backtick spans with placeholders."""
    return m.group(0).replace('.', _PLACEHOLDER).replace('!', '\x01').replace('?', '\x02')


def split_sentences(text: str) -> list[str]:
    """Split text at sentence boundaries; return list of sentences."""
    text = re.sub(r'\s+', ' ', text).strip()
    if not text:
        return []

    # Protect abbreviations by replacing their dot with a placeholder.
    protected = _ABBREV_RE.sub(lambda m: m.group(1) + _PLACEHOLDER, text)

    # Also protect periods inside backtick spans (inline code).
    protected = re.sub(r'`[^`]+`', _protect_inline_code, protected)

    # Insert newline at sentence boundaries.
    protected = _SENT_BREAK_RE.sub(lambda m: m.group(1) + '\n', protected)

    # Split and restore.
    parts = [p.replace(_PLACEHOLDER, '.').replace('\x01', '!').replace('\x02', '?').strip()
             for p in protected.split('\n')]
    return [p for p in parts if p]


# Paragraph / bullet helpers

_BULLET_RE = re.compile(r'^(\s*)([-*+]|\d+\.)\s+(.*)', re.DOTALL)
_HEADING_RE = re.compile(r'^\s*#{1,6}[\s#]')
_TABLE_RE = re.compile(r'^\s*\|')
_HR_RE = re.compile(r'^\s*[-*_]{3,}\s*$')
_FENCE_RE = re.compile(r'^\s*```')
_BQ_RE = re.compile(r'^\s*>')
_BLANK_RE = re.compile(r'^\s*$')


def _is_new_block(line: str) -> bool:
    """True if line starts a new structural block (not a prose continuation)."""
    return bool(
        _BLANK_RE.match(line) or
        _HEADING_RE.match(line) or
        _FENCE_RE.match(line) or
        _TABLE_RE.match(line) or
        _HR_RE.match(line) or
        _BQ_RE.match(line) or
        _BULLET_RE.match(line)
    )


# Blockquote prose flusher

def _flush_bq_prose(bq_lines: list[str], output: list[str]) -> None:
    """Sentence-split accumulated blockquote prose lines and append to output."""
    if not bq_lines:
        return
    bq_prefix = re.match(r'^(\s*>\s*)', bq_lines[0]).group(1)
    bq_text = ' '.join(re.sub(r'^\s*>\s*', '', bl).strip() for bl in bq_lines)
    bq_text = re.sub(r'\s+', ' ', bq_text).strip()
    sentences = split_sentences(bq_text)
    if not sentences or (len(sentences) <= 1 and len(bq_lines) == 1):
        output.extend(bq_lines)
    else:
        for s in sentences:
            output.append(bq_prefix + s)


# File processor

def process_file(path: Path) -> bool:
    """
    Process a single Markdown file in-place.
    Returns True if the file was modified, False if unchanged.
    """
    original = path.read_text(encoding='utf-8')
    lines = original.split('\n')
    output: list[str] = []

    in_frontmatter = False
    frontmatter_done = False
    in_code_block = False
    i = 0

    while i < len(lines):
        line = lines[i]
        stripped = line.strip()

        # YAML frontmatter
        if not frontmatter_done and not in_frontmatter and i == 0 and stripped == '---':
            in_frontmatter = True
            output.append(line)
            i += 1
            continue

        if in_frontmatter:
            output.append(line)
            if i > 0 and stripped == '---':
                in_frontmatter = False
                frontmatter_done = True
            i += 1
            continue

        # Fenced code blocks
        if _FENCE_RE.match(stripped):
            in_code_block = not in_code_block
            output.append(line)
            i += 1
            continue

        if in_code_block:
            output.append(line)
            i += 1
            continue

        # Pass-through: blank, heading, table row, horizontal rule
        if (not stripped or
                _HEADING_RE.match(line) or
                _TABLE_RE.match(line) or
                _HR_RE.match(stripped)):
            output.append(line)
            i += 1
            continue

        # Blockquotes — process line by line
        if _BQ_RE.match(line):
            # Process the blockquote line-by-line, tracking fence state so
            # code blocks nested inside blockquotes are emitted verbatim.
            j = i
            bq_prose: list[str] = []   # accumulated prose lines to sentence-split
            in_bq_code = False

            while j < len(lines) and _BQ_RE.match(lines[j]):
                bq_line = lines[j]
                inner = re.sub(r'^\s*>\s?', '', bq_line)
                if _FENCE_RE.match(inner):
                    # Flush any buffered prose before toggling code state.
                    _flush_bq_prose(bq_prose, output)
                    bq_prose = []
                    in_bq_code = not in_bq_code
                    output.append(bq_line)
                elif in_bq_code:
                    output.append(bq_line)
                else:
                    bq_prose.append(bq_line)
                j += 1

            # Flush any trailing prose.
            _flush_bq_prose(bq_prose, output)
            i = j
            continue

        # Bullet points
        bullet_m = _BULLET_RE.match(line)
        if bullet_m:
            pre = bullet_m.group(1)    # leading spaces
            mark = bullet_m.group(2)   # -, *, +, or 1.
            first_text = bullet_m.group(3)

            marker_str = pre + mark + ' '
            cont_indent = ' ' * len(marker_str)

            # Collect continuation lines: indented >= marker width,
            # and not a new bullet at the same or lower indent.
            j = i + 1
            all_text = first_text.strip()
            while j < len(lines):
                nl = lines[j]
                ns = nl.strip()
                if not ns:
                    break
                # Stop at a fenced code block — emit the rest verbatim.
                if _FENCE_RE.match(nl):
                    break
                nl_lead = len(nl) - len(nl.lstrip())
                # Stop at a new top-level bullet (same or lower indent) or
                # any other block element.
                if nl_lead < len(marker_str) or _BULLET_RE.match(nl):
                    break
                # It's a continuation line (indented more than marker).
                all_text += ' ' + ns
                j += 1

            # Split into sentences and re-emit.
            sentences = split_sentences(all_text)
            if not sentences:
                # Nothing to split; emit original.
                output.append(line)
                i = j
                continue

            for k, s in enumerate(sentences):
                if k == 0:
                    output.append(marker_str + s)
                else:
                    output.append(cont_indent + s)

            i = j
            continue

        # Prose paragraphs
        # Leading indent of the paragraph's first line.
        para_lead = len(line) - len(line.lstrip())
        indent_str = ' ' * para_lead

        para_text = stripped
        j = i + 1
        while j < len(lines):
            nl = lines[j]
            ns = nl.strip()
            if _is_new_block(nl):
                break
            para_text += ' ' + ns
            j += 1

        para_text = re.sub(r'\s+', ' ', para_text).strip()
        sentences = split_sentences(para_text)

        if not sentences:
            output.append(line)
            i = j
            continue

        for s in sentences:
            output.append(indent_str + s)

        i = j

    # Reconstruct and write if changed.
    result = '\n'.join(output)
    if not result.endswith('\n'):
        result += '\n'

    if result != original:
        path.write_text(result, encoding='utf-8')
        return True
    return False


# Entry point

def main():
    if len(sys.argv) < 2:
        print(f'Usage: {sys.argv[0]} <file> [file ...]', file=sys.stderr)
        sys.exit(1)

    changed = 0
    unchanged = 0
    errors = 0

    for arg in sys.argv[1:]:
        p = Path(arg)
        try:
            modified = process_file(p)
            if modified:
                changed += 1
                print(f'  changed: {arg}')
            else:
                unchanged += 1
        except Exception as e:
            errors += 1
            print(f'  ERROR:   {arg}: {e}', file=sys.stderr)

    print(f'\nDone: {changed} changed, {unchanged} unchanged, {errors} errors')
    if errors:
        sys.exit(1)


if __name__ == '__main__':
    main()
