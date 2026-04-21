# Rendering Pipeline Integration

`#PolicyTransformer` adds a second pass to the render pipeline. This document specifies the order, inputs, and failure modes.

## Existing Pipeline (Component-Scope, Unchanged)

Summarized from current rendering docs:

1. **Resolve** — `#ModuleRelease` unifies the `#Module` with `values` + computed `#ctx`. Result: a fully concrete module spec.
2. **Match** — for each `#Component` in `#components`, the matcher scans the platform's `#composedTransformers` for transformers whose `requiredResources` / `requiredTraits` are satisfied by that component. At most one transformer wins per component (provider ordering breaks ties).
3. **Render (component pass)** — each matched transformer is invoked with its component's typed inputs. Output is a set of platform resources scoped to that component.
4. **Merge** — all component-scope outputs merge into a single resource inventory. FQN + `(kind, namespace, name)` collisions are errors.
5. **Plan** — the resource inventory is diffed against observed cluster state.
6. **Apply** — Server-Side Apply stages the diff (cluster-def → class-def → workload, per opm-operator SSA staging).
7. **Prune** — resources present in the observed state but not in the plan are pruned, subject to per-type safeguards (CRDs excluded; see crd-lifecycle-research).

## With 011: Added Policy Pass

Insert two new sub-phases between the component render and the merge:

```text
1. Resolve        (unchanged)
2. Match          (unchanged — component-scope only)
3. Render (component pass)                        ← produces component-scope output
4. Policy match                                    ← NEW
5. Render (policy pass)                            ← NEW — produces module-scope output
6. Merge          (now merges both passes)
7. Plan           (unchanged)
8. Apply          (unchanged)
9. Prune          (unchanged)
```

### Step 4: Policy match

For each `#Policy` in the module's `#policies`:

1. Resolve `appliesTo` to a concrete component set:
   - `matchLabels` against each component's metadata labels.
   - `components` as explicit allow-list.
   - Union of both (if both are present).
2. For each `#Directive` in `#directives`:
   1. Find all `#PolicyTransformer`s in `#Platform.#composedPolicyTransformers` with the directive FQN in `requiredDirectives`.
   2. Filter by:
      - **Trait coverage** — every component in the set carries every FQN in the transformer's `requiredTraits`.
      - **Resource coverage** — every component carries every FQN in `requiredResources`.
      - **Rule co-presence** — the policy contains every FQN in the transformer's `requiredRules`.
      - **Context resolvability** — every path in `readsContext` is concrete in the resolved platform ctx.
   3. Apply provider-order tie-breaking.
   4. Record exactly one winning transformer per directive, or error if zero.

### Step 5: Render (policy pass)

For each winning `(policy, directive, transformer)` triple from step 4:

1. Assemble the transformer input value (schema in [06-policy-transformer.md](06-policy-transformer.md)):
   - `directive` = the directive's resolved `#spec` field.
   - `policy.name`, `policy.labels`.
   - `components[compName]` for each component in the covered set:
     - `traits[traitFQN]` = the component's resolved trait spec for each FQN in `requiredTraits`.
     - `names` = `#ctx.runtime.components[compName]`.
   - `context[path]` = resolved value for each path in `readsContext`.
   - `release` = `#ctx.runtime.release`.
2. Invoke the transformer's `out`. Collect the resource map.
3. Tag each emitted resource with provenance metadata:
   - `opm.opmodel.dev/owner-policy: <policy-name>` — mandatory.
   - `opm.opmodel.dev/owner-directive: <directive-fqn>` — mandatory.
   - `opm.opmodel.dev/owner-transformer: <transformer-fqn>` — mandatory.
   - `opm.opmodel.dev/owner-component: <component-name>` — optional; the transformer attaches this when the emitted resource is genuinely per-component (see D11 and D13 in [08-decisions.md](08-decisions.md)).

### Step 6: Merge (extended)

Merges component-pass + policy-pass outputs into a single inventory. Same collision rules apply across both. A policy transformer emitting a resource with the same `(kind, ns, name)` as a component transformer is an error.

Exception: **intentional co-ownership by annotation.** K8up Schedule CR selects PVCs via label match; the backup transformer may want to *annotate* PVCs that component transformers produced. Annotations on existing resources are not conflicts — they merge. For v1, forbid policy transformers from mutating component-scope resources; require emission of distinct resources instead. Revisit if a legitimate need surfaces.

## Ordering Within the Policy Pass

Multiple directives in the same module can, in principle, render independently. For v1 there is no declared ordering between policy transformers — execute in stable order (lexicographic by directive FQN, then by policy name) for reproducibility. This is deterministic but arbitrary; revisit if a commodity requires genuine ordering (e.g. backup must render before DR orchestration that reads backup schedule).

No component-pass transformer may depend on policy-pass output. Component pass renders first; the policy pass cannot retroactively affect components. If a commodity ever needs that, the directive that needs component-aware output is itself component-scope and should be a trait + `#Transformer`, not a directive.

## Failure Modes

| Condition | Phase | Behavior |
| --------- | ----- | -------- |
| No `#PolicyTransformer` matches a directive | Policy match (4) | Error with directive FQN + reason (missing registered provider, missing trait on component N, missing context path) |
| More than one transformer matches, after ordering | Policy match (4) | Winner picked by order. Emit warning. |
| `readsContext` path not resolvable in `#ctx.platform` | Policy match (4) | Error naming the path and the containing directive |
| Transformer output collides with component-pass output | Merge (6) | Error naming both transformers and the tuple |
| Directive spec fails CUE schema validation (malformed cron, missing backend, etc.) | Resolve (1) | Error during module unification; never reaches policy match |
| Component named in `restore.preRestore` is not in `appliesTo` | Resolve (1) | Caught by catalog-level validation on `#BackupPolicy.restore` |
| Same component covered by two `#BackupPolicy` directives | Resolve (1) | Catalog-level validation — reject (see [OQ-1](09-open-questions.md)) |

## Interaction With `opm-operator`

The operator consumes the merged resource inventory and applies it. No special handling is needed for policy-pass output — from the apply phase's perspective, a K8up `Schedule` CR is a normal Kubernetes resource. SSA staging (cluster-def → class-def → workload) applies uniformly.

Observability hooks that currently exist per-component extend naturally to policy-pass output via the provenance annotations added in step 5.3. Events on a failing K8up `Schedule` can be traced back to the originating directive by reading `opm.opmodel.dev/owner-directive`.

## Interaction With CLI Commands

`opm release preview` / `opm release diff` reports both passes:

```
release: strix-media
components:
  app   (container + scaling + backup-trait)
    → Deployment, Service, PVC[config], PVC[cache]
  db    (container + scaling + backup-trait)
    → StatefulSet, Service, PVC[data]
policies:
  nightly  (appliesTo: app, db)
    directives:
      opmodel.dev/opm/v1alpha1/operations/backup/backup@v1
        via opmodel.dev/k8up/v1alpha1/transformers/backup-schedule-transformer@v1
        → Backend[offsite-b2], Schedule[nightly]
```

`opm release restore strix-media --snapshot <id>` is an imperative flow driven by the CLI; it does not re-enter the render pipeline. It reads the `#BackupPolicy.restore` directive subfield from the release's rendered module and executes the declarative procedure.
