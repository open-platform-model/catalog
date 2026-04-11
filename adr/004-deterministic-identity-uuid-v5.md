# ADR-004: Deterministic Identity via UUID v5

## Status

Accepted (retroactive, 2026-03)

## Context

The CLI needs stable, collision-proof identifiers for Module and ModuleRelease to support reliable discovery operations (`mod delete`, `mod status`, future `mod list`). Existing metadata fields — name, FQN, version, namespace — are not individually unique enough. Two modules with the same name in different registries, or two releases of the same module in the same namespace with different versions, can collide on any single field.

Kubernetes labels have a 63-character value limit, which rules out concatenating multiple metadata fields into a label. A composite key approach (matching on multiple labels simultaneously) works but is fragile — it requires every consumer to know the exact set of fields that form the identity, and any change to that set breaks all consumers.

CUE v0.15.x introduced `uuid.SHA1` (UUID v5), which computes a deterministic UUID from a namespace and a string input. This enables identity to be derived purely in CUE at evaluation time — no runtime generation, no external state, no CLI involvement.

## Decision

Add computed, deterministic UUID v5 identity fields to `#Module` and `#ModuleRelease` metadata using CUE's `uuid.SHA1` function.

**OPM namespace:** Define a constant `OPMNamespace` UUID that serves as the UUID v5 namespace for all OPM identity computations. All UUIDs are derived from this namespace, ensuring they do not collide with UUIDs from other systems.

**Module identity:** `#Module.metadata.uuid` is computed as `uuid.SHA1(OPMNamespace, "{fqn}:{version}")`. The FQN and version together uniquely identify a module across all registries and versions. The UUID changes when the version changes.

**ModuleRelease identity:** `#ModuleRelease.metadata.uuid` is computed as `uuid.SHA1(OPMNamespace, "{fqn}:{name}:{namespace}")`. Version is deliberately excluded — a release identity is stable across upgrades of the underlying module version. This means `mod delete` and `mod status` can target a release without knowing its current version.

**Labels:** The computed UUIDs are exposed as `module.opmodel.dev/uuid` and `module-release.opmodel.dev/uuid` labels, which the CLI uses for Kubernetes label selectors during discovery.

**Non-overridable:** Because the UUID is a computed concrete value in CUE, any attempt to set a different value causes a unification conflict. This enforces identity correctness — consumers cannot accidentally or intentionally override the computed identity.

**Alternatives considered:**

- **Generate UUIDs at CLI runtime (UUID v4).** Random UUIDs would guarantee uniqueness but are not deterministic — the same module evaluated twice would get different identities. This breaks idempotent deployments and makes it impossible to derive identity from the module definition alone. Rejected because it violates the self-describing distribution principle.

- **Use a hash of the full CUE evaluation output.** This would be deterministic but would change whenever any field in the module changes, even non-identity fields like documentation strings. Rejected because identity should be stable across cosmetic changes.

- **Use composite label selectors (match on FQN + name + namespace) without a UUID.** This works but is fragile: every consumer must know the exact label combination, and adding a new identity dimension requires updating all consumers. Rejected because a single UUID label is simpler and more robust.

## Consequences

**Positive:** The CLI can discover and manage releases using a single label selector (`module-release.opmodel.dev/uuid=<value>`) instead of matching on multiple fields. Identity is deterministic and reproducible — evaluating the same module definition always produces the same UUID. The identity is self-describing: it is derived from the module definition in CUE, with no external state or runtime generation required. The non-overridable property prevents identity corruption.

**Negative:** The identity computation depends on CUE's `uuid.SHA1` function, which ties the catalog to CUE v0.15.x or later. The UUID is opaque — unlike a composite key, you cannot read the identity and understand which module it refers to without looking up the source fields. ModuleRelease identity deliberately excludes version, which means two releases of different versions of the same module in the same namespace share an identity — this is intentional (stable across upgrades) but could surprise contributors who expect version to be part of identity.

**Trade-off:** Excluding version from ModuleRelease identity means the identity is stable across upgrades but cannot distinguish between two releases of different versions of the same module in the same namespace. This is the correct trade-off for the CLI's primary use cases (delete, status), where you want to target "the release of module X in namespace Y" regardless of which version is currently deployed.
