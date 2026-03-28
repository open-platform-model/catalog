# Design Package: Module Context (`#ctx`)

| Field       | Value            |
| ----------- | ---------------- |
| **Status**  | Draft            |
| **Created** | 2026-03-25       |
| **Authors** | OPM Contributors |

## Summary

Introduces `#ctx`, a well-known definition field on `#Module` that makes runtime and environment
information available to components at definition time. Module authors can reference the release
name, namespace, cluster domain, route domain, computed resource names, and DNS variations without
hardcoding values or requiring manual user input for derived configuration.

## Documents

1. [01-problem.md](01-problem.md) — Why modules are currently blind to deployment context; the cost of that blindness
2. [02-design.md](02-design.md) — Two-layer design: `runtime` (OPM-owned) + `platform` (open extension)
3. [03-schema.md](03-schema.md) — `#RuntimeContext`, `#ComponentNames`, `#ContextBuilder`, and `#environment` schemas
4. [04-pipeline-changes.md](04-pipeline-changes.md) — `#ModuleRelease` changes; `#ContextBuilder` computation; injection flow
5. [05-decisions.md](05-decisions.md) — All design decisions with rationale and alternatives considered
6. [06-notes.md](06-notes.md) — Deferred discussions, forward-leaning notes, and open questions requiring follow-up

## Open Questions and Deferred Items

All items flagged during design as requiring further discussion are tracked in [06-notes.md](06-notes.md). The notes file distinguishes between:

- **Deferred decisions** — topics explicitly considered and set aside for a follow-up design (e.g., `#TransformerContext` migration, bundle-level context)
- **Implementation notes** — constraints the initial implementer must keep in mind to avoid closing off future options (e.g., override support, environment profile sharing)
- **Follow-up design triggers** — conditions under which a deferred item should be revisited (e.g., Strategy A for content hashes, `platform` namespacing)

## Cross-References

| Document | Purpose |
| -------- | ------- |
| `catalog/CONSTITUTION.md` | Core design principles governing all catalog changes |
| `catalog/core/v1alpha1/module/module.cue` | `#Module` definition receiving `#ctx` |
| `catalog/core/v1alpha1/modulerelease/module_release.cue` | `#ModuleRelease` computing and injecting `#ctx` |
| `catalog/core/v1alpha1/transformer/transformer.cue` | `#TransformerContext` — relationship to `#ctx` is deferred |
| `catalog/core/v1alpha1/schemas/schemas.cue` | `#ContentHash`, `#ImmutableName` — hash computation moving to `#ctx` |
| `cli/pkg/render/execute.go` | `injectContext()` — receives environment inputs for `#ctx` |
| `modules/jellyfin/components.cue` | Concrete example: `publishedServerUrl` derivable from `#ctx.runtime.route.domain` |
| `catalog/design/02-resource-name-override/` | `#resolvedNames` design — superseded by `#ctx.runtime.components` |
