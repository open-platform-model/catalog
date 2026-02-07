## Why

The Kubernetes provider has gaps between what OPM defines and what it transforms. Several traits (HealthCheck, ResourceLimit) are declared as optional on workload transformers but never wired into K8s output. New resources and traits being added (ConfigMap, Secret, WorkloadIdentity, SecurityContext, HttpRoute, NetworkRules) also need corresponding transformers. Without these, OPM definitions silently produce incomplete Kubernetes manifests.

## What Changes

- **Fix**: Wire HealthCheck trait into Deployment, StatefulSet, DaemonSet transformer outputs (livenessProbe/readinessProbe on containers)
- **Fix**: Wire ResourceLimit trait into all workload transformer outputs (container resources field)
- **Fix**: Wire SecurityContext trait into all workload transformer outputs (pod/container securityContext)
- **New**: ConfigMapTransformer — emits `v1/ConfigMap` from ConfigMap resource
- **New**: SecretTransformer — emits `v1/Secret` from Secret resource
- **New**: ServiceAccountTransformer — emits `v1/ServiceAccount` from WorkloadIdentity resource
- **New**: NetworkPolicyTransformer — emits `networking.k8s.io/v1/NetworkPolicy` from NetworkRules policy
- **New**: HPATransformer — emits `autoscaling/v2/HorizontalPodAutoscaler` when Replication trait has `auto` config
- **New**: IngressTransformer — emits `networking.k8s.io/v1/Ingress` from HttpRoute trait (routing rules, TLS, className all sourced from `#HttpRouteSchema`)
- **New**: Register all new transformers in the Kubernetes provider definition

**Note**: This change depends on `add-more-resources` and `add-more-traits` being completed first. The "fix" items can proceed against existing definitions.

## Capabilities

### New Capabilities

- `k8s-configmap-transformer`: Transformer converting ConfigMap resource to Kubernetes ConfigMap
- `k8s-secret-transformer`: Transformer converting Secret resource to Kubernetes Secret
- `k8s-serviceaccount-transformer`: Transformer converting WorkloadIdentity resource to Kubernetes ServiceAccount
- `k8s-networkpolicy-transformer`: Transformer converting NetworkRules policy to Kubernetes NetworkPolicy
- `k8s-hpa-transformer`: Transformer converting Replication auto config to Kubernetes HPA
- `k8s-ingress-transformer`: Transformer converting HttpRoute trait to Kubernetes Ingress
- `k8s-workload-trait-wiring`: Fix existing workload transformers to emit HealthCheck, ResourceLimit, and SecurityContext output

### Modified Capabilities

_(none — existing transformer behavior is additive, not changing existing output shape)_

## Impact

- **Module**: `providers` (new transformer files + provider.cue registration)
- **Dependencies**: Requires new resources from `add-more-resources` and new traits from `add-more-traits` to be available as imports
- **SemVer**: MINOR — additive new transformers, no breaking changes to existing transformer output
- **Portability**: No impact — transformers are provider-specific by design (Kubernetes only)
- **Validation**: All existing `task vet` tests must continue to pass; new test data needed for each transformer
