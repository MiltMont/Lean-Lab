# SmokeTest

## Problem (informal)

Not a research question. This direction is a **canary**: it proves that the
toolchain, the Mathlib import path, the `module` / `public import` /
`public section` chain and the build pipeline all work together.

If this direction stops compiling, the environment broke — not the maths.

## Formalisation plan

Two checks:

1. `LeanLab.SmokeTest.sq_nonneg` — `0 ≤ x ^ 2` for `x : ℝ`, proved by
   `nlinarith`. Exercises a Mathlib tactic and a real proof term.
2. `example : (2 : ℝ) + 2 = 4` — exercises `norm_num` and instance
   resolution.

## Progress log

- 2026-10-26: direction created; verified `lake build` succeeds and
  `#print axioms LeanLab.SmokeTest.sq_nonneg` reports only `propext`,
  `Classical.choice`, `Quot.sound`.
