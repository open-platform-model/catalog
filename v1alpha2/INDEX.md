# v1alpha2 — Definition Index

This directory contains three independent CUE modules. Each module has its own `cue.mod/` and is
published separately. The `opm/` module depends on `gateway_api/` and `cert_manager/` as external
dependencies; it does not embed them.

| Module | CUE module path | Status |
|---|---|---|
| `opm/` | `opmodel.dev@v1` | Existing — core OPM definitions |
| `gateway_api/` | `opmodel.dev/gateway-api@v1` | Docs only — types vendored into `opm/cue.mod/gen/` via timoni |
| `cert_manager/` | `opmodel.dev/cert-manager@v1` | Complete — re-exports from `cue.dev/x/crd/cert-manager.io@v0` |
| `kubernetes/` | — | Deferred — not in scope for this cycle |

---

## Project Structure

```text
v1alpha2/
├── opm/                         # Core OPM definitions (opmodel.dev@v1)
│   ├── core/                    # Core OPM definition types
│   │   ├── types/               # Shared primitive types and regex constraints
│   │   ├── primitives/          # Resource, Trait, Blueprint, PolicyRule base types
│   │   ├── component/           # #Component — deployable unit
│   │   ├── transformer/         # #Transformer, #TransformerContext
│   │   ├── policy/              # #Policy
│   │   ├── module/              # #Module
│   │   ├── modulerelease/       # #ModuleRelease
│   │   ├── bundle/              # #Bundle
│   │   ├── provider/            # #Provider
│   │   ├── helpers/             # Internal helpers (e.g. auto-secrets wiring)
│   │   ├── bundlerelease/       # #BundleRelease
│   │   └── matcher/             # #MatchResult, #MatchPlan
│   ├── schemas/                 # Shared field schemas (reused across definitions)
│   │   └── kubernetes/          # Mirrored Kubernetes API types (transformer targets)
│   ├── resources/               # Resource implementations
│   │   ├── config/              # ConfigMap, Secret
│   │   ├── extension/           # CRD
│   │   ├── network/             # Gateway, GatewayClass, ReferenceGrant, BackendTrafficPolicy
│   │   ├── security/            # ServiceAccount, Role, Certificate, Issuer, ClusterIssuer
│   │   ├── storage/             # Volume
│   │   └── workload/            # Container
│   ├── traits/                  # Trait implementations
│   │   ├── network/             # Expose, HttpRoute, GrpcRoute, TcpRoute, TlsRoute
│   │   ├── security/            # SecurityContext, WorkloadIdentity, Encryption
│   │   └── workload/            # Scaling, Sizing, UpdateStrategy, Placement, ...
│   ├── blueprints/              # Blueprint implementations
│   │   ├── data/                # SimpleDatabase
│   │   └── workload/            # Stateless, Stateful, Daemon, Task, ScheduledTask
│   ├── providers/               # Provider implementations
│   │   └── kubernetes/          # Kubernetes provider + transformers
│   └── examples/                # Concrete usage examples (no exported definitions)
├── gateway_api/                 # Gateway API CUE types (opmodel.dev/gateway-api@v1) [planned]
│   ├── crds/                    # Downloaded CRD YAML (reference copy, not imported)
│   ├── v1/                      # GA resource types
│   └── v1alpha2/                # Experimental resource types
├── cert_manager/                # cert-manager CUE types (opmodel.dev/cert-manager@v1) [planned]
│   └── v1/                      # cert-manager v1 resource types
└── kubernetes/                  # Kubernetes-native types [deferred]
```

---

## Core

Base definition types that form the OPM type system. Each construct lives in its own subpackage under `opm/core/`.

### `opm/core/types/`

| Definition | Description |
|---|---|
| `#LabelsAnnotationsType` | Type for labels and annotations |
| `#NameType` | RFC 1123 DNS label type |
| `#FQNType` | Primitive definition FQN type |
| `#VersionType` | Semantic version type |
| `#ModulePathType` | Registry path type |
| `#MajorVersionType` | Major version type |
| `#ModuleFQNType` | Module FQN type |
| `#BundleFQNType` | Bundle FQN type |
| `#UUIDType` | RFC 4122 UUID type |
| `OPMNamespace` | OPM namespace UUID constant |
| `#KebabToPascal` | Kebab-to-PascalCase converter |

### `opm/core/primitives/`

| Definition | Description |
|---|---|
| `#Resource` | Deployable resource definition with FQN, metadata, and OpenAPIv3-compatible spec |
| `#Trait` | Additional behavior attachable to components, with `appliesTo` constraints |
| `#Blueprint` | Reusable composition of resources and traits into a higher-level abstraction |
| `#PolicyRule` | Governance rule encoding security, compliance, or operational guardrails |

### `opm/core/component/`

| Definition | Description |
|---|---|
| `#Component` | Deployable unit composing resources, traits, and blueprints into a closed spec |

### `opm/core/transformer/`

| Definition | Description |
|---|---|
| `#Transformer` | Converts OPM components to platform-specific resources via label/resource/trait matching |
| `#TransformerContext` | Provider context injected into each transformer at render time |

### `opm/core/policy/`

| Definition | Description |
|---|---|
| `#Policy` | Groups policy rules and targets them to components via label matching or explicit refs |

### `opm/core/module/`

| Definition | Description |
|---|---|
| `#Module` | Portable application blueprint containing components, policies, and a config schema |

### `opm/core/modulerelease/`

| Definition | Description |
|---|---|
| `#ModuleRelease` | Concrete deployment instance binding a module to values and a target namespace |

### `opm/core/bundle/`

| Definition | Description |
|---|---|
| `#Bundle` | Collection of modules grouped for distribution |
| `#BundleInstance` | Single module instance within a bundle |
| `#BundleDefinitionMap` | Bundle map type |

### `opm/core/bundlerelease/`

| Definition | Description |
|---|---|
| `#BundleRelease` | Concrete deployment instance binding a bundle to values and a target namespace |
| `#BundleReleaseMap` | BundleRelease map type |

### `opm/core/provider/`

| Definition | Description |
|---|---|
| `#Provider` | Provider definition with a transformer registry for converting OPM components to platform resources |

### `opm/core/helpers/`

| Definition | Description |
|---|---|
| `#OpmSecretsComponent` | Builds the auto-generated `opm-secrets` component from discovered `#Secret` fields |
| `#SecretsResourceFQN` | Canonical FQN for the secrets resource (must stay in sync with `opm/resources/config/secret.cue`) |

### `opm/core/matcher/`

| Definition | Description |
|---|---|
| `#MatchResult` | Single (component, transformer) match result |
| `#MatchPlan` | Full component × transformer matching plan |

---

## Schemas

Reusable field schemas shared across resource and trait definitions.

### `opm/schemas/common.cue`

| Definition | Description |
|---|---|
| `#NameType`, `#LabelsAnnotationsSchema`, `#VersionSchema` | Primitive name, label/annotation, and version field schemas |

### `opm/schemas/config.cue`

| Definition | Description |
|---|---|
| `#Secret` / `#SecretLiteral` / `#SecretK8sRef` | Discriminated union for secret sources (literal, K8s ref) |
| `#SecretSchema` / `#ConfigMapSchema` | Field schemas for Secret and ConfigMap resources |
| `#ContentHash` / `#SecretContentHash` | Content-hash based immutable naming helpers |
| `#DiscoverSecrets` / `#GroupSecrets` / `#AutoSecrets` | Auto-discovery pipeline for extracting secrets from component specs |

### `opm/schemas/data.cue`

| Definition | Description |
|---|---|
| `#SimpleDatabaseSchema` | Schema for a simple database (postgres / mysql / mongodb / redis) with optional persistence |

### `opm/schemas/extension.cue`

| Definition | Description |
|---|---|
| `#CRDSchema` / `#CRDVersionSchema` | Kubernetes CRD definition schemas for vendoring operator CRDs |

### `opm/schemas/network.cue`

| Definition | Description |
|---|---|
| `#PortSchema` / `#IANA_SVC_NAME` | Port definition with name, number, and protocol |
| `#ExposeSchema` | Service exposure spec with typed port mappings |
| `#NetworkRuleSchema` / `#SharedNetworkSchema` | Network policy and shared-network schemas |
| `#HttpRouteSchema` / `#HttpRouteRuleSchema` / `#HttpRouteMatchSchema` | HTTP routing: matches, rules, and full route spec |
| `#GrpcRouteSchema` / `#GrpcRouteRuleSchema` / `#GrpcRouteMatchSchema` | gRPC routing: matches, rules, and full route spec |
| `#TcpRouteSchema` / `#TcpRouteRuleSchema` | TCP port-forwarding route spec |
| `#RouteHeaderMatch` / `#RouteRuleBase` / `#RouteAttachmentSchema` | Shared route primitives (header matching, gateway attachment) |

### `opm/schemas/quantity.cue`

| Definition | Description |
|---|---|
| `#NormalizeCPU` / `#NormalizeMemory` | Normalize CPU and memory values to Kubernetes canonical formats |

### `opm/schemas/security.cue`

| Definition | Description |
|---|---|
| `#WorkloadIdentitySchema` | Service account / workload identity for pod authentication |
| `#ServiceAccountSchema` | Standalone service account identity (name, automountToken) |
| `#PolicyRuleSchema` | Single RBAC permission rule (apiGroups, resources, verbs) |
| `#RoleSubjectSchema` | Role subject — embeds a WorkloadIdentity or ServiceAccount via CUE reference |
| `#RoleSchema` | RBAC role with scope (namespace/cluster), rules, and CUE-referenced subjects |
| `#SecurityContextSchema` | Pod and container security constraints (runAsNonRoot, privilege escalation, capabilities) |
| `#EncryptionConfigSchema` | At-rest and in-transit encryption requirements |

### `opm/schemas/storage.cue`

| Definition | Description |
|---|---|
| `#VolumeSchema` | Volume definition supporting multiple source types |
| `#VolumeMountSchema` | Mount path and options for attaching a volume to a container |
| `#EmptyDirSchema` / `#HostPathSchema` / `#PersistentClaimSchema` / `#NFSVolumeSourceSchema` | Concrete volume source schemas; use `persistentClaim` with `storageClass: "smb"` and `accessMode: "ReadWriteMany"` for CIFS/SMB volumes |
| `#FileMode` | File permission mode type |
| `#SecretVolumeItemSchema` | Secret volume item schema |
| `#SecretVolumeSourceSchema` | Secret volume source schema |

### `opm/schemas/workload.cue`

| Definition | Description |
|---|---|
| `#ContainerSchema` / `#Image` | Container definition with image, command, args, ports, env, probes, and mounts |
| `#EnvVarSchema` / `#EnvFromSource` / `#FieldRefSchema` / `#ResourceFieldRefSchema` | Environment variable sources (literal, configMap, secret, field ref) |
| `#ResourceRequirementsSchema` | CPU and memory requests/limits |
| `#ProbeSchema` | Liveness, readiness, and startup probe spec |
| `#ScalingSchema` / `#AutoscalingSpec` / `#MetricSpec` / `#MetricTargetSpec` | Horizontal scaling: replica count and HPA autoscaling metrics |
| `#SizingSchema` / `#VerticalScalingSchema` | Vertical resource sizing (CPU/memory) |
| `#RestartPolicySchema` | Container restart policy (Always / OnFailure / Never) |
| `#UpdateStrategySchema` | Rollout update strategy (RollingUpdate / Recreate / OnDelete) |
| `#InitContainersSchema` / `#SidecarContainersSchema` | Init and sidecar container list schemas |
| `#JobConfigSchema` / `#CronJobConfigSchema` | Job completions/parallelism and CronJob schedule/concurrency |
| `#StatelessWorkloadSchema` | Full schema for a stateless (Deployment) workload |
| `#StatefulWorkloadSchema` | Full schema for a stateful (StatefulSet) workload |
| `#DaemonWorkloadSchema` | Full schema for a daemon (DaemonSet) workload |
| `#TaskWorkloadSchema` | Full schema for a one-time task (Job) workload |
| `#ScheduledTaskWorkloadSchema` | Full schema for a cron-scheduled (CronJob) workload |
| `#DisruptionBudgetSchema` | Availability constraints during voluntary disruptions |
| `#GracefulShutdownSchema` | Termination grace period and pre-stop hook |
| `#PlacementSchema` | Zone/region/host spreading and node selector requirements |

---

## Resources

Concrete resource definitions that can be attached to components.
Each follows the triple pattern: `#XxxResource` (definition) · `#Xxx` (mixin) · `#XxxDefaults` (defaults).

| Definition | File | Description |
|---|---|---|
| `#ContainerResource` | `opm/resources/workload/container.cue` | Core workload resource: a container image definition requiring a workload-type label |
| `#ConfigMapsResource` | `opm/resources/config/configmap.cue` | External key/value configuration via ConfigMaps |
| `#SecretsResource` | `opm/resources/config/secret.cue` | Sensitive configuration via Secrets (literal, K8s ref, or ESO) |
| `#VolumesResource` | `opm/resources/storage/volume.cue` | Persistent and ephemeral volume storage |
| `#CRDsResource` | `opm/resources/extension/crd.cue` | Kubernetes CustomResourceDefinitions for vendoring operator CRDs |
| `#ServiceAccountResource` | `opm/resources/security/service_account.cue` | Standalone service account identity (independent of WorkloadIdentity trait) |
| `#RoleResource` | `opm/resources/security/role.cue` | RBAC Role with rules and CUE-referenced subjects; collapses k8s Role/ClusterRole + RoleBinding/ClusterRoleBinding |

---

## Traits

Behavioral extensions attachable to components.
Each follows the triple pattern: `#XxxTrait` (definition) · `#Xxx` (mixin) · `#XxxDefaults` (defaults).

### Network

| Definition | File | Description |
|---|---|---|
| `#ExposeTrait` | `opm/traits/network/expose.cue` | Expose a workload via a Kubernetes Service with typed port mappings |
| `#HttpRouteTrait` | `opm/traits/network/http_route.cue` | HTTP routing rules (Gateway API / Ingress) |
| `#GrpcRouteTrait` | `opm/traits/network/grpc_route.cue` | gRPC routing rules (Gateway API / Ingress) |
| `#TcpRouteTrait` | `opm/traits/network/tcp_route.cue` | TCP port-forwarding rules |
| `#HostNetworkTrait` | `opm/traits/network/host_network.cue` | Shares the node's network namespace with the pod |
| `#HostNetwork` | `opm/traits/network/host_network.cue` | HostNetwork component mixin |

### Security

| Definition | File | Description |
|---|---|---|
| `#SecurityContextTrait` | `opm/traits/security/security_context.cue` | Container and pod-level security constraints |
| `#WorkloadIdentityTrait` | `opm/traits/security/workload_identity.cue` | Service account / workload identity for pod authentication |
| `#EncryptionConfigTrait` | `opm/traits/security/encryption.cue` | At-rest and in-transit encryption requirements |

### Workload

| Definition | File | Description |
|---|---|---|
| `#ScalingTrait` | `opm/traits/workload/scaling.cue` | Horizontal scaling: replica count and optional HPA autoscaling |
| `#SizingTrait` | `opm/traits/workload/sizing.cue` | Vertical sizing: CPU and memory requests/limits |
| `#UpdateStrategyTrait` | `opm/traits/workload/update_strategy.cue` | Rollout update strategy (RollingUpdate / Recreate / OnDelete) |
| `#PlacementTrait` | `opm/traits/workload/placement.cue` | Zone/region/host spreading and node selector requirements |
| `#RestartPolicyTrait` | `opm/traits/workload/restart_policy.cue` | Container restart policy (Always / OnFailure / Never) |
| `#InitContainersTrait` | `opm/traits/workload/init_containers.cue` | Init containers to run before the main container starts |
| `#SidecarContainersTrait` | `opm/traits/workload/sidecar_containers.cue` | Sidecar containers injected alongside the main workload |
| `#DisruptionBudgetTrait` | `opm/traits/workload/disruption_budget.cue` | Availability constraints during voluntary disruptions |
| `#GracefulShutdownTrait` | `opm/traits/workload/graceful_shutdown.cue` | Termination grace period and pre-stop lifecycle hooks |
| `#JobConfigTrait` | `opm/traits/workload/job_config.cue` | Job settings: completions, parallelism, backoff, deadlines, TTL |
| `#CronJobConfigTrait` | `opm/traits/workload/cron_job_config.cue` | CronJob settings: schedule, concurrency policy, history limits |

---

## Blueprints

Higher-level abstractions composing resources and traits into opinionated workload patterns.
Each follows the pair pattern: `#XxxBlueprint` (definition) · `#Xxx` (mixin).

### Data

| Definition | File | Description |
|---|---|---|
| `#SimpleDatabaseBlueprint` | `opm/blueprints/data/simple_database.cue` | Opinionated stateful database (postgres / mysql / mongodb / redis) with auto-wired persistence and readiness probes |

### Workload

| Definition | File | Description |
|---|---|---|
| `#StatelessWorkloadBlueprint` | `opm/blueprints/workload/stateless_workload.cue` | Stateless workload with no stable identity or persistent storage (Deployment) |
| `#StatefulWorkloadBlueprint` | `opm/blueprints/workload/stateful_workload.cue` | Stateful workload with stable identity and persistent storage (StatefulSet) |
| `#DaemonWorkloadBlueprint` | `opm/blueprints/workload/daemon_workload.cue` | Daemon workload running on all (or selected) nodes (DaemonSet) |
| `#TaskWorkloadBlueprint` | `opm/blueprints/workload/task_workload.cue` | One-time task workload that runs to completion (Job) |
| `#ScheduledTaskWorkloadBlueprint` | `opm/blueprints/workload/scheduled_task_workload.cue` | Cron-scheduled task workload (CronJob) |

---

## Providers

Provider and transformer definitions for converting OPM components to platform resources.

### Registry

| Definition | File | Description |
|---|---|---|
| `#Registry` | `opm/providers/registry.cue` | Top-level provider registry mapping provider names to provider definitions |

### Kubernetes Provider

| Definition | File | Description |
|---|---|---|
| `#Provider` | `opm/providers/kubernetes/provider.cue` | Kubernetes provider registering all K8s transformers |

### Kubernetes Transformers

| Definition | File | Description |
|---|---|---|
| `#DeploymentTransformer` | `opm/providers/kubernetes/transformers/deployment_transformer.cue` | Converts stateless workload components to Kubernetes Deployments |
| `#StatefulsetTransformer` | `opm/providers/kubernetes/transformers/statefulset_transformer.cue` | Converts stateful workload components to Kubernetes StatefulSets |
| `#DaemonSetTransformer` | `opm/providers/kubernetes/transformers/daemonset_transformer.cue` | Converts daemon workload components to Kubernetes DaemonSets |
| `#JobTransformer` | `opm/providers/kubernetes/transformers/job_transformer.cue` | Converts task workload components to Kubernetes Jobs |
| `#CronJobTransformer` | `opm/providers/kubernetes/transformers/cronjob_transformer.cue` | Converts scheduled task components to Kubernetes CronJobs |
| `#ServiceTransformer` | `opm/providers/kubernetes/transformers/service_transformer.cue` | Creates Kubernetes Services from components with the Expose trait |
| `#IngressTransformer` | `opm/providers/kubernetes/transformers/ingress_transformer.cue` | Converts HttpRoute trait to Kubernetes Ingress |
| `#HPATransformer` | `opm/providers/kubernetes/transformers/hpa_transformer.cue` | Converts Scaling autoscaling config to Kubernetes HorizontalPodAutoscalers |
| `#ConfigMapTransformer` | `opm/providers/kubernetes/transformers/configmap_transformer.cue` | Converts ConfigMaps resources to Kubernetes ConfigMaps (with content-hash naming) |
| `#SecretTransformer` | `opm/providers/kubernetes/transformers/secret_transformer.cue` | Converts Secrets resources to Kubernetes Secrets |
| `#PVCTransformer` | `opm/providers/kubernetes/transformers/pvc_transformer.cue` | Creates PersistentVolumeClaims from Volume resources |
| `#CRDTransformer` | `opm/providers/kubernetes/transformers/crd_transformer.cue` | Converts CRDs resources to Kubernetes CustomResourceDefinitions |
| `#ServiceAccountTransformer` | `opm/providers/kubernetes/transformers/serviceaccount_transformer.cue` | Converts WorkloadIdentity traits to Kubernetes ServiceAccounts |
| `#ServiceAccountResourceTransformer` | `opm/providers/kubernetes/transformers/sa_resource_transformer.cue` | Converts standalone ServiceAccount resources to Kubernetes ServiceAccounts |
| `#RoleTransformer` | `opm/providers/kubernetes/transformers/role_transformer.cue` | Converts Role resources to k8s Role+RoleBinding or ClusterRole+ClusterRoleBinding |
| `#ToK8sContainer` / `#ToK8sContainers` / `#ToK8sVolumes` | `opm/providers/kubernetes/transformers/container_helpers.cue` | Shared helpers converting OPM container/volume schemas to Kubernetes list format |
| `#ToK8sServiceAccount` | `opm/providers/kubernetes/transformers/sa_helpers.cue` | Shared helper converting an OPM identity spec (WorkloadIdentity or ServiceAccount) to a Kubernetes ServiceAccount |

---

## Gateway API Extension Module [planned]

CUE module: `opmodel.dev/gateway-api@v1`  
Source: `catalog/v1alpha2/gateway_api/`  
Implementation plan: `gateway_api/PLAN.md`

Provides type-safe CUE definitions for all Kubernetes Gateway API resources. Types are imported from
the official CRDs (experimental channel v1.5.1) using `cue import` and manually refined with
`#Definition` patterns and explicit constraints.

### `gateway_api/v1/` — GA resources

| Definition | API | Description |
|---|---|---|
| `#Gateway` | `gateway.networking.k8s.io/v1` | Load balancer resource; Istio auto-provisions a Deployment + Service per Gateway |
| `#GatewayClass` | `gateway.networking.k8s.io/v1` | Defines a class of Gateways managed by a specific controller |
| `#HTTPRoute` | `gateway.networking.k8s.io/v1` | Routes HTTP/HTTPS traffic to backends |
| `#GRPCRoute` | `gateway.networking.k8s.io/v1` | Routes gRPC traffic (GA since v1.1.0) |
| `#TLSRoute` | `gateway.networking.k8s.io/v1` | Routes TLS traffic by SNI hostname without terminating TLS (GA since v1.5.0) |
| `#ReferenceGrant` | `gateway.networking.k8s.io/v1` | Permits cross-namespace references between route and backend resources |
| `#BackendTLSPolicy` | `gateway.networking.k8s.io/v1` | Configures TLS origination from a Gateway to a backend Service |
| `#ListenerSet` | `gateway.networking.k8s.io/v1` | Allows application teams to add listeners to a shared Gateway (new in v1.5.0) |

### `gateway_api/v1alpha2/` — Experimental resources

| Definition | API | Description |
|---|---|---|
| `#TCPRoute` | `gateway.networking.k8s.io/v1alpha2` | Routes raw TCP connections; no L7 awareness |
| `#UDPRoute` | `gateway.networking.k8s.io/v1alpha2` | Routes UDP traffic |
| `#BackendTrafficPolicy` | `gateway.networking.k8s.io/v1alpha2` | Session persistence and retry policy targeting a Service backend |

### Planned OPM additions (Phases 3–8 of `PLAN.md`)

The following definitions will be added to the `opm/` module once the `gateway_api/` type module is
complete. They are listed here for cross-reference.

**New schemas** (`opm/schemas/network.cue`):

| Definition | Description |
|---|---|
| `#GatewaySchema` | Gateway spec: `gatewayClassName`, `listeners`, optional `addresses` and `infrastructure` |
| `#GatewayListenerSchema` | Individual listener: `name`, `hostname`, `port`, `protocol`, `tls`, `allowedRoutes` |
| `#GatewayAddressSchema` | Optional static address assignment |
| `#TlsRouteSchema` | TLS passthrough route spec; embeds `#RouteAttachmentSchema` |
| `#ReferenceGrantSchema` | Cross-namespace reference grant: `from` and `to` selector arrays |

**New resources** (`opm/resources/network/`):

| Definition | File | Description |
|---|---|---|
| `#GatewayResource` | `opm/resources/network/gateway.cue` | Gateway resource; default `gatewayClassName: "istio"` |
| `#GatewayClassResource` | `opm/resources/network/gateway_class.cue` | Custom GatewayClass resource; for non-Istio controllers or explicitly managed classes |
| `#ReferenceGrantResource` | `opm/resources/network/reference_grant.cue` | Cross-namespace reference grant resource |
| `#BackendTrafficPolicyResource` | `opm/resources/network/backend_traffic_policy.cue` | Backend traffic policy (session persistence, retries) targeting a Service |

**New trait** (`opm/traits/network/`):

| Definition | File | Description |
|---|---|---|
| `#TlsRouteTrait` | `opm/traits/network/tls_route.cue` | TLS passthrough routing rules (SNI-based, no termination) |

**New transformers** (`opm/providers/kubernetes/transformers/`):

| Definition | File | Output resource |
|---|---|---|
| `#GatewayTransformer` | `opm/providers/kubernetes/transformers/gateway_transformer.cue` | `gateway.networking.k8s.io/v1 Gateway` |
| `#HttpRouteTransformer` | `opm/providers/kubernetes/transformers/http_route_transformer.cue` | `gateway.networking.k8s.io/v1 HTTPRoute` |
| `#GrpcRouteTransformer` | `opm/providers/kubernetes/transformers/grpc_route_transformer.cue` | `gateway.networking.k8s.io/v1 GRPCRoute` |
| `#TcpRouteTransformer` | `opm/providers/kubernetes/transformers/tcp_route_transformer.cue` | `gateway.networking.k8s.io/v1alpha2 TCPRoute` |
| `#TlsRouteTransformer` | `opm/providers/kubernetes/transformers/tls_route_transformer.cue` | `gateway.networking.k8s.io/v1 TLSRoute` |
| `#ReferenceGrantTransformer` | `opm/providers/kubernetes/transformers/reference_grant_transformer.cue` | `gateway.networking.k8s.io/v1 ReferenceGrant` |
| `#GatewayClassTransformer` | `opm/providers/kubernetes/transformers/gateway_class_transformer.cue` | `gateway.networking.k8s.io/v1 GatewayClass` |
| `#BackendTrafficPolicyTransformer` | `opm/providers/kubernetes/transformers/backend_traffic_policy_transformer.cue` | `gateway.networking.k8s.io/v1alpha2 BackendTrafficPolicy` |

Note: `#IngressTransformer` will be removed when these transformers are registered. Gateway API is
the native routing mechanism on this cluster; Ingress is legacy.

---

## cert-manager Extension Module [planned]

CUE module: `opmodel.dev/cert-manager@v1`  
Source: `catalog/v1alpha2/cert_manager/`  
Implementation plan: `cert_manager/PLAN.md`

Provides type-safe CUE definitions for cert-manager v1 resources by consuming the official CUE
registry module at `cue.dev/x/crd/cert-manager.io`. Types are re-exported with constrained
`apiVersion` and `kind` fields.

### `cert_manager/v1/` — cert-manager v1 resources

| Definition | API | Description |
|---|---|---|
| `#Certificate` | `cert-manager.io/v1` | Declares a desired X.509 certificate; cert-manager creates the named Secret |
| `#CertificateSpec` | `cert-manager.io/v1` | Certificate spec sub-type |
| `#Issuer` | `cert-manager.io/v1` | Namespaced certificate-signing backend (ACME, CA, self-signed, Vault) |
| `#IssuerSpec` | `cert-manager.io/v1` | Issuer spec sub-type containing solver configurations |
| `#ClusterIssuer` | `cert-manager.io/v1` | Cluster-scoped issuer; same spec shape as `#Issuer` |
| `#ClusterIssuerSpec` | `cert-manager.io/v1` | ClusterIssuer spec sub-type |

### Planned OPM additions (Phases 3–7 of `PLAN.md`)

The following definitions will be added to the `opm/` module once the `cert_manager/` type module is
complete.

**New schemas** (`opm/schemas/security.cue`):

| Definition | Description |
|---|---|
| `#CertificateSchema` | Certificate spec: `secretName`, `issuerRef`, optional `dnsNames`, `duration`, `renewBefore`, `privateKey` |
| `#IssuerSchema` | Issuer spec: `acme`, `ca`, `selfSigned`, `vault` solver backends |
| `#ClusterIssuerSchema` | Same shape as `#IssuerSchema`; cluster-scoped variant |

**New resources** (`opm/resources/security/`):

| Definition | File | Description |
|---|---|---|
| `#CertificateResource` | `opm/resources/security/certificate.cue` | Explicit TLS certificate resource |
| `#IssuerResource` | `opm/resources/security/issuer.cue` | Namespaced certificate issuer resource |
| `#ClusterIssuerResource` | `opm/resources/security/cluster_issuer.cue` | Cluster-scoped certificate issuer resource |

**New transformers** (`opm/providers/kubernetes/transformers/`):

| Definition | File | Output resource |
|---|---|---|
| `#CertificateTransformer` | `opm/providers/kubernetes/transformers/certificate_transformer.cue` | `cert-manager.io/v1 Certificate` |
| `#IssuerTransformer` | `opm/providers/kubernetes/transformers/issuer_transformer.cue` | `cert-manager.io/v1 Issuer` |
| `#ClusterIssuerTransformer` | `opm/providers/kubernetes/transformers/cluster_issuer_transformer.cue` | `cert-manager.io/v1 ClusterIssuer` |

Note: cert-manager also integrates with `#GatewayTransformer` via annotations. When a Gateway
component has an `issuerRef` field set, the transformer emits `cert-manager.io/cluster-issuer`
or `cert-manager.io/issuer` on the output Gateway manifest. No separate `#Certificate` resource
is required in that flow — cert-manager auto-creates Certificates from Gateway TLS listeners.

---
