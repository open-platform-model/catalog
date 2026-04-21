# Backup — The Worked Example

This document walks through backup end-to-end: the `#BackupTrait` schema, the `#BackupPolicy` directive schema, the K8up `#PolicyTransformer` that implements rendering, and the module author experience.

## File Layout

Backup's trait and directive co-locate in a single CUE package so a single import fixes the version for both sides of the contract.

```text
catalog/opm/v1alpha1/operations/backup/
├── trait.cue         — #BackupTrait + #BackupHook
├── directive.cue     — #BackupPolicy + #RestoreStep
├── trait_tests.cue   — positive/negative Trait tests
└── directive_tests.cue
```

Import path: `opmodel.dev/opm/v1alpha1/operations/backup@v1`. Module authors use a single alias (conventionally `backup` or `ops`) and reference `backup.#BackupTrait` / `backup.#BackupPolicy`.

---

## `#BackupTrait` — Component-Local Facts

The trait carries only what a component knows about its own data. No schedule. No backend. No retention.

```cue
// catalog/opm/v1alpha1/operations/backup/trait.cue
package backup

import (
    prim "opmodel.dev/core/v1alpha1/primitives@v1"
)

#BackupTrait: prim.#Trait & {
    metadata: {
        modulePath:  "opmodel.dev/opm/v1alpha1/operations/backup"
        version:     "v1"
        name:        "backup"
        description: "Declares this component participates in backup and what of its data to include"
        labels: {
            "trait.opmodel.dev/category": "operations"
        }
    }

    #spec: backup: {
        // Which of this component's data to include.
        // At least one target must be declared.
        targets!: [...close({
            volume?: string    // references a #VolumesResource entry on this component
            path?:   string    // filesystem path inside the primary container
            pvc?:    string    // direct PVC name (escape hatch for pre-existing volumes)
        })] & list.MinItems(1)

        // Include/exclude patterns applied within each target.
        include?: [...string]
        exclude?: [...string]

        // App-specific quiescing. Belongs here because these hooks
        // know the component's internals (pg_dump, fsfreeze, flush).
        preBackup?:  [...#BackupHook]
        postBackup?: [...#BackupHook]
    }
}

#BackupHook: close({
    name!:           string
    command!:        [...string] & list.MinItems(1)
    container?:      string                        // defaults to primary container
    onError?:        *"fail" | "continue"
    timeoutSeconds?: int & >=1 | *300
})
```

Observations:

- Targets are structurally flexible but author intent is usually `volume` (by named reference into the component's `#VolumesResource`). `path` and `pvc` exist as escape hatches.
- Include/exclude are plain glob patterns — the backup transformer translates them to whatever the underlying tool (Restic, Kopia, etc.) expects.
- Hooks name a `container` for clarity when a Pod has sidecars. Default is the primary container.
- `onError` is per-hook so a failing "nice-to-have" quiesce step doesn't block the whole backup.

---

## `#BackupPolicy` — Module-Level Orchestration

The directive carries the cross-component facts: when, where, how long, how to restore.

```cue
// catalog/opm/v1alpha1/operations/backup/directive.cue
package backup

import (
    prim "opmodel.dev/core/v1alpha1/primitives@v1"
)

#BackupPolicy: prim.#Directive & {
    metadata: {
        modulePath:  "opmodel.dev/opm/v1alpha1/operations/backup"
        version:     "v1"
        name:        "backup"
        description: "Schedule, destination, retention, and restore workflow for a set of components"
        labels: {
            "directive.opmodel.dev/category": "operations"
        }
    }

    #spec: backup: {
        // WHEN — cron expression evaluated by the backend.
        schedule!: string

        // WHERE — named reference to a platform-configured backend.
        // Resolved at render time against #Platform.#ctx.platform.backup.backends.
        backend!: string

        // HOW LONG — Restic-style retention; universal across supported backends.
        retention?: close({
            keepLast?:    int & >=0
            keepHourly?:  int & >=0
            keepDaily?:   int & >=0
            keepWeekly?:  int & >=0
            keepMonthly?: int & >=0
            keepYearly?:  int & >=0
        })

        // Free-form labels applied to every snapshot produced by this policy.
        tags?: [string]: string

        // RESTORE — declarative procedure read by the CLI at restore time.
        // Snapshot selection is imperative (CLI argument) and is not authored here.
        restore?: close({
            // Per-component health probe that must pass after data lands.
            healthChecks?: [compName=string]: close({
                path!:           string
                port!:           int & >=1 & <=65535
                timeoutSeconds?: int & >=1 | *300
                expectStatus?:   int | *200
            })

            // Ordered steps before/after the data restore itself.
            preRestore?:  [...#RestoreStep]
            postRestore?: [...#RestoreStep]

            // Behavior flags — inform the CLI how to drive the workflow.
            inPlace?: close({
                requiresScaleDown?: bool | *true
            })
            disasterRecovery?: close({
                managedByOPM?: bool | *false    // if true, OPM runs full DR flow
            })
        })
    }
}

#RestoreStep: close({
    component!:      string
    action!:         "scale-down" | "scale-up" | "delete-pods" | "wait-health" | "exec"
    args?:           [...string]
    timeoutSeconds?: int & >=1
})
```

Observations:

- `schedule` is a string; cron format is validated by the backend (not by CUE). No catalog-level syntactic validation for v1.
- `backend` is a string key resolved at render time. See [07-rendering-pipeline.md](07-rendering-pipeline.md) for resolution.
- `restore` is optional. A policy without `restore` still produces backups; CLI-driven restore falls back to defaults (best-effort sequential scale-down/up/health, no DR flow).
- `restore` contains no `snapshotSelector` — snapshot selection is always a CLI argument (`--snapshot <id|tag|time|latest>`) because restore is an imperative operation.

---

## Version Pairing

Both `#BackupTrait` and `#BackupPolicy` live in the same CUE package. A single import fixes both:

```cue
import backup "opmodel.dev/opm/v1alpha1/operations/backup@v1"
```

This is the **primary mechanism** for version alignment: the trait and the directive evolve together in one package, and downstream modules pick up both at once.

The render-time safety net: the K8up `#BackupScheduleTransformer` declares both FQNs explicitly in its match predicate. If a module were to import the trait from one package version and the directive from another (via aliased imports), the transformer would fail to match and the render would error out loudly — rather than silently produce inconsistent output.

No explicit `pairsWith` field is added to `#Trait` or `#Directive` for v1. See [OQ-2](09-open-questions.md).

---

## K8up `#BackupScheduleTransformer`

The K8up provider ships a `#PolicyTransformer` that realizes `#BackupPolicy` against K8up's CRDs.

```cue
// catalog/k8up/v1alpha1/transformers/backup.cue
package transformers

import (
    transformer "opmodel.dev/core/v1alpha1/transformer@v1"
    backup "opmodel.dev/opm/v1alpha1/operations/backup@v1"
    workload "opmodel.dev/opm/v1alpha1/traits/workload@v1"
)

#BackupScheduleTransformer: transformer.#PolicyTransformer & {
    metadata: {
        modulePath:  "opmodel.dev/k8up/v1alpha1/transformers"
        version:     "v1"
        name:        "backup-schedule-transformer"
        description: "Renders a #BackupPolicy directive into a K8up Schedule CR + a matching Backend CR"
    }

    // Match predicate
    requiredDirectives: [backup.#BackupPolicy.metadata.fqn]
    requiredTraits:     [backup.#BackupTrait.metadata.fqn]
    // requiredResources is left open — backup applies to whatever has the trait,
    // independent of the component's workload kind.

    // Context inputs consumed at render time
    readsContext: ["backup.backends"]

    // Output kinds (for discovery + diff surface)
    producesKinds: ["k8up.io/v1.Backend", "k8up.io/v1.Schedule"]

    // out is populated by the provider at render time; see 04 / 05 for mechanism.
}
```

The transformer is registered in the K8up provider:

```cue
// catalog/k8up/v1alpha1/providers/kubernetes/provider.cue
#Provider: provider.#Provider & {
    metadata: { name: "k8up", type: "kubernetes", version: "1.0.0" }

    #transformers: {
        // ... existing component-scope transformers for K8up CRs if any ...
    }

    #policyTransformers: {
        (transformers.#BackupScheduleTransformer.metadata.fqn):
            transformers.#BackupScheduleTransformer
    }
}
```

At render time (walked through in [07-rendering-pipeline.md](07-rendering-pipeline.md)) the transformer receives:

1. The `#BackupPolicy.#spec.backup` value.
2. For each component in `appliesTo`, that component's `#BackupTrait.#spec.backup` value and its computed `#ctx.runtime.components[name]` (for resource names, namespace, PVC identifiers).
3. The resolved `#ctx.platform.backup.backends[policy.backend]` struct.

It emits:

- One K8up `Backend` CR per unique `(namespace, backend)` referenced.
- One K8up `Schedule` CR per `(namespace, policy)` pair — references the Backend, declares the cron, retention, and annotates/selects the PVCs from the traits.

---

## Module Author Experience — Full Example

Concrete module definition, showing both layers in context:

```cue
package strix_media

import (
    m "opmodel.dev/core/v1alpha1/module@v1"
    policy "opmodel.dev/core/v1alpha1/policy@v1"
    workload "opmodel.dev/opm/v1alpha1/traits/workload@v1"
    backup "opmodel.dev/opm/v1alpha1/operations/backup@v1"
)

m.#Module

metadata: {
    modulePath:       "opmodel.dev/modules"
    name:             "strix-media"
    version:          "0.1.0"
    defaultNamespace: "media"
}

#components: {
    "app": #StatefulWorkload & backup.#BackupTrait & {
        spec: {
            container: { image: "strix:latest" }
            volumes: [
                {name: "config", size: "10Gi"},
                {name: "cache",  size: "50Gi"},
            ]
            backup: {
                targets: [{volume: "config"}]     // cache omitted by intent
                exclude: ["*.log", "*.tmp"]
            }
        }
    }

    "db": #StatefulWorkload & backup.#BackupTrait & {
        spec: {
            container: { image: "postgres:16" }
            volumes: [{name: "data", size: "5Gi"}]
            backup: {
                targets: [{volume: "data"}]
                preBackup: [{
                    name:    "pg-checkpoint"
                    command: ["psql", "-U", "postgres", "-c", "CHECKPOINT"]
                }]
            }
        }
    }
}

#policies: {
    "nightly": policy.#Policy & {
        appliesTo: components: ["app", "db"]
        #directives: {
            (backup.#BackupPolicy.metadata.fqn): backup.#BackupPolicy & {
                #spec: backup: {
                    schedule:  "0 2 * * *"
                    backend:   "offsite-b2"
                    retention: { keepDaily: 7, keepWeekly: 4, keepMonthly: 3 }
                    tags: { "app": "strix-media" }

                    restore: {
                        preRestore: [
                            {component: "app", action: "scale-down"},
                            {component: "db",  action: "scale-down"},
                        ]
                        postRestore: [
                            {component: "db",  action: "scale-up"},
                            {component: "db",  action: "wait-health"},
                            {component: "app", action: "scale-up"},
                            {component: "app", action: "wait-health"},
                        ]
                        healthChecks: {
                            "app": {path: "/health",  port: 8096}
                            "db":  {path: "/healthz", port: 5432}
                        }
                        inPlace: requiresScaleDown: true
                    }
                }
            }
        }
    }
}
```

### Platform side (platform-team authored, once per environment)

```cue
#Platform & {
    metadata: name: "kind-opm-dev"
    type: "kubernetes"

    #ctx: platform: backup: backends: {
        "offsite-b2": {
            type:              "b2"
            bucket:            "jacero-backups"
            credentialsSecret: "b2-creds"
            encryption:        { repoPasswordSecret: "restic-repo-pw" }
        }
        "local-minio": {
            type:              "s3"
            endpoint:          "http://minio.storage.svc:9000"
            bucket:            "backups"
            credentialsSecret: "minio-creds"
        }
    }

    #providers: [
        opm.#Provider,
        k8up.#Provider,    // registers the #BackupScheduleTransformer
    ]
}
```

---

## Restore At The CLI

Restore does not go through the render pipeline. The CLI reads the declarative `restore` subfield from the `#BackupPolicy` directive that covers the target component set, combines it with an imperative snapshot selector, and drives the workflow:

```
opm release restore strix-media --snapshot latest
opm release restore strix-media --snapshot <restic-id> --dry-run
opm release restore strix-media --tag "pre-upgrade-2026-04-21"
opm release restore strix-media --components db --snapshot latest
```

CLI responsibilities:

1. Locate the policy whose `appliesTo` covers the requested components.
2. Execute `restore.preRestore` steps in order.
3. Invoke the backup backend's restore mechanism with the selected snapshot.
4. Execute `restore.postRestore` steps in order.
5. Poll `restore.healthChecks[component]` until pass or timeout.

No OPM-side transformer or controller is invoked. The operator (K8up or similar) handles data movement; the CLI orchestrates the choreography declared in the directive.
