# Design Decisions — `#Op` & `#Action` Primitives

## Summary

Decision log for all architectural and design choices made during this enhancement. Each decision is numbered sequentially and recorded as it is made. Decisions are append-only — do not remove or renumber existing entries. If a decision is reversed, add a new decision that supersedes it.

---

## Decisions

### D1: `#Op` is a slim base type, not a full primitive

**Decision:** `#Op` has no metadata, FQN, apiVersion, or kind. It is a minimal schema base type: `$type`, `#out`, and open fields. Only `#Action` is a full primitive.

**Alternatives considered:**

- Full primitive with metadata/FQN for `#Op` — rejected because Ops are composed inline into Action steps, not referenced by FQN in maps. The Action is the publishable, referenceable unit. Full metadata on Ops adds ceremony without value.
- No base type at all (pure `@op` attributes with no `#Op` constraint) — rejected because `#Op` provides the `$type` discriminator and `#out` contract that `#Step` needs for type safety.

**Rationale:** Ops are schemas, not standalone artifacts. They parallel Hofstadter's `@task()` — inline definitions dispatched by attribute, not registered entities. The Action wraps them with identity and publishability.

**Source:** Design discussion 2026-04-11. Iterated from initial full-primitive design through Hof-inspired simplification.

---

### D2: Use `@op("...")` CUE attributes for runtime dispatch

**Decision:** Each concrete Op carries a CUE attribute (e.g., `@op("exec")`, `@op("http.get")`) that tells the OPM runtime which executor to use. The attribute sits on the Op's schema struct (Option A).

**Alternatives considered:**

- Attribute on the `#spec` field (Option B) — rejected as less readable; the attribute belongs with the schema it describes.
- A `$executor` string field instead of an attribute — rejected because this is runtime metadata, not user-facing configuration. CUE attributes are specifically designed for opaque metadata that CUE evaluation ignores.
- A `kind` field on `#Op` (e.g., `kind: "exec"`) — rejected because `kind` implies a CUE-evaluated type, while the dispatch target is runtime-only.

**Rationale:** CUE attributes are opaque to evaluation — they preserve hermeticity. The runtime reads them; CUE ignores them. This matches Hofstadter's `@task()` pattern and CUE's own `$id` in tool packages.

**Source:** Design discussion 2026-04-11. Inspired by Hofstadter's `@task(os.Exec)` model.

---

### D3: Use `$after` for explicit step ordering, not implicit DAG from references

**Decision:** Steps declare ordering via `$after: ["stepName", ...]`. The runtime builds a DAG from these declarations. Steps with no `$after` and no unresolved dependencies may run in parallel.

**Alternatives considered:**

- Hofstadter-style implicit DAG from CUE field references (e.g., `call.output` references create ordering) — rejected because it requires the runtime to trace CUE reference chains, which is complex to implement and makes ordering invisible in the declaration.
- Ordered list of steps (`[step1, step2, step3]`) — rejected because it forces sequential execution with no parallelism and loses named step identity.
- Both implicit references AND explicit `$after` — rejected for v1 simplicity. Can be added later if reference-based ordering proves valuable.

**Rationale:** Explicit `$after` is simple for the runtime (parse field, topological sort), visible in the declaration (reader sees the DAG), and supports parallelism (unreferenced steps run concurrently). Hofstadter's implicit DAG is elegant but trades implementation simplicity for authoring convenience — OPM prioritizes clarity.

**Source:** Design discussion 2026-04-11. `$after` follows CUE's own `tool/flow` convention for explicit task ordering.

---

### D4: `#out` is a hidden field

**Decision:** Op output schemas use hidden `#out` fields, not visible `out` fields.

**Alternatives considered:**

- Visible `out` field — would appear in `cue export` and enable cross-step CUE references, but pollutes the declaration with runtime-only data.
- No output schema at all — rejected because the runtime needs to know the output shape for validation and future cross-step wiring.

**Rationale:** Outputs are runtime-produced values, not author-declared configuration. Hidden fields don't appear in `cue export`, keeping declarations clean. The runtime knows the `#out` shape from the Op definition and populates it during execution. Cross-step data wiring is deferred as a non-goal.

**Source:** User decision 2026-04-11.

---

### D5: `$type` discriminator field for runtime dispatch

**Decision:** `#Op` carries `$type: "op"` and `#Action` carries `$type: "action"`. The runtime uses this field to determine how to process each step.

**Alternatives considered:**

- `kind` field — already used by `#Action` as a full primitive (`kind: "Action"`). Adding `kind: "Op"` to the slim `#Op` would be consistent but implies full-primitive status that `#Op` intentionally lacks.
- Hidden `_type` field — would not appear in `cue export` or `MarshalJSON()`, requiring the runtime to use `cue.Hidden(true)` for lookup. Adds unnecessary complexity.
- Heuristic detection (check for `#steps` field presence) — fragile and breaks if new types are added.

**Rationale:** `$` prefix is a CUE convention for metadata/control fields (used by `$id`, `$after` in CUE's own tool system). `$type` is visible in export (runtime can `LookupPath`), follows established convention, and provides unambiguous discrimination. Research confirmed `$` is not reserved at the CUE language level — it is a valid identifier letter with no special evaluation semantics.

**Source:** Design discussion 2026-04-11. Validated against CUE language specification and `cue-lang/cue` tool system conventions.

---

### D6: `#Action` is a full primitive with metadata and FQN

**Decision:** `#Action` has full primitive metadata (apiVersion, kind, metadata with modulePath, version, name, FQN). It follows the same pattern as `#Resource`, `#Trait`, and other OPM primitives.

**Alternatives considered:**

- Slim `#Action` like `#Op` (no metadata) — rejected because Actions are the publishable, referenceable unit. Lifecycle and Workflow consume Actions by reference. Module authors import Actions from CUE packages. This requires identity (FQN).

**Rationale:** Actions parallel Blueprints — both are composed units that module authors publish and others import. Blueprints have full primitive metadata; Actions should too.

**Source:** Design discussion 2026-04-11. Follows OPM primitive conventions established in `catalog/core/v1alpha2/`.

---

### D7: Steps support nested Actions (recursive composition)

**Decision:** `#Step` is typed as `(#Op | #Action)`. A step within an Action can itself be another Action with its own `#steps`. The runtime recurses.

**Alternatives considered:**

- Ops only in steps (no nesting) — rejected because it prevents reuse of composed Actions. A `#FullDeploy` Action should be able to include a `#DBMigration` Action as a step.
- Separate `#ops` and `#actions` maps (like Component's `#resources` / `#traits` / `#blueprints`) — rejected because it splits the ordering namespace. `$after` must reference step names in a single namespace for the DAG to work.

**Rationale:** Recursive composition is the natural model. The `$type` discriminator tells the runtime whether to dispatch (`"op"`) or recurse (`"action"`). This mirrors how Blueprints compose Resources and Traits, but adapted for ordered execution.

**Source:** Design discussion 2026-04-11.
