# `#PolicyTransformer`

A new transformer scope, sibling to `#Transformer`. Where `#Transformer` matches a single component and emits component-scope resources, `#PolicyTransformer` matches a `#Directive` inside a `#Policy`, reads the `appliesTo` components' trait specs, and emits module-scope resources.

## Schema

File: `catalog/core/v1alpha1/transformer/policy_transformer.cue`

```cue
package transformer

import (
    "strings"
    t "opmodel.dev/core/v1alpha1/types@v1"
)

#PolicyTransformer: {
    apiVersion: "opmodel.dev/core/v1alpha1"
    kind:       "PolicyTransformer"

    metadata: {
        modulePath!:     t.#ModulePathType
        version!:        t.#MajorVersionType
        name!:           t.#NameType
        #definitionName: (t.#KebabToPascal & {"in": name}).out

        fqn: t.#FQNType & "\(modulePath)/\(name)@\(version)"
        description?: string
        labels?:      t.#LabelsAnnotationsType
        annotations?: t.#LabelsAnnotationsType
    }

    // ---- Match predicate ----

    // At least one directive FQN — the transformer matches any #Policy whose
    // #directives contains all listed FQNs.
    requiredDirectives!: [...t.#FQNType] & list.MinItems(1)

    // Optional traits — each component in the matched policy's appliesTo must
    // carry every trait FQN listed here. Common for operational commodities:
    // the transformer reads per-component facts from these traits.
    requiredTraits?: [...t.#FQNType]

    // Optional resources — each component must carry every resource FQN listed.
    // Rare for operational commodities; present for symmetry with #Transformer.
    requiredResources?: [...t.#FQNType]

    // Optional rules — the matching policy must also include all listed rule FQNs.
    // Allows a transformer to condition its output on platform governance.
    requiredRules?: [...t.#FQNType]

    // ---- Context inputs ----

    // Dotted paths into #ctx.platform that must be resolvable at render time.
    // Catalog does not validate these (paths are platform-team-defined), but
    // the render pipeline fails loudly when a declared path is missing.
    readsContext?: [...string]

    // ---- Output declaration ----

    // Kubernetes (or equivalent platform) kinds this transformer emits.
    // Used for diff surface, discovery, and conflict detection.
    producesKinds: [...string] & list.MinItems(1)

    // Render function value — opaque to the primitive layer.
    // Populated by provider-specific implementations; invoked by the pipeline
    // with a typed input containing directive spec, components' trait specs,
    // and resolved platform context.
    out: _
}

#PolicyTransformerMap: [string]: #PolicyTransformer
```

## Matching Rules

Given a module with `#policies`, a platform with composed `#policyTransformers`, and a render:

1. For each `#Policy` in `#policies`:
   1. Compute the covered component set from `appliesTo` (label selector and/or explicit names).
   2. For each `#Directive` in the policy's `#directives`:
      1. Find all `#PolicyTransformer`s in the composed platform whose `requiredDirectives` includes the directive's FQN.
      2. For each candidate transformer:
         - **Trait check** — For every FQN in `requiredTraits`, every component in the covered set must carry that trait. Otherwise, the transformer does not match for this policy.
         - **Resource check** — Same as trait check but for `requiredResources`.
         - **Rule check** — For every FQN in `requiredRules`, the policy must also contain that rule. Otherwise, no match.
         - **Context check** — Every path in `readsContext` must resolve against the rendered platform `#ctx`. Unresolved → render-time error.
      3. If exactly one transformer matches, invoke it. If zero → error. If more than one → platform-ordering precedence (see `#Platform.#providers` ordering in 008).

A transformer operating on a directive receives the full policy context: the covered component set's traits, the directive's spec, the policy's rules (read-only, for conditioning only — transformers do not emit rule effects), and the resolved slice of platform `#ctx`.

## Inputs Available At Render Time

The render function sees a strongly-typed input value:

```cue
{
    // The directive being realized (typed; same shape as the author wrote it).
    directive: D.#spec

    // The policy metadata and merged spec, for discovery (labels, name).
    policy: {
        name:   string
        labels: {...}
    }

    // Per-component input for every component in appliesTo.
    components: [compName=string]: {
        traits: {
            // Each FQN in requiredTraits resolves to its spec subfield.
            for traitFQN in transformer.requiredTraits {
                (traitFQN): ... component's trait spec for that FQN ...
            }
        }
        // Convenience: the component's resolved name variants + DNS.
        names: ctx.#ComponentNames
    }

    // Resolved slices of platform context — only the paths declared in readsContext.
    context: {
        for path in transformer.readsContext {
            // dotted path into #ctx.platform, resolved to its concrete value.
            (path): ...
        }
    }

    // Release identity (same as #ctx.runtime for component transformers).
    release: {
        name: string, namespace: string, uuid: string
    }
}
```

Output: a map of `(kind, name) → manifest` keyed the same way component-scope transformer output is keyed. The render pipeline merges policy-scope output with component-scope output and applies both together.

## `#Provider` Integration

`#Provider` gains `#policyTransformers`:

```cue
// catalog/core/v1alpha1/provider/provider.cue (modified)
#Provider: {
    ...

    #transformers:        transformer.#TransformerMap
    #policyTransformers?: transformer.#PolicyTransformerMap

    // Declared FQNs surface both maps so #Platform can compose them uniformly.
    #declaredDirectives: [
        for _, pt in #policyTransformers {
            for fqn in pt.requiredDirectives { fqn }
        }
    ]
}
```

### `#Platform` composition

`#Platform.#composedTransformers` (existing from 008) remains scoped to component transformers. A new field aggregates policy transformers:

```cue
#Platform: {
    ...
    #composedPolicyTransformers: transformer.#PolicyTransformerMap & {
        for _, p in #providers {
            if p.#policyTransformers != _|_ {
                p.#policyTransformers
            }
        }
    }
    #declaredDirectives: list.FlattenN([
        for _, p in #providers if p.#policyTransformers != _|_ {
            p.#declaredDirectives
        }
    ], 1)
}
```

FQN collision across providers produces a CUE unification error, same as the component transformer path.

## Conflict Resolution

If more than one policy transformer matches a given directive (same FQN from two different providers), `#Platform.#providers` list order breaks the tie — earlier provider wins. Same rule as component-scope from 008. Discouraged pattern; flagged in diagnostics if detected.

If two policy transformers from different providers emit resources with the same `(kind, namespace, name)` tuple, it is a conflict. The pipeline errors out at render time with both transformer FQNs in the message.

## Comparison With `#Transformer`

| Aspect | `#Transformer` | `#PolicyTransformer` |
| ------ | -------------- | -------------------- |
| Match subject | A `#Component` | A `#Directive` in a `#Policy` |
| Match predicate | `requiredResources` + `requiredTraits` | `requiredDirectives` (required) + `requiredTraits` / `requiredResources` / `requiredRules` (optional) |
| Cardinality | One invocation per matched component | One invocation per matched directive |
| Inputs | One component's spec + ctx | Directive spec + every covered component's trait spec + ctx slice |
| Output scope | Component-namespaced resources | Module-namespaced resources (typically one per directive invocation) |
| Provider field | `#transformers` | `#policyTransformers` |

## Future Extensions (Deferred)

- **Output attribution back to components.** A policy transformer may emit resources related to specific components (e.g., PVC annotations). Today output is module-scope; the render pipeline does not attribute module-scope output back to individual components. If future diagnostics or diff tooling needs that attribution, extend `out` to optionally tag each emitted resource with a component name.
- **Reading other components' resource specs.** `requiredResources` lets the transformer require a resource exists on a covered component; it does not currently pass the full resource spec into the render input. Add if a commodity needs it.
- **Cross-module directives.** Module A's directive instructing platform behavior touching module B's components. Not supported in v1; not expected to be needed for operational commodities.
