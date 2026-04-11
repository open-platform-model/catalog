# ADR-005: Release-Prefixed Kubernetes Naming

## Status

Accepted (retroactive, 2026-03)

## Context

Transformers originally named Kubernetes resources using only the component name — for example, a Deployment transformer would emit a Deployment named `{component}`. This works when a single release of a module exists in a namespace, but fails when multiple releases coexist: two releases of the same module in the same namespace would produce identically-named Kubernetes resources, causing one to overwrite the other.

This collision problem was not theoretical. The bundle system (which deploys multiple related modules into a namespace) and multi-environment testing (deploying the same module with different configurations) both require multiple releases to coexist safely.

Additionally, the HPA and Ingress transformers had bugs where they did not propagate any naming prefix at all, meaning their output could collide even across different modules if component names happened to match.

## Decision

All transformer output now names Kubernetes resources using the pattern `{releaseName}-{componentName}` (or `{releaseName}-{componentName}-{resourceName}` for plural resources). The release name is sourced from `#TransformerContext.#moduleReleaseMetadata.name`, which is always available when a ModuleRelease is evaluated.

This naming convention applies uniformly to all transformers — Deployments, StatefulSets, Services, ConfigMaps, Secrets, HPA, Ingress, CRDs, and any future transformer. There are no exceptions.

The release name is set by the ModuleRelease author (the person deploying the module), not by the module author. This means the module definition remains portable and release-agnostic, while the concrete Kubernetes naming is determined at deployment time.

**Alternatives considered:**

- **Use namespace isolation instead of name prefixing.** Deploy each release into its own namespace to avoid name collisions entirely. Rejected because it forces an opinionated namespace-per-release topology that conflicts with common patterns like deploying related services into a shared namespace. It also complicates network policies, RBAC, and service discovery between co-deployed modules.

- **Use a hash suffix instead of the release name.** Append a short hash of the release identity to resource names (e.g. `{component}-{hash}`). This avoids collisions but produces opaque names that are difficult to correlate with releases during debugging. Rejected because operational clarity is more valuable than name brevity.

- **Make prefixing optional via a flag on the ModuleRelease.** Allow users to opt out of prefixing for single-release scenarios. Rejected because conditional naming creates two code paths in every transformer and makes it possible to accidentally deploy without prefixing, discovering the collision only when a second release is added.

## Consequences

**Positive:** Multiple releases of the same module can coexist in a single namespace without resource name collisions. The naming pattern is predictable and human-readable — given a release name and component name, you can derive the expected Kubernetes resource name without inspecting the cluster. All transformers follow the same convention, eliminating the class of bugs where individual transformers forgot to include the prefix (as previously happened with HPA and Ingress).

**Negative:** This was a breaking change for existing deployments. Upgrading a module with the new naming convention creates new Kubernetes resources alongside the old ones (which retain their unprefixed names), requiring manual cleanup or a migration step. All Kubernetes resource names are now longer, which can approach the 253-character DNS name limit in extreme cases with long release names and component names. Consumers who reference Kubernetes resources by name (e.g. in external monitoring or scripts) must update those references to include the release prefix.

**Trade-off:** Uniform prefixing adds verbosity to every resource name, even in the common single-release case where collisions are impossible. This is accepted because the alternative — conditional prefixing — creates complexity in every transformer and a latent collision risk that only manifests when a second release is deployed, which is the worst time to discover a naming problem.
