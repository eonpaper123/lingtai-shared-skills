#!/usr/bin/env python3
"""Escape dynamic text for Telegram HTML *text nodes*.

Deterministic, stdlib-only, no network. Reads UTF-8 from stdin (when no
arguments are given) or joins all argv arguments with a single space, escapes
the text for a Telegram HTML text node, and writes the escaped UTF-8 result to
stdout.

Escaping (text nodes only, in this exact order):
    &  ->  &amp;
    <  ->  &lt;
    >  ->  &gt;

Quotes are NOT escaped: this helper is for text nodes, never for attribute
values. Prefer templates with no dynamic attributes. If a value must appear in
an attribute, escape " and ' additionally and review the template manually.

Usage:
    python escape_html.py < input.txt
    python escape_html.py "user said <hi> & bye"
    echo "a < b" | python escape_html.py

Exit codes: 0 on success; 1 on input/usage errors.
"""

import sys

_ORDERED_REPLACEMENTS = (
    ("&", "&amp;"),
    ("<", "&lt;"),
    (">", "&gt;"),
)


def escape_text_node(text):
    """Escape text for a Telegram HTML text node. Deterministic."""
    for src, dst in _ORDERED_REPLACEMENTS:
        text = text.replace(src, dst)
    return text


def _read_stdin():
    data = sys.stdin.buffer.read()
    return data.decode("utf-8")


def main(argv):
    args = argv[1:]
    if args and args[0] in ("-h", "--help"):
        print(__doc__)
        return 0
    try:
        if args:
            raw = " ".join(args)
        else:
            raw = _read_stdin()
    except UnicodeDecodeError as exc:
        print("escape_html: input is not valid UTF-8: %s" % exc, file=sys.stderr)
        return 1
    except OSError as exc:
        print("escape_html: cannot read input: %s" % exc, file=sys.stderr)
        return 1

    try:
        out = escape_text_node(raw)
        sys.stdout.buffer.write(out.encode("utf-8"))
        sys.stdout.buffer.flush()
    except OSError as exc:
        print("escape_html: cannot write output: %s" % exc, file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
