module

public import LeanLab
public import Mathlib.Basic.Real.Basic
public import Mathlib.Tactic.Linarith

/-!
# SmokeTest

Verifies that the toolchain, Mathlib and the build pipeline work end to end:
imports from Mathlib, a `public` declaration reachable through the root
module, and a real proof with no `sorry`.

Delete this direction once a real research direction exists.
-/

public section

namespace LeanLab.SmokeTest

/-- Every square of a real number is non-negative. -/
theorem sq_nonneg (x : ℝ) : 0 ≤ x ^ 2 := by
  nlinarith [sq_nonneg (x - 1)]

/-- Sanity check that the ambient space is non-degenerate. -/
example : (2 : ℝ) + 2 = 4 := by norm_num

end LeanLab.SmokeTest
