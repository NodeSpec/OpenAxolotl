"""A minimal GDScript scanner for the World Static Analysis Gate (REQ-020, REQ-030).

There is no GDScript AST library to lean on, and a regex sweep over raw source
text is not defensible for a security gate: it flags every forbidden identifier
that appears inside a comment or a string literal. This node's own contract
files and doc comments are full of the words it bans, so a naive gate would
report its own explanation of the ban as a violation of it.

So the scan runs in two passes. First MASK the source — replace the body of
every comment and the contents of every string literal with spaces, preserving
newlines and column positions exactly, so line numbers survive untouched.
Then tokenize the masked text, which by construction contains only code.

Scene files are handled differently and deliberately so. In a `.tscn` the node
type lives INSIDE a string (`type=\"MultiplayerSpawner\"`), so masking strings
would erase the very thing being looked for. A `MultiplayerSpawner` can be
added in the editor without any script mentioning it, which is why scenes are
scanned at all.
"""

from __future__ import annotations

import re
from typing import Iterator, NamedTuple


class Name(NamedTuple):
    """One identifier occurrence in code, with its 1-indexed line."""

    text: str
    line: int
    is_annotation: bool

    def segments(self) -> list[str]:
        """The dotted name split into whole identifiers.

        Matching happens on SEGMENTS rather than substrings so that
        `is_multiplayer_authority` matches the authority rule exactly and does
        NOT also trip the bare `multiplayer` API rule — one violation naming
        the right thing beats two naming the wrong one.
        """
        return self.text.lstrip("@").split(".")


# A dotted name, optionally annotation-prefixed: @rpc, rpc_id, OS.execute.
_NAME = re.compile(r"@?[A-Za-z_][A-Za-z0-9_]*(?:\.[A-Za-z_][A-Za-z0-9_]*)*")

_TRIPLE_QUOTES = ('\"\"\"', "'''")


def mask_source(text: str) -> str:
    """Blank comments and string CONTENTS, preserving every newline and offset.

    The returned string is the same length as the input and has identical line
    breaks, so an offset in the mask is an offset in the original. That is what
    lets a violation report a true line number after masking.
    """
    out: list[str] = []
    index = 0
    length = len(text)

    while index < length:
        char = text[index]

        # A comment runs to end of line. The '#' itself is blanked too.
        if char == "#":
            while index < length and text[index] != "\n":
                out.append(" ")
                index += 1
            continue

        if char in ('\"', "'"):
            triple = next(
                (q for q in _TRIPLE_QUOTES if text.startswith(q, index)), None
            )
            closer = triple if triple else char
            out.append(" " * len(closer))
            index += len(closer)

            while index < length:
                if text[index] == "\\\\" and not triple:
                    # An escape consumes the next character, so a \\\" does not
                    # end the string. Without this, \"say \\\"hi\\\"\" would close
                    # early and the tail would be scanned as code.
                    out.append("  ")
                    index += 2
                    continue
                if text.startswith(closer, index):
                    out.append(" " * len(closer))
                    index += len(closer)
                    break
                # Newlines inside a triple-quoted string must survive, or every
                # line number after it shifts.
                out.append("\n" if text[index] == "\n" else " ")
                index += 1
            continue

        out.append(char)
        index += 1

    return "".join(out)


def iter_names(text: str) -> Iterator[Name]:
    """Yields every identifier in GDScript source, comments and strings excluded."""
    masked = mask_source(text)
    for match in _NAME.finditer(masked):
        token = match.group(0)
        yield Name(
            text=token,
            line=masked.count("\n", 0, match.start()) + 1,
            is_annotation=token.startswith("@"),
        )


# In a .tscn, `type=\"MultiplayerSpawner\"` and `script = ExtResource(...)` both
# matter, and both live in quoted attribute values — so scenes are scanned raw.
_SCENE_QUOTED = re.compile(r'\"([^\"\\\\]*)\"')


def _blank_scene_comments(text: str) -> str:
    """Blanks `;` comment lines in a scene file, preserving line count.

    A `.tscn` comments with ';', not '#'. Only a line whose first non-space
    character is ';' is treated as a comment — that is the format's own
    convention, and it avoids eating a ';' that appears inside a real quoted
    value. Without this, a header comment explaining the multiplayer ban would
    be reported as a violation of it.
    """
    out: list[str] = []
    for line in text.split("\n"):
        out.append("" if line.lstrip().startswith(";") else line)
    return "\n".join(out)


def iter_scene_names(text: str) -> Iterator[Name]:
    """Yields quoted attribute values from a scene file, with line numbers.

    Scene files are NOT masked the way code is: the node type being searched
    for is itself a string (`type=\"MultiplayerSpawner\"`), so masking strings
    would delete the evidence. Comments are still removed.
    """
    text = _blank_scene_comments(text)
    for match in _SCENE_QUOTED.finditer(text):
        value = match.group(1)
        if not value or not re.fullmatch(r"[A-Za-z_][A-Za-z0-9_.]*", value):
            continue
        yield Name(
            text=value,
            line=text.count("\n", 0, match.start()) + 1,
            is_annotation=False,
        )
