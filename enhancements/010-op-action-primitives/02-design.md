# Design — `#Op` & `#Action` Primitives

## Design Goals

- Introduce `#Op` as a slim base type (not a full primitive) for atomic, runtime-dispatched operations
- Introduce `#Action` as a full primitive that composes Ops into ordered execution flows
- Ops use CUE `@op("...")` attributes for runtime dispatch — opaque to CUE evaluation, interpreted by OPM runtime
- Actions use `$after` fields for explicit step ordering (DAG)
- Ops carry their schema (inputs + `#out`) so that composition is type-safe
- Actions are publishable as CUE packages — module authors import and fill in concrete values
- The hermetic boundary is clear: CUE declares, runtime executes
- `$type` discriminator field enables runtime to distinguish Ops from Actions in steps

## Non-Goals

- Implementing Lifecycle or Workflow constructs (they consume Actions, designed separately)
- Runtime execution engine design (CLI or controller internals)
- Cross-step data wiring via `#out` references (deferred; `$after` handles ordering for now)
- WASM-based Op implementations (possible future extension, not required)
- Rollback semantics (owned by Lifecycle, not Action)

---

## The Operational Type Hierarchy

```text
#Op (slim base: $type + @op + schema + #out)
  |-- #Exec         @op("exec")
  |-- #HttpGet      @op("http.get")
  |-- #WaitFor      @op("wait")
  |-- #CueEval      @op("cue.eval")
  '-- (user-defined ops via CUE packages)

#Action (full primitive: metadata + #steps)
  |-- #DBMigration
  |-- #RotateCredentials
  |-- #BackupData
  '-- (user-defined actions via CUE packages)

#Step = (#Op | #Action) & {$after?: [...string]}

Consumers:
  #Lifecycle  consumes  #Action  (state transitions: install, upgrade, delete)
  #Workflow   consumes  #Action  (on-demand: opm workflow run <name>)
```

### Parallel to the Declarative Side

| Declarative | Operational | Role |
|---|---|---|
| `#Resource` | `#Op` | Atomic building block |
| `#Blueprint` | `#Action` | Composed unit from atomic blocks |
| `#Component` | `#Lifecycle` / `#Workflow` | Consumes composed units |
| `_allFields` unification | `$after` DAG | Composition mechanism |
| Order irrelevant | Order preserved | Key difference |

---

## `#Op` — Slim Base Type

`#Op` is not a full primitive — it has no metadata, FQN, or apiVersion. It is a schema contract: inputs, a runtime dispatch attribute, and a hidden output shape.

**Location:** `v1alpha1/core/primitives/op.cue`

```cue
// #Op: Base constraint for atomic operations.
// Concrete ops extend this with @op("...") and their input schema.
// The @op attribute is opaque to CUE — the OPM runtime interprets it
// to determine which executor handles the operation.
#Op: {
    $type: "op"
    #out?: {...}
    ...
}
```

### Why `#Op` is slim

Full primitives (#Resource, #Trait, #Claim) need metadata + FQN because they are composed by reference into Components and Blueprints. Ops are composed inline into Action steps — the Action is the publishable, referenceable unit. Ops are schemas, not standalone artifacts.

This mirrors Hofstadter's model: `@task(os.Exec)` is not a registered entity with metadata — it is an inline schema that the runtime dispatches.

### The `@op("...")` attribute

CUE attributes are opaque metadata — CUE evaluation ignores them entirely. The OPM runtime walks an Action's steps, reads each `@op` attribute, and dispatches to the corresponding executor.

Known Op types (initial set):

| Attribute | Executor | Purpose |
|---|---|---|
| `@op("exec")` | Container execution | Run a command in a container image |
| `@op("http.get")` | HTTP client | Perform an HTTP GET request |
| `@op("http.post")` | HTTP client | Perform an HTTP POST request |
| `@op("wait")` | Polling loop | Wait for a condition to be satisfied |
| `@op("cue.eval")` | CUE evaluator | Evaluate a CUE expression |

### The `#out` contract

Every Op declares its output shape as a hidden `#out` field. Hidden because:

- Outputs are runtime-produced — they don't appear in `cue export` of the declaration
- They don't pollute the Action's step namespace
- The runtime knows the shape to populate after execution

```cue
#Exec: #Op & {
    @op("exec")
    image!:   string
    command!: [...string]
    env?:     [string]: string
    #out: {
        exitCode: int
        stdout:   string
        stderr:   string
    }
}
```

---

## Well-Known Ops

**Location:** Published as CUE packages under `opmodel.dev/opm/v1alpha1/ops/`

### `#Exec` — Run a command in a container

```cue
#Exec: #Op & {
    @op("exec")
    image!:   string
    command!: [...string]
    env?:     [string]: string
    workdir?: string
    #out: {
        exitCode: int
        stdout:   string
        stderr:   string
    }
}
```

### `#HttpGet` — HTTP GET request

```cue
#HttpGet: #Op & {
    @op("http.get")
    url!:     string
    headers?: [string]: string
    timeout?: *"30s" | string
    #out: {
        statusCode: int
        body:       string
        headers: [string]: string
    }
}
```

### `#HttpPost` — HTTP POST request

```cue
#HttpPost: #Op & {
    @op("http.post")
    url!:     string
    body?:    string
    headers?: [string]: string
    timeout?: *"30s" | string
    #out: {
        statusCode: int
        body:       string
        headers: [string]: string
    }
}
```

### `#WaitFor` — Wait for a condition

```cue
#WaitFor: #Op & {
    @op("wait")
    condition!: string
    timeout!:   string
    interval:   *"5s" | string
    #out: {
        satisfied: bool
        elapsed:   string
    }
}
```

### `#CueEval` — Evaluate a CUE expression

```cue
#CueEval: #Op & {
    @op("cue.eval")
    expression!: string
    scope?:      {...}
    #out: {
        value: _
    }
}
```

---

## `#Action` — Full Primitive

`#Action` is a full primitive with metadata and FQN. It composes Ops (and nested Actions) into ordered execution flows via `#steps`.

**Location:** `v1alpha1/core/primitives/action.cue`

```cue
#Action: {
    $type:      "action"
    apiVersion: "opmodel.dev/core/v1alpha1"
    kind:       "Action"

    metadata: {
        modulePath!: t.#ModulePathType
        version!:    t.#MajorVersionType
        name!:       t.#NameType
        #definitionName: (t.#KebabToPascal & {"in": name}).out

        fqn: t.#FQNType & "\(modulePath)/\(name)@\(version)"

        description?: string
        labels?:      t.#LabelsAnnotationsType
        annotations?: t.#LabelsAnnotationsType
    }

    #steps: #StepMap
}

#Step: (#Op | #Action) & {
    $after?: [...string]
}

#StepMap: [string]: #Step
#ActionMap: [string]: #Action
```

### How `#steps` works

Steps are named struct fields. Each step is either an `#Op` (atomic) or a nested `#Action` (composed). The runtime uses `$type` to discriminate:

- `$type: "op"` — dispatch via `@op("...")` attribute
- `$type: "action"` — recurse into the nested Action's `#steps`

### How `$after` works

`$after` declares explicit dependencies between steps. The runtime builds a DAG:

1. Parse all steps and their `$after` declarations
2. Topological sort
3. Steps with no unresolved dependencies are eligible to run
4. Multiple eligible steps may run in parallel
5. Step completion unlocks dependent steps
6. Any step failure fails the Action (rollback semantics owned by Lifecycle)

`$after` references step names (the struct field keys within `#steps`).

---

## Concrete Actions

### `#DBMigration`

```cue
#DBMigration: #Action & {
    metadata: {
        modulePath:  "opmodel.dev/opm/v1alpha1/actions/database"
        version:     "v1"
        name:        "db-migration"
        description: "Runs database migration with pre-check and post-verify"
    }

    #steps: {
        wait: ops.#WaitFor & {
            condition: "db.ready"
            timeout:   "120s"
        }

        migrate: ops.#Exec & {
            image:   string
            command: [...string]
        }
        migrate: $after: ["wait"]

        verify: ops.#HttpGet & {
            url: string
        }
        verify: $after: ["migrate"]
    }
}
```

### `#BackupData`

```cue
#BackupData: #Action & {
    metadata: {
        modulePath:  "opmodel.dev/opm/v1alpha1/actions/data"
        version:     "v1"
        name:        "backup-data"
        description: "Executes a backup with optional pre-backup hook and verification"
    }

    #steps: {
        preHook: ops.#Exec & {
            image:   *"alpine:3" | string
            command: [...string]
        }

        backup: ops.#Exec & {
            image:   string
            command: [...string]
        }
        backup: $after: ["preHook"]

        verify: ops.#Exec & {
            image:   string
            command: [...string]
        }
        verify: $after: ["backup"]
    }
}
```

---

## Usage by Module Authors

### Filling in a published Action

```cue
import (
    db "opmodel.dev/opm/v1alpha1/actions/database"
)

myMigration: db.#DBMigration & {
    #steps: {
        migrate: {
            image:   "flyway/flyway:10"
            command: ["flyway", "-url=jdbc:postgresql://db:5432/app", "migrate"]
        }
        verify: url: "http://app:8080/health"
    }
}
```

### Defining a custom Action inline

```cue
seedDatabase: #Action & {
    metadata: {
        modulePath: "myorg.dev/modules/myapp/actions"
        version:    "v1"
        name:       "seed-database"
    }

    #steps: {
        waitDb: ops.#WaitFor & {
            condition: "db.ready"
            timeout:   "60s"
        }

        seed: ops.#Exec & {
            image:   "myorg/db-seeder:latest"
            command: ["seed", "--env=production"]
        }
        seed: $after: ["waitDb"]

        warmCache: ops.#HttpGet & {
            url: "http://app:8080/api/cache/warm"
        }
        warmCache: $after: ["seed"]
    }
}
```

### Nesting Actions

An Action step can be another Action. The runtime recurses:

```cue
#FullDeploy: #Action & {
    metadata: {
        modulePath: "myorg.dev/modules/myapp/actions"
        version:    "v1"
        name:       "full-deploy"
    }

    #steps: {
        backup: data.#BackupData & {
            #steps: {
                preHook: {
                    image:   "alpine:3"
                    command: ["sh", "-c", "sqlite3 /data/db 'PRAGMA wal_checkpoint;'"]
                }
                backup: {
                    image:   "restic/restic:latest"
                    command: ["restic", "backup", "/data"]
                }
                verify: {
                    image:   "restic/restic:latest"
                    command: ["restic", "check"]
                }
            }
        }

        migrate: db.#DBMigration & {
            #steps: {
                migrate: {
                    image:   "flyway/flyway:10"
                    command: ["flyway", "migrate"]
                }
                verify: url: "http://app:8080/health"
            }
        }
        migrate: $after: ["backup"]

        notify: ops.#HttpPost & {
            url:  "https://hooks.slack.com/services/T.../B.../xxx"
            body: "{\"text\": \"Deploy complete\"}"
        }
        notify: $after: ["migrate"]
    }
}
```

---

## The Hermetic Boundary

| Layer | Hermetic? | What happens |
|---|---|---|
| `#Op` / `#Action` CUE definitions | Yes | Pure CUE schema — declares shape, constraints, composition |
| `@op("...")` attribute | N/A | Opaque metadata — CUE ignores it entirely |
| `$after` ordering | Yes | CUE validates the field; runtime interprets the DAG |
| `$type` discriminator | Yes | CUE validates the value; runtime dispatches on it |
| Runtime execution | No | OPM CLI or k8s controller reads attributes, executes side effects |

CUE evaluation is always hermetic. The `@op` attribute crosses the hermetic boundary only when the OPM runtime interprets it. This is the same model as CUE's own `tool/exec` — the `_tool.cue` file declares, `cue cmd` executes.

---

## How Actions Connect to Lifecycle and Workflow

Actions are the building blocks that Lifecycle and Workflow consume. This enhancement defines the blocks; the constructs that compose them are designed separately.

```text
#Op (atomic)
  '-> #Action (composed, ordered)
        |-> #Lifecycle (state transitions: install, upgrade, rollback, delete)
        '-> #Workflow  (on-demand: opm workflow run <name>)
```

**Lifecycle** will define which Actions run on which transitions, with rollback semantics and phase grouping.

**Workflow** will define which Actions run on explicit invocation, with sequential execution and no rollback.

Both consume `#ActionMap` — a map of Actions keyed by FQN.

---

## Prior Art: Hofstadter Task Engine

This design is inspired by [Hofstadter's task engine](https://hofstadter.io/getting-started/task-engine/), adapted to OPM's patterns:

| Hofstadter | OPM | Adaptation |
|---|---|---|
| `@task(os.Exec)` | `@op("exec")` | Attribute = runtime dispatch |
| Task struct fields | Op schema fields | Schema IS the definition |
| `@flow()` | `#Action` | Named, composable flow container |
| Implicit DAG from field references | `$after` explicit ordering | Simpler, deterministic, no reference-tracing in runtime |
| No formal task base type | `#Op` (minimal base) | `$type` + `#out` contract |
| `hof flow` | OPM CLI / k8s controller | Runtime that interprets attributes |

Key divergence: Hofstadter resolves ordering from CUE field references (implicit DAG). OPM uses explicit `$after` declarations. This is simpler for the runtime to implement and makes ordering visible in the CUE declaration rather than buried in reference chains.
