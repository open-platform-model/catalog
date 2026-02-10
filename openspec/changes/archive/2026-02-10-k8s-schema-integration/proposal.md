## Why

Transformer outputs are hand-written K8s resource structures with no type safety. If a transformer generates invalid K8s YAML (wrong field names, incorrect types, missing required fields), this is only caught at apply-time when K8s rejects the resource. By integrating upstream CUE K8s schemas, we get compile-time validation that transformer outputs match real K8s API schemas.

This is a MINOR change - adds new capability without breaking existing APIs.

## What Changes

- Create new CUE module `opmodel.dev/schemas/kubernetes@v0` in `v0/schemas_kubernetes/`
- Re-export upstream `cue.dev/x/k8s.io@v0` schemas with explicit type definitions
- Pin to `cue.dev/x/k8s.io@v0: v0.6.0` (K8s 1.31+ schemas)
- Start with 5 API groups needed by current transformers: `apps/v1`, `batch/v1`, `core/v1`, `networking/v1`, `autoscaling/v2`
- Document remaining API groups for future expansion

## Capabilities

### New Capabilities

- `k8s-schema-reexport`: Re-export upstream K8s CUE schemas as OPM-controlled module with version indirection

### Modified Capabilities
<!-- None - this adds a new module without changing existing specs -->

## Impact

- **New module**: `v0/schemas_kubernetes/` with module path `opmodel.dev/schemas/kubernetes@v0`
- **Providers module**: Will gain dependency on `opmodel.dev/schemas/kubernetes@v0`
- **Transformers**: Can optionally unify output with K8s schema types for validation (separate change)
- **No breaking changes**: Existing code continues to work; schema integration is additive
