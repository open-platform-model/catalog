# Open Questions — `#Directive` Primitive: Backup & Restore

Unresolved questions that must be answered before the experimental directives graduate from `opm_experiments/v1alpha1` to `opm/v1alpha1`. Answers should be captured back into `06-decisions.md` as they are resolved.

---

## Q1: PVC annotation stamping strategy

K8up only backs up a PVC when one of these holds:

1. The PVC carries the `k8up.io/backup=true` annotation.
2. The K8up operator is configured with `skipWithoutAnnotation: false` (back up every PVC in scope).

The unified directive removes per-PVC `targets[]` enumeration and scopes backup via `Policy.appliesTo`. The rendering pipeline therefore needs a strategy to make sure the right PVCs end up annotated.

**Options:**

- **A. Global operator config `skipWithoutAnnotation: false`** — back up every PVC in the release namespace. Simplest. Acceptable for single-tenant namespaces where a backup policy is present at all.
- **B. Policy-aware render pass** — a post-pass in the render pipeline annotates PVCs belonging to components named in `appliesTo` of a `#K8upBackupDirective`. Requires the pipeline to reason about cross-component state; not supported today.
- **C. `#BackupInclusionTrait`** — author attaches a trait to each component that should be backed up; the workload/PVC transformer stamps the annotation. Re-introduces the enumeration burden D21 removed.

**Dogfooding default:** Option A on `kind-opm-dev`. Revisit after the first two modules are migrated.

---

## Q2: Lease semantics for restore pause

Direction (D24): CLI acquires a `coordination.k8s.io/v1` Lease per ModuleRelease during `opm restore run`. Controller reconciler checks the Lease and skips reconcile while it is held and unexpired.

**Agreed:** per-ModuleRelease scope (matches controller's whole-MR reconcile granularity).

**Unresolved:**

- **Lease naming** — proposed `opm-restore-<release-name>`, but collisions between releases in different namespaces could share the same name. Namespace-scoped name is safer.
- **Namespace** — release namespace vs dedicated `opm-system`. Release namespace keeps RBAC local; dedicated namespace centralizes ops concerns.
- **Duration and renewal** — baseline proposal: `leaseDurationSeconds: 60`, renew every 20s. Tune after measurement.
- **Controller skip semantics** — hard skip (return immediately), or record a `ReconcilePaused` condition and requeue after lease expiry?
- **CLI RBAC** — needs `create`/`get`/`update`/`delete` on `leases.coordination.k8s.io` in the target namespace.
- **Stale lock recovery** — if a prior CLI run crashed without releasing, what is the user-visible override path? `opm restore --force-break-lock`? Manual `kubectl delete lease`?

**Dogfooding target:** exercise crash-mid-restore + new-run-acquires-lease on `kind-opm-dev` before graduation.

---

## Q3: Multi-policy `restore` merging and constraints

A `#Module` may declare multiple `#Policy` blocks. Two or more of them could each carry a `#K8upBackupDirective` with its own `restore` block. The CLI needs a single canonical view per release.

**Agreed:** not allowed in v1.

**Unresolved:**

- **Where to enforce?** CUE-level constraint on `#Module` (hard fail at evaluation with a location-rich error), or a pipeline validator (softer error message with better diagnostics)?
- **Bundle relaxation** — does `#Bundle` aggregate restore blocks from multiple modules? If so, how is cross-module restore ordering expressed? Defer until the `#Bundle` design matures.

---

## Q4: Graduation criteria for `opm_experiments`

**Proposed minimums for `#K8upBackupDirective` + `#PreBackupHookTrait` to graduate to `opm/v1alpha1`:**

- Validated against at least two distinct modules (Jellyfin + one more — Minecraft or similar).
- `opm restore run` exercised end-to-end: backup → destroy data → restore → verify healthy.
- Q1 (PVC annotation strategy) resolved.
- Q2 (Lease semantics) resolved.
- At least one second backup provider directive drafted in `opm_experiments` (e.g., a stub `#VeleroBackupDirective`) to pressure-test whether the `restore` sub-block generalizes.

**Unresolved:**

- **Sign-off process** — is graduation a review checklist artifact (PR template? ADR?) or a judgment call reflected in enhancement status?
- **Sandbox rot policy** — how long may an experiment sit without progression before it is either graduated or removed? Without a deadline, `opm_experiments` accumulates dead code.

---

## Q5: `#Directive` primitive — core-level landing strategy

`#Directive`, `#Policy.#directives`, and `#Transformer.requiredDirectives` are structural additions to `core/v1alpha1`. They are the abstraction over which experimental directives sit; they do not themselves live in `opm_experiments`.

**Unresolved:**

- **Sequencing** — land the core changes first, then experiment on top? Or gate the core change on at least one working experimental directive, to avoid locking in a suboptimal `#Directive` shape?
- **Risk** — a premature core merge makes retroactive field renames painful for downstream consumers.

**Recommendation:** develop experimental directives in `opm_experiments` against a dev branch of `core` that carries the new primitive and policy/transformer fields. Cut the core change only after the first directive ships.
