# Experiment 001: Config Sources

Unified abstraction for injecting configuration and secrets into workloads without hardcoding values in environment variables.

## Problem

OPM currently forces plaintext values in container `env` fields — there's no way to reference a Secret or ConfigMap by name. This means sensitive data like database passwords must be inlined, and there's no mechanism to reference pre-existing cluster resources (e.g., a TLS cert managed by cert-manager).

## Solution

Three new primitives:

1. **`#ConfigSourceSchema`** (`schemas/config.cue`) — A named config source with a `type` discriminator (`"config"` | `"secret"`), and either inline `data` or an `externalRef`.

2. **`#EnvVarSchema`** (`schemas/workload.cue`) — Extended env var schema supporting `from: { source, key }` alongside the existing `value` field (mutually exclusive).

3. **`#ConfigSourceTransformer`** (`providers/kubernetes/transformers/config_source_transformer.cue`) — Emits K8s ConfigMap/Secret for inline sources, nothing for external refs. All five workload transformers resolve `env.from` into K8s `valueFrom.configMapKeyRef` or `valueFrom.secretKeyRef`.

## Structure

```
experiments/001-config-sources/
├── cue.mod/module.cue          # Self-contained module (example.com/config-sources)
├── core/                       # Copied from v0/core/ (import paths rewritten)
├── schemas/
│   ├── config.cue              # +#ConfigSourceSchema
│   └── workload.cue            # +#EnvVarSchema (env.from support)
├── resources/config/
│   └── config_source.cue       # #ConfigSourceResource + #ConfigSources helper
├── providers/kubernetes/
│   ├── provider.cue            # Registers ConfigSourceTransformer
│   └── transformers/
│       ├── config_source_transformer.cue   # NEW — emits ConfigMap/Secret
│       ├── deployment_transformer.cue      # MODIFIED — env.from resolution
│       ├── statefulset_transformer.cue     # MODIFIED
│       ├── daemonset_transformer.cue       # MODIFIED
│       ├── job_transformer.cue             # MODIFIED
│       └── cronjob_transformer.cue         # MODIFIED
├── examples/
│   ├── web_app.cue             # Example component with all 3 source types
│   ├── web_app_module.cue      # Module wrapper with parameterization
│   ├── output.cue              # Exportable K8s output
│   └── transform_test.cue      # Vet-time validation assertions
├── traits/                     # Copied from v0/traits/ (unchanged)
└── README.md
```

## Usage Example

```cue
spec: {
    configSources: {
        "app-settings": {
            type: "config"
            data: LOG_LEVEL: "info"
        }
        "db-credentials": {
            type: "secret"
            data: password: "changeme"
        }
        "tls-cert": {
            type: "secret"
            externalRef: name: "wildcard-tls-cert"
        }
    }
    container: {
        name:  "web"
        image: "myapp:v1.0.0"
        env: {
            NODE_ENV:    { name: "NODE_ENV",    value: "production" }
            DB_PASSWORD: { name: "DB_PASSWORD", from: { source: "db-credentials", key: "password" } }
            TLS_KEY:     { name: "TLS_KEY",     from: { source: "tls-cert", key: "tls.key" } }
        }
    }
}
```

This produces:

- A K8s **ConfigMap** `web-app-app-settings` (inline config)
- A K8s **Secret** `web-app-db-credentials` (inline secret)
- **Nothing** for `tls-cert` (external ref — already exists in cluster)
- A Deployment with `valueFrom.configMapKeyRef` / `valueFrom.secretKeyRef` on env vars that use `from`

## Testing

All commands should be run from the experiment root:

```bash
cd experiments/001-config-sources
```

Set CUE environment variables:

```bash
export CUE_REGISTRY=localhost:5000
export CUE_CACHE_DIR=/var/home/emil/Dev/open-platform-model/.cue-cache
```

### Validate all definitions

```bash
cue vet ./...
```

This validates the entire module — schemas, resources, traits, transformers, and examples — including the vet-time assertions in `examples/transform_test.cue`.

### Export K8s output

```bash
cue export ./examples/ -e k8sOutput --out yaml
```

This renders the web app example through the K8s transformers and outputs concrete ConfigMap, Secret, and Deployment manifests. Verify:

- `configSources.app-settings` — ConfigMap with `LOG_LEVEL` and `APP_PORT`
- `configSources.db-credentials` — Secret with `username` and `password`
- No entry for `tls-cert` (external ref)
- `deployment.spec.template.spec.containers[0].env` — mix of plain `value` and `valueFrom` refs

### Format check

```bash
cue fmt ./...
```

Should produce no changes if code is already formatted.

### Evaluate specific definitions

```bash
# Inspect the ConfigSource schema
cue eval ./schemas/ -e '#ConfigSourceSchema'

# Inspect the EnvVar schema
cue eval ./schemas/ -e '#EnvVarSchema'

# Inspect the ConfigSource resource definition
cue eval ./resources/config/ -e '#ConfigSourceResource'
```

## Design Decisions

See the full design document at `openspec/changes/config-sources/design.md`. Key decisions:

| ID | Decision | Rationale |
|----|----------|-----------|
| D1 | Unified type with `"config"` / `"secret"` discriminator | Avoids separate ConfigMap/Secret resources; one concept, one field |
| D2 | Pull model (`env.from` references source) | Container declares what it needs; no push/injection magic |
| D3 | `data` / `externalRef` mutual exclusivity | A source is either inline or external, never both |
| D4 | External refs use simple `name` string | Documented as external-only; no namespace (platform handles it) |
| D5 | Inline sources generate `{component}-{source}` K8s names | Predictable, collision-free naming |
| D6 | External refs emit nothing | Resource already exists; transformer skips it |

## Known Limitations

- OPM-level fields (`from`, `name`) leak into K8s output alongside `valueFrom` — the transformer unifies rather than projects. This is a pre-existing transformer pattern issue, not specific to config sources.
- Deployment `ports` render as a struct (keyed by name) rather than a K8s list — same pre-existing issue.
- Secret `data` values are not base64-encoded in the output — the transformer emits plaintext, matching the current OPM convention.
