#!/usr/bin/env bash
# Create a new research direction (a Lean library + notes scaffold).
#
#   ./scripts/new-direction.sh <DirectionName>
#
# Creates:
#   directions/<Name>/lean/<Name>.lean        (root module)
#   directions/<Name>/lean/<Name>/Basic.lean   (direction sources)
#   directions/<Name>/notes/main.typ           (Typst notes entry point)
#   directions/<Name>/notes/idea.typ           (human: informal statement)
#   directions/<Name>/notes/formal.typ         (agent: readings, links, log)
#
# and registers the library in lakefile.toml (including defaultTargets, so
# that a bare `lake build` compiles every direction).
set -euo pipefail

DIR="${1:-}"
if [[ -z "$DIR" ]]; then
  echo "usage: $0 <DirectionName>   (e.g. MonotoneSequences)" >&2
  exit 1
fi

# PascalCase-ish name, must be a valid Lean identifier.
if [[ ! "$DIR" =~ ^[A-Z][A-Za-z0-9]*$ ]]; then
  echo "error: '$DIR' must start with an uppercase letter and contain only alphanumerics" >&2
  exit 1
fi

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if [[ -d "directions/$DIR" ]]; then
  echo "error: directions/$DIR already exists" >&2
  exit 1
fi

mkdir -p "directions/$DIR/lean/$DIR" "directions/$DIR/notes"

# Root module: re-exports the direction's sources.
cat > "directions/$DIR/lean/$DIR.lean" <<EOF
module

public import $DIR.Basic

/-!
# $DIR — root module
-/
EOF

# Direction sources.
cat > "directions/$DIR/lean/$DIR/Basic.lean" <<EOF
module

public import LeanLab

/-!
# $DIR

Research direction: $DIR.

The informal problem statement and progress log live in
\`directions/$DIR/notes/\`. This file holds the formalisation.
-/

public section

namespace LeanLab.$DIR

end LeanLab.$DIR
EOF

cat > "directions/$DIR/notes/main.typ" <<EOF
#import "/notes/template/lab.typ": *

#show: lab.with(title: "$DIR")

// idea.typ: written by humans. formal.typ: written by agents.
#include "idea.typ"
#include "formal.typ"
EOF

cat > "directions/$DIR/notes/idea.typ" <<EOF
#import "/notes/template/lab.typ": *

// Human-written. Agents read this file but do not edit it.

= Idea

// TODO: state the research question in plain language. Label each claim,
// e.g. #theorem(name: "...")[...] <thm_name>
EOF

cat > "directions/$DIR/notes/formal.typ" <<EOF
#import "/notes/template/lab.typ": *

// Agent-written. Formal statements, readings, questions and the progress log.

= Formalisation

// Readings (#reading), Lean links (#lean("LeanLab.$DIR.decl", claim: <label>))
// and questions for the human (#question) go here.

== Progress log

- $(date +%Y-%m-%d): direction created.
EOF

# Register the library in lakefile.toml and add it to defaultTargets.
python3 - "$DIR" <<'PY'
import re, sys, pathlib

name = sys.argv[1]
p = pathlib.Path("lakefile.toml")
text = p.read_text()

# 1. lean_lib block
if f'name = "{name}"' not in text:
    block = (
        f'[[lean_lib]]\n'
        f'name = "{name}"\n'
        f'srcDir = "directions/{name}/lean"\n'
        f'globs = ["{name}", "{name}.*"]\n\n'
    )
    marker = "# Research directions: one lean_lib each."
    text = text.replace(marker, block + marker)

# 2. defaultTargets: keep the list in sync so `lake build` builds everything.
m = re.search(r"^defaultTargets\s*=\s*\[(.*?)\]", text, re.M | re.S)
if m is None:
    text = re.sub(
        r"^(name\s*=\s*\"leanlab\")$",
        r'\1\ndefaultTargets = ["LeanLab"]',
        text,
        count=1,
        flags=re.M,
    )
    m = re.search(r"^defaultTargets\s*=\s*\[(.*?)\]", text, re.M | re.S)

items = [i.strip().strip('"').strip("'") for i in m.group(1).split(",")]
items = [i for i in items if i]
if name not in items:
    items.append(name)
text = text[:m.start()] + "defaultTargets = [" + ", ".join(f'"{i}"' for i in items) + "]" + text[m.end():]

p.write_text(text)
PY

cat <<EOF

Created direction '$DIR':

  directions/$DIR/lean/$DIR.lean
  directions/$DIR/lean/$DIR/Basic.lean
  directions/$DIR/notes/main.typ
  directions/$DIR/notes/idea.typ
  directions/$DIR/notes/formal.typ

Registered in lakefile.toml (defaultTargets updated). Build with:

  lake build $DIR
  typst compile --root . directions/$DIR/notes/main.typ
EOF
