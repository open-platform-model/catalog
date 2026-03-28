# Design Package: Resource Name Override

| Field       | Value            |
| ----------- | ---------------- |
| **Status**  | Draft            |
| **Created** | 2026-03-25       |
| **Authors** | OPM Contributors |

## Documents

1. [01-problem.md](01-problem.md) — Current naming architecture; cross-reference consensus; design flaw
2. [02-solution.md](02-solution.md) — `nameOverride` field; `#resolvedNames` context map; `#ResourceName` helper; cross-component reference pattern
3. [03-pipeline-changes.md](03-pipeline-changes.md) — Go and CUE changes required; transformer migration pattern
4. [04-decisions.md](04-decisions.md) — All design decisions with rationale and alternatives considered

## Cross-References

| Document | Purpose |
| -------- | ------- |
| `catalog/CONSTITUTION.md` | Core design principles governing all catalog changes |
| `catalog/core/v1alpha1/component/component.cue` | `#Component` definition receiving `nameOverride` |
| `catalog/core/v1alpha1/transformer/transformer.cue` | `#TransformerContext` receiving `#resolvedNames` |
| `cli/pkg/render/execute.go` | Go pipeline where `resolvedNames` computation is added |
| `modules/gateway/components.cue` | Concrete example of the cross-component reference problem |
