## Context

`#ConfigMapResource` and `#SecretResource` are singular resources — their `#spec` contains a single struct (`configMap: #ConfigMapSchema`, `secret: #SecretSchema`). The catalog already has a plural resource pattern established by `#VolumesResource`, which uses `volumes: [volumeName=string]: #VolumeSchema` to allow multiple named entries per component.

The `allow-list-output` sibling change introduces the `transformer.opmodel.dev/list-output: true` annotation for plural resources, which signals to consumers that a transformer emits a keyed map rather than a single object. This change converts ConfigMap and Secret to the same plural pattern, making them the second and third resources (after Volumes) to use it.

Current singular structure:

```cue
// configmap.cue
#ConfigMapResource: close(core.#Resource & {
    metadata: { name: "config-map", ... }
    #spec: configMap: schemas.#ConfigMapSchema
})

// secret.cue
#SecretResource: close(core.#Resource & {
    metadata: { name: "secret", ... }
    #spec: secret: schemas.#SecretSchema
})
```

The `#spec` field name is auto-derived from `metadata.name` via `#KebabToPascal` → `strings.ToCamel`. Changing `metadata.name` from `"config-map"` to `"config-maps"` automatically changes the spec field from `configMap` to `configMaps`. Same for `"secret"` → `"secrets"`.

## Goals / Non-Goals

**Goals:**

- Convert `#ConfigMapResource` and `#SecretResource` to the plural map pattern matching `#VolumesResource`
- Add `transformer.opmodel.dev/list-output: true` annotation to both
- Update Kubernetes transformers to emit keyed map output (matching `#PVCTransformer`)
- Maintain the existing three-part definition pattern: `#XxxResource`, `#Xxx` (composition), `#XxxDefaults`

**Non-Goals:**

- Changing `#ConfigMapSchema` or `#SecretSchema` — per-item schemas remain unchanged
- Converting any other resources or traits to plural
- Modifying `#VolumeSchema.configMap?` or `#VolumeSchema.secret?` — these are volume source references, not resource definitions
- Adding new schema fields or validation rules beyond what the map pattern requires

## Decisions

### 1. Follow the established Volumes pattern exactly

The plural resource definitions mirror `#VolumesResource` structurally:

```cue
#ConfigMapsResource: close(core.#Resource & {
    metadata: {
        apiVersion: "opmodel.dev/resources/config@v0"
        name:       "config-maps"
        annotations: {
            "transformer.opmodel.dev/list-output": true
        }
    }
    #defaults: #ConfigMapsDefaults
    #spec: configMaps: [name=string]: schemas.#ConfigMapSchema
})

#SecretsResource: close(core.#Resource & {
    metadata: {
        apiVersion: "opmodel.dev/resources/config@v0"
        name:       "secrets"
        annotations: {
            "transformer.opmodel.dev/list-output": true
        }
    }
    #defaults: #SecretsDefaults
    #spec: secrets: [name=string]: schemas.#SecretSchema & {type: string | *"Opaque"}
})
```

**Rationale:** Consistency. The Volumes pattern is proven and understood. Using the exact same structure means no new concepts, and the `list-output` annotation / transformer iteration / composition struct all work identically.

**Note on Secret defaults:** `#SecretDefaults` currently sets `type: "Opaque"`. In the plural pattern, per-entry defaults are applied via the spec constraint directly (`& {type: string | *"Opaque"}`), matching how Volumes applies `{name: string | *volumeName}`. `#SecretsDefaults` becomes a per-entry default template, same as `#VolumesDefaults`.

### 2. Transformers iterate the map and emit keyed output

Both transformers adopt the `#PVCTransformer` pattern — iterate over map entries and emit one K8s object per entry, keyed by the map key:

```
BEFORE (singular):                    AFTER (plural):

#transform: {                         #transform: {
    _configMap: spec.configMap            _configMaps: spec.configMaps
    output: {                             output: {
        apiVersion: "v1"                      for cmName, cm in _configMaps {
        kind: "ConfigMap"                         (cmName): {
        metadata: { name: ... }                       apiVersion: "v1"
        data: _configMap.data                         kind: "ConfigMap"
    }                                                 metadata: { name: cmName, ... }
}                                                     data: cm.data
                                                  }
                                              }
                                          }
                                      }
```

**Rationale:** This is how `#PVCTransformer` already works. The output key is the map entry name, and each value is a complete K8s object. Consumers that read the `list-output` annotation know to expect this shape.

**ConfigMap transformer**: Each entry becomes a K8s ConfigMap named by its map key, with `data` from the entry.

**Secret transformer**: Each entry becomes a K8s Secret named by its map key, with `type` and `data` from the entry.

### 3. FQN changes cascade through the system

Changing `metadata.name` changes the FQN (since FQN = `apiVersion#definitionName`):

```
BEFORE                                          AFTER
opmodel.dev/resources/config@v0#ConfigMap   →   opmodel.dev/resources/config@v0#ConfigMaps
opmodel.dev/resources/config@v0#Secret      →   opmodel.dev/resources/config@v0#Secrets
```

All references to these FQNs must be updated:

- Transformer `requiredResources` keys
- Provider `transformers` map (FQN keys are auto-derived from transformer metadata, but transformer `requiredResources` reference the resource FQN)
- Test data `#resources` maps

### 4. No schema changes needed

`#ConfigMapSchema` and `#SecretSchema` in `v0/schemas/config.cue` remain as-is. They define the per-item structure. The plural pattern wraps them in a map at the resource level, not the schema level. This is the same as how `#VolumeSchema` defines a single volume and `#VolumesResource` wraps it in `[string]: #VolumeSchema`.

The `#VolumeSchema.configMap?` and `#VolumeSchema.secret?` fields in `v0/schemas/storage.cue` are volume source references (mount a ConfigMap/Secret as filesystem) and are completely unrelated to the resource definitions.

## Risks / Trade-offs

**[Breaking API change]** → Accepted. At v0, breaking changes are expected. All definition names, FQNs, and spec field names change. Any external consumer referencing `#ConfigMapResource`, `#Secret`, `spec.configMap`, or `spec.secret` must update. Mitigated by the fact that no blueprints or examples currently use these resources.

**[Sibling change dependency]** → This change assumes the `allow-list-output` change has established the `transformer.opmodel.dev/list-output` annotation pattern. If that change is not yet merged, the annotation can still be added (CUE annotations are permissive), but the CLI won't recognize it until the sibling change lands. Mitigated by implementing both changes on the same timeline.

**[Empty map semantics]** → A component with `configMaps: {}` or `secrets: {}` is technically valid but produces no transformer output. This matches Volumes behavior — `volumes: {}` produces no PVCs. No special handling needed.
