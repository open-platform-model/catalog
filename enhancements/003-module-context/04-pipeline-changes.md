# Pipeline Changes

| Field       | Value            |
| ----------- | ---------------- |
| **Status**  | Draft            |
| **Created** | 2026-03-25       |
| **Authors** | OPM Contributors |

---

## End-to-End Flow

```
ModuleRelease (CUE)
  metadata: { name, namespace, uuid }
  #module: <module definition>
  #environment?: { clusterDomain, routeDomain }
  values: { ... }

  → #ContextBuilder computes _computedCtx from metadata + #environment + component keys
  → let unifiedModule = #module & {
        #config: values
        #ctx:    { runtime: _computedCtx, platform: {} }
    }
  → components: { for name, comp in unifiedModule.#components { (name): comp } }

CLI (Go)
  → ParseModuleRelease() loads the CUE value
  → If CLI has clusterDomain / routeDomain flags or config, inject via FillPath
      into #environment before evaluation
  → Evaluate unifiedModule.components
  → For each (component, transformer) pair:
      injectContext() fills #context in the transformer with #TransformerContext data
      (unchanged from current behavior)
  → Execute transformer → collect output resources
```

---

## `#ModuleRelease` Changes (CUE)

The `#ModuleRelease` definition gains two additions:

1. The optional `#environment` input field (see `03-schema.md`)
2. A `let` binding that invokes `#ContextBuilder` and passes the result into the unified module

```cue
// catalog/core/v1alpha1/modulerelease/module_release.cue
#ModuleRelease: {
    ...

    #environment?: {
        clusterDomain: *"cluster.local" | string
        routeDomain?:  string
        ...
    }

    let _env = #environment | {clusterDomain: "cluster.local"}

    let _computedCtx = (helpers.#ContextBuilder & {
        #release:     { name: metadata.name, namespace: metadata.namespace, uuid: metadata.uuid }
        #module:      { name: #moduleMetadata.name, version: #moduleMetadata.version,
                        fqn: #moduleMetadata.fqn, uuid: #moduleMetadata.uuid }
        #components:  #module.#components
        #environment: _env
    }).out

    let unifiedModule = #module & {
        #config: values
        #ctx:    { runtime: _computedCtx, platform: {} }
    }

    _autoSecrets: (schemas.#AutoSecrets & {#in: unifiedModule.#config}).out

    components: {
        for name, comp in unifiedModule.#components {
            (name): comp
        }
        if len(_autoSecrets) > 0 {
            "opm-secrets": (helpers.#OpmSecretsComponent & {#secrets: _autoSecrets}).out
        }
    }

    ...
}
```

The `platform` layer is initialized as an empty open struct. Platform teams populate it by injecting their own values via `FillPath` before evaluation, using the same mechanism as `#environment`.

---

## Go Pipeline Changes (`cli/pkg/render/`)

### `ParseModuleRelease()` — environment injection

When the CLI has cluster or route domain configuration available (from flags, config file, or provider defaults), it injects these into `#environment` before the CUE value is evaluated:

```go
// cli/pkg/module/parse.go (illustrative)
if cfg.ClusterDomain != "" || cfg.RouteDomain != "" {
    env := map[string]any{"clusterDomain": cfg.ClusterDomain}
    if cfg.RouteDomain != "" {
        env["routeDomain"] = cfg.RouteDomain
    }
    spec = spec.FillPath(cue.MakePath(cue.Def("environment")), cueCtx.Encode(env))
}
```

When `#environment` is not injected by Go, the CUE default (`clusterDomain: "cluster.local"`, no route) applies. This means the Go injection is additive and optional — the system works without it.

### `injectContext()` — no change required

The existing `injectContext()` function in `execute.go` fills `#TransformerContext` into each transformer at render time. This behavior is unchanged. `#ctx` is resolved during CUE evaluation of the unified module, before the transformer loop runs. By the time `injectContext()` is called, `#ctx` has already been resolved and is embedded in the component value.

The relationship between `#ctx` and `#TransformerContext` — whether to unify them, extend one from the other, or keep them separate — is deferred to a future design.

---

## Content Hash Injection

`#ctx.runtime.components[name].hashes` is the intended home for immutable resource content hashes. The computation of these hashes requires the resolved component spec, which in turn requires `#config` to be filled with `values`. The order of operations is:

```
1. values fills #config
2. #ctx (including resourceName, dns) is computed and fills #ctx
3. Component specs are evaluated with concrete #config and #ctx
4. Content hashes are derived from the concrete configMap/secret data in component specs
5. Hashes are injected back into #ctx.runtime.components[name].hashes
```

Step 5 creates a circular dependency if done purely in CUE: `#ctx` must be present to derive component specs, but content hashes require the evaluated component specs. Two implementation strategies are available:

**Strategy A — Two-pass CUE evaluation**: `#ctx` is injected without hashes first. Component specs are evaluated. Hashes are computed from the resolved data, then `#ctx` is re-injected with hashes populated via a second `FillPath` call. Components that reference hashes (e.g., for constructing an immutable ConfigMap name in an env var) use the second pass result.

**Strategy B — Hash computation deferred to transformers**: `#ctx.runtime.components[name].hashes` is populated by Go code in `injectContext()` rather than in `#ContextBuilder`. The Go pipeline computes hashes from the resolved component spec before calling transformers, and injects them into the context at that point. This mirrors how `#resolvedNames` was designed in `02-resource-name-override`.

Strategy B is lower risk because it follows the existing pattern and avoids a second CUE evaluation pass. It is the recommended starting point. Strategy A can be adopted later if there is a strong need for components to reference their own hash values at definition time (e.g., to self-reference an immutable ConfigMap name in an environment variable).

---

## Release File — Operator Usage

A release file gains an optional `#environment` block alongside the existing `values` block:

```cue
// releases/home/jellyfin/release.cue
#module: jellyfin_module.#Module & jellyfinModule

metadata: {
    name:      "jellyfin"
    namespace: "media"
}

#environment: {
    clusterDomain: "cluster.local"
    routeDomain:   "home.example.com"
}

values: {
    port:        8096
    serviceType: "ClusterIP"
    storage: config: {
        type: "pvc"
        size: "20Gi"
    }
}
```

With this configuration, `#ctx.runtime.route.domain` resolves to `"home.example.com"` inside the module's components, and `publishedServerUrl` is derived automatically — no entry in `values` required.
