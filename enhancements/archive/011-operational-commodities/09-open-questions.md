# Open Questions

Items explicitly set aside during design of 011. Each carries a revisit trigger.

---

## OQ-1 — Multi-policy coverage of the same component

**Current disposition.** A component may be covered by at most one `#BackupPolicy` directive across all policies in its module. Catalog validation rejects overlap.

**Use cases that would force revisit.**

- **Tiered backup.** Daily cheap snapshot to local storage + hourly expensive snapshot of only critical data to offsite. Today: one policy. With tiers: two policies on overlapping component sets.
- **Dual-destination DR.** Same data, two backends (local fast-restore + offsite DR). Today: one policy picks one backend.
- **Per-volume scheduling.** Config volume backed up nightly; data volume backed up hourly. Today: the author has to co-schedule on the most frequent cadence.

**Design directions if triggered.**

- Require explicit `tag set` or `backend + target subset` disjointness at catalog-compile time. Multiple policies allowed if their output is provably disjoint.
- Introduce a merge-strategy field on the directive — `mergeStrategy: *"reject" | "union"`. Authors who know what they are doing opt into union.
- Model tiers as a structured field in a single `#BackupPolicy.tiers[]` rather than multiple policies.

**Action.** Hold. Track in operator deployment stories over the next months. Revisit when any of the use cases above appears in a real module proposal.

---

## OQ-2 — Explicit `pairsWith` field on `#Trait` / `#Directive`

**Current disposition.** Version pairing between `#BackupTrait` and `#BackupPolicy` is achieved by co-locating them in the same CUE package. The K8up transformer additionally pins both FQNs in its match predicate — a render-time safety net.

**Use cases that would force revisit.**

- Cross-module trait/directive pairs (a trait in package A, a directive in package B, both meant to be used together) — if that ever becomes a pattern, shared-package co-location fails.
- A trait or directive authored by a third party intentionally pluggable against multiple counterparts. Harder to express via shared package.

**Design directions if triggered.**

- Add `pairsWith: [...FQN]` to `#Trait` and `#Directive`. Catalog compile-time validation fails if a module uses a trait whose `pairsWith` names a directive FQN not also present in the same module.
- Treat it as advisory metadata only (documentation) rather than enforced.

**Action.** Hold. Add only when the K8up transformer's render-time catch is judged insufficient.

---

## OQ-3 — Promote `#Platform.#ctx.platform.backup.backends` to a first-class `#BackupBackend` resource

**Current disposition.** Backends live in the open `#ctx.platform` struct. The shape is provider-defined (K8up's transformer owns the schema).

**Triggers for revisit.**

- Backend schema grows past a handful of fields and needs proper validation.
- Multiple providers (K8up, Velero, Stash) need to share backend definitions.
- Backends need their own lifecycle (rotation, audit, credential re-roll) distinct from platform config.
- The `#ctx.platform` namespace starts feeling overloaded as other commodities (cert-manager, metrics) land similar configuration blobs.

**Design directions if triggered.**

- Define `#BackupBackend` as a core resource with a closed schema. Each backend instance is a resource in a platform-team-authored module. Policy `backend:` references go from open-struct-key to resource-FQN.
- Pros: schema validation at catalog level, deduplication across providers, independent lifecycle.
- Cons: one more resource type, one more thing to register with the platform.

**Action.** Hold. Revisit when a second provider wants to consume the same backend definitions, or when schema grows.

---

## OQ-4 — Render-pipeline ordering among policy transformers

**Current disposition.** Policy transformers run in stable but arbitrary order (lexicographic by directive FQN, then policy name). Component pass always runs before policy pass; no feedback loop.

**Triggers for revisit.**

- A commodity whose directive transformer's output depends on another directive's output (e.g., a "DR schedule" directive that wants to read the "backup schedule" directive's computed Schedule CR name).
- A commodity that wants to consume provider-emitted resources from another provider's policy transformer.

**Design directions if triggered.**

- Declare explicit dependencies on a `#PolicyTransformer`: `dependsOnDirectives: [...FQN]`. The pipeline topologically sorts before rendering.
- Require that dependencies be expressed via a shared **data trait** on the covered components, not via transformer-output inspection. Keeps the pass acyclic.

**Action.** Hold. Revisit when a second policy transformer exists and the two have a real ordering relationship.

---

## OQ-5 — Does the `#Trait` + `#Directive` + `#PolicyTransformer` pattern generalize to other operational commodities?

**Status: resolved — accepted.** Three data points agree.

| Commodity | Example doc | Output cardinality | Platform-ctx subtree | Fit |
| --------- | ----------- | ------------------ | -------------------- | --- |
| Backup (K8up) | [03-backup-example.md](03-backup-example.md) | 1 `Schedule` per policy | `backup.backends` | direct |
| TLS (cert-manager) | [04-tls-example.md](04-tls-example.md) | N `Certificate` per policy | `tls.issuers` | with D11/D13 refinement |
| Routing (Gateway API) | [05-routing-example.md](05-routing-example.md) | N route CRs per policy | `routing.gateways` | with D11/D13 refinement |

Refinements crystallized during validation:

- **Per-component provenance annotation** ([D11](08-decisions.md), [D13](08-decisions.md)) — optional `opm.opmodel.dev/owner-component` for transformers whose output is honestly per-component.
- **Platform-ctx subtree convention** ([D14](08-decisions.md)) — `#ctx.platform.<commodity>.*` naming, no schema enforcement.

**Remaining candidates (optional, not blocking acceptance).**

- **Prometheus scraping.** `#MetricsTrait` on workloads declaring port + path + scrape interval; `#ScrapingPolicy` directive specifying labeling rules and alert routes. Per-component `ServiceMonitor` CRs. Expected to fit the existing pattern without further refinement.
- **DNS publishing / external-dns.** Derivable from Ingress/Route resources; may not need its own trait. Sanity check worth doing before external-dns lands as a module.

**Action.** No further validation blocking 011 acceptance. Future commodities follow the pattern by convention; each publishes its own trait + directive package and at least one provider with a matching `#PolicyTransformer`. Reopen this OQ only if a commodity surfaces that genuinely cannot fit.

---

## OQ-6 — Relationship between 011 and CRD lifecycle research

**Current disposition.** Out of scope for 011. K8up's CRDs (Schedule, Backup, Restore, Archive, Check, SnapshotList, PreBackupPod) are installed by the K8up module as ordinary module components. Their lifecycle follows [crd-lifecycle-research](../../../opm-operator/docs/research/crd-lifecycle-research.md) once that work lands.

**Triggers for revisit.**

- CRD-lifecycle work lands and introduces module-level capability declarations via `#defines` (see enhancement 015). At that point the K8up module will declare its CRDs in `#components` (existing `#CRDsResource`) and publish any new Claim types it introduces under `#defines.claims`; the `#BackupScheduleTransformer` can reference Claim FQNs for cross-validation (does the transformer write to a kind that this platform actually has registered?).
- 011 proposes any module-level field that overlaps with what CRD-lifecycle research reserves.

**Action.** Cross-link once CRD-lifecycle lands. No structural changes expected to 011 primitives.

---

## OQ-7 — CLI reads directive from release, not from the catalog

**Current disposition.** `opm release restore` reads the `#BackupPolicy.restore` subfield from the release's resolved module.

**Subtle point.** The release pins a specific module version. If the module's `#BackupPolicy` schema evolves (e.g., new restore-step actions), older releases continue to restore against the old schema they captured. Good for stability; means the CLI must tolerate a range of directive schema versions.

**Action.** Document in the CLI's restore implementation. No model change.
