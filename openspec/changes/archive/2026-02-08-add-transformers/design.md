## Context

The Kubernetes provider currently has 7 transformers (Deployment, StatefulSet, DaemonSet, Job, CronJob, Service, PVC). These cover workload scheduling and basic networking/storage but have two categories of gaps:

1. **Wiring gaps**: HealthCheck and Sizing traits are declared as optional on workload transformers but never extracted or emitted in the K8s output. SecurityContext (from `add-more-traits`, now completed) needs the same wiring.
2. **Missing transformers**: New resources (ConfigMap, Secret, WorkloadIdentity) and traits (HttpRoute, Scaling auto) from sibling changes have no K8s transformers to consume them.

All existing transformers follow a consistent pattern: single `#Transformer` definition with `requiredLabels`, `requiredResources`, `requiredTraits`, `optionalTraits`, and a `#transform` function that emits one K8s resource.

This change depends on:

- `rename-scaling-traits` (Scaling schema with `auto` field, Sizing rename from ResourceLimit, workload schema updates for `sizing?` and `securityContext?` fields)
- `add-more-resources` (ConfigMap, Secret, WorkloadIdentity resource definitions) — **completed and archived**
- `add-more-traits` (SecurityContext, HttpRoute, GrpcRoute, TcpRoute traits) — **completed and archived**

## Goals / Non-Goals

**Goals:**

- Wire HealthCheck, Sizing, and SecurityContext traits into all applicable workload transformer outputs
- Add transformers for every new resource and trait that has a natural K8s equivalent
- Maintain the existing transformer pattern (single output per transformer)
- Include test data for every new transformer
- Register all new transformers in `provider.cue`

**Non-Goals:**

- Changing the core `#Transformer` contract (single-output constraint stays)
- Adding transformers for non-K8s providers
- Handling CRDs or operator-based resources (e.g., cert-manager Certificates)
- Adding Namespace transformer (module-level concern, not component-level)
- NetworkPolicy transformer (deferred — requires extending transformer matching to support scope-level policies; see Risks)

## Decisions

### 1. Trait wiring goes into existing transformers, not separate ones

HealthCheck, Sizing, and SecurityContext modify pod/container spec fields within an existing workload resource. They don't produce standalone K8s objects.

**Decision**: Add them as `optionalTraits` on existing workload transformers and emit their fields inline.

**Alternative considered**: Separate "patch" transformers that overlay fields. Rejected because the single-output constraint means a patch transformer would need a merge mechanism that doesn't exist, and it adds complexity for no composability benefit.

**Wiring targets**:

| Trait | Output Field | Applies To |
|---|---|---|
| HealthCheck | `containers[].livenessProbe`, `containers[].readinessProbe` | Deployment, StatefulSet, DaemonSet |
| Sizing | `containers[].resources` | Deployment, StatefulSet, DaemonSet, Job, CronJob |
| SecurityContext | `spec.template.spec.securityContext` (pod-level), `containers[].securityContext` (container-level) | All workload transformers |

HealthCheck probes apply only to the main container (not sidecars), since the trait is defined at the component level, not per-container.

### 2. HPA transformer matches on Scaling `auto` field presence

The Scaling trait (from `rename-scaling-traits`) is a struct with `count` and optional `auto`. When `auto` is present, the HPA transformer should match.

**Decision**: HPATransformer uses `requiredTraits` for the Scaling trait and checks for `auto` presence inside `#transform`. The workload transformers continue to emit `spec.replicas` from `scaling.count` — the HPA overrides this at runtime.

**Alternative considered**: Making the workload transformer omit `replicas` when `auto` is present. Rejected because K8s best practice is to set initial replicas even with HPA, and the HPA takes over from there.

### 3. ConfigMap and Secret transformers are standalone, not component-scoped

ConfigMap and Secret resources are standalone K8s objects. The transformer matches components that have the ConfigMap/Secret resource attached and emits the corresponding K8s object.

**Decision**: One ConfigMap/Secret per component that declares the resource. The transformer iterates the resource's `data` map to produce the K8s object.

### 4. NetworkPolicy transformer — deferred

NetworkRules is a policy applied to scopes, not individual components. The current transformer matching is component-based and cannot access scope-level policy data.

**Decision**: Defer the NetworkPolicy transformer to a follow-up change. Implementing it requires extending the transformer matching mechanism to support scope-level policies, which is a larger architectural change outside the scope of this work.

### 5. Ingress transformer requires HttpRoute trait only

**Decision**: `requiredTraits` includes only the HttpRoute trait. The transformer does NOT require the Expose trait or a separate Ingress trait.

**Rationale**: The `#HttpRouteSchema` (from `add-more-traits`) already contains all data the Ingress transformer needs:

- `hostnames` → Ingress `rules[].host`
- `rules[].matches[].path` → Ingress `rules[].http.paths[]`
- `rules[].backendPort` → Ingress `backend.service.port.number`
- `ingressClassName` → Ingress `spec.ingressClassName` (via `#RouteAttachmentSchema`)
- `tls` → Ingress `spec.tls` (via `#RouteAttachmentSchema`)

The backend service name is derived from `#context.name` (the component name), which is the same name the Service transformer uses. No Expose data is needed.

**Previous position**: Earlier design required both Expose and a phantom `#IngressTrait`. Revised because: (1) `#IngressTrait` was never specified in `add-more-traits`, (2) `#HttpRouteSchema` already carries all routing, TLS, and ingressClassName data, (3) `backendPort` on route rules replaces the need to read Expose for port info.

### 6. ServiceAccount transformer is resource-matched

**Decision**: Matches components with `WorkloadIdentityResource`. Emits a `v1/ServiceAccount`. The workload transformers also need updating to reference the ServiceAccount name in `spec.template.spec.serviceAccountName` when WorkloadIdentity is present — this is wiring, similar to HealthCheck.

## Risks / Trade-offs

**[Scope-level transformer matching — deferred]** → NetworkRules is a module-level policy, but transformers currently match against components. The NetworkPolicyTransformer has been deferred to a follow-up change that will address the matching mechanism extension.

**[Ordering dependency]** → This change depends on `rename-scaling-traits` being completed first for HPA transformer tasks. The wiring fixes (HealthCheck, Sizing) and new transformers (ConfigMap, Secret, ServiceAccount, Ingress) can proceed after `rename-scaling-traits` lands (since it updates workload schemas with `sizing?` and `securityContext?` fields).

**[SecurityContext pod vs container level]** → SecurityContext has both pod-level and container-level fields in K8s. The OPM trait schema needs to be clear about which level it targets. **Mitigation**: Design the SecurityContext trait with a flat schema; the transformer maps `runAsNonRoot`, `runAsUser`, `runAsGroup` to pod-level and `capabilities`, `readOnlyRootFilesystem`, `allowPrivilegeEscalation` to container-level. This mirrors K8s semantics.

**[HPA and static replicas coexistence]** → Setting both `spec.replicas` and an HPA can cause flapping on redeploy if the HPA has scaled beyond the static count. **Mitigation**: Use `scaling.auto.min` as the value for `spec.replicas` in the workload transformer when `auto` is present, so the static value matches the HPA floor.
