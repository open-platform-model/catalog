## Why

Module authors need standalone ServiceAccounts and RBAC permissions as first-class OPM resources. The current WorkloadIdentity trait only covers workload-attached service accounts — it cannot model standalone identities (CI bots, controllers) or permission grants. Kubernetes RBAC primitives (Role, ClusterRole, RoleBinding, ClusterRoleBinding) are four separate objects glued by string-based name references, which is a limitation of YAML. CUE's reference system lets us collapse this into fewer, more composable resources where subjects are actual references carrying all required data.

## What Changes

- Add `#ServiceAccountSchema` to `schemas/security.cue` for standalone service account identity
- Add `#ServiceAccountResource` in `resources/security/service_account.cue` wrapping the schema with `core.#Resource`
- Add `#PolicyRuleSchema` and `#RoleSchema` to `schemas/security.cue` for RBAC permission rules with CUE-referenced subjects
- Add `#RoleResource` in `resources/security/role.cue` wrapping the schema with `core.#Resource`, supporting both namespace and cluster scope via a `scope` field (collapsing k8s Role/ClusterRole and RoleBinding/ClusterRoleBinding into one OPM resource)
- Add `#ServiceAccountResourceTransformer` in `providers/kubernetes/transformers/` converting SA resource to k8s ServiceAccount
- Add `#RoleTransformer` in `providers/kubernetes/transformers/` converting Role resource to k8s Role + RoleBinding (or ClusterRole + ClusterRoleBinding based on scope)

## Capabilities

### New Capabilities

- `service-account-resource`: Standalone ServiceAccount resource definition with schema, component mixin, and defaults. Independent of WorkloadIdentity trait — used for identities not attached to a workload.
- `role-resource`: RBAC Role resource definition with policy rules and CUE-referenced subjects. A single `scope` field (`namespace` or `cluster`) replaces the k8s Role/ClusterRole distinction. Subjects reference ServiceAccount or WorkloadIdentity objects directly via CUE references instead of string-based name bindings.
- `k8s-sa-resource-transformer`: Kubernetes transformer converting the standalone ServiceAccount resource to a k8s `v1/ServiceAccount` object. Separate from the existing WorkloadIdentity ServiceAccount transformer.
- `k8s-role-transformer`: Kubernetes transformer converting the Role resource to k8s RBAC objects. Generates both the Role/ClusterRole and the corresponding RoleBinding/ClusterRoleBinding from a single OPM resource — the user never authors bindings directly.

### Modified Capabilities

## Impact

- **Modules affected**: `schemas` (new schemas), `resources` (new resource definitions + new `security/` package), `providers` (new transformers)
- **SemVer**: MINOR — purely additive, no breaking changes to existing definitions
- **API**: New resource FQNs: `opmodel.dev/resources/security/service-account@v1`, `opmodel.dev/resources/security/role@v1`
- **Dependencies**: No new external dependencies. Resources depend on `core` and `schemas` (existing pattern). Providers depend on `core`, `schemas`, and new resources.
- **Portability**: ServiceAccount and Role resources express intent without provider-specific concerns. The k8s-specific RBAC mapping lives entirely in the provider transformers.
- **Existing code**: WorkloadIdentity trait and its existing ServiceAccount transformer are untouched. No breaking changes to downstream modules.
