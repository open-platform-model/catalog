## Why

OPM has no way to deploy Kubernetes CRDs (CustomResourceDefinition objects) as part of a module. Operators like Grafana, cert-manager, and Postgres require their CRDs to be present in the cluster before any instances can be created. Users need to vendor these CRDs alongside their modules so they are installed atomically.

## What Changes

- New `#CRDSchema` in the `schemas` module capturing structured CRD fields (group, names, scope, versions) with an open `openAPIV3Schema` for arbitrary vendor schemas
- New `extension` package in the `resources` module with a `#CRDsResource` map-based resource and `#CRDs` component helper
- New apiextensions/v1 wrapper in the `schemas/kubernetes` module exposing `#CustomResourceDefinition` from `cue.dev/x/k8s.io`
- New `#CRDTransformer` in the `providers/kubernetes` module that converts `#CRDsResource` entries into K8s `CustomResourceDefinition` objects
- Registration of the new transformer in the Kubernetes provider

## Capabilities

### New Capabilities
- `crds-resource`: A map-based OPM resource allowing users to define one or more CRDs by providing their group, names, scope, and version schemas. Deployed to the cluster via the Kubernetes CRD transformer.

### Modified Capabilities

## Impact

- **`opmodel.dev/schemas@v0`** (MINOR): New `extension.cue` file with `#CRDSchema`
- **`opmodel.dev/resources@v0`** (MINOR): New `extension/` package with `#CRDsResource`, `#CRDs`, `#CRDsDefaults`
- **`opmodel.dev/schemas/kubernetes@v0`** (MINOR): New `apiextensions/v1/` package wrapping `#CustomResourceDefinition`
- **`opmodel.dev/providers@v0`** (MINOR): New `#CRDTransformer` and registration in the Kubernetes provider
- No breaking changes; all additions are additive
- SemVer: MINOR across all four affected modules
