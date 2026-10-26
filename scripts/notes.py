#!/usr/bin/env python3
"""Sync Typst notes with Lean: regenerate notes/status.json and compile PDFs.

    scripts/notes.py            # lake build, check every #lean(...) link,
                                # write notes/status.json, compile all notes
    scripts/notes.py --check    # same, but fail instead of writing if
                                # notes/status.json is stale
    scripts/notes.py --no-build # skip `lake build` (oleans must be current)

Each direction's notes entry point is directions/<Name>/notes/main.typ.
Every `#lean("Decl.name")` marker found there is checked with
`#print axioms`, and classified as:

    proved   axioms are a subset of propext, Classical.choice, Quot.sound
    sorry    depends on sorryAx
    axioms   depends on some other (non-standard) axiom
    missing  no such declaration

Exit status is non-zero if any link is not `proved` (refutations count as
proved Lean declarations), if status.json is stale under --check, or if a
note fails to compile.
"""

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
import tempfile
import tomllib
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
STATUS = ROOT / "notes" / "status.json"
STANDARD_AXIOMS = {"propext", "Classical.choice", "Quot.sound"}


def run(cmd: list[str], **kw) -> subprocess.CompletedProcess:
    return subprocess.run(cmd, cwd=ROOT, text=True, capture_output=True, **kw)


def typst_query(note: Path, selector: str) -> list:
    rel = note.relative_to(ROOT)
    r = run(["typst", "eval", f"query({selector}).map(it => it.value)",
             "--in", str(rel), "--root", "."])
    if r.returncode != 0:
        sys.exit(f"typst query failed on {rel}:\n{r.stderr}")
    return json.loads(r.stdout)


def lean_libs() -> list[str]:
    cfg = tomllib.loads((ROOT / "lakefile.toml").read_text())
    return list(cfg.get("defaultTargets", []))


def check_decls(decls: list[str]) -> dict[str, dict]:
    """Run `#print axioms` on each declaration and classify the result."""
    if not decls:
        return {}
    header = ["module", ""] + [f"public import {lib}" for lib in lean_libs()] + [""]
    first = len(header) + 1  # 1-based line of the first #print
    src = "\n".join(header + [f"#print axioms {d}" for d in decls]) + "\n"
    with tempfile.NamedTemporaryFile("w", suffix=".lean", delete=False) as f:
        f.write(src)
        path = f.name
    try:
        r = run(["lake", "env", "lean", "--json", path])
    finally:
        Path(path).unlink(missing_ok=True)

    result: dict[str, dict] = {}
    for line in r.stdout.splitlines():
        try:
            msg = json.loads(line)
        except json.JSONDecodeError:
            continue
        idx = msg["pos"]["line"] - first
        if not 0 <= idx < len(decls):
            sys.exit(f"unexpected Lean message (imports broken?):\n{msg['data']}")
        decl, data = decls[idx], msg["data"]
        if msg["severity"] == "error":
            result[decl] = {"status": "missing", "axioms": []}
            continue
        m = re.search(r"depends on axioms: \[(.*)\]", data, re.S)
        axioms = sorted(a.strip() for a in m.group(1).split(",")) if m else []
        if "sorryAx" in axioms:
            status = "sorry"
        elif set(axioms) <= STANDARD_AXIOMS:
            status = "proved"
        else:
            status = "axioms"
        result[decl] = {"status": status, "axioms": axioms}

    missing = [d for d in decls if d not in result]
    if missing:
        sys.exit(f"no Lean output for {missing}:\n{r.stderr or r.stdout}")
    return result


def main() -> int:
    ap = argparse.ArgumentParser(
        description="Sync Typst notes with Lean.",
        epilog="See the module docstring for status meanings.")
    ap.add_argument("--check", action="store_true",
                    help="fail if notes/status.json is stale instead of writing it")
    ap.add_argument("--no-build", action="store_true", help="skip `lake build`")
    args = ap.parse_args()

    if not args.no_build:
        r = run(["lake", "build"])
        if r.returncode != 0:
            print(r.stdout, r.stderr, sep="\n")
            sys.exit("lake build failed")

    notes = sorted(ROOT.glob("directions/*/notes/main.typ"))
    links: list[tuple[Path, dict]] = []
    open_questions: dict[Path, int] = {}
    for note in notes:
        links += [(note, v) for v in typst_query(note, "<lean>")]
        n = sum(not q["answered"] for q in typst_query(note, "<question>"))
        if n:
            open_questions[note] = n

    decls = sorted({v["decl"] for _, v in links})
    status = check_decls(decls)
    new_text = json.dumps(status, indent=2, sort_keys=True) + "\n"

    ok = True
    if args.check:
        if STATUS.read_text() != new_text:
            print("notes/status.json is stale; run scripts/notes.py")
            ok = False
    else:
        STATUS.write_text(new_text)

    for note in notes:
        rel = note.relative_to(ROOT)
        r = run(["typst", "compile", "--root", ".", str(rel)])
        if r.returncode != 0:
            print(f"typst compile failed: {rel}\n{r.stderr}")
            ok = False

    print("Lean links:")
    for note, v in links:
        st = status[v["decl"]]["status"]
        shown = "refuted" if v["refutes"] and st == "proved" else st
        claim = f" <{v['claim']}>" if v["claim"] else ""
        print(f"  {shown:8} {v['decl']}{claim}  ({note.parent.parent.name})")
        ok &= st == "proved"
    if not links:
        print("  (none)")
    for note, n in open_questions.items():
        print(f"open questions: {n} in {note.relative_to(ROOT)}")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
