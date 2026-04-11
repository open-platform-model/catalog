# Design Decisions — `#Offer` Primitive

## Summary

Decision log for all design choices in the `#Offer` primitive enhancement. This enhancement realizes the `#Offer` counterpart to `#Claim` (enhancement 006), deferred in 006's decision D6.

---

## Decisions

### D1: `#Offer` is module-level, not component-level

**Decision:** Offers are declared on `#Module` via a new `#offers` field. They are not composable into Blueprints.

**Alternatives considered:**
- Component-level (like Claims) with Blueprint composition — rejected: a capability is provided by the whole module (e.g., the K8up operator), not by a single component. Blueprint composition does not apply to capability declarations.
- Both module-level and component-level — rejected: unnecessary complexity. The module is the natural boundary for "what does this installation provide?"

**Rationale:** A module deploys a Kubernetes operator (K8up, cert-manager). The operator provides capabilities to the platform. The capability belongs to the module, not to any individual component within it. This mirrors real infrastructure: you install an operator (module), and it provides capabilities (offers) that workloads (components) can consume (claims).

**Source:** User decision 2026-04-01.

---

### D2: Claims and Offers always come in pairs

**Decision:** Every well-known Claim definition has a paired well-known Offer definition. They share the same major version. Multiple providers can implement the same Offer.

**Alternatives considered:**
- Offers without paired Claims (standalone capability declarations) — rejected: an Offer that no Claim references is useless. The pair is the contract.
- One-to-one pairing (each Offer can only be implemented by one provider) — rejected: defeats the purpose. K8up and Velero should both be able to implement `#BackupOffer`.

**Rationale:** The Claim is the demand; the Offer is the supply. The pair defines the contract. The well-known definitions (published in the OPM catalog) are the standard contracts. Providers implement the standard Offer definitions, ensuring interchangeability.

**Source:** User decision 2026-04-01.

---

### D3: Offer versioning uses major-only FQN with optional `implVersion` semver

**Decision:** Offer FQNs use `#MajorVersionType` (e.g., `@v1`), matching the Claim FQN pattern. An optional `implVersion` field carries the implementation's semver (e.g., `"1.2.0"`).

**Alternatives considered:**
- Full semver in FQN — rejected: breaks the existing `#FQNType` pattern used by all primitives. Would require changing the type system.
- Semver on Claim too — rejected: Claims are stable contracts. Minor version evolution in a claim shape would create backward compatibility concerns.

**Rationale:** Major version is the compatibility key. If `#BackupClaim@v1` exists, then `#BackupOffer@v1` satisfies it. Minor/patch on the Offer (via `implVersion`) is informational — it allows providers to advertise maturity without affecting the contract. When a breaking change is needed, both Claim and Offer move to `@v2`.

**Source:** User decision 2026-04-01.

---

### D4: Offers are linked to Transformers

**Decision:** A capability Offer carries its Transformers via `#transformers`. The Provider derives its transformer registry from its Offers. This creates a formal link: Offer → Transformer → rendered resources.

**Alternatives considered:**
- Independent (Offer and Transformer are separate, correlated by convention) — rejected: loses the packaging benefit. The whole point is that K8up ships controller + Offer + Transformer as a unit.
- Transformer references Offer (inverse link) — rejected: Transformers already have `requiredClaims`. Adding an Offer reference would create a circular dependency in the type system.

**Rationale:** The link enables capability providers (K8up, Velero, cert-manager, Grafana) to package everything relevant together. The Offer is the central artifact. The Provider derives transformers from Offers, ensuring consistency.

**Source:** User decision 2026-04-01.

---

### D5: Offers have two flavors — capability (with transformers) and data (with shape)

**Decision:** Capability offers carry `#transformers` and no `#shape`. Data offers carry `#shape` and no `#transformers`. The flavor is implicit based on which optional fields are present.

**Alternatives considered:**
- Explicit `type` field — rejected: the presence of `#transformers` vs `#shape` already communicates the flavor. An explicit type field adds redundancy.
- Only capability offers (data claims fulfilled solely by external binding) — rejected: data offers enable the platform to report "Postgres is available" even for operator-managed databases like CloudNativePG.

**Rationale:** Mirrors the two Claim flavors from enhancement 006 (D5). Operational/capability claims have transformers; data claims have shapes. The Offer mirrors the same split. One primitive, two flavors.

**Source:** Design discussion 2026-04-01; mirrors 006 D5.

---

### D6: `#Provider` gains `#offers` and `#declaredOffers`

**Decision:** `#Provider` gains an optional `#offers: offer.#OfferMap` field and a computed `#declaredOffers` list. Providers that are pure rendering engines (base Kubernetes) have no offers. Capability providers (K8up, cert-manager) have offers.

**Alternatives considered:**
- Offers only on Module, not on Provider — rejected: the Platform composes Providers. If Offers only live on Modules, the Platform has no way to aggregate them. Offers must flow through the Provider composition chain.
- Offers only on Provider, not on Module — rejected: the Module is the installable unit. A future controller discovers modules, not providers. The Module must declare its Offers.

**Rationale:** Offers live on both Module (declaration for discovery) and Provider (for Platform composition). The Provider's `#offers` is the technical integration point; the Module's `#offers` is the logical declaration.

**Source:** Design discussion 2026-04-01.

---

### D7: `#Platform` gains `#composedOffers`, `#declaredOffers`, and `#satisfiedClaims`

**Decision:** Platform composes Offers from all Providers (like it composes Transformers) and computes `#satisfiedClaims` — the list of Claim FQNs that the Platform can fulfill via Offers. These fields extend enhancement 008's `#Platform` definition.

**Alternatives considered:**
- No platform-level offer aggregation (leave it to CLI logic) — rejected: CUE-level computation enables validation at definition time, not just CLI time.

**Rationale:** Follows the same composition pattern as `#composedTransformers` (enhancement 008). CUE struct unification handles merging. `#satisfiedClaims` enables the capability report and pre-render validation.

**Source:** Design discussion 2026-04-01.

---

### D8: PlatformCapability CRD is deferred

**Decision:** The OPM controller creating `PlatformCapability` CRD instances from Offers is deferred to a future enhancement. The `#Offer` primitive is independent and can be implemented first.

**Rationale:** The CRD design involves controller lifecycle, discovery mechanism, scope decisions, and conflict resolution — all topics that require dedicated discussion. The `#Offer` primitive provides value immediately (capability reporting, validation) without the CRD.

**Source:** User decision 2026-04-01. See [notes.md](notes.md) for open questions.

---

### D9: Modules can have both Claims and Offers

**Decision:** A module can declare Offers (module-level) while its components declare Claims (component-level). This creates dependency chains (e.g., CloudNativePG offers Postgres, claims S3).

**Alternatives considered:**
- Mutual exclusion (a module is either a consumer or a provider) — rejected: real operators have dependencies. CloudNativePG needs S3 for WAL archiving. An S3 operator might need TLS certificates.

**Rationale:** Dependency chains are a natural consequence of composable infrastructure. The platform team ensures all claims are satisfiable by installing the right modules and/or providing external bindings.

**Source:** User decision 2026-04-01.

---

### D10: Well-known Offer definitions live in `opm/v1alpha1/offers/`

**Decision:** Standard Offer definitions are organized by domain: `offers/ops/` (backup, restore), `offers/data/` (postgres, redis, mysql, s3), `offers/network/` (http-server, grpc-server), `offers/security/` (certificate).

**Alternatives considered:**
- Co-located with Claims (same directory) — rejected: Claims and Offers have different module paths. Keeping them separate follows the existing organizational pattern.
- In `core/` — rejected: well-known types are OPM-specific, not core primitives. The core defines `#Offer`; the OPM catalog defines the well-known instances.

**Rationale:** Mirrors the organizational pattern of well-known Claims from enhancement 006. Separate directories per domain keep the structure navigable.

**Source:** Design discussion 2026-04-01.
