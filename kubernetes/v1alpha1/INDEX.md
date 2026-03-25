# v1alpha1 — Definition Index

CUE module: `opmodel.dev/kubernetes/v1alpha1@v1`

---

## Project Structure

```
+-- providers/
|   +-- kubernetes/
|       +-- transformers/
+-- resources/
|   +-- admission/
|   +-- cluster/
|   +-- config/
|   +-- network/
|   +-- policy/
|   +-- rbac/
|   +-- storage/
|   +-- workload/
+-- schemas/
```

---

## Providers

### kubernetes

| Definition | File | Description |
|---|---|---|
| `#Provider` | `providers/kubernetes/provider.cue` | KubernetesNativeProvider registers pass-through transformers for native Kubernetes resources |

### kubernetes/transformers

| Definition | File | Description |
|---|---|---|
| `#ClusterRoleBindingTransformer` | `providers/kubernetes/transformers/cluster_role_binding_transformer.cue` | ClusterRoleBindingTransformer creates Kubernetes ClusterRoleBindings from ClusterRoleBindingResource components |
| `#ClusterRoleTransformer` | `providers/kubernetes/transformers/cluster_role_transformer.cue` | ClusterRoleTransformer creates Kubernetes ClusterRoles from ClusterRoleResource components |
| `#ConfigMapTransformer` | `providers/kubernetes/transformers/configmap_transformer.cue` | ConfigMapTransformer creates Kubernetes ConfigMaps from ConfigMapResource components |
| `#CronJobTransformer` | `providers/kubernetes/transformers/cronjob_transformer.cue` | CronJobTransformer creates Kubernetes CronJobs from CronJobResource components |
| `#DaemonSetTransformer` | `providers/kubernetes/transformers/daemonset_transformer.cue` | DaemonSetTransformer creates Kubernetes DaemonSets from DaemonSetResource components |
| `#DeploymentTransformer` | `providers/kubernetes/transformers/deployment_transformer.cue` | DeploymentTransformer creates Kubernetes Deployments from DeploymentResource components |
| `#HorizontalPodAutoscalerTransformer` | `providers/kubernetes/transformers/hpa_transformer.cue` | HorizontalPodAutoscalerTransformer creates Kubernetes HPAs from HorizontalPodAutoscalerResource components |
| `#IngressClassTransformer` | `providers/kubernetes/transformers/ingressclass_transformer.cue` | IngressClassTransformer creates Kubernetes IngressClasses from IngressClassResource components |
| `#IngressTransformer` | `providers/kubernetes/transformers/ingress_transformer.cue` | IngressTransformer creates Kubernetes Ingresses from IngressResource components |
| `#JobTransformer` | `providers/kubernetes/transformers/job_transformer.cue` | JobTransformer creates Kubernetes Jobs from JobResource components |
| `#MutatingWebhookConfigurationTransformer` | `providers/kubernetes/transformers/mutating_webhook_transformer.cue` | MutatingWebhookConfigurationTransformer creates Kubernetes MutatingWebhookConfigurations from MutatingWebhookConfigurationResource components |
| `#NamespaceTransformer` | `providers/kubernetes/transformers/namespace_transformer.cue` | NamespaceTransformer creates Kubernetes Namespaces from NamespaceResource components |
| `#NetworkPolicyTransformer` | `providers/kubernetes/transformers/networkpolicy_transformer.cue` | NetworkPolicyTransformer creates Kubernetes NetworkPolicies from NetworkPolicyResource components |
| `#PodDisruptionBudgetTransformer` | `providers/kubernetes/transformers/pdb_transformer.cue` | PodDisruptionBudgetTransformer creates Kubernetes PodDisruptionBudgets from PodDisruptionBudgetResource components |
| `#PersistentVolumeClaimTransformer` | `providers/kubernetes/transformers/pvc_transformer.cue` | PersistentVolumeClaimTransformer creates Kubernetes PVCs from PersistentVolumeClaimResource components |
| `#PersistentVolumeTransformer` | `providers/kubernetes/transformers/pv_transformer.cue` | PersistentVolumeTransformer creates Kubernetes PVs from PersistentVolumeResource components |
| `#PodTransformer` | `providers/kubernetes/transformers/pod_transformer.cue` | PodTransformer creates Kubernetes Pods from PodResource components |
| `#RoleBindingTransformer` | `providers/kubernetes/transformers/role_binding_transformer.cue` | RoleBindingTransformer creates Kubernetes RoleBindings from RoleBindingResource components |
| `#RoleTransformer` | `providers/kubernetes/transformers/role_transformer.cue` | RoleTransformer creates Kubernetes Roles from RoleResource components |
| `#SecretTransformer` | `providers/kubernetes/transformers/secret_transformer.cue` | SecretTransformer creates Kubernetes Secrets from SecretResource components |
| `#ServiceAccountTransformer` | `providers/kubernetes/transformers/serviceaccount_transformer.cue` | ServiceAccountTransformer creates Kubernetes ServiceAccounts from ServiceAccountResource components |
| `#ServiceTransformer` | `providers/kubernetes/transformers/service_transformer.cue` | ServiceTransformer creates Kubernetes Services from ServiceResource components |
| `#StatefulSetTransformer` | `providers/kubernetes/transformers/statefulset_transformer.cue` | StatefulSetTransformer creates Kubernetes StatefulSets from StatefulSetResource components |
| `#StorageClassTransformer` | `providers/kubernetes/transformers/storageclass_transformer.cue` | StorageClassTransformer creates Kubernetes StorageClasses from StorageClassResource components |
| `#TestCtx` | `providers/kubernetes/transformers/test_helpers.cue` | #TestCtx constructs a minimal concrete #TransformerContext for transformer tests |
| `#ValidatingWebhookConfigurationTransformer` | `providers/kubernetes/transformers/validating_webhook_transformer.cue` | ValidatingWebhookConfigurationTransformer creates Kubernetes ValidatingWebhookConfigurations from ValidatingWebhookConfigurationResource components |

---

## Resources

### admission

| Definition | File | Description |
|---|---|---|
| `#MutatingWebhookConfigurationComponent` | `resources/admission/mutating_webhook.cue` |  |
| `#MutatingWebhookConfigurationDefaults` | `resources/admission/mutating_webhook.cue` |  |
| `#MutatingWebhookConfigurationResource` | `resources/admission/mutating_webhook.cue` |  |
| `#ValidatingWebhookConfigurationComponent` | `resources/admission/validating_webhook.cue` |  |
| `#ValidatingWebhookConfigurationDefaults` | `resources/admission/validating_webhook.cue` |  |
| `#ValidatingWebhookConfigurationResource` | `resources/admission/validating_webhook.cue` |  |

### cluster

| Definition | File | Description |
|---|---|---|
| `#NamespaceComponent` | `resources/cluster/namespace.cue` |  |
| `#NamespaceDefaults` | `resources/cluster/namespace.cue` |  |
| `#NamespaceResource` | `resources/cluster/namespace.cue` |  |

### config

| Definition | File | Description |
|---|---|---|
| `#ConfigMapComponent` | `resources/config/configmap.cue` |  |
| `#ConfigMapDefaults` | `resources/config/configmap.cue` |  |
| `#ConfigMapResource` | `resources/config/configmap.cue` |  |
| `#SecretComponent` | `resources/config/secret.cue` |  |
| `#SecretDefaults` | `resources/config/secret.cue` |  |
| `#SecretResource` | `resources/config/secret.cue` |  |

### network

| Definition | File | Description |
|---|---|---|
| `#IngressClassComponent` | `resources/network/ingressclass.cue` |  |
| `#IngressClassDefaults` | `resources/network/ingressclass.cue` |  |
| `#IngressClassResource` | `resources/network/ingressclass.cue` |  |
| `#IngressComponent` | `resources/network/ingress.cue` |  |
| `#IngressDefaults` | `resources/network/ingress.cue` |  |
| `#IngressResource` | `resources/network/ingress.cue` |  |
| `#NetworkPolicyComponent` | `resources/network/networkpolicy.cue` |  |
| `#NetworkPolicyDefaults` | `resources/network/networkpolicy.cue` |  |
| `#NetworkPolicyResource` | `resources/network/networkpolicy.cue` |  |
| `#ServiceComponent` | `resources/network/service.cue` |  |
| `#ServiceDefaults` | `resources/network/service.cue` |  |
| `#ServiceResource` | `resources/network/service.cue` |  |

### policy

| Definition | File | Description |
|---|---|---|
| `#HorizontalPodAutoscalerComponent` | `resources/policy/hpa.cue` |  |
| `#HorizontalPodAutoscalerDefaults` | `resources/policy/hpa.cue` |  |
| `#HorizontalPodAutoscalerResource` | `resources/policy/hpa.cue` |  |
| `#PodDisruptionBudgetComponent` | `resources/policy/pdb.cue` |  |
| `#PodDisruptionBudgetDefaults` | `resources/policy/pdb.cue` |  |
| `#PodDisruptionBudgetResource` | `resources/policy/pdb.cue` |  |

### rbac

| Definition | File | Description |
|---|---|---|
| `#ClusterRoleBindingComponent` | `resources/rbac/cluster_role_binding.cue` |  |
| `#ClusterRoleBindingDefaults` | `resources/rbac/cluster_role_binding.cue` |  |
| `#ClusterRoleBindingResource` | `resources/rbac/cluster_role_binding.cue` |  |
| `#ClusterRoleComponent` | `resources/rbac/cluster_role.cue` |  |
| `#ClusterRoleDefaults` | `resources/rbac/cluster_role.cue` |  |
| `#ClusterRoleResource` | `resources/rbac/cluster_role.cue` |  |
| `#RoleBindingComponent` | `resources/rbac/role_binding.cue` |  |
| `#RoleBindingDefaults` | `resources/rbac/role_binding.cue` |  |
| `#RoleBindingResource` | `resources/rbac/role_binding.cue` |  |
| `#RoleComponent` | `resources/rbac/role.cue` |  |
| `#RoleDefaults` | `resources/rbac/role.cue` |  |
| `#RoleResource` | `resources/rbac/role.cue` |  |
| `#ServiceAccountComponent` | `resources/rbac/service_account.cue` |  |
| `#ServiceAccountDefaults` | `resources/rbac/service_account.cue` |  |
| `#ServiceAccountResource` | `resources/rbac/service_account.cue` |  |

### storage

| Definition | File | Description |
|---|---|---|
| `#PersistentVolumeClaimComponent` | `resources/storage/pvc.cue` |  |
| `#PersistentVolumeClaimDefaults` | `resources/storage/pvc.cue` |  |
| `#PersistentVolumeClaimResource` | `resources/storage/pvc.cue` |  |
| `#PersistentVolumeComponent` | `resources/storage/pv.cue` |  |
| `#PersistentVolumeDefaults` | `resources/storage/pv.cue` |  |
| `#PersistentVolumeResource` | `resources/storage/pv.cue` |  |
| `#StorageClassComponent` | `resources/storage/storageclass.cue` |  |
| `#StorageClassDefaults` | `resources/storage/storageclass.cue` |  |
| `#StorageClassResource` | `resources/storage/storageclass.cue` |  |

### workload

| Definition | File | Description |
|---|---|---|
| `#CronJobComponent` | `resources/workload/cronjob.cue` |  |
| `#CronJobDefaults` | `resources/workload/cronjob.cue` |  |
| `#CronJobResource` | `resources/workload/cronjob.cue` |  |
| `#DaemonSetComponent` | `resources/workload/daemonset.cue` |  |
| `#DaemonSetDefaults` | `resources/workload/daemonset.cue` |  |
| `#DaemonSetResource` | `resources/workload/daemonset.cue` |  |
| `#DeploymentComponent` | `resources/workload/deployment.cue` |  |
| `#DeploymentDefaults` | `resources/workload/deployment.cue` |  |
| `#DeploymentResource` | `resources/workload/deployment.cue` |  |
| `#JobComponent` | `resources/workload/job.cue` |  |
| `#JobDefaults` | `resources/workload/job.cue` |  |
| `#JobResource` | `resources/workload/job.cue` |  |
| `#PodComponent` | `resources/workload/pod.cue` |  |
| `#PodDefaults` | `resources/workload/pod.cue` |  |
| `#PodResource` | `resources/workload/pod.cue` |  |
| `#StatefulSetComponent` | `resources/workload/statefulset.cue` |  |
| `#StatefulSetDefaults` | `resources/workload/statefulset.cue` |  |
| `#StatefulSetResource` | `resources/workload/statefulset.cue` |  |

---

## Schemas

| Definition | File | Description |
|---|---|---|
| `#MutatingWebhookConfigurationSchema` | `schemas/admission.cue` | MutatingWebhookConfiguration spec — configures mutating admission webhooks |
| `#ValidatingWebhookConfigurationSchema` | `schemas/admission.cue` | ValidatingWebhookConfiguration spec — configures validating admission webhooks |
| `#NamespaceSchema` | `schemas/cluster.cue` | Namespace spec — accepts the full Kubernetes Namespace spec |
| `#ConfigMapSchema` | `schemas/config.cue` | ConfigMap spec — accepts the full Kubernetes ConfigMap spec |
| `#SecretSchema` | `schemas/config.cue` | Secret spec — accepts the full Kubernetes Secret spec |
| `#IngressClassSchema` | `schemas/network.cue` | IngressClass spec — accepts the full Kubernetes IngressClass spec |
| `#IngressSchema` | `schemas/network.cue` | Ingress spec — accepts the full Kubernetes Ingress spec |
| `#NetworkPolicySchema` | `schemas/network.cue` | NetworkPolicy spec — accepts the full Kubernetes NetworkPolicy spec |
| `#ServiceSchema` | `schemas/network.cue` | Service spec — accepts the full Kubernetes Service spec |
| `#HorizontalPodAutoscalerSchema` | `schemas/policy.cue` | HorizontalPodAutoscaler spec — accepts the full Kubernetes HPA v2 spec |
| `#PodDisruptionBudgetSchema` | `schemas/policy.cue` | PodDisruptionBudget spec — accepts the full Kubernetes PodDisruptionBudget spec |
| `#ClusterRoleBindingSchema` | `schemas/rbac.cue` | ClusterRoleBinding spec — accepts the full Kubernetes ClusterRoleBinding spec |
| `#ClusterRoleSchema` | `schemas/rbac.cue` | ClusterRole spec — accepts the full Kubernetes ClusterRole spec |
| `#RoleBindingSchema` | `schemas/rbac.cue` | RoleBinding spec — accepts the full Kubernetes RoleBinding spec |
| `#RoleSchema` | `schemas/rbac.cue` | Role spec — accepts the full Kubernetes Role spec |
| `#ServiceAccountSchema` | `schemas/rbac.cue` | ServiceAccount spec — accepts the full Kubernetes ServiceAccount spec |
| `#PersistentVolumeClaimSchema` | `schemas/storage.cue` | PersistentVolumeClaim spec — accepts the full Kubernetes PVC spec |
| `#PersistentVolumeSchema` | `schemas/storage.cue` | PersistentVolume spec — accepts the full Kubernetes PV spec |
| `#StorageClassSchema` | `schemas/storage.cue` | StorageClass spec — accepts the full Kubernetes StorageClass spec |
| `#CronJobSchema` | `schemas/workload.cue` | CronJob spec — accepts the full Kubernetes CronJob spec |
| `#DaemonSetSchema` | `schemas/workload.cue` | DaemonSet spec — accepts the full Kubernetes DaemonSet spec |
| `#DeploymentSchema` | `schemas/workload.cue` | Deployment spec — accepts the full Kubernetes Deployment spec |
| `#JobSchema` | `schemas/workload.cue` | Job spec — accepts the full Kubernetes Job spec |
| `#PodSchema` | `schemas/workload.cue` | Pod spec — accepts the full Kubernetes Pod spec |
| `#StatefulSetSchema` | `schemas/workload.cue` | StatefulSet spec — accepts the full Kubernetes StatefulSet spec |

---
