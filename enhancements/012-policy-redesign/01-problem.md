# Problem

## Context

A `#Module` is composed of one or more `#Component`. Each component is a deployable unit. Components carry `#Resource` and `#Trait` — authoring-local facts. This makes it straightforward to model applications and the things immediately around them.

It is much harder to model things or behaviors that **act across components** — a subset, or the whole set. `#Policy` was introduced for this slot.

Previous iterations of OPM also had `#Scope`, whose purpose was specifically to model cross-component shared things (e.g. "all components in this shared-network scope can reach each other"). `#Scope` was scrapped in favor of `#Policy` because KubeVela made the same move. That decision is now in question.

## Current State

`#Policy` lives at `catalog/core/v1alpha2/policy.cue` and carries:

- `appliesTo` — label match or explicit component references.
- `#rules: [fqn]: #PolicyRule` — governance rules (what MUST be true).
- `#directives?: [fqn]: #Directive` — operational orchestration (run this for me). Added by enhancement 011.
- `spec` — merged from all contained rules and directives.

Two primitives live inside `#Policy`:

| Primitive | Direction | Status |
|-----------|-----------|--------|
| `#PolicyRule` | Platform → Module (governance) | Half-baked — `enforcement.platform?: _` has no concrete enforcement mechanism |
| `#Directive` | Module → Platform (orchestration) | Load-bearing — full render path via `#PolicyTransformer` (011) |

## What 011 Confirmed and What It Left Open

Enhancement 011 validates that the `#Trait` + `#Directive` + `#PolicyTransformer` pattern works for operational commodity contracts — backup, TLS, routing. Those are all **verb-flavored** concerns: "run operation X across this set of components."

011 does not address concerns that are **noun-flavored**: "there exists a shared thing these components partake in." It also does not resolve friction with `#PolicyRule` itself.

## Existing Friction in the Current Design

1. **Naming drift.** Code uses `#PolicyRule`; 011's documentation consistently uses `#Rule` as the sibling-to-`#Directive` name. `#Policy.#rules: #PolicyRule` reads as "policy rules in a policy" — redundant.

2. **Spec field asymmetry.** `#PolicyRule.spec!` is exported. `#Directive.#spec!` is hidden. The `_allFields` merge in `policy.cue` iterates `rule.#spec` and `directive.#spec` uniformly; for `#PolicyRule` this is always `_|_`, so the rule branch of the merge is dead. Two primitives in the same construct should have identical structural shape.

3. **Asymmetric load-bearing.** `#Directive` has a full render path (`#PolicyTransformer`, context paths, annotations, provenance). `#PolicyRule` has `enforcement.platform?: _` — an escape-hatch blob with no concrete enforcement mechanism anywhere in the codebase. One primitive is load-bearing; the other is a documentation convention wearing a schema.

4. **"Governance vs orchestration" is a weak axis.** Both primitives take a typed spec and target components via `appliesTo`. The distinction rests on whether the platform's action is labeled MUST-BE-TRUE or RUN-FOR-ME. That's audience-split (platform team vs module author), not structural.

## Three Grammars of Cross-Component Concern

Three distinct flavors keep getting conflated under "cross-component stuff":

| Flavor | Grammar | Example | Current OPM home |
|---|---|---|---|
| **Noun** — a shared thing that exists; components partake | "there IS a network X, A/B/C are in it" | shared network, shared volume pool, shared identity/SA, gateway, message bus | **Missing** (was `#Scope`) |
| **Verb** — an operation run across the set | "RUN backup nightly for A/B/C" | backup, cert issuance, route attachment | `#Directive` (011) |
| **Constraint** — a predicate that must hold | "A/B/C MUST NOT be privileged" | security rule, compliance guardrail | `#PolicyRule` (half-baked) |

All three share one structural thing: **a set of components + a typed payload**. They differ only in what the transformer does with the payload.

## The Noun Gap

The noun flavor is what `#Scope` used to carry and what `#Policy` in its current shape does not honor. It shows up concretely whenever components need to share a boundary or entity:

- Two or more components in a shared isolated network (NetworkPolicy / Cilium / mesh boundary).
- Components sharing a volume pool or a PVC-provider defaults.
- Components sharing a workload identity or ServiceAccount.
- Components sharing an ingress boundary (Gateway + listener) — 011 leaves the Gateway itself at `#ctx.platform.routing.gateways`; module-owned shared ingresses aren't representable.
- Components sharing a message bus, topic namespace, or cache cluster owned by the module.

These are not rules (nothing must be true) and not verbs (nothing is being *run*). They are entities with their own lifecycle that the module declares, and components opt into or are assigned to.

## Lesson From KubeVela

KubeVela removed `ApplicationScope` in v1.0 (2021) without a published design rationale. The closest stated motivation — issue [#1613](https://github.com/kubevela/kubevela/issues/1613) — is that "there is no application-level configuration across components," and Policy was introduced to fill that slot.

In practice KubeVela's `Policy` became deployment-governance machinery (topology, override, shared-resource). The noun flavor of `Scope` (shared network boundaries, co-location guarantees) has no direct equivalent and is now either implicit (same namespace/cluster reachability), delegated to traits (pod affinity), or pushed to infrastructure (service mesh, ClusterAPI).

No community pushback is recorded. Likely because adoption of `Scope` was thin and KubeVela's target audience converged on delivery governance. For OPM — which models multi-cluster and multi-provider as first-class — the noun flavor matters more, not less.

See [03-kubevela-research.md](03-kubevela-research.md) for full research.

## Goal

Develop a model in which all three grammars — noun, verb, constraint — are expressible at module scope, authored in a way that feels natural to developers, with coherent lifecycle semantics. Resolve the `#PolicyRule` / `#Directive` friction in the same pass.

## Non-Goals

- Pick a final design in this document. 012 is exploratory; the next enhancement in this thread is expected to converge.
- Replace 011. The verb-flavor render path (`#PolicyTransformer`) is intended to survive whatever shape 012's convergence takes.
- Model **every** cross-component interaction (data plane, RPC contracts, complex orchestration). Scope is "shared things + set-level constraints + set-level operations," not a universal graph language.
