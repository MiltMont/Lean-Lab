module

/-!
# LeanLab — shared core

Definitions and lemmas that are reused across research directions live here.
Keep this module small and stable: it is the common vocabulary that every
direction imports. Anything specific to a single research question belongs in
that direction's own library under `directions/`.

Namespace convention: `LeanLab` for shared core, `LeanLab.<Direction>` for
direction-local definitions.
-/

public section

namespace LeanLab

universe u

/-- A `LeanLab` problem is a statement we want to formalise.  Kept as a
structure so that direction notes, the statement and the proof status can be
tracked together. -/
structure Problem where
  /-- Short human-readable identifier, e.g. `sumSqNonneg`. -/
  name : String
  /-- The informal statement the formalisation is meant to capture. -/
  statement : String
  deriving DecidableEq, Repr

end LeanLab
