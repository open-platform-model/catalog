## Context

OPM modules deploy workloads and their configuration, but have no mechanism for installing Kubernetes CRDs. Operators (Grafana, cert-manager, Postgres, etc.) require their CRDs to be present in the cluster before custom resources can be created. Users currently have no way to vendor these CRDs as part of a module, forcing out-of-band CRD management.

The existing resource pattern (ConfigMaps, Secrets, Volumes) is a proven, map-based model: a resource defines a map of named entries with a shared schema, and a transformer emits one Kubernetes object per entry. CRDs follow this same shape.

## Goals / Non-Goals

**Goals:**

- Add a map-based `#CRDsResource` allowing users to define one or more CRDs per component
- Define `#CRDSchema` capturing the essential CRD fields in a structured, type-safe way
- Expose `#CustomResourceDefinition` from `cue.dev/x/k8s.io` in the `schemas/kubernetes` module
- Add a `#CRDTransformer` that emits validated K8s `CustomResourceDefinition` objects

**Non-Goals:**

- CRD instance creation (creating objects of a custom type — separate future capability)
- CRD lifecycle ordering / install-before-workload sequencing (future lifecycle spec concern)
- Validation of `openAPIV3Schema` content (open struct; vendor schemas are too varied)
- Non-Kubernetes provider support for CRDs

## Decisions

### 1. Map-based resource (same pattern as ConfigMaps/Secrets)

**Decision**: `#CRDsResource` uses `crds: [name=string]: #CRDSchema` — a map where each key is a CRD identifier.

**Rationale**: Consistent with existing resources. The `"transformer.opmodel.dev/list-output": true` annotation already signals to the runtime that the transformer iterates over entries. Singular resources (like Container) would require a different transformer shape.

**Alternative considered**: A list-based resource (`crds: [...#CRDSchema]`). Rejected because map-keyed resources provide stable identity for diffing and updates.

### 2. Structured schema with open `openAPIV3Schema`

**Decision**: `#CRDSchema` captures structured top-level CRD fields (`group`, `names`, `scope`, `versions`) but leaves `versions[].schema.openAPIV3Schema` as `{...}` (open struct).

**Rationale**: The top-level CRD fields are stable, small, and benefit from type safety. The `openAPIV3Schema` content is arbitrary per vendor; constraining it would require replicating the full JSON Schema spec and would break on any vendor-specific extension. Principle VII (YAGNI) applies.

**Alternative considered**: Wrapping `#JSONSchemaProps` from apiextensions. Rejected because `#JSONSchemaProps` is a large recursive type that causes CUE evaluation overhead and adds complexity with no practical benefit for vendoring.

### 3. New `extension/` package in `resources` module

**Decision**: Place `#CRDsResource` in `v1alpha1/resources/extension/` package.

**Rationale**: CRDs don't belong in `config/` (configuration data), `security/` (IAM/RBAC), `storage/` (volumes), or `workload/` (containers). An `extension/` package cleanly groups Kubernetes extension mechanisms. Future additions (e.g., operator bundles) fit here.

### 4. New `apiextensions/v1` wrapper in `schemas/kubernetes`

**Decision**: Add `v1alpha1/schemas/kubernetes/apiextensions/v1/types.cue` re-exporting `#CustomResourceDefinition` from `cue.dev/x/k8s.io/apiextensions-apiserver/pkg/apis/apiextensions/v1`.

**Rationale**: Consistent with how other K8s types are wrapped (`core/v1`, `apps/v1`, etc.). The transformer imports from the wrapper, not directly from `cue.dev/x/k8s.io`, keeping the import graph consistent and allowing future schema augmentation.

## Risks / Trade-offs

- **Open `openAPIV3Schema`**: Users can write invalid CRD schemas that only fail at `kubectl apply` time, not at OPM validation time. Mitigation: document that OPM validates structure but not schema content.
- **Cluster-scoped CRDs in namespaced release**: CRDs are cluster-scoped objects. Deploying them via a namespaced module release requires the provider runtime to handle cluster-scoped output correctly. Mitigation: the transformer emits valid `CustomResourceDefinition` objects; runtime routing is the provider's responsibility, which already handles this for other cluster-scoped objects.
- **CRD ordering**: CRDs must be present before instances are created. OPM has no install-ordering mechanism yet. Mitigation: out of scope; noted in Non-Goals. Users deploy CRD-only components first if needed.

## Migration Plan

All additions are additive. No existing resources, traits, or transformers are modified. No migration required. Modules not using `#CRDs` are unaffected.

## Open Questions

- Should the transformer set a specific `labels` or `annotations` convention on emitted CRDs (e.g., `app.kubernetes.io/managed-by: open-platform-model`)? Current approach: use `#context.labels` consistent with other transformers.
