# Design

## Design Goals

- Introduce `#Directive` as a module-level primitive, sibling to `#Rule`, inside the existing `#Policy` construct. Direction: **module → platform** (authoring side instructs platform; distinct from `#Rule`'s platform → module mandate).
- Keep `#Trait` for component-local facts only. Cross-component concerns become directives.
- Introduce `#PolicyTransformer` as a new transformer scope distinct from `#Transformer`. It matches a directive, reads the matched components' trait specs, and emits module-scope resources.
- Enforce validation at catalog-compile time where possible (trait/directive coverage; backend name resolution) so authoring errors surface before render.

## Non-Goals (v1)

- Multi-directive coverage of the same component. Rejected at compile time for v1; see [OQ-1](09-open-questions.md).
- Explicit `pairsWith` version field on `#Trait` / `#Directive`. Version alignment achieved via shared CUE package import + transformer match constraints; see [OQ-2](09-open-questions.md).
- Cross-module directive references. Deferred.

---

## The Updated Primitive Taxonomy

### Component-level primitives (Blueprint-composable)

| Primitive | Question | Who controls | Status |
|-----------|----------|--------------|--------|
| `#Resource` | "What must exist?" | Module author | Unchanged |
| `#Trait` | "How does the component behave? / What is true about it?" | Module author | Unchanged; carries component-local operational facts |
| `#Blueprint` | "What is the reusable pattern?" | Composes `#Resource` + `#Trait` | Unchanged |

### Policy-level primitives (module-level, inside `#Policy`)

| Primitive | Direction | Who writes it | Status |
|-----------|-----------|---------------|--------|
| `#Rule` | Platform → Module | Platform team | Unchanged |
| `#Directive` | Module → Platform | Module author | **New** in 011 |

### Transformer scopes (provider-level)

| Transformer scope | Matches | Reads | Emits | Status |
|-------------------|---------|-------|-------|--------|
| `#Transformer` | A single `#Component` (via `requiredResources` / `requiredTraits`) | One component's resource + trait specs | Resources scoped to that component | Unchanged |
| `#PolicyTransformer` | A `#Directive` (via `requiredDirectives`) + optionally `requiredTraits` on matched components | The directive spec + each `appliesTo` component's trait spec + platform `#ctx` | Resources scoped to the module (one batch per directive) | **New** |

---

## `#Directive` Primitive

File: `catalog/core/v1alpha1/primitives/directive.cue`

```cue
package primitives

import (
    "strings"
    t "opmodel.dev/core/v1alpha1/types@v1"
)

// #Directive — module-level instruction from the module author to the platform.
// Sibling to #Rule inside #Policy. The platform (via a matching #PolicyTransformer
// and/or the CLI) acts on the directive; it is not a per-component property.
#Directive: {
    apiVersion: "opmodel.dev/core/v1alpha1"
    kind:       "Directive"

    metadata: {
        modulePath!:      t.#ModulePathType
        version!:         t.#MajorVersionType
        name!:            t.#NameType
        #definitionName:  (t.#KebabToPascal & {"in": name}).out

        fqn: t.#FQNType & "\(modulePath)/\(name)@\(version)"
        description?: string
        labels?:      t.#LabelsAnnotationsType
        annotations?: t.#LabelsAnnotationsType
    }

    // Directive contract schema. Contributes a named field to the #Policy's merged spec,
    // mirroring how #Rule and the component-level primitives contribute named fields.
    #spec!: (strings.ToCamel(metadata.name)): _

    // Defaults
    #defaults: #spec
}

#DirectiveMap: [string]: #Directive
```

Parallels the shape of `#Rule` closely. The distinction is semantic, not structural: `#Rule` encodes governance the platform enforces on modules; `#Directive` encodes instructions modules give the platform. Both live inside `#Policy` and contribute to its spec.

---

## Broadened `#Policy`

File: `catalog/core/v1alpha1/policy/policy.cue`

```cue
#Policy: {
    apiVersion: "opmodel.dev/core/v1alpha1"
    kind:       "Policy"

    metadata: {
        name!:        t.#NameType
        labels?:      t.#LabelsAnnotationsType
        annotations?: t.#LabelsAnnotationsType
    }

    // Governance (platform → module)
    #rules?: [RuleFQN=string]: prim.#Rule

    // Orchestration (module → platform)
    #directives?: [DirFQN=string]: prim.#Directive

    // Which components this policy applies to.
    // A policy can apply a rule, a directive, or both to the same component set.
    appliesTo: {
        matchLabels?: t.#LabelsAnnotationsType
        components?:  [...t.#NameType]
    }

    // Merged spec contributed by rules + directives. Each primitive contributes a
    // camelCase-named subfield (same pattern as #Resource and #Trait).
    spec: close({
        if #rules != _|_ {
            for _, r in #rules { r.spec }
        }
        if #directives != _|_ {
            for _, d in #directives { d.spec }
        }
    })
}

#PolicyMap: [string]: #Policy
```

`#Policy` is broadened to carry both `#rules` and `#directives`. `appliesTo` scopes both uniformly.

---

## `#PolicyTransformer` (Overview)

New file: `catalog/core/v1alpha1/transformer/policy_transformer.cue`

Full schema and matching rules are in [06-policy-transformer.md](06-policy-transformer.md). The shape in brief:

```cue
#PolicyTransformer: {
    apiVersion: "opmodel.dev/core/v1alpha1"
    kind:       "PolicyTransformer"

    metadata: { modulePath!, version!, name!, fqn, ... }

    // Match predicate
    requiredDirectives!: [...t.#FQNType]   // at least one required directive FQN
    requiredTraits?:     [...t.#FQNType]   // traits required on every component in appliesTo
    requiredResources?:  [...t.#FQNType]   // resources required on every component in appliesTo
    requiredRules?:      [...t.#FQNType]   // rules that must also be present in the Policy

    // Inputs it will read at render time
    readsContext?: [...string]             // dotted paths into #ctx.platform that must be present

    // Output declaration
    producesKinds: [...string]             // k8s kinds this transformer emits (for discovery/diff)

    // Render function — receives directive spec, appliesTo components' trait specs,
    // and resolved platform ctx. Returns a set of platform resources.
    out: _
}
```

`#Provider` gains a `#policyTransformers` field parallel to `#transformers`:

```cue
#Provider: {
    ...
    #transformers:        transformer.#TransformerMap        // component-scope
    #policyTransformers?: transformer.#PolicyTransformerMap  // policy-scope
}
```

Platform composition aggregates both across composed providers; existing composition rules apply unchanged.

---

## Module-Level Shape (Backup Example Outline)

Author-side shape after 011:

```cue
#Module & {
    #components: {
        "jellyfin-app": #StatefulWorkload & ops.#BackupTrait & {
            spec: {
                // ... workload ...
                backup: {
                    targets: [{volume: "config"}]
                    exclude: ["*.tmp"]
                }
            }
        }
        "jellyfin-db": #StatefulWorkload & ops.#BackupTrait & {
            spec: {
                // ... workload ...
                backup: {
                    targets: [{volume: "data"}]
                    preBackup: [{name: "pg-checkpoint", command: ["psql","-c","CHECKPOINT"]}]
                }
            }
        }
    }

    #policies: {
        "nightly": policy.#Policy & {
            appliesTo: components: ["jellyfin-app", "jellyfin-db"]
            #directives: {
                (ops.#BackupPolicy.metadata.fqn): ops.#BackupPolicy & {
                    #spec: backup: {
                        schedule: "0 2 * * *"
                        backend:  "offsite-b2"
                        retention: { keepDaily: 7, keepWeekly: 4, keepMonthly: 3 }
                        restore: { /* see 03-backup-example.md */ }
                    }
                }
            }
        }
    }
}
```

Full schemas in [03-backup-example.md](03-backup-example.md).

---

## Composition Cheatsheet

What goes where:

| Concern | Location | Carried by |
| ------- | -------- | ---------- |
| Per-component local fact (e.g. "which of my volumes to back up") | Component | `#Trait` in `#components[x].spec.<name>` |
| Cross-component orchestration (e.g. "backup schedule + backend + retention") | Module | `#Directive` in `#policies[y].#directives` |
| Platform mandate (e.g. "all stateful workloads MUST have `#BackupTrait`") | Module | `#Rule` in `#policies[y].#rules` |
| Render (component-scope) | Provider | `#Transformer` |
| Render (policy-scope) | Provider | `#PolicyTransformer` |
| Platform-wide configuration (e.g. backup backends with credentials) | Platform | `#Platform.#ctx.platform.<commodity>.*` (see convention below) |

---

## Platform Context Namespacing Convention

Operational commodities consistently need platform-level configuration: backup needs backends with credentials, TLS needs issuer references, routing needs Gateways. All of these live in the open `#ctx.platform` struct contributed by `#Platform` (see enhancement 008).

**Convention.** Each commodity claims a top-level subtree under `#ctx.platform` named after the commodity. The subtree matches the suffix of the commodity's directive `metadata.modulePath`:

| Commodity | Directive `modulePath` | Platform-ctx subtree |
| --------- | --------------------- | -------------------- |
| Backup | `opmodel.dev/opm/v1alpha1/operations/backup` | `#ctx.platform.backup.*` |
| TLS certificates | `opmodel.dev/opm/v1alpha1/operations/tls` | `#ctx.platform.tls.*` |
| Routing | `opmodel.dev/opm/v1alpha1/operations/routing` | `#ctx.platform.routing.*` |

Within the subtree, keys are commodity-specific:

- `#ctx.platform.backup.backends[name]` — K8up/Velero/Restic repository configs.
- `#ctx.platform.tls.issuers[name]` — cert-manager Issuer/ClusterIssuer references.
- `#ctx.platform.routing.gateways[name]` — Gateway API Gateway references with listeners.

**Why a convention, not a schema rule.** `#ctx.platform` is deliberately an open struct owned by the platform team (see 008). 011 does not add schema constraints to it. The convention is advisory: it makes `readsContext` paths predictable across commodities, eliminates subtree collisions, and lets the CLI produce useful diagnostics ("the `tls.issuers` path is missing; check your platform definition").

**For new commodities.** Pick the subtree that matches your directive's module path. If a conflict exists with another commodity's subtree, rename at the commodity level rather than improvising a sub-subtree. Platform teams can still extend `#ctx.platform` with non-commodity extensions — those should pick names that do not collide with declared commodity names.

**Transformer declaration.** A `#PolicyTransformer` names the paths it reads via `readsContext`:

```cue
#BackupScheduleTransformer: #PolicyTransformer & {
    readsContext: ["backup.backends"]
}

#CertificateTransformer: #PolicyTransformer & {
    readsContext: ["tls.issuers"]
}

#HTTPRouteTransformer: #PolicyTransformer & {
    readsContext: ["routing.gateways"]
}
```

The render pipeline validates that every declared path is resolvable at render time, and errors if a path is missing (see [07-rendering-pipeline.md](07-rendering-pipeline.md) Step 4). This gives platform teams a discoverable contract: "these paths are required by the installed commodities; populate them."

See [D14](08-decisions.md) for the decision rationale.

---

## Validation Rules

Enforced at catalog-compile time / module validation:

1. **Trait coverage** — Every component with `#BackupTrait` should be covered by exactly one `#Policy` containing a `#BackupPolicy` directive whose `appliesTo` matches the component.
   - Zero covering policies → **warn** (dead trait; nothing scheduled). Not an error because a trait without a covering directive is still structurally valid; operator may author one later.
   - More than one covering policy → **error**. (See [OQ-1](09-open-questions.md).)
2. **Directive target validity** — Every component named in a directive's containing `appliesTo` must carry the traits listed in the matching `#PolicyTransformer.requiredTraits`.
   - Missing trait → **error** (directive applies to a component that cannot fulfill it).
3. **Backend resolution** — `#BackupPolicy.backend` names a key that must exist in `#Platform.#ctx.platform.backup.backends` at render time.
   - Missing backend → **error** at render.
4. **Directive + transformer presence** — For every directive in a module, the composed `#Platform.#policyTransformers` must include at least one transformer with that directive's FQN in `requiredDirectives`.
   - No matching policy transformer → **error** (directive would be a no-op).
5. **Restore step component references** — Every `component` field in `restore.preRestore` / `restore.postRestore` / `restore.healthChecks` must appear in the containing `#Policy.appliesTo.components`.
   - Foreign reference → **error**.

Rules 1, 2, 5 are CUE-expressible. Rule 3 requires platform context and fires at render time. Rule 4 requires platform composition and fires at render time (or at `opm release diff` / `opm release preview` in the CLI).

---

## Relationship to Existing Code

| File | Change |
| ---- | ------ |
| `catalog/core/v1alpha1/primitives/` | **Add** `directive.cue` defining `#Directive` + `#DirectiveMap` |
| `catalog/core/v1alpha1/policy/policy.cue` | **Modify** `#Policy` to gain `#directives` field and merge rule+directive specs |
| `catalog/core/v1alpha1/transformer/` | **Add** `policy_transformer.cue` defining `#PolicyTransformer` + `#PolicyTransformerMap` |
| `catalog/core/v1alpha1/provider/provider.cue` | **Modify** `#Provider` to gain `#policyTransformers` |
| `catalog/opm/v1alpha1/operations/backup/` | **Add** new CUE package exporting `#BackupTrait` + `#BackupPolicy` (co-located — same version by import) |
| `catalog/k8up/v1alpha1/transformers/backup.cue` | **Add** `#BackupScheduleTransformer` as a `#PolicyTransformer` |
| `catalog/k8up/v1alpha1/providers/kubernetes/provider.cue` | **Modify** to register the new policy transformer under `#policyTransformers` |

No schema changes to existing `#Component`, `#Module`, `#Transformer`, `#Resource`, or `#Trait`.
