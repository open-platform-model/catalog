# OPM Definition Types

This document explains the semantic categories of definitions in OPM. Each category serves a distinct purpose and helps developers understand the role a definition plays in the system.

## Overview

OPM uses **Definition Types** as semantic categories to organize and communicate the purpose of each definition. Think of them as "roles" that definitions can play.

| Type | Purpose | Question It Answers | Level |
|------|---------|---------------------|-------|
| **Resource** | What must exist | "What is being deployed?" | Component |
| **Trait** | How it behaves | "How does it operate?" | Component |
| **Policy** | What must be true | "What rules must it follow?" | Scope/Module |
| **Blueprint** | Reusable composition | "What is the standardized pattern?" | Component |
| **Lifecycle** | What happens on transitions | "What happens on install/upgrade/delete?" | Component/Module |
| **Status** | What is computed state | "What is the configuration state?" | Module |
| **Test** | Does the lifecycle work | "Does the module work correctly?" | Separate artifact |

### Mental Model

```text
Resource  = The deployable thing (Container, Volume, ConfigMap)
Trait     = Behavior/configuration of that thing (Replicas, HealthCheck, Expose)
Policy    = Constraints on that thing (Encryption, NetworkRules, ResourceQuota)
Blueprint = Composition of Resources, Traits, and Policies (StatelessWorkload, TaskWorkload)
Lifecycle = Transition actions (ApplySchema, RunMigration, Cleanup)
Status    = Computed state from configuration (health, diagnostics, phase)
Test      = Lifecycle verification (InstallTest, UpgradeTest, DeleteTest)
```

---

## Resource

A **Resource** represents a fundamental, deployable entity that must exist in the runtime environment. Resources are the "nouns" of OPM - they answer the question "what is being deployed?" A Resource is standalone and has its own lifecycle; it can exist independently without requiring other definitions to make sense. Examples include Container (a running process), Volume (persistent storage), ConfigMap (configuration data), and Secret (sensitive configuration).

Resources are separate from Traits and Policies because they represent **existence** rather than behavior or constraints. A component must have at least one Resource because without something that exists, there is nothing to modify (Trait) or govern (Policy).

### What Resource Infers

- "This thing **must exist** in the environment"
- "This is the **root** of something deployable"
- "Without this, there is nothing to modify or govern"

### When to Create a Resource

Ask yourself:

- Does this thing need to exist in the runtime for the application to function?
- Can this thing exist on its own, without depending on another definition type?
- Does it have its own lifecycle (create, update, delete)?

**Examples**: Container, Volume, ConfigMap, Secret, Database, Queue

### Resource Structure

```cue
#Resource: {
    apiVersion: "opmodel.dev/core"
    kind:       "Resource"

    metadata: {
        apiVersion!:  string  // e.g., "opmodel.dev/resources/workload@v0"
        name!:        string  // e.g., "Container"
        fqn:          string  // Computed: "{apiVersion}#{name}"
        description?: string
        labels?:      {...}
        annotations?: {...}
    }

    #spec!: {...}  // OpenAPIv3 schema this resource exposes
}
```

### Resource Example

```cue
#ContainerResource: core.#Resource & {
    metadata: {
        apiVersion:  "opmodel.dev/resources/workload@v0"
        name:        "Container"
        description: "A container definition for workloads"
        labels: {
            "core.opmodel.dev/category": "workload"
        }
    }

    #spec: container: {
        image!:           string
        command?:         [...string]
        args?:            [...string]
        env?:             [...{name: string, value: string}]
        ports?:           [...{containerPort: int, protocol?: string}]
        imagePullPolicy?: "Always" | "IfNotPresent" | "Never"
    }
}
```

---

## Trait

A **Trait** represents a behavioral characteristic or configuration modifier that attaches to a Resource. Traits are the "adjectives" of OPM - they answer the question "how does this thing behave?" or "how is this thing configured?" A Trait cannot exist in isolation; it requires a Resource to make sense. Examples include Replicas (how many instances run), HealthCheck (how liveness is monitored), Expose (how the workload is accessible), RestartPolicy (what happens on failure), and ResourceLimit (how much CPU/memory to allocate).

Traits are separate from Resources because they describe **modification** rather than existence. They are separate from Policies because they express **preference** rather than enforcement - a Trait says "I want this behavior" while a Policy says "this behavior is required."

### What Trait Infers

- "This **modifies** how something operates"
- "This **requires** a Resource to make sense"
- "This describes **behavior** or **configuration**"

### When to Create a Trait

Ask yourself:

- Does this modify how something else operates?
- Is this a preference/configuration rather than a mandate?
- Can this only make sense when attached to a Resource?

**Examples**: Replicas, HealthCheck, Expose, RestartPolicy, ResourceLimit, UpdateStrategy

### Trait Structure

```cue
#Trait: {
    apiVersion: "opmodel.dev/core"
    kind:       "Trait"

    metadata: {
        apiVersion!:  string  // e.g., "opmodel.dev/traits/workload@v0"
        name!:        string  // e.g., "Replicas"
        fqn:          string  // Computed: "{apiVersion}#{name}"
        description?: string
        labels?:      {...}
        annotations?: {...}
    }

    appliesTo!: [...#Resource]  // Which Resources this Trait can modify

    #spec!: {...}  // OpenAPIv3 schema this trait exposes
}
```

### Key Difference from Resource

Traits have an `appliesTo` field that declares which Resources they can modify:

```text
Trait → appliesTo → Resource
```

### Trait Example

```cue
#ReplicasTrait: core.#Trait & {
    metadata: {
        apiVersion:  "opmodel.dev/traits/workload@v0"
        name:        "Replicas"
        description: "Number of replicas for a workload"
    }

    appliesTo: [#ContainerResource]

    #spec: replicas: int & >=0
}
```

---

## Policy

A **Policy** represents a governance constraint, rule, or expectation that must be true. Policies are the "rules" of OPM - they answer the question "what must this thing comply with?" Unlike Traits which express preferences, Policies express **requirements with enforcement consequences**. Examples include SecurityContext (must not run as root), Encryption (must encrypt data at rest), NetworkRules (must only allow traffic from specific sources), and ResourceQuota (must not exceed these limits).

Policies are separate from Traits because they have **enforcement semantics** - when violated, something happens (block, warn, audit). A Trait misconfiguration is just that - a misconfiguration. A Policy violation is a governance failure. Policies are typically authored by platform, security, or compliance teams rather than application developers.

Intrinsic constraints (like SecurityContext or ResourceLimits) that apply to a single component are modeled as **Traits**, not Policies. Policies are reserved for governance rules imposed by the platform on components (one-to-many).

### What Policy Infers

- "This **must be true** about something"
- "This is a **constraint**, not a suggestion"
- "This has **enforcement** consequences"

### The Key Distinction: Trait vs Policy

| Aspect | Trait | Policy |
|--------|-------|--------|
| **Purpose** | Configure behavior | Enforce constraint |
| **Semantics** | "Should operate this way" | "Must comply with this rule" |
| **Enforcement** | None (just configuration) | Yes (block/warn/audit) |
| **Failure mode** | Misconfiguration | Violation |
| **Who defines** | Developers, Platform teams | Platform, Security, Compliance teams |

### When to Create a Policy

Ask yourself:

- Is this a constraint that must be enforced?
- What happens if this is violated - should it block, warn, or audit?
- Is this a governance requirement rather than a developer preference?

**Examples**: Encryption, NetworkRules, ResourceQuota, SecurityContext, AuditLogging, BackupRetention

### Policy Levels

| Level | Applied In | Use Case |
|-------|------------|----------|
| Scope | `#Scope.#policies` | Cross-cutting constraints (NetworkRules, mTLS) |
| Module | `#Module.#policies` | Runtime enforcement (AuditLogging, PodDisruptionBudget) |

### Policy Structure

```cue
#Policy: {
    apiVersion: "opmodel.dev/core"
    kind:       "Policy"

    metadata: {
        apiVersion!:  string  // e.g., "opmodel.dev/policies/security@v0"
        name!:        string  // e.g., "Encryption"
        fqn:          string  // Computed: "{apiVersion}#{name}"
        description?: string
        target!:      "scope" | "module" // Where it applies
        labels?:      {...}
        annotations?: {...}
    }

    enforcement!: {
        mode!:        "deployment" | "runtime" | "both"
        onViolation!: "block" | "warn" | "audit"
        platform?:    _  // Platform-specific (Kyverno, OPA, etc.)
    }

    #spec!: {...}  // OpenAPIv3 schema this policy exposes
}
```

### Policy Example

```cue
#NetworkPolicy: core.#Policy & {
    metadata: {
        apiVersion:  "opmodel.dev/policies/network@v0"
        name:        "NetworkRules"
        description: "Enforces network boundaries"
        target:      "scope"
    }

    enforcement: {
        mode:        "deployment"
        onViolation: "block"
    }

    #spec: network: {
        allowPublicEgress: bool | *false
    }
}
```

---

## Blueprint

A **Blueprint** represents a reusable pattern that composes Resources and Traits into a higher-level abstraction. Blueprints are the "templates" of OPM - they answer the question "what is the standardized pattern?" A Blueprint simplifies complex configurations by grouping related definitions under a single schema, hiding the complexity of individual definitions from the end user.

Blueprints are used to define standardized workload types (like "StatelessWorkload" or "DatabaseCluster") that are composed of specific Resources (like Container, Volume) and Traits (like Replicas, Service).

### What Blueprint Infers

- "This is a **composition** of Resources and Traits"
- "This is a **reusable pattern**"
- "This **simplifies** configuration"

### When to Create a Blueprint

Ask yourself:

- Do you find yourself repeatedly defining the same set of Resources and Traits?
- Do you want to standardize a specific architectural pattern?
- Do you want to expose a simplified schema to consumers while managing complexity behind the scenes?

**Examples**: StatelessWorkload, StatefulWorkload, CronJob, DatabaseCluster

### Blueprint Structure

```cue
#Blueprint: {
    apiVersion: "opmodel.dev/core"
    kind:       "Blueprint"

    metadata: {
        apiVersion!:  string  // e.g., "opmodel.dev/blueprints/core@v0"
        name!:        string  // e.g., "StatelessWorkload"
        fqn:          string  // Computed: "{apiVersion}#{name}"
        description?: string
        labels?:      {...}
        annotations?: {...}
    }

    // Resources that compose this blueprint
    composedResources!: [...#Resource]

    // Traits that compose this blueprint
    composedTraits?: [...#Trait]

    #spec!: {...}  // OpenAPIv3 schema this blueprint exposes
}
```

### Blueprint Example

```cue
#StatelessWorkloadBlueprint: core.#Blueprint & {
    metadata: {
        apiVersion:  "opmodel.dev/blueprints/core@v0"
        name:        "StatelessWorkload"
        description: "A stateless workload definition"
    }

    composedResources: [
        #ContainerResource
    ]

    composedTraits: [
        #ReplicasTrait,
        #ExposeTrait
    ]

    #spec: statelessWorkload: {
        image!:    string
        replicas:  int | *1
        port?:     int
    }
}
```

---

## Status

A **Status** represents computed, configuration-derived information about a module. Status answers the question "what is the computed state of this configuration?" In OPM, Status is evaluated at CUE compile-time from module configuration - it is **not** runtime-observed state from a live system. Status provides structured diagnostic information, health indicators derived from configuration values, and human-readable messages.

Status is separate from other definition types because it is **derived/computed** rather than declared. A developer doesn't set `healthy: true` directly; they define an expression like `healthy: values.replicas >= 1` that computes health from configuration.

### What Status Infers

- "This is **computed** from configuration"
- "This provides **diagnostic insight**"
- "This is evaluated at **CUE compile-time**, not runtime"

### When to Use Status

Ask yourself:

- Is this information computed from configuration values?
- Does this provide diagnostic insight about the module's configuration?
- Should this be evaluated before deployment?

**Examples**: Health indicators, validation summaries, configuration completeness, replica counts

### Status Structure

```cue
#ModuleStatus: {
    // Structured diagnostic information (key-value pairs)
    // Only primitive types allowed for portability
    details?: [string]: bool | int | string

    // Overall health indicator
    // Must evaluate to a concrete boolean
    valid?: bool

    // Human-readable status message
    message?: string

    // Module phase derived from health (convenience field)
    phase?: "healthy" | "degraded" | "unknown"

    // Composable Runtime Probes
    // A map of probes that will be evaluated at runtime by the controller.
    // The controller unifies live state into these probes to determine runtime health.
    #probes?: #StatusProbeMap
}

#StatusProbe: close({
    apiVersion: "opmodel.dev/core/v0"
    kind:       "StatusProbe"

    metadata: {
        apiVersion!: #NameType                          // Example: "opmodel.dev/statusprobes/workload@v0"
        name!:       #NameType                          // Example: "WorkloadReady"
        fqn:         #FQNType & "\(apiVersion)#\(name)" // Example: "opmodel.dev/statusprobes/workload@v0#WorkloadReady"

        description?: string
        labels?:      #LabelsAnnotationsType
        annotations?: #LabelsAnnotationsType
    }

    // Input parameters for the probe (to be filled by the module developer)
    // Example: { resourceName: "frontend" }
    #params: {...}

    // Runtime Context (injected by the controller at runtime)
    // This defines the contract for what data is available to the logic.
    context: {
        // Map of all deployed resources (live state)
        // Key matches the resource ID in the deployment
        outputs: [string]: {...}

        // The concrete values used for the deployment
        values: {...}
    }

    // The Result Logic (Native CUE)
    // The controller unifies the live 'context' into this definition,
    // and reads the 'result' field to determine status.
    result: {
        healthy!: bool
        message?: string
        details?: [string]: bool | int | string
    }

    // Helper to expose the spec (OpenAPI compatibility)
    #spec!: (strings.ToCamel(metadata.name)): #params
})

#StatusProbeMap: [string]: #StatusProbe
```

### Status Example

```cue
myModule: #Module & {
    values: {
        frontend: { replicas: 2 }
        api:      { replicas: 3 }
    }

    #status: {
        details: {
            totalReplicas: values.frontend.replicas + values.api.replicas
        }
        healthy: values.frontend.replicas >= 1 && values.api.replicas >= 1
        message: "Module with \(details.totalReplicas) total replicas"
        phase: if healthy { "healthy" } else { "degraded" }
    }
}
```

---

## Lifecycle

A **Lifecycle** represents well-known, reusable steps that occur during state transitions. Lifecycle answers the question "what happens when this is installed, upgraded, or deleted?" Unlike Traits (how it behaves during normal operation) or Policies (what constraints apply), Lifecycle defines **transition actions** at specific lifecycle moments.

Lifecycle can be defined at **both component and module levels**. At the component level, lifecycle steps describe what happens when that specific component transitions (e.g., a database component runs migrations on upgrade). At the module level, lifecycle steps describe cross-cutting operations that affect the entire module.

Lifecycle definitions are **pre-built building blocks** provided by the platform - developers cannot write custom lifecycle steps, they select from well-known ones. This ensures lifecycle operations are safe, tested, and consistent across modules.

### What Lifecycle Infers

- "This happens during **state transitions** (install, upgrade, delete)"
- "This is a **pre-built, reusable** step"
- "This ensures **safe, tested operations**"

### When to Use Lifecycle

Ask yourself:

- Does this describe an action that occurs during install/upgrade/delete?
- Is this a well-known, reusable step rather than custom logic?
- Should this be selected from a catalog rather than implemented?

**Examples**: ApplyBaseSchema (on install), RunMigration (on upgrade), CleanupData (on delete), BackupBeforeUpgrade (before upgrade)

### Key Characteristics

- Defines actions at **state transition points** (install, upgrade, delete)
- Can be defined at **component level** or **module level**
- Is **pre-built and reusable** - developers select, not implement
- **No custom lifecycle steps** - only well-known blocks from catalog
- May specify ordering, conditions, and rollback behavior

---

## Test

A **Test** represents a verification that can be executed against a module's lifecycle. Test answers the question "does this module work correctly through its lifecycle?" Unlike Policies (constraints checked at deployment/runtime), Tests are **actively executed** verifications that a module developer defines to validate their module works through install, upgrade, and delete cycles.

Tests are defined as a **separate artifact** alongside the module, not within the module definition itself. This keeps the core OPM module system simple while allowing a dedicated test system to handle the complexity of test execution, environment setup, and result reporting. The test system is intentionally a separate concern from the OPM CLI.

### What Test Infers

- "This **verifies** the module works"
- "This is **executed** by the developer"
- "This validates **lifecycle operations**"

### When to Use Test

Ask yourself:

- Is this a verification that needs to be actively run?
- Does this validate the module's lifecycle operations?
- Should this produce a pass/fail result?

**Examples**: InstallTest (verify fresh install), UpgradeTest (verify upgrade from v1 to v2), DeleteTest (verify clean deletion), RollbackTest (verify rollback)

### Key Characteristics

- Defines **executable verifications** owned by module developers
- Validates **lifecycle operations** (install, upgrade, delete)
- Can test **version transitions** (upgrade from v1.0 to v2.0)
- Is a **separate artifact** from the module definition
- Implemented as a **separate system** from OPM CLI

---

## Summary Table

| Type | Question It Answers | Level | Required? | Key Differentiator |
|------|---------------------|-------|-----------|-------------------|
| **Resource** | "What exists?" | Component | Yes (≥1) | Fundamental existence |
| **Trait** | "How does it behave?" | Component | No | Modifies Resource behavior |
| **Policy** | "What must be true?" | Scope/Module | No | Enforcement consequences |
| **Blueprint** | "What is the pattern?" | Component | No | Composition of definitions |
| **Status** | "What is computed state?" | Module | No | Derived from configuration |
| **Lifecycle** | "What happens on transitions?" | Component/Module | No | Pre-built transition steps |
| **Test** | "Does the lifecycle work?" | Separate artifact | No | Executable verification |

## Decision Flowchart

When deciding which definition type to use:

1. **Is this a standalone deployable thing?** → **Resource**
2. **Does this modify how a Resource operates?** → **Trait**
3. **Is this a reusable composition of Resources/Traits?** → **Blueprint**
4. **Is this a constraint with enforcement consequences?** → **Policy**
5. **Is this computed from configuration?** → **Status**
6. **Does this happen during install/upgrade/delete?** → **Lifecycle**
7. **Is this a verification of lifecycle operations?** → **Test**
