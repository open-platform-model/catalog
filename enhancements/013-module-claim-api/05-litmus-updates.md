# Litmus Updates — `#Module` Flat Shape with `#Claim` and `#Api` Primitives

Updates required in `catalog/docs/core/definition-types.md`, `catalog/docs/core/primitives.md`, and `catalog/docs/core/constructs.md`.

## Sharpened Litmus Questions

The current table phrases both `#Resource` and (future) `#Claim` as answering "What must exist?" — that is the line that obscures their distinction. Replace with the sharpened questions below.

### Updated Summary Table (`docs/core/definition-types.md`)

| Type | Family | Question It Answers | Level |
|------|--------|---------------------|-------|
| **Resource** | Primitive | "What well-known thing must be rendered?" | Component |
| **Trait** | Primitive | "How does it behave?" | Component |
| **Blueprint** | Primitive | "What is the reusable pattern?" | Component |
| **PolicyRule** | Primitive | "What must be true?" | Policy |
| **Directive** | Primitive | "What should the platform do?" | Policy |
| **StatusProbe** | Primitive | "What should be checked?" | Module |
| **Op** | Primitive | "What is the unit of work?" | Action |
| **Action** | Primitive | "What is the composed operation?" | Lifecycle/Workflow |
| **Claim** | Primitive | "What ecosystem-supplied thing must be fulfilled?" | Component / Module |
| **Api** | Primitive | "What capability does this Module register?" | Module |
| **Component** | Construct | "What composes primitives?" | Module |
| **Module** | Construct | "What is the application, API, or operator?" | Top-level |
| **ModuleRelease** | Construct | "What is being deployed?" | Deployment |
| **Policy** | Construct | "What policy rules apply where?" | Module |
| **Bundle** | Construct | "What modules are grouped?" | Top-level |
| **BundleRelease** | Construct | "What bundle is being deployed?" | Deployment |
| **Provider** | Construct | "What platform is targeted?" | Rendering |
| **Transformer** | Construct | "How are components rendered?" | Rendering |
| **Status** | Construct | "What is the computed state?" | Module |
| **Lifecycle** | Construct | "What happens on transitions?" | Component/Module |
| **Workflow** | Construct | "What runs on-demand?" | Module |
| **Test** | Construct | "Does the lifecycle work?" | Separate artifact |
| **Config** | Construct | "How is OPM configured?" | Tooling |
| **Template** | Construct | "How are modules scaffolded?" | Tooling |

### Sharpened Module question

Current: "What is the application?"
New: **"What is the application, API, or operator?"**

Reflects the deliberate App / API / Operator triple-duty of `#Module`.

## Updated Decision Flowchart

`docs/core/definition-types.md` flowchart additions:

```text
1. Does it define a reusable `#spec` that gets composed?
    Yes → It's a Primitive. Continue:
        1. Is this a standalone deployable thing? → Resource
        2. Does this modify how a Resource operates? → Trait
        3. Is this a reusable composition of Resources/Traits? → Blueprint
        4. Is this a constraint with enforcement consequences? → PolicyRule
        5. Is this operational behavior the platform should execute? → Directive
        6. Is this a runtime health/readiness check? → StatusProbe
        7. Is this an atomic unit of work? → Op
        8. Is this a composed operation built from Ops/Actions? → Action
        9. Is this an ecosystem-supplied need (catalog commodity or vendor specialty)? → Claim   [new]
       10. Does this register a capability that this Module supplies to the platform? → Api    [new]
    No → It's a Construct. See constructs.md.
```

## Sharpening Rationale

### Why "What well-known thing must be rendered?" for `#Resource`

`#Resource` types are catalog-fixed. The catalog ships a Transformer for each Resource type that renders it to provider-native output (k8s YAML for the Kubernetes provider). Adding a new Resource type requires a catalog PR plus a Transformer. The author of a `#Resource` is **describing a thing in known catalog vocabulary** so a known Transformer can render it.

### Why "What ecosystem-supplied thing must be fulfilled?" for `#Claim`

`#Claim` types are ecosystem-extended. Anyone — the catalog (commodities), or a vendor (specialty services) — can publish a `#Claim` definition in a CUE package. The platform fulfills via whatever Module's `#apis` registers a matching `schema`. The author of a `#claim` is **declaring intent** that the ecosystem will satisfy at deploy time.

### Why "What capability does this Module register?" for `#Api`

`#Api` is the supply-side declaration. A Module with `#apis` is announcing to the platform "I implement these `#Claim` contracts." The platform routes matching `#claims` to this Module's components.

## Mirror in `docs/core/primitives.md`

Add two new sections:

### `#Claim`

> **Definition Type:** Primitive
>
> **Litmus:** "What ecosystem-supplied thing must be fulfilled?"
>
> **Distinguished from `#Resource`:** Resources are **catalog-fixed and transformer-rendered** (the catalog ships a Transformer per Resource type). Claims are **ecosystem-extended and provider-fulfilled** (any CUE package — catalog or vendor — may publish a `#Claim` definition; the platform routes to whichever Module's `#api` embeds a matching schema).
>
> **Identity:** `apiVersion` + `metadata.fqn`. No string `type` field. Matching is structural at the CUE level and metadata-driven at deploy time.
>
> **Placement:** Component-level for data-plane needs; Module-level for platform-relationship needs.
>
> **Pattern:** Concrete Claims follow the catalog triplet pattern: `#X` (schema) + `#XDefaults` (defaults) + `#XClaim` (`#Claim` wrapper).

### `#Api`

> **Definition Type:** Primitive
>
> **Litmus:** "What capability does this Module register?"
>
> **Shape:** `{ schema: #Claim, metadata?: { description?, examples?, labels?, annotations? } }`. Embeds exactly one `#Claim` (1:1).
>
> **Placement:** Module-level only.
>
> **Deploy semantics:** Purely declarative. The platform may use it to populate a self-service catalog, a deploy-time match cache, or both. CRD installation is not part of `#Api`; operators ship CRDs via `#CRDsResource` inside `#components`.
>
> **Asymmetry with `#Claim`:** `#Api` is not a symmetric mirror of `#Claim`. Claims express demand uniformly. Apis express supply, which is varied (commodity fulfillment, specialty type definition + fulfillment, self-service catalog publish without runtime).

## Mirror in `docs/core/constructs.md`

Update the `#Module` entry to reflect the flat shape:

> **Question:** "What is the application, API, or operator?"
>
> **Slots:** Nucleus (`metadata`, `#config`, `debugValues`, `#components`); inward (`#policies`, `#lifecycles`, `#workflows`); outward (`#claims`, `#apis`).
>
> **Triple-duty:** Same type covers Applications (components-led), API descriptions (`#config`-led), and Operators (components + lifecycles + apis).

## Affected Cross-References

| File | Change |
|------|--------|
| `docs/core/definition-types.md` | Update summary table, decision flowchart, mermaid diagram (add Claim/Api primitives) |
| `docs/core/primitives.md` | Add `#Claim` and `#Api` reference sections; sharpen `#Resource` litmus |
| `docs/core/constructs.md` | Update `#Module` entry with the flat shape and triple-duty framing |
| `v1alpha1/INDEX.md` | Regenerate via `task generate:index` after primitive files land |
