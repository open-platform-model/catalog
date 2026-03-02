## Context

The OPM catalog has a WorkloadIdentity trait (`traits/security/workload_identity.cue`) that creates a Kubernetes ServiceAccount as a side-effect of attaching identity to a Container. This covers the workload-attached case but cannot model:

1. **Standalone service accounts** — identities for CI bots, controllers, or external systems not backed by an OPM workload
2. **RBAC permissions** — granting API access to identities via Roles and RoleBindings

Kubernetes models RBAC as four separate objects (Role, ClusterRole, RoleBinding, ClusterRoleBinding) connected by string-based name references — a limitation of YAML's lack of a reference system. CUE's structural references let us collapse this into fewer, more composable resources.

Existing patterns in the codebase:

- Resources follow the three-layer pattern: schema (`schemas/`) → resource definition (`resources/<category>/`) → component mixin
- Transformers match via `requiredResources` or `requiredTraits` and emit k8s objects
- The `resources/security/` package does not exist yet (WorkloadIdentity was moved to a trait)

## Goals / Non-Goals

**Goals:**

- Add ServiceAccount as a standalone resource, independent of the WorkloadIdentity trait
- Add a unified Role resource that collapses k8s Role/ClusterRole and RoleBinding/ClusterRoleBinding into one OPM concept
- Use CUE references for Role subjects instead of k8s-style string-based name bindings
- Create k8s transformers that generate the correct RBAC objects from these resources
- Maintain full backward compatibility with existing WorkloadIdentity trait and its transformer

**Non-Goals:**

- Modifying the existing WorkloadIdentity trait or its transformer
- Supporting references to external/pre-existing k8s Roles or ServiceAccounts (deferred)
- Blueprint updates to compose these resources (separate change)
- AggregationRule support for ClusterRoles (future scope)
- ResourceNames field on PolicyRules (future scope)

## Decisions

### D1: ServiceAccount as a Resource (not a Trait)

**Choice:** `#ServiceAccountResource` in `resources/security/service_account.cue`

**Rationale:** A standalone ServiceAccount is an independently existing object — it doesn't modify or attach to another resource. This matches the OPM distinction: Resources describe "what exists" independently, Traits modify behavior. The existing WorkloadIdentity is a Trait because it says "this workload *has* this identity." A standalone SA just says "this identity exists."

**Alternatives considered:**

- Adding a second trait: Traits require `appliesTo` referencing a Resource. A standalone SA has nothing to apply to.
- Extending WorkloadIdentity: Would conflate two different use cases and break existing modules.

### D2: Role collapses four k8s types into one OPM resource

**Choice:** A single `#RoleResource` with `scope: *"namespace" | "cluster"` replaces k8s Role, ClusterRole, RoleBinding, and ClusterRoleBinding.

**Rationale:**

- RoleBinding/ClusterRoleBinding are pure glue objects — they exist only because YAML has no reference system. In CUE, subjects are direct references on the Role itself.
- Role/ClusterRole differ only in scope (namespace vs cluster). A `scope` field captures this without duplicating the entire definition.
- The transformer generates the right k8s objects (2 per Role: the role + its binding) based on the `scope` field.
- Principle VII (Simplicity): Fewer concepts that compose well over many specialized concepts.

**Alternatives considered:**

- Mirroring k8s 1:1 (4 separate resources): Unnecessary complexity, RoleBinding carries no unique information when subjects are CUE references.
- Separate Role and ClusterRole resources without bindings: Still requires two resources for what is semantically one concept with different scope.

### D3: CUE references for subjects instead of string names

**Choice:** Role subjects contain CUE references to `#WorkloadIdentitySchema` or `#ServiceAccountSchema` objects.

**Rationale:**

- CUE references carry all required data (name, etc.) — no string-based cross-referencing needed
- Type-safe: CUE rejects references to non-existent or invalid identities at definition time
- Follows OPM Principle I (Type Safety First)
- The transformer extracts subject names from the referenced objects when generating k8s RoleBindings

**Implementation:** The `#RoleSubjectSchema` uses CUE embedding to accept either schema type directly:

```cue
#RoleSubjectSchema: {#WorkloadIdentitySchema | #ServiceAccountSchema}
```

No wrapper field — the identity fields (`name`, etc.) are embedded at the top level of each subject. Subjects are referenced inline via CUE embedding: `subjects: [{_appIdentity.workloadIdentity}]`. The transformer reads `name` directly from each subject for the k8s RoleBinding.

### D4: ServiceAccount schema is minimal

**Choice:**

```
#ServiceAccountSchema: {
    name!:           string
    automountToken?: bool
}
```

**Rationale:** Mirrors the existing `#WorkloadIdentitySchema` structure. A service account fundamentally needs a name and a token-mounting decision. Additional fields (labels, annotations, image pull secrets) can be added later as non-breaking MINOR changes. Principle VII applies.

### D5: Separate transformer for SA resource

**Choice:** New `#ServiceAccountResourceTransformer` in addition to the existing `#ServiceAccountTransformer`.

**Rationale:** The existing transformer matches on `requiredTraits: WorkloadIdentity`. The new transformer matches on `requiredResources: ServiceAccount`. They have different matching criteria and produce ServiceAccounts from different sources. Keeping them separate follows the single-responsibility pattern used throughout the transformer layer.

### D6: Role transformer generates two k8s objects

**Choice:** The `#RoleTransformer` outputs a list containing both the k8s role object and its binding.

**Rationale:** Since OPM's Role resource subsumes both concepts, the transformer must generate both k8s objects. The component carrying a Role resource MUST use the `"transformer.opmodel.dev/list-output": true` annotation (same pattern as Secrets/ConfigMaps) so the transformer pipeline handles multiple outputs.

The transformer reads `scope` to decide:

- `"namespace"` → k8s `rbac.authorization.k8s.io/v1/Role` + `RoleBinding`
- `"cluster"` → k8s `rbac.authorization.k8s.io/v1/ClusterRole` + `ClusterRoleBinding`

## Schema Reference

All schemas live in `schemas/security.cue`. Existing schemas (`#WorkloadIdentitySchema`, `#SecurityContextSchema`, `#EncryptionConfigSchema`) are untouched.

### #ServiceAccountSchema

```cue
#ServiceAccountSchema: {
    name!:           string
    automountToken?: bool
}
```

Structurally identical to `#WorkloadIdentitySchema`. Both represent a named identity with an optional token-mounting decision. This shared shape is what makes them interchangeable as Role subjects.

### #PolicyRuleSchema

```cue
#PolicyRuleSchema: {
    apiGroups!: [...string]
    resources!: [...string]
    verbs!:     [...string]
}
```

Maps 1:1 to a single k8s RBAC policy rule entry. Each field is a list of strings matching the k8s RBAC API. The `apiGroups` field uses `""` for core API group (same convention as k8s).

Examples:

- `{apiGroups: [""], resources: ["pods"], verbs: ["get", "list", "watch"]}` — read pods
- `{apiGroups: ["apps"], resources: ["deployments"], verbs: ["*"]}` — full access to deployments

### #RoleSubjectSchema

```cue
#RoleSubjectSchema: {#WorkloadIdentitySchema | #ServiceAccountSchema}
```

Uses CUE embedding — the identity fields are at the top level of each subject, no wrapper. Both `#WorkloadIdentitySchema` and `#ServiceAccountSchema` satisfy this because they share `name!: string`. The transformer reads `name` directly from each subject to populate the k8s RoleBinding subject.

Usage with CUE references:

```cue
_appIdentity: workloadIdentity: {name: "my-app", automountToken: false}

role: {
    name: "pod-reader"
    rules: [{apiGroups: [""], resources: ["pods"], verbs: ["get", "list"]}]
    subjects: [{_appIdentity.workloadIdentity}]
}
```

The `{_appIdentity.workloadIdentity}` embeds the referenced value directly into the subject. CUE validates it satisfies `#RoleSubjectSchema` at definition time.

### #RoleSchema

```cue
#RoleSchema: {
    name!:     string
    scope:     *"namespace" | "cluster"
    rules!:    [...#PolicyRuleSchema] & [_, ...]
    subjects!: [...#RoleSubjectSchema] & [_, ...]
}
```

- `name` — the role name, used for both the k8s Role/ClusterRole and its Binding
- `scope` — determines whether the transformer emits namespace-scoped (Role + RoleBinding) or cluster-scoped (ClusterRole + ClusterRoleBinding) k8s objects. Defaults to `"namespace"`.
- `rules` — at least one policy rule required (enforced by `& [_, ...]`)
- `subjects` — at least one subject required (enforced by `& [_, ...]`). Each subject embeds a `#WorkloadIdentitySchema` or `#ServiceAccountSchema` directly via CUE embedding.

The `& [_, ...]` constraint ensures non-empty lists — a Role with no rules or no subjects is meaningless and rejected at definition time.

## Risks / Trade-offs

**[Risk]** CUE reference for subjects creates a dependency between components (the Role must be defined in the same module or have access to the identity reference)
**→ Mitigation:** This is by design — CUE references are compile-time, so all connected resources must be visible during evaluation. This aligns with how modules already compose resources and traits.

**[Risk]** Two paths to ServiceAccount creation (WorkloadIdentity trait vs SA resource) could confuse users
**→ Mitigation:** Clear naming and documentation. WorkloadIdentity = "my workload needs an identity." ServiceAccount resource = "this identity exists standalone." The transformer FQNs are distinct.

**[Trade-off]** No external role references — users cannot bind to k8s built-in ClusterRoles like `view`, `edit`, `admin`
**→ Accepted:** Deferred to a future change. The current scope covers module-authored RBAC only. Adding external references later is a non-breaking MINOR change.

**[Trade-off]** Two Role instances needed if the same permissions are granted at different scopes (namespace vs cluster)
**→ Accepted:** This is rare and explicit. Two instances with different `scope` values are clearer than a single resource with mixed scoping rules.
