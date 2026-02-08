## Context

OPM currently has two policy-related types:

- `#Policy` (Primitive) — defines a governance rule schema with enforcement configuration
- `#Scope` (Construct) — groups policies and targets them to components

The naming inherits from OAM where "Scope" was a first-class construct. KubeVela deprecated Scopes (v1.0→v1.9) in favor of flat Policies on the Application, finding that:

1. Only two scope types were ever implemented (HealthScope, NetworkScope)
2. Each new cross-cutting concern required a new scope type — too rigid
3. CUE-backed PolicyDefinitions proved more general and extensible

OPM's `#Scope` already works like KubeVela's replacement — it's a policy application group, not an OAM-style typed scope. The name is misleading.

### Current Structure

```cue
// Primitive (policy.cue)
#Policy: close({
    kind: "Policy"
    metadata: {
        apiVersion!: #APIVersionType
        name!:       #NameType
        fqn:         #FQNType
        target!:     "scope"            // ← only valid value
    }
    enforcement!: { mode!, onViolation! }
    #spec!: ...
})

// Construct (scope.cue)
#Scope: close({
    kind: "Scope"
    metadata: { name! }
    #policies: [FQN=string]: #Policy    // ← map of primitives
    appliesTo: {
        componentLabels?: [string]: #LabelsAnnotationsType  // ← underspecified
        components: [...#Component]                          // ← full structs
    }
    spec: close(_allFields)             // ← merged from #policies
})

// Module (module.cue)
#Module: close({
    #scopes?: [Id=string]: #Scope
})
```

### Composition Parallel with Component

`#Component` composes Resources + Traits + Blueprints → `spec`. The renamed `#Policy` composes PolicyRules → `spec`. Same pattern:

```text
#Component                          #Policy (renamed from #Scope)
├── #resources: [FQN]: #Resource    ├── #rules: [FQN]: #PolicyRule
├── #traits?: [FQN]: #Trait         │
├── #blueprints?: [FQN]: #Blueprint │
├── _allFields (merged)             ├── _allFields (merged)
└── spec: close(_allFields)         └── spec: close(_allFields)
```

## Goals / Non-Goals

**Goals:**

- Rename types to align with KubeVela's learned terminology (Scope → Policy, Policy → PolicyRule)
- Preserve the grouping model — a Policy construct groups PolicyRules and targets components
- Add label-based component matching to `appliesTo`
- Maintain the `_allFields` → `spec` merge pattern consistent with Component
- Keep type safety: CUE unification catches conflicting rule specs at definition time

**Non-Goals:**

- Changing how enforcement works (mode, onViolation, platform — unchanged)
- Adding workflow/orchestration concepts (KubeVela's Workflow is a separate concern)
- Adding per-component inline policy support (policies remain grouped in constructs)
- Changing the `#spec` auto-naming convention on PolicyRule

## Decisions

### D1: Primitive naming — `#PolicyRule`

**Decision**: Rename `#Policy` → `#PolicyRule`

**Alternatives considered**:

- `#PolicyDefinition` — mirrors KubeVela's CRD name, but OPM primitives use short names (`#Resource`, `#Trait`, `#Blueprint`), not `-Definition` suffix
- `#Constraint` — loses the "policy" family connection; harder to discover
- `#GovernanceRule` — too verbose

**Rationale**: `#PolicyRule` stays in the "policy" family, is concise, and the word "rule" accurately describes what it is — a single enforceable constraint with enforcement semantics.

### D2: Construct naming — `#Policy`

**Decision**: Rename `#Scope` → `#Policy`

**Rationale**: Aligns with KubeVela's final model. At the Module level, `#policies: [string]: #Policy` reads naturally. The construct groups rules and targets components — this is what "policy" means in modern platform engineering.

### D3: Internal field — `#rules` (not `#policies`)

**Decision**: The field holding PolicyRules inside a Policy is named `#rules`.

```cue
#Policy: close({
    #rules: [RuleFQN=string]: #PolicyRule
})
```

**Rationale**: `#policies` containing `#PolicyRule` would be confusing. `#rules` is clear — a Policy contains rules.

### D4: Remove `metadata.target` from PolicyRule

**Decision**: Drop the `target!: "scope"` field entirely.

**Rationale**: The only valid value was `"scope"`. With the rename, it would become `"policy"` — still only one value. A field with a single valid value provides no discrimination. If future targets emerge (e.g., component-level policy rules), the field can be re-added.

### D5: File naming — `policy_rule.cue` + `policy.cue`

**Decision**: Rename files to avoid collision:

- `v0/core/policy.cue` → `v0/core/policy_rule.cue` (primitive)
- `v0/core/scope.cue` → `v0/core/policy.cue` (construct)

**Rationale**: The construct is the more prominent type (used in Module). It gets the clean `policy.cue` name. The primitive gets the qualified `policy_rule.cue`.

### D6: `appliesTo` — add `matchLabels`, simplify `components`

**Decision**: Redesign `appliesTo`:

```cue
appliesTo: {
    // Label-based matching — select components whose labels are a superset
    matchLabels?: #LabelsAnnotationsType

    // Explicit component references
    components?: [...#Component]
}
```

- `matchLabels` uses flat key-value matching (same as Kubernetes label selectors)
- `components` and `matchLabels` are OR — a component matches if it satisfies either
- Both fields are optional — but at least one MUST be provided
- Remove the old `componentLabels?: [string]: #LabelsAnnotationsType` (underspecified, unused)

**Alternatives considered**:

- Kubernetes `matchExpressions` (In, NotIn, Exists, DoesNotExist) — violates Principle VII (YAGNI). Can add later if needed.
- `components` as `[...#NameType]` (names only, not full structs) — tempting for ergonomics, but full struct references allow CUE unification to validate that the referenced component actually exists in the module.

### D7: Map type aliases

**Decision**:

- `#PolicyMap` → refers to the construct: `[string]: #Policy`
- `#PolicyRuleMap` → refers to the primitive: `[string]: _` (matches current `#PolicyMap` pattern)
- Remove `#ScopeMap`

## Target Schema

### PolicyRule (Primitive) — `v0/core/policy_rule.cue`

```cue
#PolicyRule: close({
    apiVersion: "opmodel.dev/core/v0"
    kind:       "PolicyRule"

    metadata: {
        apiVersion!:  #APIVersionType
        name!:        #NameType
        _definitionName: (#KebabToPascal & {"in": name}).out
        fqn: #FQNType & "\(apiVersion)#\(_definitionName)"

        description?: string
        labels?:      #LabelsAnnotationsType
        annotations?: #LabelsAnnotationsType
    }

    enforcement!: {
        mode!:        "deployment" | "runtime" | "both"
        onViolation!: "block" | "warn" | "audit"
        platform?:    _
    }

    #spec!: (strings.ToCamel(metadata._definitionName)): _
})

#PolicyRuleMap: [string]: _
```

### Policy (Construct) — `v0/core/policy.cue`

```cue
#Policy: close({
    apiVersion: "opmodel.dev/core/v0"
    kind:       "Policy"

    metadata: {
        name!:        #NameType
        labels?:      #LabelsAnnotationsType
        annotations?: #LabelsAnnotationsType
    }

    // PolicyRules grouped by this policy
    #rules: [RuleFQN=string]: #PolicyRule & {
        metadata: name: string | *RuleFQN
    }

    // Which components this policy applies to
    // At least one of matchLabels or components must be specified
    appliesTo: {
        matchLabels?: #LabelsAnnotationsType
        components?:  [...#Component]
    }

    _allFields: {
        if #rules != _|_ {
            for _, rule in #rules {
                if rule.#spec != _|_ {
                    for k, v in rule.#spec {
                        (k): v
                    }
                }
            }
        }
    }

    spec: close(_allFields)
})

#PolicyMap: [string]: #Policy
```

### Module — `v0/core/module.cue`

```cue
#Module: close({
    // ...existing fields...
    #policies?: [Id=string]: #Policy
})
```

### D8: Downstream concrete definition names — keep unchanged

**Decision**: Concrete PolicyRule instances in `v0/policies/` keep their existing names. Only the core type they extend changes.

```text
CONCRETE NAME (unchanged)    EXTENDS (changed)
#NetworkRulesPolicy          core.#PolicyRule  (was core.#Policy)
#SharedNetworkPolicy         core.#PolicyRule  (was core.#Policy)
#NetworkRules                core.#Policy      (was core.#Scope)
#SharedNetwork               core.#Policy      (was core.#Scope)
```

**Alternatives considered**:

- `#NetworkRulesPolicyRule` — mechanically appends new type name, but too verbose
- `#NetworkRule` — clean, but too similar to `#NetworkRules` (the construct)
- `#NetworkPolicyRule` — sounds like a Kubernetes NetworkPolicy

**Rationale**: The word "Policy" in `#NetworkRulesPolicy` is descriptive (it's a policy-related definition), not a type reference. Keeping names stable avoids unnecessary churn in downstream consumers. The type change (`core.#Policy` → `core.#PolicyRule`) is the only change needed.

### Downstream Consumer Example — `v0/policies/network/network_rules.cue`

```cue
// Before
#NetworkRulesPolicy: close(core.#Policy & { ... })
#NetworkRules: close(core.#Scope & {
    #policies: {(#NetworkRulesPolicy.metadata.fqn): #NetworkRulesPolicy}
})

// After — concrete names unchanged, only the core types change
#NetworkRulesPolicy: close(core.#PolicyRule & { ... })
#NetworkRules: close(core.#Policy & {
    #rules: {(#NetworkRulesPolicy.metadata.fqn): #NetworkRulesPolicy}
})
```

## Risks / Trade-offs

- **[MAJOR breaking change]** → All consumers of `#Scope`, `#Policy`, `#Module.#scopes` break. Mitigated by: this is pre-v1, no external consumers yet. SemVer MAJOR bump.
- **[Name overload]** "Policy" is used for both the primitive family and the construct. → Mitigated by: `#PolicyRule` vs `#Policy` is clear in context. The `#rules` field inside `#Policy` reinforces the relationship.
- **[Label matching is simple]** `matchLabels` only supports equality. → Acceptable per Principle VII (YAGNI). `matchExpressions` can be added later without breaking changes.
- **[`components` as full structs]** Verbose to reference. → Preserves CUE unification validation. Module authors typically use comprehensions (e.g., `components: [for _, c in #components {c}]`).

## Open Questions

- Should the `v0/policies/` module directory be renamed? Currently `policies/network/` contains both PolicyRule definitions and Policy (construct) wrappers. The directory name still makes sense since both are in the "policy" family.
