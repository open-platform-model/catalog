# Kubernetes Native Resources Reference

This document catalogs all native Kubernetes API resources as of v1.35.x,
organized by API group. It serves as the implementation backlog for the
`opmodel.dev/kubernetes/v1alpha1` OPM catalog module.

## Implementation Status Legend

- [x] Tier 1 — Implemented in this module
- [ ] Tier 2 — Planned (next batch)
- [ ] Tier 3 — Infrastructure-level (future)
- [ ] Tier 4 — Internal/Review (unlikely to need OPM resources)

---

## Tier 1 — Implemented (~25 resources)

### Workload (apps/v1, batch/v1, v1)

| Status | Kind | API Group | API Version | Scope |
|--------|------|-----------|-------------|-------|
| [x] | Deployment | apps | apps/v1 | Namespaced |
| [x] | StatefulSet | apps | apps/v1 | Namespaced |
| [x] | DaemonSet | apps | apps/v1 | Namespaced |
| [x] | Job | batch | batch/v1 | Namespaced |
| [x] | CronJob | batch | batch/v1 | Namespaced |
| [x] | Pod | core | v1 | Namespaced |

### Networking (networking.k8s.io/v1, v1)

| Status | Kind | API Group | API Version | Scope |
|--------|------|-----------|-------------|-------|
| [x] | Service | core | v1 | Namespaced |
| [x] | Ingress | networking.k8s.io | networking.k8s.io/v1 | Namespaced |
| [x] | IngressClass | networking.k8s.io | networking.k8s.io/v1 | Cluster |
| [x] | NetworkPolicy | networking.k8s.io | networking.k8s.io/v1 | Namespaced |

### Configuration (v1)

| Status | Kind | API Group | API Version | Scope |
|--------|------|-----------|-------------|-------|
| [x] | ConfigMap | core | v1 | Namespaced |
| [x] | Secret | core | v1 | Namespaced |

### Storage (v1, storage.k8s.io/v1)

| Status | Kind | API Group | API Version | Scope |
|--------|------|-----------|-------------|-------|
| [x] | PersistentVolumeClaim | core | v1 | Namespaced |
| [x] | PersistentVolume | core | v1 | Cluster |
| [x] | StorageClass | storage.k8s.io | storage.k8s.io/v1 | Cluster |

### RBAC (rbac.authorization.k8s.io/v1, v1)

| Status | Kind | API Group | API Version | Scope |
|--------|------|-----------|-------------|-------|
| [x] | ServiceAccount | core | v1 | Namespaced |
| [x] | Role | rbac.authorization.k8s.io | rbac.authorization.k8s.io/v1 | Namespaced |
| [x] | ClusterRole | rbac.authorization.k8s.io | rbac.authorization.k8s.io/v1 | Cluster |
| [x] | RoleBinding | rbac.authorization.k8s.io | rbac.authorization.k8s.io/v1 | Namespaced |
| [x] | ClusterRoleBinding | rbac.authorization.k8s.io | rbac.authorization.k8s.io/v1 | Cluster |

### Cluster Management (v1)

| Status | Kind | API Group | API Version | Scope |
|--------|------|-----------|-------------|-------|
| [x] | Namespace | core | v1 | Cluster |

### Policy (policy/v1, autoscaling/v2)

| Status | Kind | API Group | API Version | Scope |
|--------|------|-----------|-------------|-------|
| [x] | HorizontalPodAutoscaler | autoscaling | autoscaling/v2 | Namespaced |
| [x] | PodDisruptionBudget | policy | policy/v1 | Namespaced |

### Admission (admissionregistration.k8s.io/v1)

| Status | Kind | API Group | API Version | Scope |
|--------|------|-----------|-------------|-------|
| [x] | ValidatingWebhookConfiguration | admissionregistration.k8s.io | admissionregistration.k8s.io/v1 | Cluster |
| [x] | MutatingWebhookConfiguration | admissionregistration.k8s.io | admissionregistration.k8s.io/v1 | Cluster |

---

## Tier 2 — Planned (next batch)

| Status | Kind | API Group | API Version | Scope |
|--------|------|-----------|-------------|-------|
| [ ] | CustomResourceDefinition | apiextensions.k8s.io | apiextensions.k8s.io/v1 | Cluster |
| [ ] | EndpointSlice | discovery.k8s.io | discovery.k8s.io/v1 | Namespaced |
| [ ] | CertificateSigningRequest | certificates.k8s.io | certificates.k8s.io/v1 | Cluster |
| [ ] | Lease | coordination.k8s.io | coordination.k8s.io/v1 | Namespaced |
| [ ] | RuntimeClass | node.k8s.io | node.k8s.io/v1 | Cluster |
| [ ] | PriorityClass | scheduling.k8s.io | scheduling.k8s.io/v1 | Cluster |
| [ ] | LimitRange | core | v1 | Namespaced |
| [ ] | ResourceQuota | core | v1 | Namespaced |
| [ ] | ReplicaSet | apps | apps/v1 | Namespaced |
| [ ] | Endpoints | core | v1 | Namespaced |

---

## Tier 3 — Infrastructure-level (future)

| Status | Kind | API Group | API Version | Scope |
|--------|------|-----------|-------------|-------|
| [ ] | CSIDriver | storage.k8s.io | storage.k8s.io/v1 | Cluster |
| [ ] | CSINode | storage.k8s.io | storage.k8s.io/v1 | Cluster |
| [ ] | CSIStorageCapacity | storage.k8s.io | storage.k8s.io/v1 | Namespaced |
| [ ] | VolumeAttachment | storage.k8s.io | storage.k8s.io/v1 | Cluster |
| [ ] | FlowSchema | flowcontrol.apiserver.k8s.io | flowcontrol.apiserver.k8s.io/v1 | Cluster |
| [ ] | PriorityLevelConfiguration | flowcontrol.apiserver.k8s.io | flowcontrol.apiserver.k8s.io/v1 | Cluster |
| [ ] | ValidatingAdmissionPolicy | admissionregistration.k8s.io | admissionregistration.k8s.io/v1 | Cluster |
| [ ] | ValidatingAdmissionPolicyBinding | admissionregistration.k8s.io | admissionregistration.k8s.io/v1 | Cluster |
| [ ] | APIService | apiregistration.k8s.io | apiregistration.k8s.io/v1 | Cluster |
| [ ] | ServiceCIDR | networking.k8s.io | networking.k8s.io/v1 | Cluster |
| [ ] | IPAddress | networking.k8s.io | networking.k8s.io/v1 | Cluster |
| [ ] | Node | core | v1 | Cluster |
| [ ] | ComponentStatus | core | v1 | Cluster |

---

## Tier 4 — Internal/Review (not planned)

These resources are primarily used by Kubernetes internally or for access review
and are unlikely to need OPM resource definitions.

| Kind | API Group | Notes |
|------|-----------|-------|
| TokenReview | authentication.k8s.io | Internal auth |
| TokenRequest | authentication.k8s.io | Internal auth |
| SubjectAccessReview | authorization.k8s.io | Permission check |
| SelfSubjectAccessReview | authorization.k8s.io | Self-check |
| SelfSubjectRulesReview | authorization.k8s.io | Self-check |
| LocalSubjectAccessReview | authorization.k8s.io | Namespace permission check |
| Binding | core | Scheduler internal |
| PodTemplate | core | Internal template |
| ControllerRevision | apps | Rollout history |
| ReplicationController | core | Legacy (deprecated) |
| StorageVersionMigration | storagemigration.k8s.io | Migration utility |
| VolumeAttributesClass | storage.k8s.io | Rarely used |
| Event | events.k8s.io/v1 | Observability only |

---

## Notes

- Source: Kubernetes v1.35.x API reference
- OPM `kubernetes` module provides **native K8s resource definitions** as a supplementary path
  alongside OPM's portable abstractions (the `opm` module).
- Module authors choose: OPM abstractions (portable) vs. native K8s resources (direct control).
- Transformers are pass-through: they apply OPM context (name prefix, namespace, labels) to the
  native K8s spec without schema translation.
