# Problem Statement — `#Op` & `#Action` Primitives

## Current State

OPM's type system covers the declarative side — Resources, Traits, Blueprints, Claims compose into Components, which compose into Modules. The rendering pipeline (Provider, Transformer, Matcher) produces platform-specific output from these declarations.

The operational side is documented but unimplemented. The definition-types taxonomy lists two draft primitives:

- **Op** — "An atomic, reusable unit of work" (e.g., RunCommand, HTTPCall, WaitFor, CUEEval)
- **Action** — "A composed operation built from Ops and other Actions" (e.g., DBMigration, RotateCredentials, BackupData)

Two draft constructs consume Actions:

- **Lifecycle** — orchestrates Actions during state transitions (install, upgrade, delete)
- **Workflow** — sequences Actions for on-demand execution (`opm workflow run db-migration`)

None of these have CUE definitions. Without Op and Action, Lifecycle and Workflow have nothing to compose.

## Gap 1: No Primitive for Executable Operations

OPM can describe *what exists* and *what is needed* but cannot describe *what to do*. Every other concern has a primitive:

| Concern | Primitive | Status |
|---------|-----------|--------|
| "What must exist?" | `#Resource` | Implemented |
| "How does it behave?" | `#Trait` | Implemented |
| "What does it need?" | `#Claim` | Enhancement 006 |
| "What is the pattern?" | `#Blueprint` | Implemented |
| "What is the atomic operation?" | `???` | **Missing** |
| "What is the composed operation?" | `???` | **Missing** |

## Gap 2: Operational Claims Have No Execution Model

Enhancement 006 introduces operational claims like `#BackupClaim` (component-level) and `#RestoreOrchestration` (module-level). These declare *what* should happen but provide no model for *how* the runtime executes the operations. The restore orchestration says "restore the database, check health, start the app" — but there is no type for the individual steps or their ordering.

## Gap 3: No Composition Model for Operations

OPM's strength is composition: Resources + Traits + Claims compose into Components via Blueprints. Operations need an equivalent:

- Atomic operations (exec, http call, wait) should be reusable across different composed operations
- Composed operations (db-migration, rotate-credentials) should be publishable as CUE packages
- Lifecycle and Workflow should consume these composed operations without knowing their internals

Today, any operational logic lives outside CUE — in shell scripts, Helm hooks, or manual kubectl procedures.

## Concrete Example

### What should exist:

```cue
// Atomic ops — reusable, schema-typed, runtime-dispatched
#Exec: #Op & {
    @op("exec")
    image!:   string
    command!: [...string]
    #out: { exitCode: int, stdout: string }
}

#WaitFor: #Op & {
    @op("wait")
    condition!: string
    timeout!:   string
    #out: { satisfied: bool }
}

#HttpGet: #Op & {
    @op("http.get")
    url!: string
    #out: { statusCode: int, body: string }
}

// Composed action — ordered steps, publishable, reusable
#DBMigration: #Action & {
    metadata: { name: "db-migration" }
    #steps: {
        wait: ops.#WaitFor & {
            condition: "db.ready"
            timeout:   "120s"
        }
        migrate: ops.#Exec & {
            image:   string  // user provides
            command: [...string]
        }
        migrate: $after: ["wait"]

        verify: ops.#HttpGet & {
            url: string  // user provides
        }
        verify: $after: ["migrate"]
    }
}

// Module author uses it
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

## Why Existing Workarounds Fail

**Shell scripts alongside modules:** No schema validation, no composition, no reuse across modules. A migration script in one module cannot be adapted for another without copy-paste.

**Helm hooks / K8s Jobs:** Tightly coupled to Kubernetes. OPM aims for runtime agnosticism — operations should be declarable in CUE and executable by any OPM-compatible runtime.

**Manual kubectl procedures:** The restore procedure documented in the K8up backup work (2026-03-28) is 12+ manual steps. These steps are precisely the kind of sequenced operations that `#Action` should capture as a typed, composable declaration.

**`tool/exec` in `_tool.cue`:** CUE's own scripting layer (`cue cmd`) is tied to the CUE CLI, not to OPM's runtime. OPM needs operations that the OPM CLI and k8s controller can interpret and execute, not operations that require the CUE CLI.
