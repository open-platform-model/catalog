## Why

The OPM catalog currently has only two resources (Container, Volumes). Real-world workloads need external configuration, secrets management, and workload identity as fundamental primitives. Schemas for ConfigMap and Secret already exist in `schemas/config.cue` but have no resource definitions wrapping them, meaning they cannot be referenced by components, matched by transformers, or composed into blueprints.

## What Changes

- Add `config/ConfigMap` resource definition wrapping the existing `#ConfigMapSchema`
- Add `config/Secret` resource definition wrapping the existing `#SecretSchema`
- Add `security/WorkloadIdentity` resource definition with a new `#WorkloadIdentitySchema`
- Add `#WorkloadIdentitySchema` to `schemas/security.cue` (new file)

## Capabilities

### New Capabilities

- `configmap-resource`: Resource definition for ConfigMap, wrapping `#ConfigMapSchema`. Enables components to declare external configuration that transformers can emit as platform-native config objects.
- `secret-resource`: Resource definition for Secret, wrapping `#SecretSchema`. Enables components to declare sensitive configuration that transformers can emit as platform-native secret objects.
- `workload-identity-resource`: Resource definition for WorkloadIdentity with a new `#WorkloadIdentitySchema`. Enables components to declare a workload identity (name, token automount) that transformers can emit as platform-native identity objects.

### Modified Capabilities

_None. These are purely additive resources._

## Impact

- **Modules affected**: `schemas` (new `#WorkloadIdentitySchema`), `resources` (new resource definitions)
- **SemVer**: MINOR — purely additive, no breaking changes
- **API**: New resource FQNs: `opmodel.dev/resources/config@v0#ConfigMap`, `opmodel.dev/resources/config@v0#Secret`, `opmodel.dev/resources/security@v0#WorkloadIdentity`
- **Dependencies**: No new external dependencies. Resources depend on `core` and `schemas` (existing pattern)
- **Portability**: Fully provider-agnostic. All three resources express intent without platform-specific concerns.
- **Downstream**: The `add-transformers` change will create K8s transformers consuming these resources.
