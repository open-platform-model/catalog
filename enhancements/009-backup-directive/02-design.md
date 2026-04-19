# Design — `#Directive` Primitive: Backup & Restore

## Design Goals

- Introduce `#Directive` as a primitive type inside `#Policy`, alongside `#PolicyRule`.
- Directives describe operational behavior the platform executes — no enforcement semantics.
- One unified K8up directive that carries three concerns with distinct consumers: scheduling (transformer), repository connection (transformer + CLI), and restore procedure (CLI).
- Provider-specific backup sub-schema (K8up first, Velero later); provider-agnostic `restore` sub-block shape that any future provider directive can reuse.
- Per-component pre-backup quiescing declared as a component trait, not as a directive field.
- Experimental schemas live in `opm_experiments/v1alpha1`; the underlying abstractions land in `core/v1alpha1`.

## Non-Goals (v1)

- Component-level placement or Blueprint composition (that is enhancement 006's `#Claim`).
- Data dependency claims (Postgres, Redis connections).
- Cross-module backup coordination.
- Environment-level S3 backend defaults.
- A generic, cross-provider backup abstraction.
- ConfigMap and Secret backup (dropped from v1 together with `targets[]` — see D21).

---

## Where each piece lives

| Artifact | Module | Path |
|---|---|---|
| `#Directive` primitive | `core/v1alpha1` | `core/v1alpha1/primitives/directive.cue` |
| `#Policy.#directives` field | `core/v1alpha1` | `core/v1alpha1/policy/policy.cue` |
| `#Transformer.requiredDirectives` field | `core/v1alpha1` | `core/v1alpha1/transformer/transformer.cue` |
| `#K8upBackupDirective` | `opm_experiments/v1alpha1` | `opm_experiments/v1alpha1/directives/k8up_backup.cue` |
| `#PreBackupHookTrait` | `opm_experiments/v1alpha1` | `opm_experiments/v1alpha1/traits/pre_backup_hook.cue` |
| K8up Schedule transformer | `opm_experiments/v1alpha1` | `opm_experiments/v1alpha1/providers/kubernetes/transformers/k8up_schedule.cue` |
| K8up PreBackupPod transformer | `opm_experiments/v1alpha1` | `opm_experiments/v1alpha1/providers/kubernetes/transformers/k8up_pre_backup_pod.cue` |

The core-level changes are structural and land in `core/v1alpha1` on their own cadence. The experimental pieces iterate freely in `opm_experiments` until the graduation criteria in 07-open-questions.md Q4 are met.

---

## The `#Directive` Primitive

`#Directive` follows the same metadata and `#spec` pattern as `#PolicyRule` but omits the `enforcement` block. It lives inside `#Policy` via a new `#directives` map.

```cue
#Directive: {
    apiVersion: "opmodel.dev/core/v1alpha1"
    kind:       "Directive"

    metadata: {
        modulePath!:  t.#ModulePathType   // e.g., "opmodel.dev/opm_experiments/v1alpha1/directives"
        version!:     t.#MajorVersionType // e.g., "v1"
        name!:        t.#NameType         // e.g., "k8up-backup"
        #definitionName: (t.#KebabToPascal & {"in": name}).out

        fqn: t.#FQNType & "\(modulePath)/\(name)@\(version)"

        description?: string
        labels?:      t.#LabelsAnnotationsType
        annotations?: t.#LabelsAnnotationsType
    }

    // MUST be an OpenAPIv3-compatible schema
    // Dynamically-named per directive (camelCase of metadata.name)
    #spec!: (strings.ToCamel(metadata.name)): _
}

#DirectiveMap: [string]: #Directive
```

### Comparison with `#PolicyRule`

| Aspect | `#PolicyRule` | `#Directive` |
|--------|---------------|--------------|
| Purpose | Governance rules, security, compliance | Operational behavior the platform executes |
| Enforcement block | Required (`mode`, `onViolation`) | None |
| Who writes it | Platform team | Module author |
| Examples | Encryption policy, resource limits | K8up backup, restore procedures |
| Metadata | Same pattern | Same pattern |
| Spec | Same pattern (`#spec!: camelName: _`) | Same pattern |

---

## `#Policy` Changes

`#Policy` gains a `#directives` field alongside `#rules`. The `_allFields` comprehension extends to merge spec fields from both into the policy's `spec`.

```cue
#Policy: {
    apiVersion: "opmodel.dev/core/v1alpha1"
    kind:       "Policy"

    metadata: {
        name!: t.#NameType
        labels?:      t.#LabelsAnnotationsType
        annotations?: t.#LabelsAnnotationsType
    }

    // Governance
    #rules: [RuleFQN=string]: prim.#PolicyRule & {
        metadata: name: string | *RuleFQN
    }

    // Operations
    #directives?: [DirectiveFQN=string]: prim.#Directive & {
        metadata: name: string | *DirectiveFQN
    }

    // Scope
    appliesTo: {
        matchLabels?: t.#LabelsAnnotationsType
        components?: [...component.#Component]
    }

    _allFields: {
        if #rules != _|_ {
            for _, rule in #rules {
                if rule.#spec != _|_ {
                    for k, v in rule.#spec { (k): v }
                }
            }
        }
        if #directives != _|_ {
            for _, directive in #directives {
                if directive.#spec != _|_ {
                    for k, v in directive.#spec { (k): v }
                }
            }
        }
    }

    spec: close(_allFields)
}
```

A `#Policy` may contain only `#rules`, only `#directives`, or both.

---

## `#Transformer` Changes

Two new fields to match directives the same way the pipeline already matches labels, resources, and traits.

```cue
#Transformer: {
    // ... existing matching fields (requiredLabels, requiredResources, requiredTraits) ...

    // Directives required by this transformer.
    // Matched against #Policy.#directives for policies that target the component.
    requiredDirectives: [string]: _

    // Directives optionally consumed.
    optionalDirectives: [string]: _

    #transform: {
        #component: _
        #context:   #TransformerContext
        output:     {...}
    }
}
```

The matching rule is additive: a transformer matches a component when all of its `requiredLabels`, `requiredResources`, `requiredTraits`, and `requiredDirectives` are present. See 03-transformer-integration.md for enrichment and output details.

---

## The Unified `#K8upBackupDirective`

Single directive, three concerns, two consumers.

```cue
#K8upBackupDirective: prim.#Directive & {
    metadata: {
        modulePath:  "opmodel.dev/opm_experiments/v1alpha1/directives"
        version:     "v1"
        name:        "k8up-backup"
        description: "K8up backup schedule, shared repository, and CLI restore procedure (experimental)"
    }
    #spec: close({k8upBackup: #K8upBackupDirectiveSchema})
}
```

### `#K8upBackupDirectiveSchema`

```cue
#K8upBackupDirectiveSchema: {
    // ── Backup scheduling (K8up transformer) ──────────────────────────────

    schedule!:     string                  // Backup cron; required, no default
    checkSchedule: *"0 4 * * 0" | string   // Restic repo integrity check
    pruneSchedule: *"0 5 * * 0" | string   // Restic snapshot pruning

    retention: {
        keepDaily:   *7 | int
        keepWeekly:  *4 | int
        keepMonthly: *6 | int
    }

    // ── Repository (shared by transformer + CLI) ──────────────────────────

    repository!: {
        // Backup tool format; determines which tool the CLI uses for browsing/restore
        format: *"restic" | "kopia"

        // S3 storage backend
        s3!: {
            endpoint!:        string
            bucket!:          string
            accessKeyID!:     schemas.#Secret
            secretAccessKey!: schemas.#Secret
        }

        // Repository encryption key
        password!: schemas.#Secret
    }

    // ── Restore procedure (CLI only) ──────────────────────────────────────
    //
    // Keys MUST be component names that appear in the parent Policy's
    // appliesTo.components list. Definition order is restore order.

    restore?: [componentName=string]: {
        requiresScaleDown: *true | bool
        healthCheck?: {
            path!: string
            port!: int
        }
    }
}
```

### Design Notes

**One `repository` block.** Previously the backup directive carried `backend` and the restore directive carried `repository`; the two had to be kept in sync manually. A single block eliminates drift. The K8up Schedule transformer reads it to generate the backend; the CLI reads it to connect to the repo.

**No `targets[]`.** Backup scope comes entirely from `Policy.appliesTo`. K8up handles "which PVC" at its own layer via annotations (see 03-transformer-integration.md and 07-open-questions.md Q1).

**`restore` is CLI-only.** The K8up transformer ignores this block. The CLI reads it to build a per-component restore plan. Its shape is provider-agnostic — a future `#VeleroBackupDirective` can reuse it verbatim.

**Definition order = restore order.** CUE preserves struct field order. Write `database` before `app` in `restore` to restore in that order. (Ordering is less load-bearing at the module level than at the bundle level; for `#Module`, a module is already a single deployable unit — see 07-open-questions.md Q3.)

**No default schedule.** Backup cadence is a conscious choice; silent defaults are unsafe.

**`schemas.#Secret` references.** Credentials and password use the OPM secret schema with its `$opm` discriminator; the transformer's `#ResolveSecretRef` handles both OPM-managed and plain secret refs.

---

## `#PreBackupHookTrait`

A per-component trait that declares a quiescing command to run as a K8up PreBackupPod. The PreBackupPod transformer matches on trait presence; each component carrying the trait emits one PreBackupPod CR.

```cue
#PreBackupHookTrait: trait.#Trait & {
    metadata: {
        modulePath:  "opmodel.dev/opm_experiments/v1alpha1/traits"
        version:     "v1"
        name:        "pre-backup-hook"
        description: "Declares a quiescing command to run as a K8up PreBackupPod before backing up this component (experimental)"
    }
    spec: close({preBackupHook: #PreBackupHookSchema})
}
```

### `#PreBackupHookSchema`

```cue
#PreBackupHookSchema: {
    image!:   string
    command!: [...string]

    // Optional mount of one of the component's own volumes into the hook pod.
    // Useful for on-disk quiescing (SQLite WAL checkpoint, pg_dump into the
    // PVC). Not needed for hooks that talk over the network (RCON, HTTP).
    volumeMount?: {
        volume!:   string             // must reference a volume on this component
        mountPath: *"/data" | string
    }
}
```

### Design Notes

**Per-component, not per-directive.** A component that needs quiescing carries the trait once. Any backup policy that targets it picks the hook up automatically.

**No policy reference.** The trait does not know which policy triggers its hook. Coupling happens at the K8up layer via pod selection — see 03-transformer-integration.md.

**Volume reference validated locally.** `volumeMount.volume` references a volume name on the same component; the link is checked at CUE evaluation time.

---

## Relationship to Other Enhancements

### Enhancement 004 (archived)

Enhancement 004's component-level `#BackupTrait` + `#PreBackupHookTrait` was at the wrong scope for the backup policy itself, but it was right about hooks being component-scoped. This enhancement adopts the component-scoped hook as `#PreBackupHookTrait` (D22) while moving the policy decision to module scope via `#Policy.#directives`.

### Enhancement 006 (Draft, not superseded)

Enhancement 006's `#Claim` + `#Orchestration` design addresses a broader space — data dependencies, Blueprint composition, cross-component coordination. This enhancement extracts only the module-level operational-behavior concept as `#Directive`. The two designs remain compatible.

### Enhancement 007 (Draft, not superseded)

Enhancement 007's `#Offer` is the supply side of 006. Not relevant to this enhancement.
