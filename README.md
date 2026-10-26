# lean-lab

A Lean 4 project for turning research ideas into machine-checked mathematics.

- **Lean** `leanprover/lean4:v4.35.0`
- **Mathlib** `v4.35.0` (pinned)
- **Agent tooling** `lean-lsp-mcp` over stdio, wired into Hermes as `lean-lsp`

Agents working here should read **[AGENTS.md](AGENTS.md)** first — it covers
the module-system file shape, the MCP tool signatures, the formalisation
workflow, and the error messages that bite.

## Install

1. **Lean** — install `elan` (the Lean toolchain manager) by following
   <https://lean-lang.org/install/> (or the manual route at
   <https://github.com/leanprover/elan>). Do not install Lean from a system
   package manager: `elan` reads `lean-toolchain` and fetches the exact
   version this project pins.
2. **Clone and build**:

   ```bash
   git clone <this-repo-url> lean-lab
   cd lean-lab
   lake exe cache get    # download prebuilt Mathlib (~2 GB); skips hours of compiling
   lake build            # build every direction
   ```

3. **Agent tooling (optional)** — for MCP-driven work, set up
   [lean-lsp-mcp](https://github.com/oOo0oOo/lean-lsp-mcp) following its
   README: install [uv](https://docs.astral.sh/uv/getting-started/installation/)
   and [ripgrep](https://github.com/BurntSushi/ripgrep#installation), then
   register `uvx lean-lsp-mcp` with your MCP client. Set
   `LEAN_PROJECT_PATH` to wherever you cloned this repo. Tested with
   `lean-lsp-mcp` 0.31.0; see [notes/00-setup.md](notes/00-setup.md).

## Quick start

From the repository root:

```bash
lake build                    # build every direction
./scripts/new-direction.sh MyTopic
lake build MyTopic
```

## Layout

```
LeanLab/                 shared core library (common vocabulary)
LeanLab.lean              root module for the shared core
directions/<Name>/        one research direction
  lean/<Name>.lean        root module
  lean/<Name>/            Lean sources
  notes/00-statement.md   informal statement, plan, progress log
notes/                    project-level notes
references/               papers and external material
scripts/new-direction.sh  scaffold a new direction
```

`LeanLab/` holds only what more than one direction uses. Everything
direction-specific lives in that direction.

## Design decisions

**Mathlib is a default dependency.** Every direction can import Mathlib
without declaring it. The project is for research, so Mathlib is always
available.

**One library per direction.** Each direction is an independent `lean_lib`
with its own `srcDir`, so a broken direction cannot block the others and
each can be built in isolation (`lake build <Name>`).

**`autoImplicit = false`.** Every binder must be explicit. This catches
accidental reliance on guessed implicit arguments, which is the usual reason
a formalisation diverges from the informal claim.

**Notes live next to the code.** Each direction carries its informal
statement and a dated progress log. A refuted claim is a result and gets
recorded too.

## Verification

Every theorem must pass `lean_verify` with only `propext`,
`Classical.choice` and `Quot.sound` in its axiom set. `sorryAx` means the
proof is not finished.
