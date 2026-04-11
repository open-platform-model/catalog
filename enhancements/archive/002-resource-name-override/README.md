# Design Package: Resource Name Override

| Field          | Value            |
| -------------- | ---------------- |
| **Status**     | Superseded       |
| **Created**    | 2026-03-25       |
| **Deprecated** | 2026-04-11       |
| **Authors**    | OPM Contributors |

> **Superseded by [003-module-context](../003-module-context/)** (decision D16).
> Resource name override is implemented as `metadata.resourceName` on `#Component`, read by `#ContextBuilder` and propagated through `#ComponentNames`. The separate `nameOverride`, `#resolvedNames`, `#ResourceName` helper, and transformer migration from this design are no longer needed.

## Documents (archived)

1. [01-problem.md](01-problem.md) — Current naming architecture; cross-reference consensus; design flaw
2. [02-solution.md](02-solution.md) — `nameOverride` field; `#resolvedNames` context map; `#ResourceName` helper; cross-component reference pattern
3. [03-pipeline-changes.md](03-pipeline-changes.md) — Go and CUE changes required; transformer migration pattern
4. [04-decisions.md](04-decisions.md) — All design decisions with rationale and alternatives considered
