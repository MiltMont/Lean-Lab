#import "/notes/template/lab.typ": *

// Agent-written. Formal statements, readings, questions and the progress log.

= Formalisation

#reading[
  In @thm_sq_nonneg, $x^2$ is the monoid power `x ^ 2` with a natural-number
  exponent, on `ℝ` from Mathlib. No other reading is plausible.
]

#lean("LeanLab.SmokeTest.sq_nonneg", claim: <thm_sq_nonneg>)
proved by `nlinarith [sq_nonneg (x - 1)]` in
`directions/SmokeTest/lean/SmokeTest/Basic.lean`.

The $2 + 2 = 4$ check is an anonymous `example` with no declaration name, so
it has no status tag; `lake build` failing is its only signal.

#question(
  answer: [Keep it as a permanent canary. (Milton, 2026-10-26; given in chat
    and recorded here by the agent.)],
)[
  Should SmokeTest stay permanently as a canary, or be deleted once a real
  direction exists? The Lean module docstring says to delete it; the notes
  describe it as a permanent canary.
]

== Progress log

- 2026-10-26: direction created; `lake build` succeeds and
  `#print axioms LeanLab.SmokeTest.sq_nonneg` reports only `propext`,
  `Classical.choice`, `Quot.sound`.
- 2026-10-26: notes migrated from `00-statement.md` to Typst
  (`main.typ`, `idea.typ`, `formal.typ`).
- 2026-10-26: question answered: SmokeTest is kept permanently; removed the
  "delete this direction" line from the Lean module docstring.
