# AGENTS.md — instructions for agents working in this Lean research project

This repository formalises research ideas in Lean 4. You are expected to work
here as a *formalisation* agent: turn informal mathematical claims into Lean
statements, prove them (or find and record the precise obstruction), and keep
the written record in sync with the code.

## 0. Ground rules

1. **Never invent a Mathlib API.** Every theorem, lemma, instance and notation
   you use must be confirmed to exist before you rely on it. Use
   `lean_local_search` / `lean_hover_info` / `lean_declaration_file`. A
   hallucinated lemma name is the single most common failure mode and it costs
   a full build cycle to discover.
2. **`sorry` is not a proof.** It is acceptable only as a temporary scaffold
   while developing a statement. Any theorem that ships must pass
   `lean_verify` with only `propext`, `Classical.choice`, `Quot.sound` in its
   axiom set. `sorryAx` means "not finished".
3. **Record what you learned.** A direction's `notes/` directory is the
   research log: the informal statement, the formal statement, the plan, and
   a dated progress log. If you discover that a claim is *false*, that is a
   result — write the counterexample down.
4. **State the informal claim before formalising it.** If the informal text is
   ambiguous, resolve the ambiguity explicitly in the notes, state the
   reading you chose, and note the alternatives. Formalising an ambiguous
   claim wastes effort.

## 1. Layout

```
lean-lab/
├── lean-toolchain            Lean v4.35.0
├── lakefile.toml             mathlib v4.35.0 pinned; one lean_lib per direction
├── LeanLab/                  Shared core library (common vocabulary)
├── directions/<Name>/        One research direction
│   ├── lean/<Name>/          Lean sources for that direction
│   └── notes/                Informal statement + progress log (markdown)
├── notes/                    Project-level notes, cross-cutting questions
├── references/               Papers, notes, external material
└── scripts/new-direction.sh  Scaffold a new direction
```

- `LeanLab/` holds only definitions and lemmas reused by more than one
  direction. Everything else belongs in the direction that uses it.
- Namespaces: `LeanLab` for shared core, `LeanLab.<Direction>` for
  direction-local definitions.
- New direction: `./scripts/new-direction.sh <PascalCaseName>` — it creates
  the directory, the notes scaffold, and registers the `lean_lib` in
  `lakefile.toml`.

## 2. Toolchain facts

| Item | Value |
|---|---|
| Lean | `leanprover/lean4:v4.35.0` |
| Mathlib | `v4.35.0` (pinned in `lakefile.toml`) |
| Build | `lake build` / `lake build <Target>` |
| MCP server | `lean-lsp` (lean-lsp-mcp 0.31.0), stdio transport |

`lakefile.toml` sets `autoImplicit = false` and `relaxedAutoImplicit = false`,
so **every variable and hypothesis must be declared explicitly**. If Lean
cannot find a name, it is because it was not introduced, not because of
implicit-argument guessing.

### The Lean 4.35 module system — mandatory file shape

Lean 4.35 / Mathlib v4.35 use the new `module` system. Files **must** follow
this shape or they will not elaborate:

```lean
module                          -- 1. opens the module

public import Mathlib.Algebra.Order.Field.Basic   -- 2. imports

/-!                            -- 3. module docstring (AFTER imports)
# Title
-/

public section                 -- 4. make the declarations below exported

namespace Foo                  -- 5. ordinary namespace
theorem bar : True := trivial
end Foo
```

Rules that are easy to get wrong:

- **`import` must be the first command.** A docstring or comment *before* the
  imports causes `invalid 'import' command, it must be used in the beginning
  of the file`. The `/-! ... -/` block therefore goes *after* the imports.
- **Use `public import`, not `import`,** for anything whose declarations you
  will mention in a public theorem. A plain `import` is private to the file,
  and you get: `Unknown constant 'Real'` / `A public declaration 'Real' exists
  but is imported privately`.
- **`public section` is what exports your declarations.** Without it, other
  files cannot see your theorems even though the file compiles.
- A **root module** (e.g. `SmokeTest.lean`) re-exports a submodule with
  `public import SmokeTest.Basic`. Importing the root then gives access to
  everything below it.
- `lake build` builds only what `defaultTargets` lists. The
  `scripts/new-direction.sh` script keeps that list in sync — if you add a
  `[[lean_lib]]` by hand, add it to `defaultTargets` too.

Corrected Mathlib import paths for v4.35 (the old ones are deprecated and
emit warnings):

| Instead of | Use |
|---|---|
| `Mathlib.Data.Real.Basic` | `Mathlib.Basic.Real.Basic` |
| `Mathlib.Data.Complex.Basic` | `Mathlib.Basic.Complex.Basic` |

Prefer importing `Mathlib.Tactic.<Name>` for tactics. `import Mathlib` pulls
in everything and is slow to elaborate — import what you need.

## 3. The MCP tools you have

The `lean-lsp-mcp` server is connected; its tools appear as
`mcp_lean_lsp_<tool>`. All 22 tools are available. `file_path` arguments are
relative to the project root (e.g. `LeanLab/Basic.lean`,
`directions/Foo/lean/Foo/Basic.lean`).

Exact signatures (verified against the running server):

```
lean_file_outline(file_path*, max_declarations?)
lean_diagnostic_messages(file_path*, start_line?, end_line?, declaration_name?,
                          interactive, timeout_s?, severity?)
lean_code_actions(file_path*, line*)
lean_goal(file_path*, line*, column?, format, timeout_s?)
lean_term_goal(file_path*, line*, column?)
lean_hover_info(file_path*, line*, column*)
lean_completions(file_path*, line*, column*, max_completions, resolve_details)
lean_declaration_file(file_path*, symbol*, context_lines, full_file)
lean_references(file_path*, line*, column*, max_results?)
lean_local_search(query*, limit, project_root?)
lean_leansearch(query*, num_results)
lean_loogle(query*, num_results)
lean_leanfinder(query*, num_results, version)
lean_hammer_premise(file_path*, line*, column*, num_results)
lean_multi_attempt(file_path*, line*, snippets[], column?)
lean_run_code(code*)
lean_verify(file_path*, theorem_name*, scan_source)
lean_minimal_hypotheses(file_path*, theorem_name*, inactivity_timeout)
lean_profile_proof(file_path*, line*, top_n, timeout)
lean_build(lean_project_path?, clean, fetch_cache, output_lines)
```

`*` = required. Note `lean_multi_attempt` takes **`snippets`** (an array of
tactic strings), and `lean_verify` takes the **fully qualified theorem name**
(e.g. `LeanLab.Foo.bar`).

### Inspection

| Tool | Use it for |
|---|---|
| `mcp_lean_lsp_lean_file_outline` | Imports + declarations with signatures for a file. Start here when joining a file. |
| `mcp_lean_lsp_lean_goal` | The proof goal at a line (or line+column). **The primary way to see what you must prove.** |
| `mcp_lean_lsp_lean_term_goal` | Goal for a specific term position. |
| `mcp_lean_lsp_lean_hover_info` | Docs/types for the symbol under the cursor. |
| `mcp_lean_lsp_lean_declaration_file` | Where a symbol is declared. |
| `mcp_lean_lsp_lean_references` | All uses of a symbol. |
| `mcp_lean_lsp_lean_diagnostic_messages` | Errors/warnings in a file, optionally filtered by severity. |
| `mcp_lean_lsp_lean_completions` | Identifier/import completions at a position. |

### Proving

| Tool | Use it for |
|---|---|
| `mcp_lean_lsp_lean_multi_attempt` | Screen several candidate tactics at one position. Returns goal state + errors per attempt. **Prefer this over one-at-a-time editing.** |
| `mcp_lean_lsp_lean_code_actions` | "Try this" suggestions from `simp?`, `exact?`, `apply?`. Returns edits you apply yourself. |
| `mcp_lean_lsp_lean_run_code` | Compile a standalone snippet (or `#eval`). Good for testing a statement, `#check`ing a name, and finding counterexamples. |
| `mcp_lean_lsp_lean_hammer_premise` | Premises that could close the current goal. |
| `mcp_lean_lsp_lean_profile_proof` | Per-line timing — find the slow tactic when a proof takes too long. |

### Searching for existing results

| Tool | Use it for |
|---|---|
| `mcp_lean_lsp_lean_local_search` | Grep the local project and stdlib. Fast, no rate limit. **First choice for "does X exist?"** |
| `mcp_lean_lsp_lean_leansearch` | Natural-language search over Mathlib (leansearch.net). |
| `mcp_lean_lsp_lean_loogle` | Search by identifier, type shape, or subexpression (loogle.lean-lang.org). |
| `mcp_lean_lsp_lean_leanfinder` | Semantic search over Mathlib theorems. |

The three external search tools are **rate-limited to 3 requests per 30 s**,
shared. Do not loop on them. Prefer `lean_local_search` when you suspect the
result is already in Mathlib source, and space out external calls.

### Soundness and build

| Tool | Use it for |
|---|---|
| `mcp_lean_lsp_lean_verify` | Axioms used by a theorem + scan for `unsafe`/`set_option debug.*`. **Run before declaring anything proved.** |
| `mcp_lean_lsp_lean_build` | `lake build` (and restart the LSP). Use `fetch_cache=true` only when dependency caches are missing. |
| `mcp_lean_lsp_lean_minimal_hypotheses` | Which hypotheses are actually load-bearing — for sharpening a statement. Slow (re-elaborates per hypothesis). |

## 4. Workflow for formalising an idea

Follow these phases. Do not skip to writing a proof term.

**Phase 1 — Read the idea.**
Read the informal claim (in `notes/` or from the user). List its ambiguities.
Decide the *reading* you will formalise. Write it down.

**Phase 2 — Find the right abstraction.**
Do not formalise the most specific version you can think of. Look for the
general statement that has the clean proof — then specialise. Typical
generality moves: replace a concrete object with a typeclass-constrained one,
replace a fixed sequence with an arbitrary one, weaken `=` to `≤`, or
generalise a function to a monotone/continuous one. State in the notes why you
think this is the right level.

**Phase 3 — Survey Mathlib.**
Search before you write. `lean_local_search` for names you suspect;
`lean_leansearch` / `lean_loogle` / `lean_leanfinder` for the *concept*.
Record the exact names and signatures you will use, with their module paths,
in the notes. Reuse existing machinery rather than re-proving it.

**Phase 4 — Draft the statement.**
Write it in the direction's Lean file. Check that it elaborates and states
what you intend:
- `lean_run_code` for a quick `#check`/`#print` of the statement type.
- `lean_goal` at the statement's position to confirm the goal is exactly the
  claim (not a stronger or weaker variant).

**Phase 5 — Check whether it is true.**
Before spending effort on a proof, look for counterexamples. For concrete
instances use `decide`/`native_decide` in `lean_run_code`; for general
statements try to derive a contradiction from the hypotheses. If the claim is
false, write the counterexample into the notes *and* into Lean, and stop
formalising it as true.

**Phase 6 — Prove.**
- `lean_multi_attempt` to screen 2–4 tactics at once at a given position.
- `lean_hammer_premise` when you are stuck on *which* lemma applies.
- `lean_code_actions` for `simp?` / `exact?` / `apply?` suggestions.
- Check each intermediate goal with `lean_goal`; do not guess.
- Keep the proof short and readable. Prefer `simp`/`aesop`/`omega`/`ring`/
  `linarith` over long manual term-mode proofs; use `obtain`/`rcases` for
  destructuring; use `Finset.sum`/`Finset.prod` idioms rather than raw
  induction.

**Phase 7 — Verify.**
- `lean_verify` on every finished theorem: axiom set must be exactly
  `propext`, `Classical.choice`, `Quot.sound` (or a subset).
- `lake build` clean.
- Update the direction's progress log with what was proved, what was refuted,
  and what is still open.

## 5. Style conventions

- **File shape is fixed** (see §2): `module`, `public import ...`, `/-! doc -/`,
  `public section`, then the code. Do not deviate.
- `theorem`/`lemma` names describe the content in camelCase; use `'` to
  disambiguate variants (`foo_of_bar`).
- Statement order: hypotheses before the conclusion, `∀` before `∃`.
- Prefer explicit binders: `theorem foo {α : Type*} (h : p α) : q α`.
- Mark `variable`s at the top of a file or section rather than repeating them.
- Cross-reference notes in Lean via doc comments, e.g.
  `--! See notes/00-statement.md`.
- Keep `autoImplicit` off means every identifier is visible in the signature;
  prefer that.
- Put the direction's informal statement and plan in
  `directions/<Name>/notes/00-statement.md`, and append a dated line to the
  progress log every time you change the formalisation.

## 6. Commands

```bash
cd /home/delfos/Documents/lean-lab

lake build                    # build everything
lake build LeanLab            # build one library
lake build Foo                # build direction Foo
lake env lean LeanLab/Basic.lean   # check one file
lake clean                    # nuke build artifacts (rarely needed)
```

Prefer the MCP tools over shelling out for iteration — they reuse a warm
language server. Use `lake build` for the authoritative final check.

## 7. Traps

Each of these was hit while bootstrapping this project; they are real error
messages, not hypotheticals.

- **`invalid 'import' command, it must be used in the beginning of the file`.**
  A docstring or comment precedes the imports. Imports go first; the `/-! -/`
  block goes after them.
- **`Unknown constant 'Real'` / `A public declaration 'Real' exists but is
  imported privately`.** You used plain `import` for a Mathlib module whose
  declarations appear in a public theorem. Change it to `public import`.
- **Another file cannot see your theorem, but your file compiles.** You are
  missing `public section`.
- **`error: no such file or directory .../LeanLab/LeanLab`.** Lake's `srcDir`
  and `globs` disagree. With `srcDir = "."` and `globs = ["LeanLab",
  "LeanLab.*"]` there must be a root file `LeanLab.lean` *and* a directory
  `LeanLab/`. A direction's root file is `directions/<Name>/lean/<Name>.lean`.
- **`warning: no targets specified and no default targets configured`.**
  `lake build` has nothing to do. `defaultTargets` in `lakefile.toml` must
  list every library. The `new-direction.sh` script maintains it.
- **`'Mathlib.Data.Real.Basic' has been deprecated`.** Mathlib v4.35 moved
  these; use `Mathlib.Basic.Real.Basic`.
- **Mathlib version skew.** Lean Finder's default snapshot is `v4.28.0`, older
  than this project's `v4.35.0`. Results may mention lemmas that were renamed
  or removed. Always confirm with `lean_local_search` or `lean_hover_info`
  before using a name found via external search.
- **`autoImplicit = false`.** "unknown identifier" usually means the variable
  was never introduced — not a Mathlib search failure.
- **`simp` blowing up.** If `simp` loops or takes forever, narrow the
  simp set (`simp only [...]`), use `simp_all` deliberately, or profile with
  `lean_profile_proof`.
- **Universe metavariables.** If Lean reports an unresolved universe, annotate
  `.{u}` / `.{v}` explicitly on the theorem.
- **Non-terminating `decide`.** `decide` on a large `Nat`/`Finset` problem
  will hang; use `native_decide` or reduce the instance size for testing.
- **Stale LSP.** After editing files by hand, the server may hold a stale
  view; `lean_build` restarts it. If `lean_goal` disagrees with the file on
  disk, rebuild.
- **Line numbers are 1-based and count every line**, including comments and
  blank lines. `lean_goal` wants the line of the *tactic*, not the theorem.
- **Rate limits.** Three external search requests per 30 seconds, shared
  globally. Batch your queries; do not retry in a tight loop.

## 8. Where things live

| Need | Location |
|---|---|
| Informal statement of a direction | `directions/<Name>/notes/00-statement.md` |
| Lean code for a direction | `directions/<Name>/lean/<Name>/` |
| Shared definitions | `LeanLab/` |
| Cross-cutting questions | `notes/` |
| External papers/notes | `references/` |
| New direction scaffold | `scripts/new-direction.sh` |
