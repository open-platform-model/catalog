## 1. Module Setup

- [x] 1.1 Create directory `v0/schemas_kubernetes/`
- [x] 1.2 Create `v0/schemas_kubernetes/cue.mod/module.cue` with module path `opmodel.dev/schemas/kubernetes@v0` and dependency on `cue.dev/x/k8s.io@v0: v0.6.0`
- [x] 1.3 Run `task tidy MODULE=schemas_kubernetes` to fetch upstream dependency

## 2. API Group Re-exports

- [x] 2.1 Create `apps/v1/types.cue` with explicit re-exports (30 types: #Deployment, #StatefulSet, #DaemonSet, #ReplicaSet, etc.)
- [x] 2.2 Create `batch/v1/types.cue` with explicit re-exports (17 types: #Job, #CronJob, etc.)
- [x] 2.3 Create `core/v1/types.cue` with explicit re-exports (218 types: #Pod, #Service, #ConfigMap, #Secret, etc.)
- [x] 2.4 Create `networking/v1/types.cue` with explicit re-exports (30 types: #Ingress, #NetworkPolicy, etc.)
- [x] 2.5 Create `autoscaling/v2/types.cue` with explicit re-exports (24 types: #HorizontalPodAutoscaler, etc.)

## 3. Documentation

- [x] 3.1 Add comment in module.cue documenting the upstream K8s version mapping (v0.6.0 ≈ K8s 1.31+)
- [x] 3.2 Add comment listing future API groups available for expansion

## 4. Validation

- [x] 4.1 Run `task fmt MODULE=schemas_kubernetes` to format all files
- [x] 4.2 Run `task vet MODULE=schemas_kubernetes` to validate module (requires CUE_REGISTRY='opmodel.dev=localhost:5000+insecure,registry.cue.works')
- [x] 4.3 Run `task eval MODULE=schemas_kubernetes` to verify types are properly exported
