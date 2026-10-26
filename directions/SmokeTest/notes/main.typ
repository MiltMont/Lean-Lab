#import "/notes/template/lab.typ": *

#show: lab.with(
  title: "SmokeTest",
  subtitle: upper[canary direction],
  primary: upper[lean-lab],
  secondary: [Checks that the toolchain, Mathlib and the notes pipeline work.],
)

// idea.typ: written by humans. formal.typ: written by agents.
#include "idea.typ"
#include "formal.typ"
