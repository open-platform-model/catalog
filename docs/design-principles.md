# OPM Core Principles

The Open Platform Model is governed by eight core principles defined in [openspec/config.yaml](../openspec/config.yaml). These principles guide all design decisions and maintain architectural coherence.

| # | Principle | Summary |
|---|-----------|---------|
| **I** | [Type Safety First](#i-type-safety-first) | CUE validates at definition time — never in production |
| **II** | [Separation of Concerns](#ii-separation-of-concerns) | Developers own Modules, Platform owns Policies, Consumers own Releases |
| **III** | [Composability](#iii-composability) | Definitions compose via unification without implicit coupling |
| **IV** | [Declarative Intent](#iv-declarative-intent) | Express WHAT, not HOW — no imperative scripts |
| **V** | [Portability by Design](#v-portability-by-design) | Runtime-agnostic definitions; runtime concerns isolated in providers |
| **VI** | [Semantic Versioning](#vi-semantic-versioning) | SemVer 2.0.0 + Conventional Commits for all artifacts |
| **VII** | [Simplicity & YAGNI](#vii-simplicity--yagni) | Justified complexity only — start simple, compose for power |
| **VIII** | [Self-Describing Distribution](#viii-self-describing-distribution) | CUE structure carries all dependency, schema, and version info |

---

## I. Type Safety First

All definitions MUST be expressed in CUE. Invalid configuration MUST be rejected at definition time — never in production. CUE's structural typing, constraints, and validation provide compile-time guarantees that prevent runtime failures.

- **Structural typing**: every field has a CUE type constraint (`int & >=0 & <=1000`)
- **Closed structs**: `close()` prevents undefined fields — no silent typos or drift
- **Cross-field validation**: relationships between fields are enforced (e.g. exactly one volume source)
- **Pattern constraints**: regex and length validation on names, labels, etc.
- **Defaults with constraints**: defaults are validated against their disjunctions

```cue
#ScalingSchema: {
    count!: int & >=0 & <=1000   // required, typed, range-constrained
    cpu?:   int & >=0 & <=100    // optional, typed, range-constrained
}
```

Validation happens in layers: definition time (`cue vet`), module release time (values unification), provider transform time, and finally platform apply time as defense-in-depth. Most errors are caught at the first two layers.

---

## II. Separation of Concerns

The delivery flow MUST maintain clear ownership boundaries across three layers:

```text
Developer: Module            "What my app needs"
    |                        Components, config schema, defaults
    v  (unification)         NO platform specifics, NO environment details
Platform: Policy & Provider  "How we govern and deploy"
    |                        Security policies, platform labels, provider selection
    v  (instantiation)       NO app logic changes
Consumer: ModuleRelease      "The actual deployment"
                             Concrete values, environment, secrets
                             NO schema definition
```

- **Developers** define `#config` schemas and provide `values` defaults
- **Platform teams** apply policies via CUE unification (`&`) — additive, never destructive
- **Consumers** create `ModuleRelease` artifacts that bind modules to concrete values
- **CUE enforces boundaries**: consumers can't bypass schemas, policies can't remove developer fields, transformers only produce output (read-only context)

Each layer is independently testable and evolvable. Same module, different policies and values per environment.

---

## III. Composability

Definitions MUST compose without implicit coupling. Resources describe "what exists," Traits modify behavior, Blueprints compose both, and Components reference definitions by name.

**How it works:**

- **Flat spec merging**: each definition contributes a uniquely-named field to `spec` — no nesting hierarchy
- **Field name = definition name**: derived from `metadata.name` (e.g. `"security-context"` becomes `securityContext`), preventing collisions
- **No direct references between definitions**: Resources don't know about Traits and vice versa — they compose via CUE unification in the Component
- **Transformers as integration points**: only transformers read from multiple spec fields to produce platform output

```cue
// Each definition owns a distinct field in spec
web: workload.#Container & workload.#Scaling & network.#Expose & {
    spec: {
        container: image: repository: "nginx"
        scaling:   count: 3
        expose:    type: "LoadBalancer"
    }
}
```

Adding or removing a definition doesn't affect the others. CUE catches conflicts at definition time — no silent overwrites.

---

## IV. Declarative Intent

Modules MUST express intent, not implementation. Declare WHAT, not HOW.

- **No imperative scripts** in definitions (no pre/post hooks, no shell commands)
- **No ordering dependencies** between components (unless explicit via lifecycle `dependsOn`)
- **No runtime-specific API calls** in modules (no `kubernetes.getSecret()`)
- **No platform-specific resource types** or field names in modules

```cue
// Module declares desired state only
#components: {
    web: workload.#StatelessWorkload & {
        spec: statelessWorkload: {
            container: image: repository: "nginx"
            scaling:   count: 3
        }
    }
}
// Provider figures out HOW: resource creation order, readiness checks,
// platform-specific manifests, label selectors, etc.
```

Providers CAN contain imperative logic (if/else, field extraction, transformation) — that's their job. Modules remain pure declarative data. This enables idempotence, testability, portability, and diff/preview before applying.

---

## V. Portability by Design

Modules MUST stay declarative and decoupled from any specific runtime. Provider-specific concerns belong in ProviderDefinitions, so any provider that implements the catalog's primitives can render a module without the module being rewritten.

**Runtime-agnostic primitives:**

OPM primitives describe intent — workload, scaling, exposure, health, storage — without naming platform-specific resource kinds. Each provider translates these primitives to its own platform resources.

OPM targets **semantic portability** ("same intent, different implementation"), not feature parity. Core primitives describe common intent; advanced features may not have direct equivalents in every provider. Providers document the primitives they support and their capability matrix.

**Modules CAN'T contain**: platform-specific resource types (`apiVersion: apps/v1`), platform-specific field names (`livenessProbe` instead of `healthCheck`), or platform-specific config formats. Use OPM primitives; providers handle translation.

**Escape hatch**: `#customResources` for explicitly non-portable, provider-namespaced extensions.

---

## VI. Semantic Versioning

All artifacts MUST follow SemVer 2.0.0. All commits MUST follow Conventional Commits v1.

**What gets versioned:**

| Artifact | Scheme | Example |
|----------|--------|---------|
| CUE modules | Major in import path | `opmodel.dev@v1` |
| Definitions | Major in metadata | `metadata.version: "v1"` |
| OPM modules | Full SemVer | `example.com/myapp:1.2.3` |
| Git tags | SemVer with `v` prefix | `v1.2.3` |
| Commits | Conventional Commits | `feat(core): add X` |

**Breaking changes (MAJOR)**: remove field, change type, make optional required, tighten constraint, rename field, change FQN.

**Non-breaking (MINOR)**: add optional field with default, add component, loosen constraint, add enum value.

**Bug fixes (PATCH)**: fix validation, correct defaults, fix transformer output.

Commit types map to bumps: `feat` = MINOR, `fix` = PATCH, `!` or `BREAKING CHANGE:` footer = MAJOR. Breaking changes require a new import path (`@v1` to `@v2`), preventing accidental breakage. Both versions can coexist during migration.

---

## VII. Simplicity & YAGNI

Start simple. Complexity MUST be justified with clear rationale.

- **Prefer composition over specialization**: one `#Container` composed with traits beats `#HttpContainer`, `#GrpcContainer`, `#TcpContainer`, etc.
- **Prefer explicit over implicit**: no auto-magic (e.g. "port named http auto-creates ingress") — users declare what they want
- **Justify every addition**: validated demand (multiple users), core use case (>50%), no workaround exists, clear scope
- **Reject speculative features**: "we might need this someday" is not justification

**Complexity budget (guardrails):**

```text
Resource definitions:   <= 10 core
Trait definitions:      <= 20 core
Blueprint definitions:  <= 10 core
Fields per schema:      <= 15 top-level
Nesting depth:          <= 3 levels
Required fields:        <= 3 per schema
```

When principles conflict (e.g. type safety wants exhaustive validation, simplicity wants fewer constraints): cover common errors, not all possible errors. Document the trade-off.

---

## VIII. Self-Describing Distribution

OPM modules are self-describing distributions. All information required to deploy is derivable from CUE structure — not from external metadata files, lock files, or runtime discovery.

```text
CUE import       = dependency declaration
CUE type          = schema contract
Computed FQN      = version pin
Evaluation graph  = dependency graph
```

**The derivation chain**: Module imports → Component embeds mixins → Mixins register FQNs in `#resources`/`#traits` maps → FQNs computed from metadata → Provider transformers declare required FQNs → Matching by FQN set intersection → Transform to platform resources.

From a published module you can derive: which resources and traits it uses, which provider versions are compatible, full schema of every field, config contract for consumers, and the complete dependency graph. No external metadata required — the module IS the bill of materials.

This is why OPM is built on CUE. Structural references carry full definitions (not just names), unification resolves all references at evaluation time, computed FQNs prevent drift, and closed structs guarantee every field comes from a known versioned definition.

---

## How Principles Interact

The principles are mutually reinforcing:

- **Type Safety (I)** validates composition (III), separation (II), and portability (V)
- **Separation of Concerns (II)** keeps modules declarative (IV), portable (V), and self-describing (VIII)
- **Composability (III)** enables simplicity (VII) and safe versioned evolution (VI)
- **Declarative Intent (IV)** enables portability (V) and testability
- **Portability (V)** requires declarative (IV) and separation (II)
- **Semantic Versioning (VI)** supports composability (III) and self-describing distribution (VIII)
- **Simplicity (VII)** constrains composability (III) and guides design choices
- **Self-Describing (VIII)** is built on type safety (I), composability (III), and versioning (VI)

Conflicts between principles are rare and usually signal a design smell. When they occur, document the trade-off explicitly.

## Further Reading

- [openspec/config.yaml](../openspec/config.yaml) — Full constitutional text
- [docs/core/](core/) — How principles apply to definition types
- [docs/rfc/](rfc/) — Principles in practice
