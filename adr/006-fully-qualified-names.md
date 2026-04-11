# ADR-006: Fully Qualified Names (FQN)

## Status

Accepted (retroactive, 2026-04)

## Context

Every primitive definition (Resource, Trait, Blueprint, PolicyRule, Directive, Transformer), module, and bundle in the catalog needs a stable, globally unique identifier that encodes its origin, purpose, and compatibility level. This identifier must:

- Be globally unique across registries and organizations.
- Encode the compatibility boundary (major version for primitives, SemVer for modules).
- Be deterministic — derived entirely from the definition's metadata, not assigned externally.
- Be human-readable — unlike a UUID, an operator should be able to read an FQN and know what it refers to and where it came from.
- Serve as the input to UUID v5 computation (see ADR-004).
- Act as the matching key for transformer selection (see Transformer Matching below).

Without a formal convention, naming could drift across registries, collide between organizations, or encode version information inconsistently — breaking matching, identity, and dependency resolution.

### Transformer Matching

The render pipeline uses FQN as the primary key for binding components to transformers. Each component declares `#resources` and `#traits` maps keyed by primitive FQN. Each transformer declares `requiredResources`, `requiredTraits`, and `requiredDirectives` maps (plus optional variants) also keyed by FQN. The matching algorithm performs set intersection: a transformer is eligible for a component when the component's FQN keyset satisfies the transformer's required FQN keyset.

This means FQN is not just an identifier — it is the contract surface between module authors and provider authors. A module author declares *what* a component needs by embedding primitives (which contribute FQN keys); a provider author declares *what* their transformer can handle by listing the FQNs it requires. Neither side references the other directly — the FQN keysets are the only coupling point.

## Decision

Every definition computes a `fqn` field from three metadata values: `modulePath`, `name`, and `version`. The computation is a CUE string template embedded in each primitive's metadata block — authors do not write FQN strings; they set the three inputs and the schema assembles the result.

**Three FQN formats exist, distinguished by what they identify:**

**Primitive FQN** (`#FQNType`) — for Resources, Traits, Blueprints, PolicyRules, Directives, and Transformers:

    {modulePath}/{name}@{version}

- Delimiter: `@` — signals an API contract boundary.
- Version: major-only (`v1`, `v2`) — primitives follow a major-version compatibility model where all `v1` definitions are wire-compatible.
- Regex: `^[a-z0-9.-]+(/[a-z0-9.-]+)*/[a-z0-9]([a-z0-9-]*[a-z0-9])?@v[0-9]+$`
- Example: `opmodel.dev/opm/resources/workload/container@v1`

**Module FQN** (`#ModuleFQNType`) — for Modules:

    {modulePath}/{name}:{version}

- Delimiter: `:` — mirrors container image tagging conventions.
- Version: full SemVer (`1.2.3`, `0.1.0-rc.1`) — modules carry precise version information for dependency resolution.
- Regex: `^[a-z0-9.-]+(/[a-z0-9.-]+)*/[a-z0-9]([a-z0-9-]*[a-z0-9])?:\d+\.\d+\.\d+.*$`
- Example: `opmodel.dev/opm/modules/my-app:1.2.3`

**Bundle FQN** (`#BundleFQNType`) — for Bundles:

    {modulePath}/{name}:{version}

- Delimiter: `:` — same container-image-style as modules.
- Version: major-only (`v1`, `v2`) — bundles version their composition contract at the major level.
- Regex: `^[a-z0-9.-]+(/[a-z0-9.-]+)*/[a-z0-9]([a-z0-9-]*[a-z0-9])?:v[0-9]+$`
- Example: `opmodel.dev/opm/bundles/game-stack:v1`

**Shared constraints across all formats:**

- `modulePath`: a registry-rooted path (`[a-z0-9.-]+(/[a-z0-9.-]+)*`), validated by `#ModulePathType`, max 254 characters.
- `name`: RFC 1123 DNS label — lowercase alphanumeric, hyphens allowed mid-string, 1–63 characters.
- The `fqn` field is computed and non-overridable: setting a conflicting value causes a CUE unification error, enforcing correctness by construction.

**Alternatives considered:**

- *Flat name + version* (e.g., `container@v1`): No registry scope — would collide across organizations.
- *URN-style* (e.g., `urn:opm:opmodel.dev:resources:container:v1`): Verbose, unfamiliar in the container/Kubernetes ecosystem, no tooling benefit.
- *Single delimiter for all types*: Using `@` everywhere (or `:` everywhere) would lose the semantic signal — `@` implies an API contract boundary (primitives), `:` implies a tagged artifact (modules, bundles). The distinction maps to how each type is versioned and consumed.

## Consequences

**Positive:** FQN is human-readable and self-describing — given `opmodel.dev/opm/traits/workload/scaling@v1`, an operator knows the registry, category path, definition name, and compatibility level without looking anything up. This supports the Self-Describing Distribution principle.

**Positive:** The delimiter convention (`@` vs `:`) communicates the versioning model at a glance. Primitives use `@` (major-version API contract); modules and bundles use `:` (artifact tagging). Teams familiar with container images or Go module paths recognize the conventions immediately.

**Positive:** Because FQN is computed from metadata and regex-validated, it cannot be malformed or inconsistent with the definition's declared identity. The schema enforces the invariant — no runtime validation or linting step is needed.

**Negative:** Three FQN formats means consumers (CLI, controller, documentation tooling) must handle each variant. The CLI already does this via CUE evaluation rather than string parsing, which absorbs the complexity, but any new consumer must be aware of the distinction.

**Trade-off:** Encoding the registry path in the FQN makes definitions location-aware. A definition moved between registries gets a new FQN (and therefore a new UUID). This is intentional — the registry is part of the trust boundary — but means that forking or mirroring a definition creates a distinct identity rather than an alias.
