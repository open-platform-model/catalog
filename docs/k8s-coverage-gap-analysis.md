# Kubernetes Coverage Gap Analysis

> **Status**: Draft — living document for iterative refinement
> **Date**: 2026-02-09
> **Scope**: OPM catalog `v0/` — resources, traits, blueprints, policies, and K8s provider transformers

---

## Current Coverage

What OPM models today, mapped to Kubernetes API groups:

### Workloads (`apps/v1`, `batch/v1`)

| K8s Resource | OPM Concept | Transformer |
|---|---|---|
| Deployment | `#StatelessWorkloadBlueprint` + `#ContainerResource` | `deployment_transformer.cue` |
| StatefulSet | `#StatefulWorkloadBlueprint` + `#ContainerResource` | `statefulset_transformer.cue` |
| DaemonSet | `#DaemonWorkloadBlueprint` + `#ContainerResource` | `daemonset_transformer.cue` |
| Job | `#TaskWorkloadBlueprint` + `#JobConfigTrait` | `job_transformer.cue` |
| CronJob | `#ScheduledTaskWorkloadBlueprint` + `#CronJobConfigTrait` | `cronjob_transformer.cue` |

### Networking (`v1`, `networking.k8s.io/v1`)

| K8s Resource | OPM Concept | Transformer |
|---|---|---|
| Service (ClusterIP, NodePort, LB) | `#ExposeTrait` | `service_transformer.cue` |
| Ingress | `#HttpRouteTrait` | `ingress_transformer.cue` |
| *(no K8s output)* | `#GrpcRouteTrait` — schema only | — |
| *(no K8s output)* | `#TcpRouteTrait` — schema only | — |

### Config (`v1`)

| K8s Resource | OPM Concept | Transformer |
|---|---|---|
| ConfigMap | `#ConfigMapResource` | `configmap_transformer.cue` |
| Secret | `#SecretResource` | `secret_transformer.cue` |

### Storage (`v1`)

| K8s Resource | OPM Concept | Transformer |
|---|---|---|
| PersistentVolumeClaim | `#VolumesResource` (persistentClaim) | `pvc_transformer.cue` |
| EmptyDir | `#VolumesResource` (emptyDir) | Woven into workload transformers |

### Identity (`v1`)

| K8s Resource | OPM Concept | Transformer |
|---|---|---|
| ServiceAccount | `#WorkloadIdentityResource` | `serviceaccount_transformer.cue` |

### Autoscaling (`autoscaling/v2`)

| K8s Resource | OPM Concept | Transformer |
|---|---|---|
| HorizontalPodAutoscaler | `#ScalingTrait` (auto) | `hpa_transformer.cue` |

### Workload Traits (woven into workload transformers)

| Trait | Transformer Integration |
|---|---|
| Scaling (count + HPA) | Replicas on workload + HPA transformer |
| HealthCheck (liveness/readiness) | Probes on container spec |
| UpdateStrategy | Strategy/updateStrategy on workload |
| RestartPolicy | restartPolicy on pod spec |
| SecurityContext | Pod + container securityContext |
| SidecarContainers | Additional containers in pod spec |
| InitContainers | initContainers in pod spec |
| **Placement** | **Schema exists, NOT woven into transformers** |
| **GracefulShutdown** | **Schema exists, NOT woven into transformers** |
| **DisruptionBudget** | **Schema exists, NO PDB transformer** |

### Policies

| Policy | Transformer |
|---|---|
| NetworkRules | **Schema exists, NO NetworkPolicy transformer** |
| SharedNetwork | Intent-only (no direct K8s mapping) |

---

## Gap Analysis

### Tier 1 — Core gaps most K8s apps need

#### 1.1 Environment variable references (HIGH)

**Problem**: `#ContainerSchema.env` only supports literal `name`/`value` pairs. Missing:

- `valueFrom.secretKeyRef` — reference a key in a Secret
- `valueFrom.configMapKeyRef` — reference a key in a ConfigMap
- `valueFrom.fieldRef` — downward API (pod name, namespace, etc.)
- `valueFrom.resourceFieldRef` — container resource limits/requests
- `envFrom` — bulk inject all keys from a ConfigMap or Secret

**Impact**: Most real-world K8s apps use `valueFrom` for secrets injection. Without it, users must hardcode sensitive values or work around the model.

**Where to fix**: `schemas/workload.cue` (`#ContainerSchema.env`)

**Design question**: Should `valueFrom` be part of the container schema directly, or should config wiring be a separate trait that "connects" ConfigMaps/Secrets to containers?

#### 1.2 Startup Probe (HIGH)

**Problem**: `#HealthCheckSchema` has `livenessProbe` and `readinessProbe` but no `startupProbe`. Startup probes are critical for slow-starting applications (JVM apps, ML models, etc.) where a liveness probe would kill the pod before it finishes starting.

**Where to fix**: `schemas/workload.cue` (`#HealthCheckSchema`) + weave into workload transformers

**Effort**: Small

#### 1.3 Image Pull Secrets (MEDIUM)

**Problem**: No way to reference private container registry credentials. In K8s, this is `pod.spec.imagePullSecrets`.

**Where to fix**: Could be a trait on the container resource or a field on the container schema.

**Effort**: Small

#### 1.4 Container postStart lifecycle hook (MEDIUM)

**Problem**: `#GracefulShutdownTrait` models `preStopCommand` but there's no `postStart` hook. K8s supports both `lifecycle.preStop` and `lifecycle.postStart`.

**Where to fix**: `schemas/workload.cue` (`#GracefulShutdownSchema`) or a dedicated lifecycle trait

**Effort**: Small

---

### Tier 2 — Schema-exists-but-no-transformer (incomplete pipeline)

These are capabilities already modeled at the schema/trait level that have no path to K8s output:

| Schema/Trait | Missing Transformer | K8s Target |
|---|---|---|
| `#DisruptionBudgetTrait` | PDB transformer | `policy/v1 PodDisruptionBudget` |
| `#PlacementTrait` | Weave into workload transformers | `topologySpreadConstraints`, affinity |
| `#GracefulShutdownTrait` | Weave into workload transformers | `terminationGracePeriodSeconds`, `lifecycle.preStop` |
| `#NetworkRulesPolicy` | NetworkPolicy transformer | `networking.k8s.io/v1 NetworkPolicy` |
| `#GrpcRouteTrait` | Gateway API GRPCRoute transformer | `gateway.networking.k8s.io/v1 GRPCRoute` |
| `#TcpRouteTrait` | Gateway API TCPRoute transformer | `gateway.networking.k8s.io/v1alpha2 TCPRoute` |
| `#EncryptionTrait` | Intent-only — needs design decision | (no direct K8s mapping?) |

**Note**: Placement and GracefulShutdown should be woven into the existing workload transformers (Deployment, StatefulSet, DaemonSet, Job, CronJob) — same pattern as SecurityContext. DisruptionBudget needs its own transformer since it produces a separate K8s resource.

---

### Tier 3 — RBAC & Security gaps

#### 3.1 RBAC (MEDIUM)

**Problem**: `#WorkloadIdentityResource` creates a ServiceAccount but can't grant it any permissions. No model for:

- `Role` / `ClusterRole`
- `RoleBinding` / `ClusterRoleBinding`

**Design question**: How far into RBAC? Options:

1. **Full RBAC resource**: Model Role/Binding as first-class OPM resources
2. **Permissions intent on WorkloadIdentity**: Add a `permissions` field to `#WorkloadIdentitySchema` that describes what the workload needs (read secrets, list pods, etc.) and let the transformer generate the RBAC resources
3. **Policy-based**: Model RBAC rules as a policy

Option 2 feels most aligned with OPM's intent-based philosophy.

#### 3.2 Pod Security Standards (MEDIUM)

**Problem**: No way to express pod security admission labels (`pod-security.kubernetes.io/{enforce,audit,warn}: {restricted,baseline,privileged}`) on namespaces.

**Prerequisite**: Namespace modeling (see Tier 4).

#### 3.3 ResourceQuota / LimitRange (LOW)

**Problem**: No resource governance at namespace level. These are typically cluster-admin concerns but important for multi-tenant patterns.

**Prerequisite**: Namespace modeling.

---

### Tier 4 — Namespace & storage gaps

#### 4.1 Namespace (MEDIUM)

**Problem**: The transformer system uses `#context.namespace` but there's no way to model namespace properties (labels, annotations, resource quotas, pod security labels). Namespaces are just strings today.

**Design options**:

- A `#NamespaceResource` that declares namespace properties
- Namespace as part of module/bundle configuration
- Implicit namespace from deployment context

#### 4.2 Volume types (MEDIUM)

`#VolumeSchema` supports `emptyDir` and `persistentClaim` but is missing:

- `hostPath` — host filesystem mount
- `projected` — composite of serviceAccountToken, downwardAPI, configMap, secret
- CSI ephemeral volumes

#### 4.3 VolumeClaimTemplates in StatefulSet (MEDIUM)

**Problem**: The StatefulSet transformer doesn't emit `volumeClaimTemplates`. It relies on standalone PVCs via the PVC transformer. For proper StatefulSet semantics (per-replica storage), VolumeClaimTemplates should be inline in the StatefulSet spec.

---

### Tier 5 — Observability & missing transformer gaps

#### 5.1 PDB transformer (MEDIUM)

`#DisruptionBudgetTrait` exists with `minAvailable`/`maxUnavailable` but no transformer emits `policy/v1 PodDisruptionBudget`.

**Effort**: Small — straightforward transformer.

#### 5.2 Annotations-driven observability (MEDIUM)

No first-class support for common annotation patterns:

- Prometheus scrape config (`prometheus.io/scrape`, `prometheus.io/port`, etc.)
- Datadog, Fluentd, and other observability tool annotations

**Design question**: Should this be a trait (`#ObservabilityTrait`) or just documented annotation conventions?

---

### Tier 6 — Advanced patterns (nice-to-have)

| Pattern | Notes |
|---|---|
| Custom Resources (CRDs) | No generic way to model arbitrary CRDs |
| Pod topology spread constraints | Placement has `spreadAcross` but transformers don't emit `topologySpreadConstraints` |
| Node affinity/anti-affinity | Placement has `requirements` but transformers don't emit affinity rules |
| PriorityClass | No priority/preemption concept |
| RuntimeClass | No container runtime selection |
| Ephemeral Containers | Debug containers — very niche |
| ExternalName Service | No way to model external service references |
| EndpointSlice | Usually auto-managed, but headless service patterns may need it |

---

## Design Questions

These questions need answers before implementation:

### Q1: Weave vs. separate transformer?

For traits that affect pod spec (Placement, GracefulShutdown) — should they be woven into existing workload transformers (like SecurityContext is today), or should they get their own transformer?

**Recommendation**: Weave into workload transformers. They modify the pod template, not create separate K8s resources.

### Q2: Gateway API vs. Ingress

Currently only Ingress has a transformer. The route schemas (HTTP, gRPC, TCP) are already modeled. Should OPM:

- Support both Ingress and Gateway API transformers?
- Treat Gateway API as the future and Ingress as legacy?
- Let the provider decide (different providers for Ingress vs. Gateway API)?

### Q3: How deep into RBAC?

Options:

1. Full Role/Binding resources
2. Intent-based permissions on WorkloadIdentity
3. Policy-based RBAC

### Q4: Environment variable wiring

Should `valueFrom` be part of `#ContainerSchema.env` directly, or should config wiring be a separate trait/mechanism?

---

## Priority-Ordered Implementation Plan

| # | Gap | Type | Effort | Notes |
|---|-----|------|--------|-------|
| 1 | env valueFrom refs | Schema change | S | Most impactful single change |
| 2 | startupProbe | Schema + transformer weave | S | Simple addition to HealthCheck |
| 3 | PDB transformer | New transformer | S | Trait already exists |
| 4 | Placement → workload transformers | Transformer change | S | Trait already exists |
| 5 | GracefulShutdown → workload transformers | Transformer change | S | Trait already exists |
| 6 | VPA transformer | New transformer | S | Schema already exists |
| 7 | VolumeClaimTemplates in StatefulSet | Transformer fix | S | Important for stateful semantics |
| 8 | NetworkPolicy transformer | Schema tighten + transformer | M | Schema needs work (from/to is loose) |
| 9 | Gateway API transformers | 3 new transformers | M | HTTPRoute, GRPCRoute, TCPRoute |
| 10 | RBAC modeling | New resource + transformer | M | Needs design decision (Q3) |
| 11 | Namespace resource | New resource + transformer | M | Enables PodSecurity, ResourceQuota |
| 12 | imagePullSecrets | Schema/trait + transformer weave | S | |
| 13 | postStart lifecycle hook | Schema change | S | |

Items 1–7 are small, high-impact changes. Items 8–11 are medium effort. Items 12–13 are polish.
