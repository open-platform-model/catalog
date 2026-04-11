# ADR-003: Plural Resources and List-Output Signaling

## Status

Accepted (retroactive, 2026-03)

## Context

OPM resources originally followed a singular pattern: one ConfigMap resource per component, one Secret resource per component. This created an artificial 1:1 limitation — real workloads routinely need multiple ConfigMaps (application config, feature flags, environment-specific overrides) and multiple Secrets (TLS certificates, database credentials, API keys).

The singular pattern forced workarounds: either cramming unrelated configuration into a single ConfigMap, or splitting a logical component into multiple components just to get additional config resources. Both options degraded the component model.

A secondary problem arose from the fix: if a resource's spec becomes a map of named entries (each producing a separate Kubernetes object), transformers and consumers need to know whether a resource produces a single object or a keyed map of objects. Without an explicit signal, consumers would have to hard-code knowledge of which resources are plural, breaking composability.

A third problem followed from the signal: pipeline-internal annotations used for signaling (like the list-output marker) would leak into rendered Kubernetes manifests unless explicitly filtered. Annotations on resources propagate to components via existing comprehensions, meaning any annotation added for pipeline purposes would appear in the final Kubernetes output.

## Decision

Convert ConfigMap and Secret from singular to plural resources using a map-based spec pattern, signal plurality via an annotation, and filter pipeline-internal annotations from Kubernetes output.

**Plural resource pattern:** Rename `#ConfigMapResource` to `#ConfigMapsResource` and `#SecretResource` to `#SecretsResource`. The spec field becomes a map keyed by name: `#spec: configMaps: [name=string]: #ConfigMapSchema`. Each map entry produces a separate Kubernetes object. The per-item schema is unchanged — only the cardinality wrapper changes. This pattern was already proven by `#VolumesResource`.

**List-output annotation:** Add `transformer.opmodel.dev/list-output: "true"` to the resource metadata of plural resources. The annotation lives on the resource definition (which is intrinsically plural), not on the component or transformer. It propagates to the component automatically via existing annotation comprehensions. Transformers and consumers check for the annotation's presence to determine output shape; absence means single-object output (the default).

**Pipeline annotation filtering:** Filter all annotations with the `transformer.opmodel.dev/` prefix from `componentAnnotations` and `componentLabels` in `#TransformerContext` using `strings.HasPrefix`. This filtering happens in one place (the TransformerContext definition), not at each resource or trait schema. Module-level labels and annotations are never filtered — they carry identity and ownership semantics. The pipeline annotations still propagate through the component for internal use, but are stripped from rendered Kubernetes output.

**Alternatives considered:**

- **Embed the plurality signal in the core type system (e.g. a `plural: true` field on `#Resource`).** This would be more explicit but adds a field to the core primitive that only matters for transformer dispatch. Rejected because annotations are the established mechanism for behavior hints in OPM, and adding a field to core for a provider-level concern violates separation of concerns.

- **Have transformers inspect the spec structure to infer plurality.** This would avoid any signal but requires transformers to understand the internal structure of every resource they process. Rejected because it breaks encapsulation and makes the transformer contract implicit rather than declarative.

- **Filter annotations at the resource/trait schema level instead of TransformerContext.** This would distribute the filtering logic across many files. Rejected in favor of a single filtering point using the `transformer.opmodel.dev/` prefix convention.

## Consequences

**Positive:** Components can declare multiple ConfigMaps and Secrets naturally, matching real-world workload patterns. The map pattern is consistent with the existing VolumesResource precedent. The annotation-based signaling keeps the transformer contract declarative and composable — new plural resources only need to add the annotation, with no changes to consumer code. Pipeline-internal annotations are cleanly separated from Kubernetes output, preventing operational confusion from unexpected annotations on deployed resources.

**Negative:** This was a breaking API change — definition names, FQNs, and spec field names all changed. Existing modules referencing `#ConfigMapResource` or `#SecretResource` broke. Transformers changed from emitting a single object to iterating a map and emitting keyed output. The annotation-based signaling adds an implicit contract that is not enforced by the type system — a plural resource missing the annotation would silently produce incorrect output.

**Trade-off:** Using annotations for pipeline signaling keeps the core type system simple but creates a parallel contract that exists outside CUE's type checking. This is acceptable because the annotation is set on the resource definition (not by consumers), so the contract is maintained by catalog authors, not downstream users.
