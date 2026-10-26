# Setup

Bootstrap record for this project.

## Versions

| Component | Version | Source |
|---|---|---|
| Lean | `v4.35.0` | `lean-toolchain` |
| Mathlib | `v4.35.0` | pinned in `lakefile.toml` |
| lean-lsp-mcp | `0.31.0` | `uvx lean-lsp-mcp` |
| Hermes MCP name | `lean-lsp` | `~/.hermes/config.yaml` |

Mathlib's release tags track the Lean toolchain exactly, so `v4.35.0` is the
matching Mathlib release for Lean `v4.35.0`. Bumping one requires bumping
the other.

## MCP configuration

Registered in `~/.hermes/config.yaml` under `mcp_servers.lean-lsp`:

```yaml
lean-lsp:
  command: "uvx"
  args: ["lean-lsp-mcp"]
  env:
    LEAN_PROJECT_PATH: "/home/delfos/Documents/lean-lab"
    LEAN_LOG_LEVEL: "WARNING"
    LEAN_MCP_INSTRUCTIONS: "..."
  timeout: 300
  connect_timeout: 120
```

`LEAN_PROJECT_PATH` is set so the server resolves `file_path` arguments
against this project without ambiguity. The server also supports project
switching over stdio, but pinning it avoids surprises.

Tools are exposed to the agent as `mcp_lean_lsp_<tool>`.

## What was verified

- `lake update` resolves dependencies and fetches the Mathlib olean cache
  (9031 files).
- `lake build` compiles `LeanLab` and every direction from a clean state.
- `lake build` produces zero warnings.
- `#print axioms LeanLab.SmokeTest.sq_nonneg` reports exactly
  `[propext, Classical.choice, Quot.sound]` — no `sorryAx`.
- `import SmokeTest` makes `LeanLab.SmokeTest.sq_nonneg` and
  `LeanLab.Problem` visible from another module: the `public import` /
  `public section` chain works.
- All 22 MCP tools are listed by the server. Spot-checked live:
  `lean_file_outline`, `lean_goal`, `lean_multi_attempt`, `lean_run_code`,
  `lean_local_search`, `lean_verify`.
- `scripts/new-direction.sh` scaffolds a direction, registers the library and
  updates `defaultTargets`; the new direction then builds.

## Known environment facts

- `lean-lsp-mcp` runs under `uvx`; the package is already in the uv cache, so
  startup is fast.
- `ripgrep` is installed at `/usr/bin/rg`, which `lean_local_search` and the
  `lean_verify` source scan require.
- Mathlib's olean cache lives at `~/.cache/mathlib` (35456 `.ltar` files) and
  is shared across projects.
- A full `.lake/` for one project is roughly 7.3 GB.
