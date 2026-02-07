## 1. Wire existing traits into workload transformers

- [ ] 1.1 Add `#HealthCheckTrait` as optional trait on Deployment, StatefulSet, DaemonSet transformers (already listed but not wired)
- [ ] 1.2 Extract `healthCheck` from component spec and emit `livenessProbe`/`readinessProbe` on the main container in Deployment transformer
- [ ] 1.3 Apply same HealthCheck wiring to StatefulSet transformer
- [ ] 1.4 Apply same HealthCheck wiring to DaemonSet transformer
- [ ] 1.5 Add `#ResourceLimitTrait` as optional trait on Deployment, StatefulSet, DaemonSet, Job, CronJob transformers
- [ ] 1.6 Extract `resourceLimit` from component spec and emit `resources` (requests/limits) on the main container in Deployment transformer
- [ ] 1.7 Apply same ResourceLimit wiring to StatefulSet, DaemonSet, Job, CronJob transformers
- [ ] 1.8 Add `#SecurityContextTrait` as optional trait on all workload transformers (Deployment, StatefulSet, DaemonSet, Job, CronJob)
- [ ] 1.9 Extract `securityContext` and emit pod-level fields (`runAsNonRoot`, `runAsUser`, `runAsGroup`) and container-level fields (`readOnlyRootFilesystem`, `allowPrivilegeEscalation`, `capabilities`) in Deployment transformer
- [ ] 1.10 Apply same SecurityContext wiring to StatefulSet, DaemonSet, Job, CronJob transformers
- [ ] 1.11 Add test components with HealthCheck, ResourceLimit, and SecurityContext to `test_data.cue`
- [ ] 1.12 Verify existing test data still validates unchanged (`task vet MODULE=providers`)

## 2. ConfigMap transformer

- [ ] 2.1 Create `providers/kubernetes/transformers/configmap_transformer.cue` with `#ConfigMapTransformer`
- [ ] 2.2 Set `requiredResources` to ConfigMap resource FQN, no requiredLabels/requiredTraits
- [ ] 2.3 Implement `#transform` to emit `v1/ConfigMap` with data from resource spec
- [ ] 2.4 Add test component for ConfigMap to `test_data.cue`
- [ ] 2.5 Validate with `task vet MODULE=providers`

## 3. Secret transformer

- [ ] 3.1 Create `providers/kubernetes/transformers/secret_transformer.cue` with `#SecretTransformer`
- [ ] 3.2 Set `requiredResources` to Secret resource FQN, no requiredLabels/requiredTraits
- [ ] 3.3 Implement `#transform` to emit `v1/Secret` with type (default Opaque) and data from resource spec
- [ ] 3.4 Add test component for Secret to `test_data.cue`
- [ ] 3.5 Validate with `task vet MODULE=providers`

## 4. ServiceAccount transformer

- [ ] 4.1 Create `providers/kubernetes/transformers/serviceaccount_transformer.cue` with `#ServiceAccountTransformer`
- [ ] 4.2 Set `requiredResources` to WorkloadIdentity resource FQN
- [ ] 4.3 Implement `#transform` to emit `v1/ServiceAccount` with name from WorkloadIdentity and `automountServiceAccountToken` from spec
- [ ] 4.4 Add WorkloadIdentity as optional resource on Deployment, StatefulSet, DaemonSet, Job, CronJob transformers
- [ ] 4.5 Wire `serviceAccountName` into workload transformer pod spec when WorkloadIdentity is present
- [ ] 4.6 Add test component for ServiceAccount to `test_data.cue`
- [ ] 4.7 Validate with `task vet MODULE=providers`

## 5. NetworkPolicy transformer

- [ ] 5.1 Create `providers/kubernetes/transformers/networkpolicy_transformer.cue` with `#NetworkPolicyTransformer`
- [ ] 5.2 Implement matching mechanism for components with network rule configuration
- [ ] 5.3 Implement `#transform` to emit `networking.k8s.io/v1/NetworkPolicy` with podSelector from component labels, policyTypes, and ingress/egress rules
- [ ] 5.4 Handle `denyAll: true` case (empty ingress/egress arrays)
- [ ] 5.5 Add test component for NetworkPolicy to `test_data.cue`
- [ ] 5.6 Validate with `task vet MODULE=providers`

## 6. HPA transformer

- [ ] 6.1 Create `providers/kubernetes/transformers/hpa_transformer.cue` with `#HPATransformer`
- [ ] 6.2 Set `requiredTraits` to Replication trait FQN
- [ ] 6.3 Implement `#transform` to emit `autoscaling/v2/HorizontalPodAutoscaler` when `replication.auto` is present
- [ ] 6.4 Map `auto.min` → `minReplicas`, `auto.max` → `maxReplicas`, `auto.metrics` → `spec.metrics`
- [ ] 6.5 Set `scaleTargetRef` based on component workload type (Deployment or StatefulSet)
- [ ] 6.6 Handle optional `behavior` field for stabilization windows
- [ ] 6.7 Update Deployment and StatefulSet transformers to use `replication.auto.min` as `spec.replicas` when `auto` is present
- [ ] 6.8 Add test component for HPA to `test_data.cue`
- [ ] 6.9 Validate with `task vet MODULE=providers`

## 7. Ingress transformer

- [ ] 7.1 Create `providers/kubernetes/transformers/ingress_transformer.cue` with `#IngressTransformer`
- [ ] 7.2 Set `requiredTraits` to HttpRoute trait FQN only (no Expose, no Ingress trait)
- [ ] 7.3 Implement `#transform` to emit `networking.k8s.io/v1/Ingress` with rules from HttpRoute and backend service name from `#context.name`, backend port from `backendPort`
- [ ] 7.4 Map `httpRoute.hostnames` to Ingress `rules[].host`, route `rules[].matches[].path` to Ingress paths
- [ ] 7.5 Handle TLS configuration from `httpRoute.tls` (via `#RouteAttachmentSchema`) — map `certificateRef.name` to `secretName`, `hostnames` to `tls[].hosts`
- [ ] 7.6 Handle `className` from `httpRoute.className` (via `#RouteAttachmentSchema`) → `spec.ingressClassName`
- [ ] 7.7 Default `pathType` to `"Prefix"` when not specified
- [ ] 7.8 Add test component for Ingress to `test_data.cue`
- [ ] 7.9 Validate with `task vet MODULE=providers`

## 8. Provider registration and final validation

- [ ] 8.1 Register all new transformers in `providers/kubernetes/provider.cue` transformers map with valid FQN keys
- [ ] 8.2 Run `task fmt` across all modules
- [ ] 8.3 Run `task vet` across all modules
- [ ] 8.4 Run `task eval MODULE=providers` to verify output structure
