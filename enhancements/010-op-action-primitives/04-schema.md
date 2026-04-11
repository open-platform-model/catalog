# Schema — `#Op` & `#Action` Primitives

| Field       | Value            |
| ----------- | ---------------- |
| **Status**  | Draft            |
| **Created** | 2026-04-11       |
| **Authors** | OPM Contributors |

---

## New Definitions

### `#Op` — base type

**File:** `v1alpha1/core/primitives/op.cue`

```cue
package primitives

// #Op: Base constraint for atomic operations.
// Concrete ops extend this with @op("...") and their input schema.
// The @op attribute is opaque to CUE — the OPM runtime interprets it
// to determine which executor handles the operation.
// Not a full primitive — no metadata or FQN. Ops are schemas, not artifacts.
#Op: {
	$type: "op"
	#out?: {...}
	...
}
```

### `#Action` — full primitive

**File:** `v1alpha1/core/primitives/action.cue`

```cue
package primitives

import (
	"strings"
	t "opmodel.dev/core/v1alpha1/types@v1"
)

// #Action: A composed operation built from Ops and other Actions.
// Actions represent meaningful, developer-facing operations that
// Lifecycle and Workflow constructs consume.
// Steps are ordered via $after declarations (explicit DAG).
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

// #Step: A single step in an Action — either an atomic Op or a nested Action.
// The runtime uses $type to discriminate: "op" -> dispatch, "action" -> recurse.
#Step: (#Op | #Action) & {
	$after?: [...string]
}

#StepMap: [string]: #Step
#ActionMap: [string]: #Action
```

---

## Well-Known Ops

**Package:** `opmodel.dev/opm/v1alpha1/ops`

These are the initial set of Ops shipped with OPM. Published as a CUE module for import by Action authors.

### `#Exec`

```cue
package ops

import prim "opmodel.dev/core/v1alpha1/primitives@v1"

#Exec: prim.#Op & {
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

### `#HttpGet`

```cue
package ops

import prim "opmodel.dev/core/v1alpha1/primitives@v1"

#HttpGet: prim.#Op & {
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

### `#HttpPost`

```cue
package ops

import prim "opmodel.dev/core/v1alpha1/primitives@v1"

#HttpPost: prim.#Op & {
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

### `#WaitFor`

```cue
package ops

import prim "opmodel.dev/core/v1alpha1/primitives@v1"

#WaitFor: prim.#Op & {
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

### `#CueEval`

```cue
package ops

import prim "opmodel.dev/core/v1alpha1/primitives@v1"

#CueEval: prim.#Op & {
	@op("cue.eval")
	expression!: string
	scope?:      {...}
	#out: {
		value: _
	}
}
```

---

## Composition Example

### Published Action

```cue
package database

import (
	prim "opmodel.dev/core/v1alpha1/primitives@v1"
	ops "opmodel.dev/opm/v1alpha1/ops@v1"
)

#DBMigration: prim.#Action & {
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

### Module author fills in

```cue
import db "opmodel.dev/opm/v1alpha1/actions/database@v1"

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

### Nested Action

```cue
#FullDeploy: prim.#Action & {
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

## Runtime Execution Model (Informational)

This section describes how the OPM runtime processes an Action. It is informational — the runtime implementation is out of scope for this enhancement.

```text
1. Parse #steps map
2. For each step, read $type:
   - "op"     -> leaf node, read @op("...") attribute for executor
   - "action" -> recurse into nested #steps
3. Build DAG from $after declarations
4. Topological sort
5. Execute:
   - Steps with no unresolved dependencies -> eligible (may run in parallel)
   - On step completion -> unlock dependent steps
   - On step failure -> fail the Action
6. Rollback semantics are NOT defined by Action — owned by Lifecycle
```
