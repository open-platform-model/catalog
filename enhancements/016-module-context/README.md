# Design Package: `#ctx` — Module Runtime Context

| Field       | Value            |
| ----------- | ---------------- |
| **Status**  | Draft            |
| **Created** | 2026-04-30       |
| **Authors** | OPM Contributors |

## Summary

Defines `#ctx` as the runtime-context channel injected into every `#Module` at release time. `#ctx` carries the deployment identity (release name, namespace, UUID; module name, version, FQN, UUID), the cluster environment (cluster domain, optional route domain), the per-component computed names (`resourceName`, DNS variants), and an open `platform` extension struct that platform teams use to publish per-platform facts (storage classes, backup backends, TLS issuers, gateways, app domains).

`#ctx` is **not** authored by module developers. It is computed by `#ContextBuilder` and unified into the module by `#ModuleRelease` during evaluation. Components reference it inside their specs (e.g. `#ctx.runtime.route.domain`, `#ctx.runtime.components.foo.dns.fqdn`, `#ctx.platform.appDomain`) without any operator input.

The schema is structured as a layered hierarchy: `#PlatformContext` (Layer 1, supplied by `#Platform`), `#EnvironmentContext` (Layer 2, supplied by `#Environment`), and release identity (Layer 3, from `#ModuleRelease.metadata`) merge into `#ModuleContext` — the value that `#Module.#ctx` resolves to.

This enhancement extracts the `#ctx` work from the now-archived [008-platform-construct](../archive/008-platform-construct/) and lands it as a standalone enhancement so that 014 (Platform construct) and 015 (Module schema) can both reference a single context-system source. The `#Platform` composition work, the `#Environment` deployment-target binding, and `#ModuleRelease` integration that 008 originally bundled are split: 014 owns Platform composition; 015 owns the Module shape; 016 owns the context schemas, `#Environment` minimum-context-node form, and `#ContextBuilder` only.

## Documents

1. [01-problem.md](01-problem.md) — Module blindness to deployment context; values vs context confusion; per-platform facts have no schema-level home
2. [02-design.md](02-design.md) — `#ctx` two-layer (`runtime` + `platform`) shape; layered hierarchy; `#ContextBuilder` flow; integration with `#Platform`, `#Environment`, `#ModuleRelease`
3. [03-schema.md](03-schema.md) — CUE definitions for `#ModuleContext`, `#PlatformContext`, `#EnvironmentContext`, `#RuntimeContext`, `#ComponentNames`, `#Environment`, `#ContextBuilder`
4. [04-decisions.md](04-decisions.md) — Decision log (carried forward from 008's ctx-relevant decisions, plus the split rationale)

## Scope

### In scope

- `#ctx` definition field on `#Module` (referenced from 015).
- `#ModuleContext`, `#PlatformContext`, `#EnvironmentContext`, `#RuntimeContext`, `#ComponentNames` schemas.
- `#ContextBuilder` helper that assembles the final `#ModuleContext` from layered inputs.
- `#Environment` construct in its minimum form (metadata + `#ctx: #EnvironmentContext` + `#platform` reference). The construct exists primarily as the Layer 2 context node and as the deployment target that `#ModuleRelease.#env` points at.
- `#ModuleRelease` integration sketch (how the builder is invoked).
- `#Component.metadata.resourceName` override and the cascade through `#ComponentNames`.
- `#Component.#names: #ComponentNames` per-component injection so a component reads its own resourceName / DNS variants without retyping its map key (D32).

### Out of scope

- `#Platform` composition (`#registry`, computed views) — owned by 014.
- `#Module` schema (slots, `#defines`, `#claims`) — owned by 015.
- `#TransformerContext` and how `#ctx` relates to it — deferred to a follow-up.
- Bundle-level context (cross-module references) — deferred (see Open Questions).
- Content hashes for immutable ConfigMaps/Secrets — removed from this enhancement (see D31); revisit when a concrete module-readable use case surfaces.
- Runtime-fill mechanism for `#registry` (014's territory).

## Cross-References

| Document | Purpose |
| -------- | ------- |
| `CONSTITUTION.md` (repo root) | Core design principles |
| `catalog/enhancements/archive/008-platform-construct/` | Predecessor — original combined Platform + Environment + `#ctx` design. The `#ctx` portion is lifted into this enhancement; the Platform composition portion is replaced by 014; the Module shape portion lives in 015. |
| `catalog/enhancements/014-platform-construct/` | Sibling — `#Platform.#ctx` references `#PlatformContext` defined here |
| `catalog/enhancements/015-module-defines/` | Sibling — `#Module.#ctx` references `#ModuleContext` defined here |
| `catalog/core/v1alpha2/module.cue` | Gains `#ctx: #ModuleContext` field |
| `catalog/core/v1alpha2/component.cue` | Gains optional `metadata.resourceName` override and a `#names: #ComponentNames` definition field |
| `catalog/core/v1alpha2/module_release.cue` | Modified to invoke `#ContextBuilder` and unify both `ctx` and per-component `#names` injections into the module |

## Applicability Checklist

- [x] `03-schema.md` — New CUE definitions for `#ModuleContext`, `#PlatformContext`, `#EnvironmentContext`, `#RuntimeContext`, `#ComponentNames`, `#Environment`, `#ContextBuilder`
- [ ] `NN-pipeline-changes.md` — Go pipeline modifications (deferred — content-hash injection, etc.)
- [ ] `NN-module-integration.md` — Module-author migration of `#config`-borne URLs/identities into `#ctx` references (deferred to a follow-up)
- [ ] `NN-context-flow.md` — Visual flow diagram (folded into 02-design.md while thin)
