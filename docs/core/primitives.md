# OPM Primitives

Primitives are schema contracts — independently authored building blocks that all share the same shape: `metadata` (with `apiVersion`, `name`, `fqn`) + `#spec` (OpenAPIv3 compatible schema). They are composed into [Constructs](constructs.md).

A Primitive:

- Defines a reusable `#spec` schema
- Is independently authored and versioned
- Is composed into Components, Policies, or other Constructs
- Can exist across multiple modules

See [Definition Types](definition-types.md) for the full taxonomy.

---

## Resource

A **Resource** represents a fundamental, deployable entity that must exist in the runtime environment. Resources are the "nouns" of OPM — they answer the question "what is being deployed?" A Resource is standalone and has its own lifecycle; it can exist independently without requiring other definitions to make sense. Examples include Container (a running process), Volume (persistent storage), ConfigMap (configuration data), and Secret (sensitive configuration).

Resources are separate from Traits and PolicyRules because they represent **existence** rather than behavior or constraints. A component must have at least one Resource because without something that exists, there is nothing to modify (Trait) or govern (PolicyRule).

### What Resource Infers

- "This thing **must exist** in the environment"
- "This is the **root** of something deployable"
- "Without this, there is nothing to modify or govern"

### When to Create a Resource

Ask yourself:

- Does this thing need to exist in the runtime for the application to function?
- Can this thing exist on its own, without depending on another primitve?
- Does it have its own lifecycle (create, update, delete)?

**Examples**: Container, Volume, ConfigMap, Secret, Database, Queue

### Resource Structure

```cue
#Resource: {
    apiVersion: "opmodel.dev/core/v0"
    kind:       "Resource"

    metadata: {
        apiVersion!:  string  // e.g., "opmodel.dev/resources/workload@v0"
        name!:        string  // e.g., "container"
        fqn:          string  // Computed: "{apiVersion}#{Name}"
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
        name:        "container"
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

**CUE schema**: [`v0/core/resource.cue`](../../v0/core/resource.cue)

---

## Trait

A **Trait** represents a behavioral characteristic or configuration modifier that attaches to a Resource. Traits are the "adjectives" of OPM — they answer the question "how does this thing behave?" or "how is this thing configured?" A Trait cannot exist in isolation; it requires a Resource to make sense. Examples include Scaling (how many instances run and autoscaling behavior), HealthCheck (how liveness is monitored), Expose (how the workload is accessible), RestartPolicy (what happens on failure), and Sizing (how much CPU/memory to allocate).

Traits are separate from Resources because they describe **modification** rather than existence. They are separate from PolicyRules because they express **preference** rather than enforcement — a Trait says "I want this behavior" while a PolicyRule says "this behavior is required."

### What Trait Infers

- "This **modifies** how something operates"
- "This **requires** a Resource to make sense"
- "This describes **behavior** or **configuration**"

### When to Create a Trait

Ask yourself:

- Does this modify how something else operates?
- Is this a preference/configuration rather than a mandate?
- Can this only make sense when attached to a Resource?

**Examples**: Scaling, HealthCheck, Expose, RestartPolicy, Sizing, UpdateStrategy

### Trait Structure

```cue
#Trait: {
    apiVersion: "opmodel.dev/core/v0"
    kind:       "Trait"

    metadata: {
        apiVersion!:  string  // e.g., "opmodel.dev/traits/workload@v0"
        name!:        string  // e.g., "scaling"
        fqn:          string  // Computed: "{apiVersion}#{Name}"
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
#ScalingTrait: core.#Trait & {
    metadata: {
        apiVersion:  "opmodel.dev/traits/workload@v0"
        name:        "scaling"
        description: "Scaling behavior for a workload"
    }

    appliesTo: [#ContainerResource]

    #spec: scaling: {
        count: int & >=1 & <=1000 | *1
        auto?: #AutoscalingSpec
    }
}
```

**CUE schema**: [`v0/core/trait.cue`](../../v0/core/trait.cue)

---

## Blueprint

A **Blueprint** represents a reusable pattern that composes Resources and Traits into a higher-level abstraction. Blueprints are the "templates" of OPM — they answer the question "what is the standardized pattern?" A Blueprint simplifies complex configurations by grouping related definitions under a single schema, hiding the complexity of individual definitions from the end user.

Blueprints are used to define standardized workload types (like "StatelessWorkload" or "SimpleDatabase") that are composed of specific Resources (like Container, Volume) and Traits (like Scaling, Expose).

### What Blueprint Infers

- "This is a **composition** of Resources and Traits"
- "This is a **reusable pattern**"
- "This **simplifies** configuration"

### When to Create a Blueprint

Ask yourself:

- Do you find yourself repeatedly defining the same set of Resources and Traits?
- Do you want to standardize a specific architectural pattern?
- Do you want to expose a simplified schema to consumers while managing complexity behind the scenes?

**Examples**: StatelessWorkload, StatefulWorkload, CronJob, SimpleDatabase

### Blueprint Structure

```cue
#Blueprint: {
    apiVersion: "opmodel.dev/core/v0"
    kind:       "Blueprint"

    metadata: {
        apiVersion!:  string  // e.g., "opmodel.dev/blueprints/core@v0"
        name!:        string  // e.g., "stateless-workload"
        fqn:          string  // Computed: "{apiVersion}#{Name}"
        description?: string
        labels?:      {...}
        annotations?: {...}
    }

    composedResources!: [...#Resource]
    composedTraits?: [...#Trait]

    #spec!: {...}  // OpenAPIv3 schema this blueprint exposes
}
```

### Blueprint Example

```cue
#StatelessWorkloadBlueprint: core.#Blueprint & {
    metadata: {
        apiVersion:  "opmodel.dev/blueprints/core@v0"
        name:        "stateless-workload"
        description: "A stateless workload definition"
    }

    composedResources: [
        #ContainerResource
    ]

    composedTraits: [
        #ScalingTrait,
        #ExposeTrait
    ]

    #spec: statelessWorkload: {
        image!:    string
        scaling:   { count: int | *1 }
        port?:     int
    }
}
```

**CUE schema**: [`v0/core/blueprint.cue`](../../v0/core/blueprint.cue)

---

## PolicyRule

A **PolicyRule** represents a governance constraint or rule that must be true. PolicyRules are the "rules" of OPM — they answer the question "what must this thing comply with?" Unlike Traits which express preferences, PolicyRules express **requirements with enforcement consequences**. When violated, something happens (block, warn, audit).

PolicyRules are separate from Traits because they express **enforcement** rather than preference — a Trait says "I want this behavior" while a PolicyRule says "this behavior is required." PolicyRules are composed into [Policies](constructs.md#policy) which target them to components.

### What PolicyRule Infers

- "This **must be true** for the system to be compliant"
- "This has **enforcement consequences** when violated"
- "This is a **governance constraint**, not a preference"

### When to Create a PolicyRule

Ask yourself:

- Is this a mandate with enforcement consequences (block, warn, audit)?
- Does this apply across components rather than to a single resource?
- Is this a governance, security, or compliance requirement?

**Examples**: Encryption, NetworkRules, ResourceQuota, AuditLogging, BackupRetention

### PolicyRule Structure

```cue
#PolicyRule: {
    apiVersion: "opmodel.dev/core/v0"
    kind:       "PolicyRule"

    metadata: {
        apiVersion!:  string  // e.g., "opmodel.dev/policies/security@v0"
        name!:        string  // e.g., "encryption"
        fqn:          string  // Computed: "{apiVersion}#{Name}"
        description?: string
        labels?:      {...}
        annotations?: {...}
    }

    enforcement!: {
        mode!:        "deployment" | "runtime" | "both"
        onViolation!: "block" | "warn" | "audit"
        platform?:    _
    }

    #spec!: {...}  // OpenAPIv3 schema this policy rule exposes
}
```

### PolicyRule Example

```cue
#NetworkRulesPolicy: core.#PolicyRule & {
    metadata: {
        apiVersion:  "opmodel.dev/policies/connectivity@v0"
        name:        "network-rules"
        description: "Defines network traffic rules"
    }

    enforcement: {
        mode:        "deployment"
        onViolation: "block"
    }

    #spec: networkRules: [ruleName=string]: schemas.#NetworkRuleSchema
}
```

**CUE schema**: [`v0/core/policy_rule.cue`](../../v0/core/policy_rule.cue)

---

## StatusProbe

> **Draft** — This definition type is not yet finalized.

A **StatusProbe** represents a reusable, composable check that evaluates runtime health or readiness. StatusProbes are the schema contracts for health checks — they define *what* to check via `#params` and `#spec`, while the [Status](constructs.md#status) construct orchestrates *how* and *when* they are evaluated.

**Examples**: WorkloadReady, DatabaseConnected, CertificateValid

---

## LifecycleAction

> **Draft** — This definition type is not yet finalized.

A **LifecycleAction** represents a reusable, well-known action that can run during state transitions (install, upgrade, delete). LifecycleActions are the schema contracts for transition steps — they define *what* action to perform via `#spec`, while the [Lifecycle](constructs.md#lifecycle) construct orchestrates *when* and *in what order* they execute.

LifecycleActions are pre-built building blocks provided by the platform. Developers select from well-known actions rather than implementing custom ones.

**Examples**: RunMigration, ApplySchema, BackupData, CleanupResources, ValidateState
