## 1. Module Dependency Setup

- [x] 1.1 Add `opmodel.dev/schemas/kubernetes@v0` to `v0/providers/cue.mod/module.cue` deps
- [x] 1.2 Run `task tidy MODULE=providers` to resolve the dependency

## 2. Workload Transformers (apps/v1) — Fix volumes + add schema

- [x] 2.1 Update `deployment_transformer.cue`: import `k8sappsv1`, unify output with `k8sappsv1.#Deployment`, fix `volumes` struct→list
- [x] 2.2 Update `statefulset_transformer.cue`: import `k8sappsv1`, unify output with `k8sappsv1.#StatefulSet`, fix `volumes` struct→list
- [x] 2.3 Update `daemonset_transformer.cue`: import `k8sappsv1`, unify output with `k8sappsv1.#DaemonSet`, fix `volumes` struct→list

## 3. Batch Transformers (batch/v1) — Fix volumes + add schema

- [x] 3.1 Update `job_transformer.cue`: import `k8sbatchv1`, unify output with `k8sbatchv1.#Job`, fix `volumes` struct→list
- [x] 3.2 Update `cronjob_transformer.cue`: import `k8sbatchv1`, unify output with `k8sbatchv1.#CronJob`, fix `volumes` struct→list

## 4. Core/v1 Single-Resource Transformers

- [x] 4.1 Update `service_transformer.cue`: import `k8scorev1`, unify output with `k8scorev1.#Service`
- [x] 4.2 Update `serviceaccount_transformer.cue`: import `k8scorev1`, unify output with `k8scorev1.#ServiceAccount`

## 5. Networking and Autoscaling Transformers

- [x] 5.1 Update `ingress_transformer.cue`: import `k8snetv1`, unify output with `k8snetv1.#Ingress`
- [x] 5.2 Update `hpa_transformer.cue`: import `k8sasv2`, unify output with `k8sasv2.#HorizontalPodAutoscaler` inside the conditional guard

## 6. Multi-Resource Transformers (per-value unification)

- [x] 6.1 Update `configmap_transformer.cue`: import `k8scorev1`, unify each value with `k8scorev1.#ConfigMap`
- [x] 6.2 Update `secret_transformer.cue`: import `k8scorev1`, unify each value with `k8scorev1.#Secret`
- [x] 6.3 Update `pvc_transformer.cue`: import `k8scorev1`, unify each value with `k8scorev1.#PersistentVolumeClaim`

## 7. Validation

- [x] 7.1 Run `task fmt MODULE=providers` and fix any formatting issues
- [x] 7.2 Run `task vet MODULE=providers` and resolve any unification errors
- [x] 7.3 Run `task eval MODULE=providers` to verify evaluated output is correct
