## Why

The Kubernetes provider has gaps between what OPM defines and what it transforms. Several traits (HealthCheck, Sizing) are declared as optional on workload transformers but never wired into K8s output. New resources and traits added by completed sibling changes (ConfigMap, Secret, WorkloadIdentity, SecurityContext, HttpRoute) also need corresponding transformers. Without these, OPM definitions silently produce incomplete Kubernetes manifests.

## What Changes

- **Fix**: Wire HealthCheck trait into Deployment, StatefulSet, DaemonSet transformer outputs (livenessProbe/readinessProbe on containers)
- **Fix**: Wire Sizing trait into all workload transformer outputs (container resources field)
- **Fix**: Wire SecurityContext trait into all workload transformer outputs (pod/container securityContext)
- **New**: ConfigMapTransformer — emits `v1/ConfigMap` from ConfigMap resource
- **New**: SecretTransformer — emits `v1/Secret` from Secret resource
- **New**: ServiceAccountTransformer — emits `v1/ServiceAccount` from WorkloadIdentity resource
- **New**: HPATransformer — emits `autoscaling/v2/HorizontalPodAutoscaler` when Scaling trait has `auto` config
- **New**: IngressTransformer — emits `networking.k8s.io/v1/Ingress` from HttpRoute trait (routing rules, TLS, ingressClassName all sourced from `#HttpRouteSchema`)
- **New**: Register all new transformers in the Kubernetes provider definition

**Note**: This change depends on `rename-scaling-traits` (for Scaling trait with `auto` field and workload schema updates). The `add-more-resources` and `add-more-traits` dependencies are completed and archived.

**Deferred**: NetworkPolicyTransformer — requires extending transformer matching to support scope-level policies. Tracked separately.

## Capabilities

### New Capabilities

- `k8s-configmap-transformer`: Transformer converting ConfigMap resource to Kubernetes ConfigMap
- `k8s-secret-transformer`: Transformer converting Secret resource to Kubernetes Secret
- `k8s-serviceaccount-transformer`: Transformer converting WorkloadIdentity resource to Kubernetes ServiceAccount
- `k8s-hpa-transformer`: Transformer converting Scaling auto config to Kubernetes HPA
- `k8s-ingress-transformer`: Transformer converting HttpRoute trait to Kubernetes Ingress
- `k8s-workload-trait-wiring`: Fix existing workload transformers to emit HealthCheck, Sizing, and SecurityContext output

### Modified Capabilities

_(none — existing transformer behavior is additive, not changing existing output shape)_

## Impact

- **Module**: `providers` (new transformer files + provider.cue registration)
- **Dependencies**: Requires `rename-scaling-traits` to be completed first (Scaling trait with `auto` field, workload schema updates). `add-more-resources` and `add-more-traits` are already completed.
- **SemVer**: MINOR — additive new transformers, no breaking changes to existing transformer output
- **Portability**: No impact — transformers are provider-specific by design (Kubernetes only)
- **Validation**: All existing `task vet` tests must continue to pass; new test data needed for each transformer
