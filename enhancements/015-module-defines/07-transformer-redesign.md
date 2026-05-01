# Transformer Redesign — Two Types, `#ModuleRelease`-Driven

| Field       | Value      |
| ----------- | ---------- |
| **Status**  | Draft      |
| **Created** | 2026-04-30 |
| **Revised** | 2026-05-01 — replaces the scope-bucket / `_scope` design with a two-type split |
| **Targets** | `catalog/core/v1alpha2/transformer.cue` |

## Why this doc exists

`#Module` lets `#Claim` instances live at **component level** (per-component data-plane needs) or at **module level** (cross-component platform-relationship needs) — CL-D10 in `10-decisions.md`. The original v1alpha1 `#Transformer` only matches a single `#Component` and emits a single resource. Two new shapes need to express cleanly:

1. **Module-scope render**: fires once per `#Module` (e.g. `#HostnameClaim` → ExternalDNS CR).
2. **Dual-scope render**: consumes a module-level `#Claim` and per-component `#Trait` / `#Resource` together, emits cross-component output (e.g. K8up `#BackupClaim` + per-component `#BackupTrait` → one Schedule CR + one Backend CR per Module — see `08-examples.md` Example 7).

This doc redesigns `#Transformer` to support both. It supersedes the earlier scope-bucket / `_scope` proposal that lived in this file (see TR-D5 in `10-decisions.md`).

## Runtime guarantee

The runtime always invokes `#transform` with a **fully concrete `#ModuleRelease`** — every `#components`, `#claims`, `#config`, `#ctx` value resolved before the transformer fires. The transformer body can index into `#moduleRelease` freely. This guarantee shapes the schema: there is no need for the matcher to pre-filter components into a map for the body's convenience; the body walks `#moduleRelease.#components` itself when it needs to.

## Design constraints recap

- **CL-D2**: `#Resource` and `#Claim` stay separate primitives.
- **CL-D10**: same `#Claim` primitive, two scopes (component or module).
- **CL-D11**: `#Resource`/`#Trait` stay component-only — never module-level.
- **DEF-D1 / DEF-D2 / DEF-D3**: transformers ship through `#defines.transformers` keyed by FQN.
- **TR-D5 (this doc)**: two transformer primitives — `#ComponentTransformer` and `#ModuleTransformer` — supersede the single `#Transformer` with scope buckets. `#defines.transformers` accepts a union of the two.

## Schema — `#ComponentTransformer`

Fires **once per matching component**. Match keys read against a single `#Component`. The render body receives the `#ModuleRelease` plus the matched `#Component`.

```cue
// catalog/core/v1alpha2/transformer.cue
package transformer

#ComponentTransformer: {
    apiVersion: "opmodel.dev/core/v1alpha2"
    kind:       "ComponentTransformer"

    metadata: {
        modulePath!: #ModulePathType   // "opmodel.dev/opm/v1alpha2/providers/kubernetes"
        version!:    #MajorVersionType
        name!:       #NameType
        #definitionName: (#KebabToPascal & {"in": name}).out
        fqn: #FQNType & "\(modulePath)/\(name)@\(version)"
        description!: string
        labels?:      #LabelsAnnotationsType
        annotations?: #LabelsAnnotationsType
    }

    // Match keys — read against the candidate #Component.
    requiredLabels?:    #LabelsAnnotationsType
    optionalLabels?:    #LabelsAnnotationsType
    requiredResources?: [FQN=string]: _
    optionalResources?: [FQN=string]: _
    requiredTraits?:    [FQN=string]: _
    optionalTraits?:    [FQN=string]: _
    requiredClaims?:    [FQN=string]: _   // component-level Claims
    optionalClaims?:    [FQN=string]: _

    // Optional declarative metadata for catalog UIs and pipeline diff.
    readsContext?:  [...string]
    producesKinds?: [...string]

    // Render function. Runtime always supplies both inputs concretely.
    #transform: {
        #moduleRelease: _              // fully concrete #ModuleRelease
        #component:     _              // the matched #Component (singular)
        #context:       #TransformerContext

        output: {...}
    }
}
```

## Schema — `#ModuleTransformer`

Fires **once per `#Module`** that satisfies the match. Match keys read against `#Module` top level. The render body receives the `#ModuleRelease` and walks `#moduleRelease.#components` itself when dual-scope work is needed.

```cue
#ModuleTransformer: {
    apiVersion: "opmodel.dev/core/v1alpha2"
    kind:       "ModuleTransformer"

    metadata: {
        modulePath!: #ModulePathType
        version!:    #MajorVersionType
        name!:       #NameType
        #definitionName: (#KebabToPascal & {"in": name}).out
        fqn: #FQNType & "\(modulePath)/\(name)@\(version)"
        description!: string
        labels?:      #LabelsAnnotationsType
        annotations?: #LabelsAnnotationsType
    }

    // Match keys — read against #Module top level.
    // Only Claims and module labels — Resources/Traits are component-only by CL-D11.
    requiredLabels?: #LabelsAnnotationsType
    optionalLabels?: #LabelsAnnotationsType
    requiredClaims?: [FQN=string]: _   // module-level Claims
    optionalClaims?: [FQN=string]: _

    // Pre-fire gate for dual-scope renders.
    // Declares "I expect at least one component carrying X to exist."
    // The matcher checks this before firing; the body still iterates
    // #moduleRelease.#components itself to do the actual work.
    requiresComponents?: {
        resources?: [FQN=string]: _
        traits?:    [FQN=string]: _
        claims?:    [FQN=string]: _
    }

    readsContext?:  [...string]
    producesKinds?: [...string]

    #transform: {
        #moduleRelease: _              // fully concrete #ModuleRelease
        #context:       #TransformerContext

        output: {...}
    }
}
```

## Status writeback to `#Claim` instances

`#Claim` carries an open `#status?` field (CL-D15 in `10-decisions.md`). The transformer that fulfils a Claim writes that Claim's `#status` as part of its render. The split lifecycle:

1. **Match.** Matcher walks `#composedTransformers`. A transformer whose `requiredClaims` contains a Claim FQN is the fulfiller for that Claim instance.
2. **Render.** Transformer body runs — `#transform.output` produces the provider-specific resource(s); a sibling `#transform.#statusWrites` carries per-claim status data (sketch below).
3. **Inject.** The Go pipeline reads `#statusWrites` and injects values via `FillPath` into the matched `#Claim` instance's `#status`. Same Strategy B precedent as 016 D12 hash injection.
4. **Consume.** Downstream transformers / component bodies that read `#claims.<id>.#status.<field>` see the populated values. The matcher topologically orders fulfillers before consumers.

### Schema sketch — `#statusWrites`

The exact field name and shape are an implementation concern; the doc records the channel exists. One convention:

```cue
#ComponentTransformer: {
    ...
    #transform: {
        #moduleRelease: _
        #component:     _
        #context:       #TransformerContext

        output: {...}                          // provider-specific render

        // Per-claim status data the runtime writes back into the matched
        // #Claim instance's #status. Keyed by the consumer Module's claim id
        // (e.g. "db" if the module declared #claims.db: ...). The matcher
        // resolves claim ids by FQN-equality between requiredClaims and the
        // candidate component's #claims.
        #statusWrites?: [claimId=string]: _
    }
}

#ModuleTransformer: {
    ...
    #transform: {
        #moduleRelease: _
        #context:       #TransformerContext

        output: {...}

        #statusWrites?: [claimId=string]: _    // resolves against #moduleRelease.#claims
    }
}
```

A `#PublicEndpointTransformer` that fulfils `net.#PublicEndpointClaim` would emit:

```cue
#statusWrites: (claimIdForFqn): {
    url:  "https://\(_claim.#spec.publicEndpoint.hostname).\(#context.runtime.route.domain)"
    fqdn: "\(_claim.#spec.publicEndpoint.hostname).\(#context.runtime.route.domain)"
}
```

— and the runtime injects that map into `#claims.<id>.#status` before downstream code reads it.

### Side-effect-only claims

Claims fulfilled purely by side-effect (e.g. backup orchestration — see Example 7 in `08-examples.md`) may omit `#statusWrites` entirely. Their `#status` stays empty by design; consumers do not read resolution data because there is none. The schema does not require `#statusWrites` for any fulfiller — the field is optional, mirroring `#Claim.#status?`.

## Publication slot — union type

`#defines.transformers` accepts either type:

```cue
#TransformerMap: [#FQNType]: #ComponentTransformer | #ModuleTransformer
```

`#Module.#defines.transformers` (in `module.cue`) is keyed by FQN with the same FQN-binding constraint as the other `#defines` sub-maps:

```cue
transformers?: [FQN=string]: (transformer.#ComponentTransformer | transformer.#ModuleTransformer) & {
    metadata: fqn: FQN
}
```

## Matcher

The matcher iterates `#composedTransformers` (014) once per Module under render. Type identity gives fan-out directly — no derived discriminator.

```text
function renderModule(moduleRelease, transformers, runtimeContext) -> [Output]:
    outputs = []
    for t in transformers:
        outputs.extend(matchAndRender(moduleRelease, t, runtimeContext))
    return outputs

function matchAndRender(moduleRelease, t, runtimeContext) -> [Output]:
    if t.kind == "ComponentTransformer":
        outputs = []
        for (name, cmp) in moduleRelease.#components.items():
            if not satisfiesComponent(cmp, t):
                continue
            ctx = buildContext(moduleRelease, runtimeContext, t, cmp)
            outputs.append(runRender(t, moduleRelease, cmp, ctx))
        return outputs

    if t.kind == "ModuleTransformer":
        if not satisfiesModule(moduleRelease, t):
            return []
        if t.requiresComponents is not None and not anyComponentMatches(moduleRelease, t.requiresComponents):
            return []
        ctx = buildContext(moduleRelease, runtimeContext, t, component=None)
        return [ runRender(t, moduleRelease, ctx) ]

    fail("unknown transformer kind: %s" % t.kind)
```

### `satisfiesComponent`

```text
function satisfiesComponent(cmp, t) -> bool:
    for (k, v) in t.requiredLabels or {}:
        if cmp.metadata.labels.get(k) != v: return False
    for fqn in t.requiredResources or {}:
        if fqn not in fqnsOf(cmp.#resources): return False
    for fqn in t.requiredTraits or {}:
        if fqn not in fqnsOf(cmp.#traits or {}): return False
    for fqn in t.requiredClaims or {}:
        if not anyClaimWithFQN(cmp.#claims or {}, fqn): return False
    return True
```

### `satisfiesModule`

```text
function satisfiesModule(moduleRelease, t) -> bool:
    for (k, v) in t.requiredLabels or {}:
        if moduleRelease.metadata.labels.get(k) != v: return False
    for fqn in t.requiredClaims or {}:
        if not anyClaimWithFQN(moduleRelease.#claims or {}, fqn): return False
    return True
```

`anyClaimWithFQN(claims, fqn)` returns true iff some entry in `claims` has `metadata.fqn == fqn`. Matching is FQN-equality (CL-D4 / DEF-D2) — the spec is the payload, not the match key.

### `anyComponentMatches`

```text
function anyComponentMatches(moduleRelease, rc) -> bool:
    for cmp in moduleRelease.#components.values():
        ok = True
        for fqn in rc.resources or {}:
            if fqn not in fqnsOf(cmp.#resources): ok = False; break
        if not ok: continue
        for fqn in rc.traits or {}:
            if fqn not in fqnsOf(cmp.#traits or {}): ok = False; break
        if not ok: continue
        for fqn in rc.claims or {}:
            if not anyClaimWithFQN(cmp.#claims or {}, fqn): ok = False; break
        if ok: return True
    return False
```

A `#ModuleTransformer` whose `requiresComponents` finds zero matches **does not fire** and the platform reports an unfulfilled dual-scope render. This turns a misconfiguration into a deploy-time error rather than a vacuous output.

## Worked component-scope example — Deployment

```cue
#DeploymentTransformer: transformer.#ComponentTransformer & {
    metadata: { ... }

    requiredLabels:    "core.opmodel.dev/workload-type": "stateless"
    requiredResources: (workload.#ContainerResource.metadata.fqn): _

    #transform: {
        #moduleRelease: _
        #component:     _
        #context:       #TransformerContext

        output: {
            apiVersion: "apps/v1"
            kind:       "Deployment"
            metadata:   { name: #component.metadata.name, ... }
            spec:       { ... uses #component.spec ... }
        }
    }
}
```

`#component` is singular and concrete — body indexes into it directly.

## Worked module-scope example — Hostname

```cue
#HostnameTransformer: transformer.#ModuleTransformer & {
    metadata: { ... }

    requiredClaims: (platform.#HostnameClaim.metadata.fqn): _
    // No requiresComponents — pure module-scope render.

    readsContext:  ["dns.zones"]
    producesKinds: ["externaldns.k8s.io/v1.DNSEndpoint"]

    #transform: {
        #moduleRelease: _
        #context:       #TransformerContext

        // Look up the claim instance that matched.
        let claim = #moduleRelease.#claims[
            for k, v in #moduleRelease.#claims
            if v.metadata.fqn == platform.#HostnameClaim.metadata.fqn { k }
        ][0]

        output: {
            apiVersion: "externaldns.k8s.io/v1"
            kind:       "DNSEndpoint"
            spec: { hostname: claim.#spec.hostname.fqdn, ... }
        }
    }
}
```

Fires once per Module carrying a `#HostnameClaim`. No per-component fan-out.

## Worked dual-scope example — K8up backup

The K8up `#BackupScheduleTransformer` (Example 7 in `08-examples.md`):

```cue
#BackupScheduleTransformer: transformer.#ModuleTransformer & {
    metadata: {
        modulePath:  "opmodel.dev/k8up/v1alpha2/transformers"
        version:     "v1"
        name:        "backup-schedule-transformer"
        description: "Renders #BackupClaim + per-component #BackupTrait → K8up Backend + Schedule CRs"
    }

    // Module-level orchestration claim.
    requiredClaims: (backup.#BackupClaim.metadata.fqn): _

    // Pre-fire gate — refuse to fire if no component carries the trait.
    requiresComponents: traits: (backup.#BackupTrait.metadata.fqn): _

    readsContext:  ["backup.backends"]
    producesKinds: ["k8up.io/v1.Backend", "k8up.io/v1.Schedule"]

    #transform: {
        #moduleRelease: _
        #context:       #TransformerContext

        // Body walks components itself, filtering inline for the trait.
        let _bearers = {
            for name, cmp in #moduleRelease.#components
            if cmp.#traits != _|_
            if cmp.#traits[backup.#BackupTrait.metadata.fqn] != _|_ {
                (name): cmp
            }
        }

        let _claim = #moduleRelease.#claims[
            for k, v in #moduleRelease.#claims
            if v.metadata.fqn == backup.#BackupClaim.metadata.fqn { k }
        ][0]

        output: {
            backend: { ... uses _claim.#spec.backup.backend + #context.platform.backup.backends ... }
            schedule: {
                apiVersion: "k8up.io/v1"
                kind:       "Schedule"
                spec: {
                    schedule: _claim.#spec.backup.schedule
                    podSelector: matchExpressions: [{
                        key: "app.kubernetes.io/name"
                        operator: "In"
                        values: [for name, _ in _bearers { name }]
                    }]
                    // ... retention from _claim.#spec.backup.retention ...
                }
            }
        }
    }
}
```

Match flow on the Strix media Module:

1. `kind == "ModuleTransformer"` → check `satisfiesModule`.
2. `requiredClaims` check passes — `nightly` claim has the right FQN.
3. `requiresComponents.traits` gate — `anyComponentMatches` returns true (`app` and `db` both carry `#BackupTrait`).
4. `#transform` fires once. Body's `_bearers` comprehension picks up `app` and `db`. Output emits one Backend and one Schedule referencing both.

If the Module satisfied the claim but no component carried `#BackupTrait`, step 3 returns false and the transformer is skipped — the platform reports an unfulfilled dual-scope render at deploy time.

## What changed from the earlier scope-bucket design

| Old (superseded) | New |
|---|---|
| Single `#Transformer` with `componentMatch` / `moduleMatch` buckets | Two primitives: `#ComponentTransformer` / `#ModuleTransformer` |
| Derived `_scope` field | Removed — type identity carries the scope |
| `#transform.#components: [string]: _` (singleton / multi / empty) | `#component` (singular, on `#ComponentTransformer`) or absent (on `#ModuleTransformer`) |
| Pre-filtered map of components for dual-scope | Body walks `#moduleRelease.#components` itself; `requiresComponents` is a pre-fire gate, not a filter |
| `#defines.transformers: [FQN]: #Transformer` | `#defines.transformers: [FQN]: #ComponentTransformer \| #ModuleTransformer` |

The runtime guarantee (always-concrete `#ModuleRelease`) is what makes the simpler shape work: bodies that need cross-component data iterate `#moduleRelease.#components` rather than receiving a pre-filtered map.

## Migration impact (catalog/opm/v1alpha2)

When the well-known catalog is rebuilt under v1alpha2:

| Source | Change |
|---|---|
| Existing component-scope transformers (Deployment, Service, ConfigMap, …) | Wrap as `#ComponentTransformer`; rename `#transform.#component` field is already singular; replace v1alpha1 imports |
| New module-scope transformers (Hostname, ExternalDNS, etc.) | Author as `#ModuleTransformer` |
| K8up backup, cert-manager, Gateway-API routing | Author as `#ModuleTransformer` with `requiresComponents` |

`cue vet` will flag any transformer that does not match either of the two definitions.

## Open questions

### TR-Q3 — Does 014's `#provider` synthetic value still work? (was Q15)

`014/02-design.md` claims the existing matcher interface is preserved via a synthetic `#provider` wrapping `#composedTransformers`. With two transformer kinds, the matcher dispatches by `kind`. Either the existing `#provider` shape carries enough information, or 014 needs a follow-up amendment.

**Sub-question (CL-D15/CL-D16):** does the matcher's `runRender` step also handle `#statusWrites` injection back into the resolved Module, or is `#status` injection a separate pipeline phase that runs between transformer dispatches? The phase split affects whether the synthetic `#provider` needs to expose any state to the post-render injection step.

**Revisit trigger**: when 014 transitions from draft to implementation.

### CL-Q8 — Multiple module-level Claims of the same FQN (was Q16)

The matcher pseudocode picks the first matching claim instance via a comprehension lookup. If a Module carries two `#claims` entries with the same FQN at module level, the body silently sees only one. Should that be a CUE-time uniqueness check on `#Module.#claims`?

**Lean direction**: yes — duplicate module-level Claim FQN is a misconfiguration. Worth enforcing at `#Module` schema time.

**Revisit trigger**: pipeline implementation, or first author hitting it.

### TR-Q4 — `requiresComponents` granularity (was Q17)

`requiresComponents` is a single conjunction (resources AND traits AND claims). A transformer that wants "components carrying `#BackupTrait` *or* components with a backup-tagged volume" cannot express that. Disjunctive gates may eventually want their own shape; deferred until a real case appears.

**Revisit trigger**: first transformer that needs a disjunctive gate.

### CL-Q7 — Status writeback ordering (was Q18)

A `#ComponentTransformer` (or `#ModuleTransformer`) that fulfils a Claim writes `#status` via `#statusWrites`. A second transformer — or a component body — reads the same Claim's `#status` to wire connection data. The matcher must dispatch fulfillers before consumers; the dispatch order is the topological sort of an FQN-graph derived from `requiredClaims` (write edges) and `#claims.<id>.#status.<field>` reads (read edges).

Open sub-questions:

- **Cycle detection.** Two transformers that each write a Claim the other reads form a cycle. Should the matcher detect this at platform-evaluation time (CUE-time) or at deploy-time (Go-pipeline)?
- **Missing fulfiller.** If a consumer reads `#status.X` but no transformer writes it, what is the deploy-time signal? `_|_` from CUE? An explicit unmatched-claim error from the matcher?
- **Multi-fulfiller.** TR-Q2 (multi-fulfiller resolution policy) — when two transformers both have `requiredClaims: <FQN>`, only one writes `#status` for a given claim instance. Selection policy is the same as TR-Q2.

**Revisit trigger**: pipeline implementation, or first author hitting a cycle/missing-fulfiller case.

## Decisions added by this redesign

(Live in `10-decisions.md` under the TR- and CL- prefixes.)

- **TR-D5** (was D28): Replace single `#Transformer` with two primitives: `#ComponentTransformer` (per-component fire) and `#ModuleTransformer` (per-module fire). `#defines.transformers` accepts the union. `_scope` and the bucketed match-key shape are gone. `requiresComponents` on `#ModuleTransformer` carries the dual-scope pre-fire gate. Supersedes TR-D1–TR-D4 (was D24–D27).
- **TR-D6** (was D29): Runtime always passes a fully concrete `#ModuleRelease` to `#transform`. Transformer bodies index freely.
- **TR-D7** (was D30): `#ModuleTransformer.requiresComponents` is a pre-fire gate, not a filter. Body iterates `#moduleRelease.#components` itself.
- **CL-D15** (was D31) — `#Claim` gains `#status?`. Transformer-written resolution surface; concrete claims pin a `#status` schema (or omit it for side-effect-only fulfilment).
- **CL-D16** (was D32) — `#status` injection follows 016 D12 (Strategy B / Go pipeline). Matcher topologically orders fulfillers before consumers; `#statusWrites` is the channel sketched above.
