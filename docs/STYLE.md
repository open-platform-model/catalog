# Documentation Style Guide — Catalog

Inherits all rules from the [workspace STYLE.md](../../STYLE.md). This file adds catalog-specific conventions.

## Audience

**Catalog maintainers and CUE experts.** Readers understand CUE syntax, OPM type hierarchy, and the publishing workflow. They are not newcomers.

## Tone

- **Terse**. Say the minimum needed. Trust the reader to infer context.
- **API-reference style**. Lead with type signatures and constraints, follow with a brief explanation if non-obvious.
- Avoid motivational language ("This makes it easy to…"). State facts.
- No hand-holding preambles.

## Document Types in This Repo

| Type | Location | Purpose |
|------|----------|---------|
| Design principles | `docs/design-principles.md` | Authoritative design decisions |
| Core type reference | `docs/core/` | Per-type reference: definition, fields, constraints |
| RFCs | `docs/rfc/` | Proposed changes; follow RFC template |
| Analysis docs | `docs/` root | One-off deep dives |

## CUE Examples

- Every type reference doc must include at least one minimal CUE example showing the required fields.
- CUE examples use ` ```cue ` fencing.
- Show `#`-prefixed definitions, not concrete instances, when documenting types.
- Label examples with a comment when illustrating a specific constraint or default.

```cue
// Minimal valid Resource definition
#Resource: {
    metadata: name!: string
    kind:     "Container"
}
```

- Do not show deprecated syntax. If a field is optional, show it in a separate example.

## Field Documentation

Document fields in this order: required fields first, then optional fields, then hidden/computed fields.

Use inline tables when documenting multiple fields:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | `string` | yes | Kebab-case identifier |
| `description` | `string` | no | Human-readable summary |

## Glossary

Canonical glossary: [`opm/docs/glossary.md`](../../opm/docs/glossary.md). Do not duplicate definitions here.

## What to Omit

- Motivation or history unless it is a design doc.
- Step-by-step tutorials (those belong in `opm/docs/`).
- CLI command walkthroughs (those belong in `cli/docs/`).
