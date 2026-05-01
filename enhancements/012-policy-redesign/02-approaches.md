# Approaches

Candidate models for expressing cross-component concerns in OPM. Each approach lists two variants where applicable. Examples use a shared scenario so trade-offs are directly comparable.

## Shared Scenario

A three-component module: `web`, `api`, `db`. Four cross-component concerns across the three grammars:

- **Noun (symmetric):** `web` + `api` share an isolated network; `db` is outside.
- **Constraint:** all three must run non-privileged.
- **Verb:** all three are backed up nightly (already covered by 011; shown briefly for contrast with other options).
- **Asymmetric (stretch):** `api` ships logs to an external `logging-collector` sibling.

---

## Option A — Three Primitives Under `#Policy`

One primitive per flavor. Clean ontology.

- `#Scope` — noun; declares a shared entity; components partake.
- `#Directive` — verb; module → platform operation. Keeps 011's contract.
- `#Rule` — constraint; platform → module governance. Rename of `#PolicyRule`.

`#Policy` groups any combination with shared `appliesTo` and uniform spec merging. Each primitive gets a matching transformer scope:

- `#ScopeTransformer` — emits the shared entity + optional per-member annotations/labels.
- `#PolicyTransformer` (from 011) — emits module-scope resources from a directive.
- `#RuleTransformer` (new or absorbed into an existing admission layer) — emits the constraint into whatever platform enforces it (Kyverno, OPA, admission webhook).

### Variant A.1 — Central membership (authored on `#Policy.appliesTo`)

Module author lists members on the policy. Scope is a field inside the policy.

```cue
// catalog/opm/v1alpha2/network/shared_network.cue
package network

import prim "opmodel.dev/core/v1alpha2"

#SharedNetworkScope: prim.#Scope & {
    metadata: {
        modulePath: "opmodel.dev/opm/v1alpha2/network"
        version:    "v1"
        name:       "shared-network"
        description: "A shared intra-module network boundary that components partake in"
    }
    #spec: sharedNetwork: {
        isolation!: "namespace" | "networkpolicy" | "cilium-ciliumnetworkpolicy"
        egress?:    "allow-all" | "deny-all" | "explicit"
        allowFrom?: [...string]
    }
}
```

```cue
// module author
import (
    net  "opmodel.dev/opm/v1alpha2/network"
    sec  "opmodel.dev/opm/v1alpha2/security"
    policy "opmodel.dev/core/v1alpha2"
)

#components: {
    "web": #StatelessWorkload & { spec: container: image: "strix-web:latest" }
    "api": #StatelessWorkload & { spec: container: image: "strix-api:latest" }
    "db":  #StatefulWorkload  & { spec: container: image: "postgres:16" }
}

#policies: {
    "app-net": policy.#Policy & {
        appliesTo: components: ["web", "api"]
        #scopes: {
            (net.#SharedNetworkScope.metadata.fqn): net.#SharedNetworkScope & {
                #spec: sharedNetwork: {
                    isolation: "networkpolicy"
                    egress:    "explicit"
                }
            }
        }
    }

    "hardening": policy.#Policy & {
        appliesTo: components: ["web", "api", "db"]
        #rules: {
            (sec.#NoPrivilegedRule.metadata.fqn): sec.#NoPrivilegedRule & {
                enforcement: { mode: "deployment", onViolation: "block" }
            }
        }
    }
}
```

### Variant A.2 — Distributed membership (component opt-in)

Components opt in via a member-mixin wrapper. The policy's `appliesTo` is derived from membership.

```cue
// catalog/opm/v1alpha2/network/member.cue
#Member: {
    // mixin metadata that tells the matcher this component joins a named scope
    #membership: network: string   // references a #SharedNetworkScope instance
}
```

```cue
// module author
#components: {
    "web": #StatelessWorkload & net.#Member & { #membership: network: "app-net" }
    "api": #StatelessWorkload & net.#Member & { #membership: network: "app-net" }
    "db":  #StatefulWorkload  & { /* not a member */ }
}

#policies: {
    "app-net": policy.#Policy & {
        appliesTo: byMembership: { network: "app-net" }   // resolver collects members
        #scopes: {
            (net.#SharedNetworkScope.metadata.fqn): net.#SharedNetworkScope & {
                #spec: sharedNetwork: { isolation: "networkpolicy", egress: "explicit" }
            }
        }
    }
}
```

Two authoring shapes, one primitive. Variant-level choice is about *where* membership is expressed, not *what* the primitive is.

### Rendered output (either variant)

```yaml
# Module-scope NetworkPolicy emitted by #ScopeTransformer
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: strix-app-net
  namespace: media
  annotations:
    opm.opmodel.dev/owner-policy: app-net
    opm.opmodel.dev/owner-scope:  opmodel.dev/opm/v1alpha2/network/shared-network@v1
spec:
  podSelector:
    matchExpressions:
      - key: opm.opmodel.dev/network
        operator: In
        values: ["app-net"]
  ingress:
    - from: [{ podSelector: { matchLabels: { "opm.opmodel.dev/network": "app-net" }}}]
```

The component-pass receives a pod-label injection for each member; the scope-transformer emits the shared NetworkPolicy. Lifecycle follows the policy — deleting the policy removes the NetworkPolicy and (on re-render) the pod labels.

### Pros / Cons

| Pro | Con |
|---|---|
| Honors the three grammars explicitly | Three primitives + three transformer scopes; concept-budget heavy |
| Each transformer scope is purposeful and type-safe | Modest redundancy between `#Scope` and `#Directive` structures |
| Component opt-in (A.2) reads naturally, matches how traits already work | Two ways to express membership may confuse authors; need a convention |

---

## Option C — Noun as a Module-Level `#Resource` (Pure and Hybrid)

Cross-component *things* are resources — lifted one scope up from component-local to module- or policy-local.

### Variant C.1 — Pure: module-level `#resources`

The noun lives at module scope, authored once. Components reference it by name. Lifecycle tied to the module, independent of any policy.

```cue
// catalog/opm/v1alpha2/network/shared_network.cue
#SharedNetworkResource: prim.#Resource & {
    metadata: {
        modulePath: "opmodel.dev/opm/v1alpha2/network"
        version:    "v1"
        name:       "shared-network"
    }
    spec: sharedNetwork: {
        isolation!: "networkpolicy" | "cilium-ciliumnetworkpolicy"
        egress?:    "allow-all" | "deny-all" | "explicit"
    }
}

#AttachedTo: {
    #attachments: network?: string    // references a module-level #resources key
}
```

```cue
// module author
#Module & {
    #resources: {
        "app-net": net.#SharedNetworkResource & {
            spec: sharedNetwork: { isolation: "networkpolicy", egress: "explicit" }
        }
    }
    #components: {
        "web": #StatelessWorkload & net.#AttachedTo & { #attachments: network: "app-net" }
        "api": #StatelessWorkload & net.#AttachedTo & { #attachments: network: "app-net" }
        "db":  #StatefulWorkload  & { /* no attachment */ }
    }
}
```

Same rendered output as A, but ownership annotations point to the resource, not a policy.

### Variant C.2 — Hybrid A/C: `#resources` nested inside `#Policy`

Keep the authoring shape "noun-as-resource," but nest it under `#Policy` so lifecycle is policy-scoped. No new primitive kind; `#Policy` grows one field.

```cue
#policies: {
    "app-net": policy.#Policy & {
        appliesTo: components: ["web", "api"]
        #resources: {
            "shared-net": net.#SharedNetworkResource & {
                spec: sharedNetwork: { isolation: "networkpolicy", egress: "explicit" }
            }
        }
    }
}
```

A `#PolicyTransformer`-like scope reads `policy.#resources[x]` and emits. Feels very CUE-natural — nested declarations all the way down.

### Pros / Cons

| Pro | Con |
|---|---|
| Reuses `#Resource` — no new primitive kind (variant C.2 adds a field) | Stretches `#Resource` from "thing a component declares" to "thing that spans components" |
| Variant C.2 matches the lifecycle answer (noun dies with policy) | Pure C.1 contradicts the "noun dies with policy" constraint |
| Authoring is familiar — resources are already known to authors | Membership still needs a way to be expressed (component-side attachment vs policy-side selector) |
| Works symmetrically with 011's pattern (noun-at-platform-`#ctx` → noun-at-module) | Two levels of resource (component-level vs module-/policy-level) increase model surface |

---

## Option D — Relations as First-Class Edges

Components are nodes. Relations are typed edges and hyperedges with a payload. Scope collapses into a hyperedge; directed data flow becomes a directed edge. `#Policy` (in its current form) is subsumed by constraints-over-relations and directives-over-relations.

### Variant D.1 — Symmetric hyperedge (Scope-flavored)

```cue
// catalog/opm/v1alpha2/relations/network.cue
#SharedNetwork: prim.#Relation & {
    metadata: {
        modulePath: "opmodel.dev/opm/v1alpha2/relations"
        version:    "v1"
        name:       "shared-network"
    }
    cardinality: "hyperedge"  // touches N >= 2 nodes, unordered
    #spec: sharedNetwork: {
        isolation!: "namespace" | "networkpolicy" | "cilium-ciliumnetworkpolicy"
        egress?:    "deny-all" | "allow-all" | "explicit"
    }
}

// module author
#relations: {
    "app-net": net.#SharedNetwork & {
        members: ["web", "api"]
        #spec: sharedNetwork: { isolation: "networkpolicy", egress: "explicit" }
    }
}
```

### Variant D.2 — Directed edge (asymmetric data flow)

```cue
#LogFlow: prim.#Relation & {
    metadata: {
        modulePath: "opmodel.dev/opm/v1alpha2/relations"
        version:    "v1"
        name:       "log-flow"
    }
    cardinality: "directed"
    #spec: logFlow: {
        format!:      "json" | "logfmt"
        destination!: string
    }
}

#relations: {
    "api-logs": net.#LogFlow & {
        from: "api"
        to:   "logging-collector"
        #spec: logFlow: { format: "json", destination: "otlp://collector:4317" }
    }
}
```

Rules and directives attach naturally to edges as meta-constraints or meta-operations:

- "No cross-cluster edges allowed in this module."
- "Every `#LogFlow` must use TLS."
- "Backup all components that are endpoints of a `#DataFlow` edge."

### Rendered output

- Symmetric hyperedge `app-net` → one NetworkPolicy + pod labels on members.
- Directed edge `api-logs` → an Istio `VirtualService` / OTel pipeline with `api`'s Service as source, collector as destination. Asymmetric rendering falls out of edge direction.

### Queries this model enables

| Query | `#Policy` (A/C) | `#Relation` (D) |
|---|---|---|
| "Which components share network X?" | scan all policies | `graph.edges(kind=SharedNetwork).members` |
| "Which components send logs to Y?" | not expressible | `graph.edges(kind=LogFlow, to=Y).from` |
| "Is there a path from A to B?" | not expressible | graph reachability |
| "Diff ingress edges into DB between releases" | not expressible | edge-diff |

### Pros / Cons

| Pro | Con |
|---|---|
| Handles asymmetric / directed concerns cleanly | Big conceptual lift from current model |
| Richer queryable data model (graph) | New top-level module slot (`#relations`); new primitive (`#Relation`) |
| Uniform treatment of shared-things, data-flow, depends-on, reachability | Authoring ergonomics unproven at OPM's granularity |
| Collapses `#Scope` + `#Directive` + (parts of) `#Policy` into one axis | Tooling (diff, preview, render) needs graph awareness |

---

## Options B and E — Noted, Not Fleshed Out

### Option B — Collapse to one primitive with a `kind` tag

Single primitive (`#PolicySpec` / `#Claim`) carries `{kind: "noun" | "verb" | "constraint", spec}`. Transformers dispatch on `kind`.

- Pro: minimal schema surface; removes the `spec` vs `#spec` bug inherent in A.
- Con: tagged unions are awkward in CUE; loses type-level distinction at authoring time.
- Main blocker: noun-flavored things often have lifecycle concerns that differ from the policy-matched rule/directive kinds. Jamming them into a single tagged primitive muddies ownership. Worth revisiting if the lifecycle answer were different.

### Option E — `#Policy` carries an opaque typed spec; transformers decide the flavor

Strip `#PolicyRule` and `#Directive` entirely. `#Policy` carries `appliesTo` + `spec: _`. The flavor lives in the matching `#PolicyTransformer`s, not in authoring.

- Pro: fewest primitives. Close to what 011 already does (matching by FQN).
- Con: authors lose kind-level type safety; one policy could be interpreted by any matching transformer.
- Potential middle-ground between A and B if the noun/verb/constraint distinction moves entirely to the transformer side.

---

## Quick Comparison on the Shared Scenario

| Concern | Option A | Option C (hybrid) | Option D |
|---|---|---|---|
| shared network (web + api) | `#SharedNetworkScope` in `#Policy.#scopes` | `#SharedNetworkResource` in `#Policy.#resources` | `#SharedNetwork` hyperedge in `#relations` |
| non-privileged rule (all three) | `#NoPrivilegedRule` in `#Policy.#rules` | `#NoPrivilegedRule` in `#Policy.#rules` | rule-over-nodes (same as A) or rule-over-edges |
| nightly backup (from 011) | `#BackupPolicy` in `#Policy.#directives` | `#BackupPolicy` in `#Policy.#directives` | directive-on-hyperedge, or keep directive as-is |
| api → collector log flow | not natural | not natural | `#LogFlow` directed edge |
| new primitives | 1 (`#Scope`) + `#Rule` rename | 0 (reuse `#Resource`); +1 field on `#Policy` | 1 (`#Relation`); optionally replaces `#Scope` + `#Directive` |
| membership variants | central (A.1) / component opt-in (A.2) | module-level (C.1) / policy-nested (C.2) | hyperedge (D.1) / directed (D.2) |

---

## Cross-Cutting Tensions

| Axis | Pull one way | Pull the other |
|---|---|---|
| Primitive count | Few (E / B) — one Policy, opaque content | Many (A / D) — distinct kinds per flavor |
| Membership authoring | Central on `#Policy.appliesTo` | Distributed via component opt-in |
| Noun lifecycle | Owned by Policy (dies with it) | Module-level (independent) |
| Symmetry | All members equal (A / C) | Directed, A → B (D) |
| Matching | Nominal — FQN-driven | Structural — shape-driven |

---

## Where the Brainstorm Narrowed

Current answer to lifecycle ("removing Policy X removes the shared network") rules out Variant C.1 (module-level resource independent of policy). It does **not** choose between:

- Option A (new `#Scope` primitive)
- Variant C.2 (reuse `#Resource` nested inside `#Policy`)
- Option D (relations / edges)

The remaining question is whether the shared-noun concern earns its own primitive name (`#Scope`), reuses the existing `#Resource` primitive one scope up (C.2), or is subsumed into a richer relation model (D). That question is the subject of [04-open-questions.md](04-open-questions.md).
