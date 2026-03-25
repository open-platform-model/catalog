# v1alpha1 — Definition Index

CUE module: `opmodel.dev/opm/v1alpha1@v1`

---

## Project Structure

```
+-- blueprints/
|   +-- data/
|   +-- workload/
+-- providers/
|   +-- kubernetes/
|       +-- transformers/
+-- resources/
|   +-- config/
|   +-- extension/
|   +-- network/
|   +-- security/
|   +-- storage/
|   +-- workload/
+-- schemas/
|   +-- kubernetes/
|       +-- apiextensions/
|       |   +-- v1/
|       +-- apps/
|       |   +-- v1/
|       +-- autoscaling/
|       |   +-- v2/
|       +-- batch/
|       |   +-- v1/
|       +-- certmanager/
|       |   +-- v1/
|       +-- core/
|       |   +-- v1/
|       +-- gateway/
|       +-- networking/
|           +-- v1/
+-- traits/
    +-- network/
    +-- security/
    +-- workload/
```

---

## Blueprints

### data

| Definition | File | Description |
|---|---|---|
| `#SimpleDatabase` | `blueprints/data/simple_database.cue` |  |
| `#SimpleDatabaseBlueprint` | `blueprints/data/simple_database.cue` |  |

### workload

| Definition | File | Description |
|---|---|---|
| `#DaemonWorkload` | `blueprints/workload/daemon_workload.cue` |  |
| `#DaemonWorkloadBlueprint` | `blueprints/workload/daemon_workload.cue` |  |
| `#ScheduledTaskWorkload` | `blueprints/workload/scheduled_task_workload.cue` |  |
| `#ScheduledTaskWorkloadBlueprint` | `blueprints/workload/scheduled_task_workload.cue` |  |
| `#StatefulWorkload` | `blueprints/workload/stateful_workload.cue` |  |
| `#StatefulWorkloadBlueprint` | `blueprints/workload/stateful_workload.cue` |  |
| `#StatelessWorkload` | `blueprints/workload/stateless_workload.cue` |  |
| `#StatelessWorkloadBlueprint` | `blueprints/workload/stateless_workload.cue` |  |
| `#TaskWorkload` | `blueprints/workload/task_workload.cue` |  |
| `#TaskWorkloadBlueprint` | `blueprints/workload/task_workload.cue` |  |

---

## Providers

| Definition | File | Description |
|---|---|---|
| `#Registry` | `providers/registry.cue` |  |

### kubernetes

| Definition | File | Description |
|---|---|---|
| `#Provider` | `providers/kubernetes/provider.cue` | KubernetesProvider transforms OPM components to Kubernetes native resources |

### kubernetes/transformers

| Definition | File | Description |
|---|---|---|
| `#ConfigMapTransformer` | `providers/kubernetes/transformers/configmap_transformer.cue` | ConfigMapTransformer converts ConfigMaps resources to Kubernetes ConfigMaps |
| `#ToK8sContainer` | `providers/kubernetes/transformers/container_helpers.cue` | #ToK8sContainer converts an OPM #ContainerSchema to a Kubernetes #Container |
| `#ToK8sContainers` | `providers/kubernetes/transformers/container_helpers.cue` | #ToK8sContainers converts a list of OPM containers to Kubernetes containers |
| `#ToK8sVolumes` | `providers/kubernetes/transformers/container_helpers.cue` | #ToK8sVolumes converts OPM volumes map to Kubernetes volumes list |
| `#CRDTransformer` | `providers/kubernetes/transformers/crd_transformer.cue` | CRDTransformer converts CRDs resources to Kubernetes CustomResourceDefinitions |
| `#CronJobTransformer` | `providers/kubernetes/transformers/cronjob_transformer.cue` | CronJobTransformer converts scheduled task components to Kubernetes CronJobs |
| `#DaemonSetTransformer` | `providers/kubernetes/transformers/daemonset_transformer.cue` | DaemonSetTransformer converts daemon workload components to Kubernetes DaemonSets |
| `#DeploymentTransformer` | `providers/kubernetes/transformers/deployment_transformer.cue` | DeploymentTransformer converts stateless workload components to Kubernetes Deployments |
| `#GrpcRouteTransformer` | `providers/kubernetes/transformers/grpc_route_transformer.cue` | GrpcRouteTransformer creates Gateway API GRPCRoutes from components with GrpcRoute trait |
| `#HPATransformer` | `providers/kubernetes/transformers/hpa_transformer.cue` | HPATransformer converts Scaling auto config to Kubernetes HorizontalPodAutoscalers |
| `#HttpRouteTransformer` | `providers/kubernetes/transformers/http_route_transformer.cue` | HttpRouteTransformer creates Gateway API HTTPRoutes from components with HttpRoute trait |
| `#JobTransformer` | `providers/kubernetes/transformers/job_transformer.cue` | JobTransformer converts task workload components to Kubernetes Jobs |
| `#PVCTransformer` | `providers/kubernetes/transformers/pvc_transformer.cue` | PVCTransformer creates standalone PersistentVolumeClaims from Volume resources |
| `#RoleTransformer` | `providers/kubernetes/transformers/role_transformer.cue` | RoleTransformer converts OPM Role resources to Kubernetes RBAC objects |
| `#ToK8sServiceAccount` | `providers/kubernetes/transformers/sa_helpers.cue` | #ToK8sServiceAccount converts an OPM identity spec (either #WorkloadIdentitySchema or #ServiceAccountSchema — both share the same shape) to a Kubernetes ServiceAccount |
| `#ServiceAccountResourceTransformer` | `providers/kubernetes/transformers/sa_resource_transformer.cue` | ServiceAccountResourceTransformer converts standalone ServiceAccount resources to Kubernetes ServiceAccounts |
| `#ServiceAccountTransformer` | `providers/kubernetes/transformers/sa_trait_transformer.cue` | ServiceAccountTransformer converts WorkloadIdentity traits to Kubernetes ServiceAccounts |
| `#SecretTransformer` | `providers/kubernetes/transformers/secret_transformer.cue` | SecretTransformer converts Secrets resources to Kubernetes Secrets |
| `#ServiceTransformer` | `providers/kubernetes/transformers/service_transformer.cue` | ServiceTransformer creates Kubernetes Services from components with Expose trait |
| `#StatefulsetTransformer` | `providers/kubernetes/transformers/statefulset_transformer.cue` | StatefulsetTransformer converts stateful workload components to Kubernetes StatefulSets |
| `#TcpRouteTransformer` | `providers/kubernetes/transformers/tcp_route_transformer.cue` | TcpRouteTransformer creates Gateway API TCPRoutes from components with TcpRoute trait |
| `#TestCtx` | `providers/kubernetes/transformers/test_helpers.cue` | #TestCtx constructs a minimal concrete #TransformerContext for transformer tests |
| `#TlsRouteTransformer` | `providers/kubernetes/transformers/tls_route_transformer.cue` | TlsRouteTransformer creates Gateway API TLSRoutes from components with TlsRoute trait |

---

## Resources

### config

| Definition | File | Description |
|---|---|---|
| `#ConfigMaps` | `resources/config/configmap.cue` |  |
| `#ConfigMapsDefaults` | `resources/config/configmap.cue` |  |
| `#ConfigMapsResource` | `resources/config/configmap.cue` |  |
| `#Secrets` | `resources/config/secret.cue` |  |
| `#SecretsDefaults` | `resources/config/secret.cue` |  |
| `#SecretsResource` | `resources/config/secret.cue` |  |

### extension

| Definition | File | Description |
|---|---|---|
| `#CRDs` | `resources/extension/crd.cue` |  |
| `#CRDsDefaults` | `resources/extension/crd.cue` |  |
| `#CRDsResource` | `resources/extension/crd.cue` |  |

### security

| Definition | File | Description |
|---|---|---|
| `#Role` | `resources/security/role.cue` |  |
| `#RoleDefaults` | `resources/security/role.cue` |  |
| `#RoleResource` | `resources/security/role.cue` |  |
| `#ServiceAccount` | `resources/security/service_account.cue` |  |
| `#ServiceAccountDefaults` | `resources/security/service_account.cue` |  |
| `#ServiceAccountResource` | `resources/security/service_account.cue` |  |

### storage

| Definition | File | Description |
|---|---|---|
| `#Volumes` | `resources/storage/volume.cue` |  |
| `#VolumesDefaults` | `resources/storage/volume.cue` |  |
| `#VolumesResource` | `resources/storage/volume.cue` |  |

### workload

| Definition | File | Description |
|---|---|---|
| `#Container` | `resources/workload/container.cue` |  |
| `#ContainerDefaults` | `resources/workload/container.cue` |  |
| `#ContainerResource` | `resources/workload/container.cue` |  |

---

## Schemas

| Definition | File | Description |
|---|---|---|
| `#LabelsAnnotationsSchema` | `schemas/common.cue` | Labels and annotations schema |
| `#NameType` | `schemas/common.cue` | DNS label name type (RFC 1123) |
| `#VersionSchema` | `schemas/common.cue` | Semantic version schema |
| `#AutoSecrets` | `schemas/config.cue` | #AutoSecrets discovers all #Secret instances from a resolved config and groups them by $secretName/$dataKey in one step |
| `#ConfigMapSchema` | `schemas/config.cue` | ConfigMap specification |
| `#ContentHash` | `schemas/config.cue` | #ContentHash computes a deterministic 10-character hex hash of a string data map |
| `#DiscoverSecrets` | `schemas/config.cue` | #DiscoverSecrets walks a resolved config (up to 3 levels deep) and collects all fields whose value is a #Secret |
| `#GroupSecrets` | `schemas/config.cue` | #GroupSecrets takes a flat map of discovered secrets and groups them by $secretName, keyed by $dataKey |
| `#ImmutableName` | `schemas/config.cue` | #ImmutableName computes the K8s resource name for a ConfigMap |
| `#Secret` | `schemas/config.cue` | #Secret is the contract type that module authors place on sensitive fields |
| `#SecretContentHash` | `schemas/config.cue` | #SecretContentHash normalizes #Secret entries and plain strings to a string map, then delegates to #ContentHash |
| `#SecretImmutableName` | `schemas/config.cue` | #SecretImmutableName computes the K8s resource name for a Secret |
| `#SecretK8sRef` | `schemas/config.cue` | #SecretK8sRef: points to a pre-existing K8s Secret in the cluster |
| `#SecretLiteral` | `schemas/config.cue` | #SecretLiteral: user provides the actual value |
| `#SecretSchema` | `schemas/config.cue` | Secret specification for K8s Secret resources |
| `#SecretType` | `schemas/config.cue` |  |
| `#SimpleDatabaseSchema` | `schemas/data.cue` |  |
| `#CRDSchema` | `schemas/extension.cue` | CRDSchema defines a Kubernetes CustomResourceDefinition to be deployed to the cluster |
| `#CRDVersionSchema` | `schemas/extension.cue` | CRDVersionSchema defines a single version entry in a CRD |
| `#ExposeSchema` | `schemas/network.cue` | Expose specification |
| `#NetworkRuleSchema` | `schemas/network.cue` |  |
| `#PortSchema` | `schemas/network.cue` | Port specification |
| `#SharedNetworkSchema` | `schemas/network.cue` |  |
| `#NormalizeCPU` | `schemas/quantity.cue` | #NormalizeCPU normalizes CPU input to Kubernetes canonical form |
| `#NormalizeMemory` | `schemas/quantity.cue` | #NormalizeMemory normalizes memory input to Kubernetes binary format |
| `#AcmeHttp01SolverSchema` | `schemas/security.cue` | ACME HTTP-01 solver — uses HTTP challenge to prove domain ownership |
| `#AcmeSolverSchema` | `schemas/security.cue` | ACME solver — selects which challenge type to use |
| `#CertificateIssuerRefSchema` | `schemas/security.cue` | IssuerRef embedded in Certificate — identifies which Issuer signs the cert |
| `#CertificatePrivateKeySchema` | `schemas/security.cue` | PrivateKey configuration |
| `#CertificateSchema` | `schemas/security.cue` | Certificate spec — defines the desired TLS certificate |
| `#ClusterIssuerSchema` | `schemas/security.cue` | ClusterIssuer schema (cluster-scoped — same spec shape as Issuer) |
| `#EncryptionConfigSchema` | `schemas/security.cue` |  |
| `#IssuerSchema` | `schemas/security.cue` | Issuer schema (namespace-scoped) |
| `#IssuerSpecSchema` | `schemas/security.cue` | IssuerSpec — common configuration for Issuer and ClusterIssuer |
| `#PolicyRuleSchema` | `schemas/security.cue` | Single RBAC permission rule |
| `#RoleSchema` | `schemas/security.cue` | RBAC role with rules and CUE-referenced subjects |
| `#RoleSubjectSchema` | `schemas/security.cue` | Role subject — embeds an identity directly via CUE reference |
| `#SecurityContextSchema` | `schemas/security.cue` | Security context constraints for container and pod-level hardening |
| `#ServiceAccountSchema` | `schemas/security.cue` | Standalone service account identity |
| `#WorkloadIdentitySchema` | `schemas/security.cue` |  |
| `#EmptyDirSchema` | `schemas/storage.cue` | EmptyDir specification |
| `#FileMode` | `schemas/storage.cue` |  |
| `#HostPathSchema` | `schemas/storage.cue` | HostPath specification - mounts a file or directory from the host node |
| `#NFSVolumeSourceSchema` | `schemas/storage.cue` | NFS volume source - mounts a directory from an NFS server |
| `#PersistentClaimSchema` | `schemas/storage.cue` | Persistent claim specification |
| `#SecretVolumeItemSchema` | `schemas/storage.cue` |  |
| `#SecretVolumeSourceSchema` | `schemas/storage.cue` |  |
| `#VolumeMountSchema` | `schemas/storage.cue` | Volume mount specification - defines container mount point |
| `#VolumeSchema` | `schemas/storage.cue` | Volume specification - defines storage source |
| `#AutoscalingSpec` | `schemas/workload.cue` |  |
| `#ContainerSchema` | `schemas/workload.cue` | Container specification |
| `#CronJobConfigSchema` | `schemas/workload.cue` |  |
| `#DisruptionBudgetSchema` | `schemas/workload.cue` | Availability constraints during voluntary disruptions |
| `#EnvFromSource` | `schemas/workload.cue` | Bulk injection source — inject all keys from a ConfigMap or Secret as env vars |
| `#EnvVarSchema` | `schemas/workload.cue` | Environment variable specification |
| `#FieldRefSchema` | `schemas/workload.cue` | Downward API field reference — expose pod/container metadata as env vars |
| `#GpuResourceSchema` | `schemas/workload.cue` | #GpuResourceSchema specifies a GPU extended resource claim for a container |
| `#GracefulShutdownSchema` | `schemas/workload.cue` | Termination behavior for graceful workload shutdown |
| `#Image` | `schemas/workload.cue` | Image specification for container images, used in #ContainerSchema Borrowed from timoni's #Image schema |
| `#InitContainersSchema` | `schemas/workload.cue` |  |
| `#JobConfigSchema` | `schemas/workload.cue` |  |
| `#MetricSpec` | `schemas/workload.cue` |  |
| `#MetricTargetSpec` | `schemas/workload.cue` |  |
| `#PlacementSchema` | `schemas/workload.cue` | Provider-agnostic workload placement intent |
| `#ProbeSchema` | `schemas/workload.cue` | Probe specification used by liveness, readiness, and startup probes |
| `#ResourceFieldRefSchema` | `schemas/workload.cue` | Container resource field reference — expose resource limits/requests as env vars |
| `#ResourceRequirementsSchema` | `schemas/workload.cue` |  |
| `#RestartPolicySchema` | `schemas/workload.cue` |  |
| `#ScalingSchema` | `schemas/workload.cue` |  |
| `#SidecarContainersSchema` | `schemas/workload.cue` |  |
| `#SizingSchema` | `schemas/workload.cue` |  |
| `#StatelessWorkloadSchema` | `schemas/workload.cue` |  |
| `#UpdateStrategySchema` | `schemas/workload.cue` |  |
| `#VerticalScalingSchema` | `schemas/workload.cue` |  |

### kubernetes/apiextensions/v1

| Definition | File | Description |
|---|---|---|
| `#CustomResourceColumnDefinition` | `schemas/kubernetes/apiextensions/v1/types.cue` |  |
| `#CustomResourceDefinition` | `schemas/kubernetes/apiextensions/v1/types.cue` |  |
| `#CustomResourceDefinitionList` | `schemas/kubernetes/apiextensions/v1/types.cue` |  |
| `#CustomResourceDefinitionNames` | `schemas/kubernetes/apiextensions/v1/types.cue` |  |
| `#CustomResourceDefinitionSpec` | `schemas/kubernetes/apiextensions/v1/types.cue` |  |
| `#CustomResourceDefinitionVersion` | `schemas/kubernetes/apiextensions/v1/types.cue` |  |
| `#CustomResourceSubresources` | `schemas/kubernetes/apiextensions/v1/types.cue` |  |
| `#CustomResourceValidation` | `schemas/kubernetes/apiextensions/v1/types.cue` |  |
| `#JSONSchemaProps` | `schemas/kubernetes/apiextensions/v1/types.cue` |  |

### kubernetes/apps/v1

| Definition | File | Description |
|---|---|---|
| `#ControllerRevision` | `schemas/kubernetes/apps/v1/types.cue` |  |
| `#ControllerRevisionList` | `schemas/kubernetes/apps/v1/types.cue` |  |
| `#DaemonSet` | `schemas/kubernetes/apps/v1/types.cue` |  |
| `#DaemonSetCondition` | `schemas/kubernetes/apps/v1/types.cue` |  |
| `#DaemonSetList` | `schemas/kubernetes/apps/v1/types.cue` |  |
| `#DaemonSetSpec` | `schemas/kubernetes/apps/v1/types.cue` |  |
| `#DaemonSetStatus` | `schemas/kubernetes/apps/v1/types.cue` |  |
| `#DaemonSetUpdateStrategy` | `schemas/kubernetes/apps/v1/types.cue` |  |
| `#Deployment` | `schemas/kubernetes/apps/v1/types.cue` |  |
| `#DeploymentCondition` | `schemas/kubernetes/apps/v1/types.cue` |  |
| `#DeploymentList` | `schemas/kubernetes/apps/v1/types.cue` |  |
| `#DeploymentSpec` | `schemas/kubernetes/apps/v1/types.cue` |  |
| `#DeploymentStatus` | `schemas/kubernetes/apps/v1/types.cue` |  |
| `#DeploymentStrategy` | `schemas/kubernetes/apps/v1/types.cue` |  |
| `#ReplicaSet` | `schemas/kubernetes/apps/v1/types.cue` |  |
| `#ReplicaSetCondition` | `schemas/kubernetes/apps/v1/types.cue` |  |
| `#ReplicaSetList` | `schemas/kubernetes/apps/v1/types.cue` |  |
| `#ReplicaSetSpec` | `schemas/kubernetes/apps/v1/types.cue` |  |
| `#ReplicaSetStatus` | `schemas/kubernetes/apps/v1/types.cue` |  |
| `#RollingUpdateDaemonSet` | `schemas/kubernetes/apps/v1/types.cue` |  |
| `#RollingUpdateDeployment` | `schemas/kubernetes/apps/v1/types.cue` |  |
| `#RollingUpdateStatefulSetStrategy` | `schemas/kubernetes/apps/v1/types.cue` |  |
| `#StatefulSet` | `schemas/kubernetes/apps/v1/types.cue` |  |
| `#StatefulSetCondition` | `schemas/kubernetes/apps/v1/types.cue` |  |
| `#StatefulSetList` | `schemas/kubernetes/apps/v1/types.cue` |  |
| `#StatefulSetOrdinals` | `schemas/kubernetes/apps/v1/types.cue` |  |
| `#StatefulSetPersistentVolumeClaimRetentionPolicy` | `schemas/kubernetes/apps/v1/types.cue` |  |
| `#StatefulSetSpec` | `schemas/kubernetes/apps/v1/types.cue` |  |
| `#StatefulSetStatus` | `schemas/kubernetes/apps/v1/types.cue` |  |
| `#StatefulSetUpdateStrategy` | `schemas/kubernetes/apps/v1/types.cue` |  |

### kubernetes/autoscaling/v2

| Definition | File | Description |
|---|---|---|
| `#ContainerResourceMetricSource` | `schemas/kubernetes/autoscaling/v2/types.cue` |  |
| `#ContainerResourceMetricStatus` | `schemas/kubernetes/autoscaling/v2/types.cue` |  |
| `#CrossVersionObjectReference` | `schemas/kubernetes/autoscaling/v2/types.cue` |  |
| `#ExternalMetricSource` | `schemas/kubernetes/autoscaling/v2/types.cue` |  |
| `#ExternalMetricStatus` | `schemas/kubernetes/autoscaling/v2/types.cue` |  |
| `#HorizontalPodAutoscaler` | `schemas/kubernetes/autoscaling/v2/types.cue` |  |
| `#HorizontalPodAutoscalerBehavior` | `schemas/kubernetes/autoscaling/v2/types.cue` |  |
| `#HorizontalPodAutoscalerCondition` | `schemas/kubernetes/autoscaling/v2/types.cue` |  |
| `#HorizontalPodAutoscalerList` | `schemas/kubernetes/autoscaling/v2/types.cue` |  |
| `#HorizontalPodAutoscalerSpec` | `schemas/kubernetes/autoscaling/v2/types.cue` |  |
| `#HorizontalPodAutoscalerStatus` | `schemas/kubernetes/autoscaling/v2/types.cue` |  |
| `#HPAScalingPolicy` | `schemas/kubernetes/autoscaling/v2/types.cue` |  |
| `#HPAScalingRules` | `schemas/kubernetes/autoscaling/v2/types.cue` |  |
| `#MetricIdentifier` | `schemas/kubernetes/autoscaling/v2/types.cue` |  |
| `#MetricSpec` | `schemas/kubernetes/autoscaling/v2/types.cue` |  |
| `#MetricStatus` | `schemas/kubernetes/autoscaling/v2/types.cue` |  |
| `#MetricTarget` | `schemas/kubernetes/autoscaling/v2/types.cue` |  |
| `#MetricValueStatus` | `schemas/kubernetes/autoscaling/v2/types.cue` |  |
| `#ObjectMetricSource` | `schemas/kubernetes/autoscaling/v2/types.cue` |  |
| `#ObjectMetricStatus` | `schemas/kubernetes/autoscaling/v2/types.cue` |  |
| `#PodsMetricSource` | `schemas/kubernetes/autoscaling/v2/types.cue` |  |
| `#PodsMetricStatus` | `schemas/kubernetes/autoscaling/v2/types.cue` |  |
| `#ResourceMetricSource` | `schemas/kubernetes/autoscaling/v2/types.cue` |  |
| `#ResourceMetricStatus` | `schemas/kubernetes/autoscaling/v2/types.cue` |  |

### kubernetes/batch/v1

| Definition | File | Description |
|---|---|---|
| `#CronJob` | `schemas/kubernetes/batch/v1/types.cue` |  |
| `#CronJobList` | `schemas/kubernetes/batch/v1/types.cue` |  |
| `#CronJobSpec` | `schemas/kubernetes/batch/v1/types.cue` |  |
| `#CronJobStatus` | `schemas/kubernetes/batch/v1/types.cue` |  |
| `#Job` | `schemas/kubernetes/batch/v1/types.cue` |  |
| `#JobCondition` | `schemas/kubernetes/batch/v1/types.cue` |  |
| `#JobList` | `schemas/kubernetes/batch/v1/types.cue` |  |
| `#JobSpec` | `schemas/kubernetes/batch/v1/types.cue` |  |
| `#JobStatus` | `schemas/kubernetes/batch/v1/types.cue` |  |
| `#JobTemplateSpec` | `schemas/kubernetes/batch/v1/types.cue` |  |
| `#PodFailurePolicy` | `schemas/kubernetes/batch/v1/types.cue` |  |
| `#PodFailurePolicyOnExitCodesRequirement` | `schemas/kubernetes/batch/v1/types.cue` |  |
| `#PodFailurePolicyOnPodConditionsPattern` | `schemas/kubernetes/batch/v1/types.cue` |  |
| `#PodFailurePolicyRule` | `schemas/kubernetes/batch/v1/types.cue` |  |
| `#SuccessPolicy` | `schemas/kubernetes/batch/v1/types.cue` |  |
| `#SuccessPolicyRule` | `schemas/kubernetes/batch/v1/types.cue` |  |
| `#UncountedTerminatedPods` | `schemas/kubernetes/batch/v1/types.cue` |  |

### kubernetes/certmanager/v1

| Definition | File | Description |
|---|---|---|
| `#Certificate` | `schemas/kubernetes/certmanager/v1/types.cue` | From cue |
| `#CertificateRequest` | `schemas/kubernetes/certmanager/v1/types.cue` |  |
| `#Challenge` | `schemas/kubernetes/certmanager/v1/types.cue` | From cue |
| `#ClusterIssuer` | `schemas/kubernetes/certmanager/v1/types.cue` |  |
| `#Issuer` | `schemas/kubernetes/certmanager/v1/types.cue` |  |
| `#Order` | `schemas/kubernetes/certmanager/v1/types.cue` |  |

### kubernetes/core/v1

| Definition | File | Description |
|---|---|---|
| `#Affinity` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#AppArmorProfile` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#AttachedVolume` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#AWSElasticBlockStoreVolumeSource` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#AzureDiskVolumeSource` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#AzureFilePersistentVolumeSource` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#AzureFileVolumeSource` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#Binding` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#Capabilities` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#CephFSPersistentVolumeSource` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#CephFSVolumeSource` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#CinderPersistentVolumeSource` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#CinderVolumeSource` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#ClientIPConfig` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#ClusterTrustBundleProjection` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#ComponentCondition` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#ComponentStatus` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#ComponentStatusList` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#ConfigMap` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#ConfigMapEnvSource` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#ConfigMapKeySelector` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#ConfigMapList` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#ConfigMapNodeConfigSource` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#ConfigMapProjection` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#ConfigMapVolumeSource` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#Container` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#ContainerExtendedResourceRequest` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#ContainerImage` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#ContainerPort` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#ContainerResizePolicy` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#ContainerRestartRule` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#ContainerRestartRuleOnExitCodes` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#ContainerState` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#ContainerStateRunning` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#ContainerStateTerminated` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#ContainerStateWaiting` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#ContainerStatus` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#ContainerUser` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#CSIPersistentVolumeSource` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#CSIVolumeSource` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#DaemonEndpoint` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#DownwardAPIProjection` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#DownwardAPIVolumeFile` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#DownwardAPIVolumeSource` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#EmptyDirVolumeSource` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#EndpointAddress` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#EndpointPort` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#Endpoints` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#EndpointsList` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#EndpointSubset` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#EnvFromSource` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#EnvVar` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#EnvVarSource` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#EphemeralContainer` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#EphemeralVolumeSource` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#Event` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#EventList` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#EventSeries` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#EventSource` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#ExecAction` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#FCVolumeSource` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#FileKeySelector` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#FlexPersistentVolumeSource` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#FlexVolumeSource` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#FlockerVolumeSource` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#GCEPersistentDiskVolumeSource` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#GitRepoVolumeSource` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#GlusterfsPersistentVolumeSource` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#GlusterfsVolumeSource` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#GRPCAction` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#HostAlias` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#HostIP` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#HostPathVolumeSource` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#HTTPGetAction` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#HTTPHeader` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#ImageVolumeSource` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#ISCSIPersistentVolumeSource` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#ISCSIVolumeSource` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#KeyToPath` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#Lifecycle` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#LifecycleHandler` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#LimitRange` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#LimitRangeItem` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#LimitRangeList` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#LimitRangeSpec` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#LinuxContainerUser` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#LoadBalancerIngress` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#LoadBalancerStatus` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#LocalObjectReference` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#LocalVolumeSource` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#ModifyVolumeStatus` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#Namespace` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#NamespaceCondition` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#NamespaceList` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#NamespaceSpec` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#NamespaceStatus` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#NFSVolumeSource` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#Node` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#NodeAddress` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#NodeAffinity` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#NodeCondition` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#NodeConfigSource` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#NodeConfigStatus` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#NodeDaemonEndpoints` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#NodeFeatures` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#NodeList` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#NodeRuntimeHandler` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#NodeRuntimeHandlerFeatures` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#NodeSelector` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#NodeSelectorRequirement` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#NodeSelectorTerm` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#NodeSpec` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#NodeStatus` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#NodeSwapStatus` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#NodeSystemInfo` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#ObjectFieldSelector` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#ObjectReference` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#PersistentVolume` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#PersistentVolumeClaim` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#PersistentVolumeClaimCondition` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#PersistentVolumeClaimList` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#PersistentVolumeClaimSpec` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#PersistentVolumeClaimStatus` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#PersistentVolumeClaimTemplate` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#PersistentVolumeClaimVolumeSource` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#PersistentVolumeList` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#PersistentVolumeSpec` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#PersistentVolumeStatus` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#PhotonPersistentDiskVolumeSource` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#Pod` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#PodAffinity` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#PodAffinityTerm` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#PodAntiAffinity` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#PodCertificateProjection` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#PodCondition` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#PodDNSConfig` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#PodDNSConfigOption` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#PodExtendedResourceClaimStatus` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#PodIP` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#PodList` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#PodOS` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#PodReadinessGate` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#PodResourceClaim` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#PodResourceClaimStatus` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#PodSchedulingGate` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#PodSecurityContext` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#PodSpec` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#PodStatus` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#PodTemplate` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#PodTemplateList` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#PodTemplateSpec` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#PortStatus` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#PortworxVolumeSource` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#PreferredSchedulingTerm` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#Probe` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#ProjectedVolumeSource` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#QuobyteVolumeSource` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#RBDPersistentVolumeSource` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#RBDVolumeSource` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#ReplicationController` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#ReplicationControllerCondition` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#ReplicationControllerList` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#ReplicationControllerSpec` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#ReplicationControllerStatus` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#ResourceClaim` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#ResourceFieldSelector` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#ResourceHealth` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#ResourceQuota` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#ResourceQuotaList` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#ResourceQuotaSpec` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#ResourceQuotaStatus` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#ResourceRequirements` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#ResourceStatus` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#ScaleIOPersistentVolumeSource` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#ScaleIOVolumeSource` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#ScopedResourceSelectorRequirement` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#ScopeSelector` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#SeccompProfile` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#Secret` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#SecretEnvSource` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#SecretKeySelector` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#SecretList` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#SecretProjection` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#SecretReference` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#SecretVolumeSource` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#SecurityContext` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#SELinuxOptions` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#Service` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#ServiceAccount` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#ServiceAccountList` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#ServiceAccountTokenProjection` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#ServiceList` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#ServicePort` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#ServiceSpec` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#ServiceStatus` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#SessionAffinityConfig` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#SleepAction` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#StorageOSPersistentVolumeSource` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#StorageOSVolumeSource` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#Sysctl` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#Taint` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#TCPSocketAction` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#Toleration` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#TopologySelectorLabelRequirement` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#TopologySelectorTerm` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#TopologySpreadConstraint` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#TypedLocalObjectReference` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#TypedObjectReference` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#Volume` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#VolumeDevice` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#VolumeMount` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#VolumeMountStatus` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#VolumeNodeAffinity` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#VolumeProjection` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#VolumeResourceRequirements` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#VsphereVirtualDiskVolumeSource` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#WeightedPodAffinityTerm` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#WindowsSecurityContextOptions` | `schemas/kubernetes/core/v1/types.cue` |  |

### kubernetes/networking/v1

| Definition | File | Description |
|---|---|---|
| `#HTTPIngressPath` | `schemas/kubernetes/networking/v1/types.cue` |  |
| `#HTTPIngressRuleValue` | `schemas/kubernetes/networking/v1/types.cue` |  |
| `#Ingress` | `schemas/kubernetes/networking/v1/types.cue` |  |
| `#IngressBackend` | `schemas/kubernetes/networking/v1/types.cue` |  |
| `#IngressClass` | `schemas/kubernetes/networking/v1/types.cue` |  |
| `#IngressClassList` | `schemas/kubernetes/networking/v1/types.cue` |  |
| `#IngressClassParametersReference` | `schemas/kubernetes/networking/v1/types.cue` |  |
| `#IngressClassSpec` | `schemas/kubernetes/networking/v1/types.cue` |  |
| `#IngressList` | `schemas/kubernetes/networking/v1/types.cue` |  |
| `#IngressLoadBalancerIngress` | `schemas/kubernetes/networking/v1/types.cue` |  |
| `#IngressLoadBalancerStatus` | `schemas/kubernetes/networking/v1/types.cue` |  |
| `#IngressPortStatus` | `schemas/kubernetes/networking/v1/types.cue` |  |
| `#IngressRule` | `schemas/kubernetes/networking/v1/types.cue` |  |
| `#IngressServiceBackend` | `schemas/kubernetes/networking/v1/types.cue` |  |
| `#IngressSpec` | `schemas/kubernetes/networking/v1/types.cue` |  |
| `#IngressStatus` | `schemas/kubernetes/networking/v1/types.cue` |  |
| `#IngressTLS` | `schemas/kubernetes/networking/v1/types.cue` |  |
| `#IPAddress` | `schemas/kubernetes/networking/v1/types.cue` |  |
| `#IPAddressList` | `schemas/kubernetes/networking/v1/types.cue` |  |
| `#IPAddressSpec` | `schemas/kubernetes/networking/v1/types.cue` |  |
| `#IPBlock` | `schemas/kubernetes/networking/v1/types.cue` |  |
| `#NetworkPolicy` | `schemas/kubernetes/networking/v1/types.cue` |  |
| `#NetworkPolicyEgressRule` | `schemas/kubernetes/networking/v1/types.cue` |  |
| `#NetworkPolicyIngressRule` | `schemas/kubernetes/networking/v1/types.cue` |  |
| `#NetworkPolicyList` | `schemas/kubernetes/networking/v1/types.cue` |  |
| `#NetworkPolicyPeer` | `schemas/kubernetes/networking/v1/types.cue` |  |
| `#NetworkPolicyPort` | `schemas/kubernetes/networking/v1/types.cue` |  |
| `#NetworkPolicySpec` | `schemas/kubernetes/networking/v1/types.cue` |  |
| `#ParentReference` | `schemas/kubernetes/networking/v1/types.cue` |  |
| `#ServiceBackendPort` | `schemas/kubernetes/networking/v1/types.cue` |  |
| `#ServiceCIDR` | `schemas/kubernetes/networking/v1/types.cue` |  |
| `#ServiceCIDRList` | `schemas/kubernetes/networking/v1/types.cue` |  |
| `#ServiceCIDRSpec` | `schemas/kubernetes/networking/v1/types.cue` |  |
| `#ServiceCIDRStatus` | `schemas/kubernetes/networking/v1/types.cue` |  |

---

## Traits

### network

| Definition | File | Description |
|---|---|---|
| `#Expose` | `traits/network/expose.cue` |  |
| `#ExposeDefaults` | `traits/network/expose.cue` |  |
| `#ExposeTrait` | `traits/network/expose.cue` |  |
| `#GrpcRoute` | `traits/network/grpc_route.cue` |  |
| `#GrpcRouteDefaults` | `traits/network/grpc_route.cue` |  |
| `#GrpcRouteTrait` | `traits/network/grpc_route.cue` |  |
| `#HostNetwork` | `traits/network/host_network.cue` |  |
| `#HostNetworkTrait` | `traits/network/host_network.cue` |  |
| `#HttpRoute` | `traits/network/http_route.cue` |  |
| `#HttpRouteDefaults` | `traits/network/http_route.cue` |  |
| `#HttpRouteTrait` | `traits/network/http_route.cue` |  |
| `#TcpRoute` | `traits/network/tcp_route.cue` |  |
| `#TcpRouteDefaults` | `traits/network/tcp_route.cue` |  |
| `#TcpRouteTrait` | `traits/network/tcp_route.cue` |  |
| `#TlsRoute` | `traits/network/tls_route.cue` |  |
| `#TlsRouteDefaults` | `traits/network/tls_route.cue` |  |
| `#TlsRouteTrait` | `traits/network/tls_route.cue` |  |

### security

| Definition | File | Description |
|---|---|---|
| `#EncryptionConfig` | `traits/security/encryption.cue` |  |
| `#EncryptionConfigDefaults` | `traits/security/encryption.cue` |  |
| `#EncryptionConfigTrait` | `traits/security/encryption.cue` |  |
| `#HostIPC` | `traits/security/host_ipc.cue` |  |
| `#HostIPCTrait` | `traits/security/host_ipc.cue` |  |
| `#HostPID` | `traits/security/host_pid.cue` |  |
| `#HostPIDTrait` | `traits/security/host_pid.cue` |  |
| `#SecurityContext` | `traits/security/security_context.cue` |  |
| `#SecurityContextDefaults` | `traits/security/security_context.cue` |  |
| `#SecurityContextTrait` | `traits/security/security_context.cue` |  |
| `#WorkloadIdentity` | `traits/security/workload_identity.cue` |  |
| `#WorkloadIdentityDefaults` | `traits/security/workload_identity.cue` |  |
| `#WorkloadIdentityTrait` | `traits/security/workload_identity.cue` |  |

### workload

| Definition | File | Description |
|---|---|---|
| `#CronJobConfig` | `traits/workload/cron_job_config.cue` |  |
| `#CronJobConfigDefaults` | `traits/workload/cron_job_config.cue` |  |
| `#CronJobConfigTrait` | `traits/workload/cron_job_config.cue` |  |
| `#DisruptionBudget` | `traits/workload/disruption_budget.cue` |  |
| `#DisruptionBudgetDefaults` | `traits/workload/disruption_budget.cue` |  |
| `#DisruptionBudgetTrait` | `traits/workload/disruption_budget.cue` |  |
| `#GracefulShutdown` | `traits/workload/graceful_shutdown.cue` |  |
| `#GracefulShutdownDefaults` | `traits/workload/graceful_shutdown.cue` |  |
| `#GracefulShutdownTrait` | `traits/workload/graceful_shutdown.cue` |  |
| `#InitContainers` | `traits/workload/init_containers.cue` |  |
| `#InitContainersDefaults` | `traits/workload/init_containers.cue` |  |
| `#InitContainersTrait` | `traits/workload/init_containers.cue` |  |
| `#JobConfig` | `traits/workload/job_config.cue` |  |
| `#JobConfigDefaults` | `traits/workload/job_config.cue` |  |
| `#JobConfigTrait` | `traits/workload/job_config.cue` |  |
| `#Placement` | `traits/workload/placement.cue` |  |
| `#PlacementDefaults` | `traits/workload/placement.cue` |  |
| `#PlacementTrait` | `traits/workload/placement.cue` |  |
| `#RestartPolicy` | `traits/workload/restart_policy.cue` |  |
| `#RestartPolicyDefaults` | `traits/workload/restart_policy.cue` |  |
| `#RestartPolicyTrait` | `traits/workload/restart_policy.cue` |  |
| `#Scaling` | `traits/workload/scaling.cue` |  |
| `#ScalingDefaults` | `traits/workload/scaling.cue` |  |
| `#ScalingTrait` | `traits/workload/scaling.cue` |  |
| `#SidecarContainers` | `traits/workload/sidecar_containers.cue` |  |
| `#SidecarContainersDefaults` | `traits/workload/sidecar_containers.cue` |  |
| `#SidecarContainersTrait` | `traits/workload/sidecar_containers.cue` |  |
| `#Sizing` | `traits/workload/sizing.cue` |  |
| `#SizingDefaults` | `traits/workload/sizing.cue` |  |
| `#SizingTrait` | `traits/workload/sizing.cue` |  |
| `#UpdateStrategy` | `traits/workload/update_strategy.cue` |  |
| `#UpdateStrategyDefaults` | `traits/workload/update_strategy.cue` |  |
| `#UpdateStrategyTrait` | `traits/workload/update_strategy.cue` |  |

---

