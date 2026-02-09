## 1. Wire existing traits into workload transformers

**Files modified**: `deployment_transformer.cue`, `statefulset_transformer.cue`, `daemonset_transformer.cue`, `job_transformer.cue`, `cronjob_transformer.cue`, `test_data.cue`

**Import needed**: All 5 workload transformers need `security_traits "opmodel.dev/traits/security@v0"` for `#SecurityContextTrait`.

**Wiring pattern**: Current transformers pass `_containers` as a flat list. To add probes/resources/securityContext to only the main container (index 0), change output construction from `containers: _containers` to building the main container inline with conditional fields, then concatenating sidecars.

- [x] 1.1 Add `#HealthCheckTrait` as optional trait on Deployment, StatefulSet, DaemonSet transformers (already listed but not wired)
- [x] 1.2 Extract `healthCheck` from component spec and emit `livenessProbe`/`readinessProbe` on the main container in Deployment transformer
- [x] 1.3 Apply same HealthCheck wiring to StatefulSet transformer
- [x] 1.4 Apply same HealthCheck wiring to DaemonSet transformer
- [x] 1.5 Add `#SizingTrait` as optional trait on Deployment, StatefulSet, DaemonSet, Job, CronJob transformers
- [x] 1.6 Extract `sizing` from component spec and emit `resources` (requests/limits) on the main container in Deployment transformer
- [x] 1.7 Apply same Sizing wiring to StatefulSet, DaemonSet, Job, CronJob transformers
- [x] 1.8 Add `#SecurityContextTrait` as optional trait on all workload transformers (Deployment, StatefulSet, DaemonSet, Job, CronJob)
      - FQN: `opmodel.dev/traits/security@v0#SecurityContext` (note: `security` package, not `workload`)
- [x] 1.9 Extract `securityContext` and emit pod-level fields (`runAsNonRoot`, `runAsUser`, `runAsGroup`) and container-level fields (`readOnlyRootFilesystem`, `allowPrivilegeEscalation`, `capabilities`) in Deployment transformer
- [x] 1.10 Apply same SecurityContext wiring to StatefulSet, DaemonSet, Job, CronJob transformers
- [x] 1.11 Add test components with HealthCheck, Sizing, and SecurityContext to `test_data.cue`
      - Add `_testComponentWithTraits` (stateless component with `healthCheck`, `sizing`, `securityContext` populated)
      - Add `_testDeploymentWithTraits` validation using the transformer
- [x] 1.12 Verify existing test data still validates unchanged (`task vet MODULE=providers`)

## 2. ConfigMap transformer

**Files created**: `configmap_transformer.cue`
**Import**: `config_resources "opmodel.dev/resources/config@v0"`

- [x] 2.1 Create `providers/kubernetes/transformers/configmap_transformer.cue` with `#ConfigMapTransformer`
- [x] 2.2 Set `requiredResources` to `"opmodel.dev/resources/config@v0#ConfigMap": config_resources.#ConfigMapResource`, no requiredLabels/requiredTraits
- [x] 2.3 Implement `#transform` to emit `v1/ConfigMap` — extract `#component.spec.configMap`, emit `metadata` from `#context`, `data` from resource spec
- [x] 2.4 Add test component `_testConfigMapComponent` with ConfigMap resource to `test_data.cue`, add `_testConfigMapTransformer` validation
- [x] 2.5 Validate with `task vet MODULE=providers`

## 3. Secret transformer

**Files created**: `secret_transformer.cue`
**Import**: `config_resources "opmodel.dev/resources/config@v0"` (same as ConfigMap)

- [x] 3.1 Create `providers/kubernetes/transformers/secret_transformer.cue` with `#SecretTransformer`
- [x] 3.2 Set `requiredResources` to `"opmodel.dev/resources/config@v0#Secret": config_resources.#SecretResource`, no requiredLabels/requiredTraits
- [x] 3.3 Implement `#transform` to emit `v1/Secret` — extract `#component.spec.secret`, emit with `type` (default `"Opaque"` from schema defaults) and `data`
- [x] 3.4 Add test component `_testSecretComponent` and `_testSecretTransformer` to `test_data.cue`
- [x] 3.5 Validate with `task vet MODULE=providers`

## 4. ServiceAccount transformer

**Files created**: `serviceaccount_transformer.cue`
**Files modified**: All 5 workload transformers, `test_data.cue`
**Import**: `security_resources "opmodel.dev/resources/security@v0"`

- [x] 4.1 Create `providers/kubernetes/transformers/serviceaccount_transformer.cue` with `#ServiceAccountTransformer`
- [x] 4.2 Set `requiredResources` to `"opmodel.dev/resources/security@v0#WorkloadIdentity": security_resources.#WorkloadIdentityResource`
- [x] 4.3 Implement `#transform` to emit `v1/ServiceAccount` — extract `#component.spec.workloadIdentity`, emit with `automountServiceAccountToken` from spec
- [x] 4.4 Add WorkloadIdentity as optional resource on Deployment, StatefulSet, DaemonSet, Job, CronJob transformers
      - Import `security_resources "opmodel.dev/resources/security@v0"` in each
      - Add `"opmodel.dev/resources/security@v0#WorkloadIdentity": security_resources.#WorkloadIdentityResource` to `optionalResources`
- [x] 4.5 Wire `serviceAccountName` into workload transformer pod spec when `#component.spec.workloadIdentity != _|_`
- [x] 4.6 Add test component `_testServiceAccountComponent` and `_testServiceAccountTransformer` to `test_data.cue`
- [x] 4.7 Validate with `task vet MODULE=providers`

## 5. HPA transformer

**Files created**: `hpa_transformer.cue`
**Files modified**: `deployment_transformer.cue`, `statefulset_transformer.cue`, `test_data.cue`

**Decision**: Read `core.opmodel.dev/workload-type` label from `#component.metadata.labels` inside `#transform`, map `"stateless"` → `"Deployment"`, `"stateful"` → `"StatefulSet"` for `scaleTargetRef.kind`.

- [x] 5.1 Create `providers/kubernetes/transformers/hpa_transformer.cue` with `#HPATransformer`
- [x] 5.2 Set `requiredTraits` to `"opmodel.dev/traits/workload@v0#Scaling": workload_traits.#ScalingTrait`
- [x] 5.3 Implement `#transform` to emit `autoscaling/v2/HorizontalPodAutoscaler` when `#component.spec.scaling.auto != _|_`; emit empty struct when `auto` is absent
- [x] 5.4 Map `auto.min` → `minReplicas`, `auto.max` → `maxReplicas`, `auto.metrics` → `spec.metrics`
      - Metric type mapping: `"cpu"` → `Resource` with `name: "cpu"`, `"memory"` → `Resource` with `name: "memory"`, `"custom"` → `Pods` with metric name from `metricName`
- [x] 5.5 Set `scaleTargetRef` by reading `#component.metadata.labels["core.opmodel.dev/workload-type"]` and mapping to K8s kind
- [x] 5.6 Handle optional `behavior` field — conditionally include `spec.behavior` from `auto.behavior`
- [x] 5.7 Update Deployment and StatefulSet transformers to use `scaling.auto.min` as `spec.replicas` when `#component.spec.scaling.auto != _|_`
- [x] 5.8 Add test component `_testHPAComponent` (stateless with `scaling.auto` config) and `_testHPATransformer` to `test_data.cue`
- [x] 5.9 Validate with `task vet MODULE=providers`

## 6. Ingress transformer

**Files created**: `ingress_transformer.cue`
**Import**: `network_traits "opmodel.dev/traits/network@v0"` (same as service transformer)

**Note on backend service name**: Service transformer uses `#component.metadata.name` for the Service name. The Ingress backend must reference the same name — use `#component.metadata.name`, not `#context.name`.

- [x] 6.1 Create `providers/kubernetes/transformers/ingress_transformer.cue` with `#IngressTransformer`
- [x] 6.2 Set `requiredTraits` to `"opmodel.dev/traits/network@v0#HttpRoute": network_traits.#HttpRouteTrait` only (no Expose, no Ingress trait)
- [x] 6.3 Implement `#transform` to emit `networking.k8s.io/v1/Ingress` — extract `#component.spec.httpRoute`, backend service name from `#component.metadata.name`, backend port from `backendPort`
- [x] 6.4 Map `httpRoute.hostnames` to Ingress `rules[].host` (omit `host` field if no hostnames), route `rules[].matches[].path` to Ingress paths
- [x] 6.5 Handle TLS configuration from `httpRoute.tls` (via `#RouteAttachmentSchema`) — map `certificateRef.name` to `secretName`, `hostnames` to `tls[].hosts`
- [x] 6.6 Handle `ingressClassName` from `httpRoute.ingressClassName` (via `#RouteAttachmentSchema`) → `spec.ingressClassName`
- [x] 6.7 Default `pathType` to `"Prefix"` (already the schema default for `#HttpRouteMatchSchema.path.type`)
- [x] 6.8 Add test component `_testIngressComponent` (with HttpRoute trait, hostnames, rules) and `_testIngressTransformer` to `test_data.cue`
- [x] 6.9 Validate with `task vet MODULE=providers`

## 7. Provider registration and final validation

**Files modified**: `provider.cue`

- [x] 7.1 Register all 5 new transformers in `providers/kubernetes/provider.cue` transformers map with FQN keys: `#ConfigMapTransformer`, `#SecretTransformer`, `#ServiceAccountTransformer`, `#HPATransformer`, `#IngressTransformer`
- [x] 7.2 Run `task fmt` across all modules
- [x] 7.3 Run `task vet` across all modules
- [x] 7.4 Run `task eval MODULE=providers` to verify output structure
