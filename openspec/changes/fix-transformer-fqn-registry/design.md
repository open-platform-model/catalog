## Context

Seven transformer definitions exist under `v0/providers/kubernetes/transformers/`. They use two different `metadata.apiVersion` patterns:

| Pattern | Used by |
|---|---|
| `"opmodel.dev/providers/kubernetes/transformers@v0"` | statefulset, job, cronjob, service, pvc (5 of 7) |
| `"transformer.opmodel.dev/workload@v1"` | deployment, daemonset (2 of 7) |

The provider registry at `v0/providers/kubernetes/provider.cue` maps transformer FQN strings to definitions. These keys use a third pattern (`"transformer.opmodel.dev/workload@v0#..."`, `"transformer.opmodel.dev/network@v0#..."`, `"transformer.opmodel.dev/storage@v0#..."`) that matches neither actual apiVersion pattern. CUE doesn't catch this because `#TransformerMap` is `[string]: #Transformer` — the key is unconstrained.

The `test_data.cue` resource and trait FQN keys (`"opmodel.dev/resources/workload@v0#Container"`, etc.) are already correct — they match the computed FQNs from resource/trait definitions. These are unaffected.

## Goals / Non-Goals

**Goals:**

- Standardize all Kubernetes transformer `metadata.apiVersion` values to `"opmodel.dev/providers/kubernetes/transformers@v0"`
- Replace hand-written FQN strings in `provider.cue` with computed key references
- Ensure every transformer registry key exactly matches the transformer's computed `fqn`
- Constrain `#TransformerMap` keys to `#FQNType` so non-FQN keys are rejected at definition time

**Non-Goals:**

- Constraining other map types (`#ResourceMap`, `#TraitMap`, `#BlueprintMap`, `#PolicyMap`) to `#FQNType` keys — those maps are used differently (component maps where values are `_` not full definitions) and deserve separate analysis
- Changing resource/trait FQN references in `test_data.cue` (already correct)
- Establishing an apiVersion convention for future non-Kubernetes providers (out of scope)

## Decisions

### 1. Standardize on `"opmodel.dev/providers/kubernetes/transformers@v0"`

**Decision**: All seven Kubernetes transformers use `"opmodel.dev/providers/kubernetes/transformers@v0"` as their `metadata.apiVersion`.

**Rationale**: This is the majority pattern (5 of 7 already use it). It follows the `opmodel.dev/providers/<provider>/<type>@v<N>` convention used elsewhere in the codebase. The alternative `"transformer.opmodel.dev/..."` inverts the domain hierarchy and uses `@v1` inconsistently (no `@v0` ever existed).

**Alternative considered**: Use `"transformer.opmodel.dev/workload@v0"` to match the existing provider.cue keys — rejected because it would require changing 5 files instead of 2, and the `transformer.opmodel.dev` pattern is inconsistent with the rest of OPM's domain conventions.

### 2. Use computed FQN references as provider registry keys

**Decision**: Replace hand-written string keys with CUE parenthesized key expressions:

```cue
transformers: {
    (k8s_transformers.#DeploymentTransformer.metadata.fqn): k8s_transformers.#DeploymentTransformer
    (k8s_transformers.#StatefulSetTransformer.metadata.fqn): k8s_transformers.#StatefulSetTransformer
    // ...
}
```

**Rationale**: Parenthesized keys in CUE evaluate the expression to produce the key string. Since `metadata.fqn` is computed from `apiVersion` and `_definitionName`, the key will always match the transformer's own FQN — making drift structurally impossible. This is the same pattern used in example components (e.g., `(#ContainerResource.metadata.fqn): ...`).

**Alternative considered**: Validate keys with a CUE constraint (e.g., assert key == value.metadata.fqn) — rejected because it adds complexity without solving the root cause. Computed keys eliminate the class of bug entirely.

### 3. Constrain `#TransformerMap` keys to `#FQNType`

**Decision**: Change the `#TransformerMap` definition in `v0/core/transformer.cue` from `[string]: #Transformer` to `[#FQNType]: #Transformer`.

```cue
#TransformerMap: [#FQNType]: #Transformer
```

**Rationale**: This adds a type-safety layer at the schema level. Even if a provider author uses hand-written string keys (not computed references), invalid keys are rejected at `cue vet` time. Combined with Decision 2, this provides defense in depth: computed keys prevent drift, and the type constraint catches any manual overrides.

The change is minimal (one line in core) and `#FQNType` is already defined in `v0/core/common.cue`. The `#Provider.transformers` field is typed as `#TransformerMap`, so the constraint propagates automatically.

**Alternative considered**: Only rely on computed keys (Decision 2) without schema constraint — rejected because it doesn't protect against future hand-written keys in other providers. The schema constraint encodes the invariant at the type level (Principle I: Type Safety First).

**Impact on other map types**: `#ResourceMap`, `#TraitMap`, `#BlueprintMap`, and `#PolicyMap` also use `[string]` keys. These are used in `#Component` where values are `_` (unconstrained) and keys serve as FQN lookup keys. Constraining those maps is a valid improvement but has a wider blast radius (affects all component definitions across all modules) and should be evaluated separately.

### 4. Leave test_data.cue resource/trait FQN keys unchanged

**Decision**: Do not modify FQN keys for `#resources` and `#traits` maps in `test_data.cue`.

**Rationale**: These keys (`"opmodel.dev/resources/workload@v0#Container"`, `"opmodel.dev/traits/workload@v0#CronJobConfig"`, etc.) already match the computed FQNs from the resource and trait definitions. They are correct. Changing them to computed references would be a nice improvement but is out of scope — test_data uses string literals consistently and `cue vet` validates the unification.

## Risks / Trade-offs

**[FQN value changes for deployment and daemonset transformers]** → These two transformers change apiVersion from `@v1` to `@v0`, which changes their computed FQN. Any external code referencing these FQNs will break. Mitigation: pre-v1 software, no external consumers yet.

**[Computed keys may obscure transformer registration]** → Hand-written keys are immediately readable; computed keys require tracing the expression. Mitigation: the pattern `(#Foo.metadata.fqn): #Foo` is self-documenting and already used in example components.

**[#FQNType constraint on TransformerMap is a core schema change]** → Affects the core module, not just providers. However, the change is one line and only tightens an existing unconstrained key. All existing valid usage already uses FQN-shaped strings, so no legitimate code breaks.
