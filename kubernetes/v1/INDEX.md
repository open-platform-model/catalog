# v1alpha1 — Definition Index

CUE module: `opmodel.dev/kubernetes/v1@v1`

---

## Project Structure

```
+-- providers/
|   +-- kubernetes/
|       +-- transformers/
+-- resources/
|   +-- admission/
|   |   +-- testdata/
|   +-- cluster/
|   +-- config/
|   |   +-- testdata/
|   +-- network/
|   |   +-- testdata/
|   +-- policy/
|   +-- rbac/
|   |   +-- testdata/
|   +-- storage/
|   |   +-- testdata/
|   +-- workload/
|       +-- testdata/
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
| `#ClusterRoleBindingTransformer` | `providers/kubernetes/transformers/cluster_role_binding_transformer.cue` | #ClusterRoleBindingTransformer passes native Kubernetes ClusterRoleBinding resources through with OPM context applied (name prefix, labels) |
| `#ClusterRoleTransformer` | `providers/kubernetes/transformers/cluster_role_transformer.cue` | #ClusterRoleTransformer passes native Kubernetes ClusterRole resources through with OPM context applied (name prefix, labels) |
| `#ConfigMapTransformer` | `providers/kubernetes/transformers/configmap_transformer.cue` | #ConfigMapTransformer passes native Kubernetes ConfigMap resources through with OPM context applied (name prefix, namespace, labels) |
| `#CronJobTransformer` | `providers/kubernetes/transformers/cronjob_transformer.cue` | #CronJobTransformer passes native Kubernetes CronJob resources through with OPM context applied (name prefix, namespace, labels) |
| `#DaemonSetTransformer` | `providers/kubernetes/transformers/daemonset_transformer.cue` | #DaemonSetTransformer passes native Kubernetes DaemonSet resources through with OPM context applied (name prefix, namespace, labels) |
| `#DeploymentTransformer` | `providers/kubernetes/transformers/deployment_transformer.cue` | #DeploymentTransformer passes native Kubernetes Deployment resources through with OPM context applied (name prefix, namespace, labels) |
| `#HorizontalPodAutoscalerTransformer` | `providers/kubernetes/transformers/hpa_transformer.cue` | #HorizontalPodAutoscalerTransformer passes native Kubernetes HPA resources through with OPM context applied (name prefix, namespace, labels) |
| `#IngressClassTransformer` | `providers/kubernetes/transformers/ingressclass_transformer.cue` | #IngressClassTransformer passes native Kubernetes IngressClass resources through with OPM context applied (name prefix, labels) |
| `#IngressTransformer` | `providers/kubernetes/transformers/ingress_transformer.cue` | #IngressTransformer passes native Kubernetes Ingress resources through with OPM context applied (name prefix, namespace, labels) |
| `#JobTransformer` | `providers/kubernetes/transformers/job_transformer.cue` | #JobTransformer passes native Kubernetes Job resources through with OPM context applied (name prefix, namespace, labels) |
| `#MutatingWebhookConfigurationTransformer` | `providers/kubernetes/transformers/mutating_webhook_transformer.cue` | #MutatingWebhookConfigurationTransformer passes native Kubernetes MutatingWebhookConfiguration resources through with OPM context applied |
| `#NamespaceTransformer` | `providers/kubernetes/transformers/namespace_transformer.cue` | #NamespaceTransformer passes native Kubernetes Namespace resources through with OPM context applied (name prefix, labels) |
| `#NetworkPolicyTransformer` | `providers/kubernetes/transformers/networkpolicy_transformer.cue` | #NetworkPolicyTransformer passes native Kubernetes NetworkPolicy resources through with OPM context applied (name prefix, namespace, labels) |
| `#PodDisruptionBudgetTransformer` | `providers/kubernetes/transformers/pdb_transformer.cue` | #PodDisruptionBudgetTransformer passes native Kubernetes PodDisruptionBudget resources through with OPM context applied (name prefix, namespace, labels) |
| `#PodTransformer` | `providers/kubernetes/transformers/pod_transformer.cue` | #PodTransformer passes native Kubernetes Pod resources through with OPM context applied (name prefix, namespace, labels) |
| `#PersistentVolumeClaimTransformer` | `providers/kubernetes/transformers/pvc_transformer.cue` | #PersistentVolumeClaimTransformer passes native Kubernetes PVC resources through with OPM context applied (name prefix, namespace, labels) |
| `#PersistentVolumeTransformer` | `providers/kubernetes/transformers/pv_transformer.cue` | #PersistentVolumeTransformer passes native Kubernetes PV resources through with OPM context applied (name prefix, labels) |
| `#RoleBindingTransformer` | `providers/kubernetes/transformers/role_binding_transformer.cue` | #RoleBindingTransformer passes native Kubernetes RoleBinding resources through with OPM context applied (name prefix, namespace, labels) |
| `#RoleTransformer` | `providers/kubernetes/transformers/role_transformer.cue` | #RoleTransformer passes native Kubernetes Role resources through with OPM context applied (name prefix, namespace, labels) |
| `#SecretTransformer` | `providers/kubernetes/transformers/secret_transformer.cue` | #SecretTransformer passes native Kubernetes Secret resources through with OPM context applied (name prefix, namespace, labels) |
| `#ServiceAccountTransformer` | `providers/kubernetes/transformers/serviceaccount_transformer.cue` | #ServiceAccountTransformer passes native Kubernetes ServiceAccount resources through with OPM context applied (name prefix, namespace, labels) |
| `#ServiceTransformer` | `providers/kubernetes/transformers/service_transformer.cue` | #ServiceTransformer passes native Kubernetes Service resources through with OPM context applied (name prefix, namespace, labels) |
| `#StatefulSetTransformer` | `providers/kubernetes/transformers/statefulset_transformer.cue` | #StatefulSetTransformer passes native Kubernetes StatefulSet resources through with OPM context applied (name prefix, namespace, labels) |
| `#StorageClassTransformer` | `providers/kubernetes/transformers/storageclass_transformer.cue` | #StorageClassTransformer passes native Kubernetes StorageClass resources through with OPM context applied (name prefix, labels) |
| `#TestCtx` | `providers/kubernetes/transformers/test_helpers.cue` | #TestCtx constructs a minimal concrete #TransformerContext for transformer tests |
| `#ValidatingWebhookConfigurationTransformer` | `providers/kubernetes/transformers/validating_webhook_transformer.cue` | #ValidatingWebhookConfigurationTransformer passes native Kubernetes ValidatingWebhookConfiguration resources through with OPM context applied |

---

## Resources

### admission

| Definition | File | Description |
|---|---|---|
| `#MutatingWebhookConfiguration` | `resources/admission/mutating_webhook.cue` |  |
| `#MutatingWebhookConfigurationDefaults` | `resources/admission/mutating_webhook.cue` |  |
| `#MutatingWebhookConfigurationResource` | `resources/admission/mutating_webhook.cue` | #MutatingWebhookConfigurationResource defines a native Kubernetes MutatingWebhookConfiguration as an OPM resource |
| `#ValidatingWebhookConfiguration` | `resources/admission/validating_webhook.cue` |  |
| `#ValidatingWebhookConfigurationDefaults` | `resources/admission/validating_webhook.cue` |  |
| `#ValidatingWebhookConfigurationResource` | `resources/admission/validating_webhook.cue` | #ValidatingWebhookConfigurationResource defines a native Kubernetes ValidatingWebhookConfiguration as an OPM resource |

### cluster

| Definition | File | Description |
|---|---|---|
| `#Namespace` | `resources/cluster/namespace.cue` |  |
| `#NamespaceDefaults` | `resources/cluster/namespace.cue` |  |
| `#NamespaceResource` | `resources/cluster/namespace.cue` | #NamespaceResource defines a native Kubernetes Namespace as an OPM resource |

### config

| Definition | File | Description |
|---|---|---|
| `#ConfigMap` | `resources/config/configmap.cue` |  |
| `#ConfigMapDefaults` | `resources/config/configmap.cue` |  |
| `#ConfigMapResource` | `resources/config/configmap.cue` | #ConfigMapResource defines a native Kubernetes ConfigMap as an OPM resource |
| `#Secret` | `resources/config/secret.cue` |  |
| `#SecretDefaults` | `resources/config/secret.cue` |  |
| `#SecretResource` | `resources/config/secret.cue` | #SecretResource defines a native Kubernetes Secret as an OPM resource |

### network

| Definition | File | Description |
|---|---|---|
| `#IngressClass` | `resources/network/ingressclass.cue` |  |
| `#IngressClassDefaults` | `resources/network/ingressclass.cue` |  |
| `#IngressClassResource` | `resources/network/ingressclass.cue` | #IngressClassResource defines a native Kubernetes IngressClass as an OPM resource |
| `#Ingress` | `resources/network/ingress.cue` |  |
| `#IngressDefaults` | `resources/network/ingress.cue` |  |
| `#IngressResource` | `resources/network/ingress.cue` | #IngressResource defines a native Kubernetes Ingress as an OPM resource |
| `#NetworkPolicy` | `resources/network/networkpolicy.cue` |  |
| `#NetworkPolicyDefaults` | `resources/network/networkpolicy.cue` |  |
| `#NetworkPolicyResource` | `resources/network/networkpolicy.cue` | #NetworkPolicyResource defines a native Kubernetes NetworkPolicy as an OPM resource |
| `#Service` | `resources/network/service.cue` |  |
| `#ServiceDefaults` | `resources/network/service.cue` |  |
| `#ServiceResource` | `resources/network/service.cue` | #ServiceResource defines a native Kubernetes Service as an OPM resource |

### policy

| Definition | File | Description |
|---|---|---|
| `#HorizontalPodAutoscaler` | `resources/policy/hpa.cue` |  |
| `#HorizontalPodAutoscalerDefaults` | `resources/policy/hpa.cue` |  |
| `#HorizontalPodAutoscalerResource` | `resources/policy/hpa.cue` | #HorizontalPodAutoscalerResource defines a native Kubernetes HPA v2 as an OPM resource |
| `#PodDisruptionBudget` | `resources/policy/pdb.cue` |  |
| `#PodDisruptionBudgetDefaults` | `resources/policy/pdb.cue` |  |
| `#PodDisruptionBudgetResource` | `resources/policy/pdb.cue` | #PodDisruptionBudgetResource defines a native Kubernetes PodDisruptionBudget as an OPM resource |

### rbac

| Definition | File | Description |
|---|---|---|
| `#ClusterRoleBinding` | `resources/rbac/cluster_role_binding.cue` |  |
| `#ClusterRoleBindingDefaults` | `resources/rbac/cluster_role_binding.cue` |  |
| `#ClusterRoleBindingResource` | `resources/rbac/cluster_role_binding.cue` | #ClusterRoleBindingResource defines a native Kubernetes ClusterRoleBinding as an OPM resource |
| `#ClusterRole` | `resources/rbac/cluster_role.cue` |  |
| `#ClusterRoleDefaults` | `resources/rbac/cluster_role.cue` |  |
| `#ClusterRoleResource` | `resources/rbac/cluster_role.cue` | #ClusterRoleResource defines a native Kubernetes ClusterRole as an OPM resource |
| `#RoleBinding` | `resources/rbac/role_binding.cue` |  |
| `#RoleBindingDefaults` | `resources/rbac/role_binding.cue` |  |
| `#RoleBindingResource` | `resources/rbac/role_binding.cue` | #RoleBindingResource defines a native Kubernetes RoleBinding as an OPM resource |
| `#Role` | `resources/rbac/role.cue` |  |
| `#RoleDefaults` | `resources/rbac/role.cue` |  |
| `#RoleResource` | `resources/rbac/role.cue` | #RoleResource defines a native Kubernetes Role as an OPM resource |
| `#ServiceAccount` | `resources/rbac/service_account.cue` |  |
| `#ServiceAccountDefaults` | `resources/rbac/service_account.cue` |  |
| `#ServiceAccountResource` | `resources/rbac/service_account.cue` | #ServiceAccountResource defines a native Kubernetes ServiceAccount as an OPM resource |

### storage

| Definition | File | Description |
|---|---|---|
| `#PersistentVolumeClaim` | `resources/storage/pvc.cue` |  |
| `#PersistentVolumeClaimDefaults` | `resources/storage/pvc.cue` |  |
| `#PersistentVolumeClaimResource` | `resources/storage/pvc.cue` | #PersistentVolumeClaimResource defines a native Kubernetes PVC as an OPM resource |
| `#PersistentVolume` | `resources/storage/pv.cue` |  |
| `#PersistentVolumeDefaults` | `resources/storage/pv.cue` |  |
| `#PersistentVolumeResource` | `resources/storage/pv.cue` | #PersistentVolumeResource defines a native Kubernetes PV as an OPM resource |
| `#StorageClass` | `resources/storage/storageclass.cue` |  |
| `#StorageClassDefaults` | `resources/storage/storageclass.cue` |  |
| `#StorageClassResource` | `resources/storage/storageclass.cue` | #StorageClassResource defines a native Kubernetes StorageClass as an OPM resource |

### workload

| Definition | File | Description |
|---|---|---|
| `#CronJob` | `resources/workload/cronjob.cue` |  |
| `#CronJobDefaults` | `resources/workload/cronjob.cue` |  |
| `#CronJobResource` | `resources/workload/cronjob.cue` | #CronJobResource defines a native Kubernetes CronJob as an OPM resource |
| `#DaemonSet` | `resources/workload/daemonset.cue` |  |
| `#DaemonSetDefaults` | `resources/workload/daemonset.cue` |  |
| `#DaemonSetResource` | `resources/workload/daemonset.cue` | #DaemonSetResource defines a native Kubernetes DaemonSet as an OPM resource |
| `#Deployment` | `resources/workload/deployment.cue` |  |
| `#DeploymentDefaults` | `resources/workload/deployment.cue` |  |
| `#DeploymentResource` | `resources/workload/deployment.cue` | #DeploymentResource defines a native Kubernetes Deployment as an OPM resource |
| `#Job` | `resources/workload/job.cue` |  |
| `#JobDefaults` | `resources/workload/job.cue` |  |
| `#JobResource` | `resources/workload/job.cue` | #JobResource defines a native Kubernetes Job as an OPM resource |
| `#Pod` | `resources/workload/pod.cue` |  |
| `#PodDefaults` | `resources/workload/pod.cue` |  |
| `#PodResource` | `resources/workload/pod.cue` | #PodResource defines a native Kubernetes Pod as an OPM resource |
| `#StatefulSet` | `resources/workload/statefulset.cue` |  |
| `#StatefulSetDefaults` | `resources/workload/statefulset.cue` |  |
| `#StatefulSetResource` | `resources/workload/statefulset.cue` | #StatefulSetResource defines a native Kubernetes StatefulSet as an OPM resource |

---

## Schemas

| Definition | File | Description |
|---|---|---|
| `#MutatingWebhookConfigurationSchema` | `schemas/admission.cue` | #MutatingWebhookConfigurationSchema accepts the full Kubernetes MutatingWebhookConfiguration spec |
| `#ValidatingWebhookConfigurationSchema` | `schemas/admission.cue` | #ValidatingWebhookConfigurationSchema accepts the full Kubernetes ValidatingWebhookConfiguration spec |
| `#NamespaceSchema` | `schemas/cluster.cue` | #NamespaceSchema accepts the full Kubernetes Namespace spec |
| `#ConfigMapSchema` | `schemas/config.cue` | #ConfigMapSchema accepts the full Kubernetes ConfigMap spec |
| `#SecretSchema` | `schemas/config.cue` | #SecretSchema accepts the full Kubernetes Secret spec |
| `#IngressClassSchema` | `schemas/network.cue` | #IngressClassSchema accepts the full Kubernetes IngressClass spec |
| `#IngressSchema` | `schemas/network.cue` | #IngressSchema accepts the full Kubernetes Ingress spec |
| `#NetworkPolicySchema` | `schemas/network.cue` | #NetworkPolicySchema accepts the full Kubernetes NetworkPolicy spec |
| `#ServiceSchema` | `schemas/network.cue` | #ServiceSchema accepts the full Kubernetes Service spec |
| `#HorizontalPodAutoscalerSchema` | `schemas/policy.cue` | #HorizontalPodAutoscalerSchema accepts the full Kubernetes HPA v2 spec |
| `#PodDisruptionBudgetSchema` | `schemas/policy.cue` | #PodDisruptionBudgetSchema accepts the full Kubernetes PodDisruptionBudget spec |
| `#ClusterRoleBindingSchema` | `schemas/rbac.cue` | #ClusterRoleBindingSchema accepts the full Kubernetes ClusterRoleBinding spec |
| `#ClusterRoleSchema` | `schemas/rbac.cue` | #ClusterRoleSchema accepts the full Kubernetes ClusterRole spec |
| `#RoleBindingSchema` | `schemas/rbac.cue` | #RoleBindingSchema accepts the full Kubernetes RoleBinding spec |
| `#RoleSchema` | `schemas/rbac.cue` | #RoleSchema accepts the full Kubernetes Role spec |
| `#ServiceAccountSchema` | `schemas/rbac.cue` | #ServiceAccountSchema accepts the full Kubernetes ServiceAccount spec |
| `#PersistentVolumeClaimSchema` | `schemas/storage.cue` | #PersistentVolumeClaimSchema accepts the full Kubernetes PVC spec |
| `#PersistentVolumeSchema` | `schemas/storage.cue` | #PersistentVolumeSchema accepts the full Kubernetes PV spec |
| `#StorageClassSchema` | `schemas/storage.cue` | #StorageClassSchema accepts the full Kubernetes StorageClass spec |
| `#CronJobSchema` | `schemas/workload.cue` | #CronJobSchema accepts the full Kubernetes CronJob spec |
| `#DaemonSetSchema` | `schemas/workload.cue` | #DaemonSetSchema accepts the full Kubernetes DaemonSet spec |
| `#DeploymentSchema` | `schemas/workload.cue` | #DeploymentSchema accepts the full Kubernetes Deployment spec |
| `#JobSchema` | `schemas/workload.cue` | #JobSchema accepts the full Kubernetes Job spec |
| `#PodSchema` | `schemas/workload.cue` | #PodSchema accepts the full Kubernetes Pod spec |
| `#StatefulSetSchema` | `schemas/workload.cue` | #StatefulSetSchema accepts the full Kubernetes StatefulSet spec |

---

