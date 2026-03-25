# kubernetes — Native Kubernetes Resource Definitions

CUE module: `opmodel.dev/kubernetes/v1alpha1@v1`

## Summary

This module provides OPM `#Resource` and `#Transformer` definitions for native Kubernetes API
resources. It is a **supplementary** path alongside OPM's portable abstractions.

**When to use this module:**
- You need direct, full-fidelity control over a native Kubernetes resource
- The OPM `opm` module does not yet have an abstraction for the resource you need
  (e.g., `ValidatingWebhookConfiguration`, `MutatingWebhookConfiguration`)
- You want to include Kubernetes-native resources in a module without writing raw manifests

**When NOT to use this module:**
- You want portability across platforms — use the `opm` module instead
- The OPM `opm` module already provides the abstraction you need

## Contents

| Path | Description |
|------|-------------|
| `resources/workload/` | Deployment, StatefulSet, DaemonSet, Job, CronJob, Pod |
| `resources/network/` | Service, Ingress, IngressClass, NetworkPolicy |
| `resources/config/` | ConfigMap, Secret |
| `resources/storage/` | PersistentVolumeClaim, PersistentVolume, StorageClass |
| `resources/rbac/` | ServiceAccount, Role, ClusterRole, RoleBinding, ClusterRoleBinding |
| `resources/cluster/` | Namespace |
| `resources/policy/` | HorizontalPodAutoscaler, PodDisruptionBudget |
| `resources/admission/` | ValidatingWebhookConfiguration, MutatingWebhookConfiguration |
| `providers/kubernetes/` | Pass-through transformer registry |
| `schemas/` | Open-schema definitions for each resource domain |

## Transformer Behaviour

Transformers in this module are **pass-through with OPM context**:
1. Accept the native K8s spec from the resource
2. Apply the ModuleRelease name prefix to the resource name
3. Apply the ModuleRelease namespace
4. Merge OPM labels from context

No schema translation occurs — the spec you write is the spec deployed.

## Kubernetes Version

Definitions target the Kubernetes v1.35.x API.

## Links

- [Kubernetes API Reference v1.35](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.35/)
- [KUBERNETES_RESOURCES.md](KUBERNETES_RESOURCES.md) — full resource backlog with tier classification
