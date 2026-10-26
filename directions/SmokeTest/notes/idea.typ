#import "/notes/template/lab.typ": *

// Human-written. Agents read this file but do not edit it.

= Idea

Not a research question. This direction is a _canary_: it shows that the
toolchain, the Mathlib import path, the `module` / `public import` /
`public section` chain, the build pipeline and these notes all work
together. If this direction stops compiling, the environment broke, not the
mathematics.

#theorem(name: "Squares are non-negative")[
  For every real number $x$, we have $x^2 >= 0$.
] <thm_sq_nonneg>

A second, unnamed check confirms that $2 + 2 = 4$ in $RR$, which exercises
`norm_num` and instance resolution.
