# Problem

## Context

Operational commodity contracts — backup, TLS certificate issuance, metrics scraping, DNS publishing — share a recurring shape: a component declares facts about itself that participate in the operation, and the module author declares a cross-component plan for how the operation should run. OPM today can express the first half cleanly via `#Trait`. It has no crisp home for the second half.

## What Backup Actually Needs

Concrete case from an existing deployment:

- Jellyfin stateful workload, two PVCs: `config` (back up), `cache` (don't).
- Jellyfin's Postgres database, one PVC: `data`. Pre-backup: `CHECKPOINT`.
- Cadence: nightly 02:00.
- Destination: offsite Backblaze B2 bucket.
- Retention: 7 daily, 4 weekly, 3 monthly.
- Restore: scale both down → restore data → DB up + health probe → app up + health probe.

Two distinct layers fall out of this description:

1. **Component-local** — for each component, which of its own data participates in backup and what app-specific hooks to run around the snapshot. Other components don't care.
2. **Module-level** — schedule, destination, retention, restore orchestration. Not a property of any one component; the coordination layer above them.

Both layers need authoring homes.

## Where OPM Falls Short Today

### Only `#Trait` is available for authoring operational intent

A `#Trait` attaches to a single component. Backup's component-local facts (targets, quiescing hooks) fit naturally. Backup's module-level facts (schedule, backend, retention, restore procedure) do not — they are not properties of a single component, and duplicating them across every participating component's trait (a) inflates authoring, (b) invites drift, and (c) misrepresents the actual cardinality (one schedule, many components).

### `#Policy` carries `#Rule` but not a counterpart for module-author instructions

`#Policy` is the module-level construct that applies to a set of components. It currently carries `#Rule` — platform-team-written governance applied down to modules. It has no paired primitive for the opposite direction: module author to platform — "for these components, run this operation this way."

### `#Transformer` matches one component and reads one component's state

The existing transformer scope produces component-scoped output. Backup's K8up `Schedule` CR is module-scoped (one per policy, not one per component). A component-scope transformer either duplicates the Schedule CR or ignores half of its inputs. Neither works honestly.

## What's Missing, Concretely

1. A module-level primitive that expresses "instruction from module author to platform" alongside `#Rule` ("platform mandate to module") inside `#Policy`. This enhancement introduces `#Directive`.
2. A transformer scope that matches on a directive and reads the matched components' traits. Today's `#Transformer` matches one component and reads one component's state. Backup renders one K8up `Schedule` CR per module-level backup policy, reading multiple components' trait specs. That is a module/policy-scope operation. This enhancement introduces `#PolicyTransformer`.

## Goal

Express backup — and, by pattern, other operational commodity contracts — using:

- Existing `#Trait` for component-local facts.
- New `#Directive` primitive for module-level orchestration, inside the existing `#Policy` construct.
- New `#PolicyTransformer` scope for directive-driven rendering.

The concept budget spent on this feature is: one new primitive, one new transformer scope, one broadening of an existing construct.

## Non-Goals

- **Data-plane contracts.** Typed value exchange (e.g., Postgres connection details injected into a component's environment) is a structurally different problem; it involves bidirectional value flow rather than module-level operational orchestration. Out of scope.
- **A universal replacement for existing data-plane concepts.** This enhancement argues only that operational commodities fit the Trait + Directive shape. Other commodity shapes remain open problems.
- **Cross-module directive references.** A directive in module A instructing platform behavior for a release in module B. Considered; deferred.
- **Runtime directives without a supporting transformer.** Every directive that produces platform state requires a matching `#PolicyTransformer`. Directives purely consumed by the CLI (e.g., restore procedure) are fine; those produce no platform state at render time.
