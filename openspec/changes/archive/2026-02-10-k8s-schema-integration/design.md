## Context

OPM transformers generate Kubernetes resources as untyped CUE structs. The upstream CUE registry provides curated K8s schemas at `cue.dev/x/k8s.io@v0` that include:

- All K8s API types with full field definitions
- Hardcoded `apiVersion` and `kind` values per resource type
- Proper required/optional field markers

Current state: Transformers manually construct output like:

```cue
output: {
    apiVersion: "apps/v1"
    kind:       "Deployment"
    // ... fields could be wrong, no validation
}
```

Target state: Transformers can validate against real schemas:

```cue
import appsv1 "opmodel.dev/schemas/kubernetes/apps/v1"
output: appsv1.#Deployment & { /* fields validated */ }
```

## Goals / Non-Goals

**Goals:**

- Create `opmodel.dev/schemas/kubernetes@v0` module with explicit re-exports
- Pin upstream dependency to `cue.dev/x/k8s.io@v0: v0.6.0`
- Cover 5 API groups used by current transformers
- Document remaining 16 API groups for future expansion
- Maintain version indirection (consumers depend on OPM module, not upstream directly)

**Non-Goals:**

- Updating transformers to use these schemas (separate change)
- Supporting multiple K8s versions simultaneously
- Adding OPM-specific constraints on K8s types
- Subsetting or filtering K8s types within each API group

## Decisions

### 1. Separate module in `v0/schemas_kubernetes/`

**Decision:** Create as standalone module, not subpackage of `v0/schemas/`.

**Rationale:** The `opmodel.dev/schemas@v0` module should not depend on external K8s schemas. Consumers of common OPM schemas (network, workload, etc.) shouldn't transitively pull K8s types.

**Alternatives considered:**

- Subpackage of schemas: Simpler structure, but bleeds K8s dependency to all schema consumers
- Part of providers: Would couple K8s schemas to provider implementations

### 2. Explicit re-exports over package embedding

**Decision:** Each type file explicitly lists all re-exported definitions:

```cue
#Deployment:     appsv1.#Deployment
#DeploymentList: appsv1.#DeploymentList
#DeploymentSpec: appsv1.#DeploymentSpec
// ... all types
```

**Rationale:** Clear, greppable, documents exactly what's available. Package embedding (`appsv1`) is implicit and harder to understand.

### 3. Single version, bump intentionally

**Decision:** Pin to one upstream version (`v0.6.0`), bump manually when needed.

**Rationale:** K8s stable APIs (apps/v1, core/v1, etc.) are backwards compatible. OPM transformers use a subset of fields that exist across K8s versions. Multi-version support adds significant complexity for minimal benefit.

**Process:** When CUE publishes new k8s.io version:

1. Bump dep in module.cue
2. Run `task vet` to detect breakage
3. Fix any issues, release new schemas/kubernetes version

### 4. Start with 5 API groups, document the rest

**Decision:** Implement only the API groups current transformers need:

- `apps/v1` - Deployment, StatefulSet, DaemonSet
- `batch/v1` - Job, CronJob
- `core/v1` - Service, ConfigMap, Secret, PVC, ServiceAccount, Pod
- `networking/v1` - Ingress, NetworkPolicy
- `autoscaling/v2` - HorizontalPodAutoscaler

**Documented for future:** admissionregistration, apiserverinternal, authentication, authorization, certificates, coordination, discovery, events, flowcontrol, node, policy, rbac, resource, scheduling, storage, storagemigration

**Rationale:** YAGNI. Add API groups when there's demand.

## Risks / Trade-offs

**[Upstream version opacity]** → The CUE module version (v0.6.0) doesn't clearly map to a K8s release version. Mitigation: Document approximate K8s version in module.cue comments and README.

**[Missing types at runtime]** → If transformers generate fields not in the pinned schema version, CUE won't catch it (open structs). Mitigation: This is acceptable - extra fields are forward-compatible with newer K8s.

**[Dependency on external registry]** → Module depends on `cue.dev/x/k8s.io` being available. Mitigation: Standard CUE ecosystem risk, same as any curated module dependency.
